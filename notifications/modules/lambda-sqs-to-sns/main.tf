locals {
  index_js = <<-EOF
    const { SNSClient, PublishCommand } = require("@aws-sdk/client-sns");

    // crea el cliente en la región actual (Lambda setea AWS_REGION)
    const sns = new SNSClient({ region: process.env.AWS_REGION });

    exports.handler = async (event) => {
      const topicArn = process.env.SNS_TOPIC_ARN;
      const records  = (event && event.Records) ? event.Records : [];

      const titles = [];
      for (const rec of records) {
        try {
          const body = JSON.parse(rec.body || "{}");
          if (body && body.title) titles.push(body.title);
        } catch (_) { /* ignorar parse y seguir */ }
      }

      const total  = records.length;
      const titled = titles.length;

      const subject = titled > 0
        ? "Nuevo" + (titled > 1 ? "s" : "") +
          " artículo" + (titled > 1 ? "s" : "") +
          " generado" + (titled > 1 ? "s" : "") +
          " (" + titled + ")"
        : "Mensajes procesados (" + total + ")";

      const message =
        "Se procesaron " + total + " mensaje(s) de SQS.\\n" +
        (titled > 0 ? "Títulos: " + titles.join(", ") : "Sin títulos detectados.");

      try {
        await sns.send(new PublishCommand({
          TopicArn: topicArn,
          Subject:  subject,
          Message:  message
        }));
        console.log("Notificación enviada:", subject);
        return { ok: true, processed: total };
      } catch (err) {
        console.error("Error publicando en SNS:", err && (err.stack || err.message || err));
        throw err; // para que CloudWatch cuente el error (alarma)
      }
    };
  EOF
}

# Empaqueta la función
data "archive_file" "lambda_zip" {
  type        = "zip"
  output_path = "${path.module}/lambda.zip"

  source {
    content  = local.index_js
    filename = "index.js"
  }
}

# Rol IAM para la Lambda
resource "aws_iam_role" "role" {
  name = "${var.function_name}-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "lambda.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
  tags = var.tags
}

# Política mínima: logs + SNS + SQS
data "aws_iam_policy_document" "policy_doc" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      "arn:aws:logs:*:*:log-group:/aws/lambda/${var.function_name}:*"
    ]
  }

  statement {
    effect    = "Allow"
    actions   = ["sns:Publish"]
    resources = [var.sns_topic_arn]
  }

  statement {
    effect = "Allow"
    actions = [
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
      "sqs:GetQueueUrl"
    ]
    resources = ["arn:aws:sqs:*:*:${var.sqs_queue_name}"]
  }
}

resource "aws_iam_policy" "policy" {
  name   = "${var.function_name}-policy"
  policy = data.aws_iam_policy_document.policy_doc.json
}

resource "aws_iam_role_policy_attachment" "attach" {
  role       = aws_iam_role.role.name
  policy_arn = aws_iam_policy.policy.arn
}

# Log group con retención de 14 días
resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = 14
  tags              = var.tags
}

# Función Lambda
resource "aws_lambda_function" "this" {
  function_name    = var.function_name
  role             = aws_iam_role.role.arn
  runtime          = var.runtime
  handler          = "index.handler"
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  architectures = ["arm64"]
  memory_size   = 128
  timeout       = 10

  environment {
    variables = {
      SNS_TOPIC_ARN = var.sns_topic_arn
      LOG_LEVEL     = "INFO"
    }
  }

  depends_on = [aws_cloudwatch_log_group.this]
  tags       = var.tags
}

# Trigger SQS -> Lambda
resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  event_source_arn                   = var.sqs_queue_arn
  function_name                      = aws_lambda_function.this.arn
  batch_size                         = var.batch_size
  maximum_batching_window_in_seconds = var.batching_window
  enabled                            = true
}

