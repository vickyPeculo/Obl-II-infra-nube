locals {
  index_js = <<-EOF
    const { S3Client, PutObjectCommand } = require("@aws-sdk/client-s3");
    const { SQSClient, SendMessageCommand } = require("@aws-sdk/client-sqs");
    const crypto = require("crypto");

    const s3  = new S3Client({ region: process.env.AWS_REGION });
    const sqs = new SQSClient({ region: process.env.AWS_REGION });

    // Generador automático sin IA
    function generateArticle(topic) {
      const body =
        "<h2>Introducción</h2>\n" +
        "<p>Este artículo fue generado automáticamente a partir del tópico <strong>" + topic + "</strong>.</p>\n" +
        "<h2>Desarrollo</h2>\n" +
        "<p>En esta sección se presentan conceptos relevantes, explicaciones funcionales y detalles técnicos relacionados con el tema.</p>\n" +
        "<p>El objetivo es proveer información clara y estructurada sin depender de ningún modelo de IA externa.</p>\n" +
        "<h2>Conclusión</h2>\n" +
        "<p>Este artículo demuestra la capacidad del sistema de generar contenido de forma automática, desacoplada y sin interacción directa con el servicio principal.</p>\n";

      return {
        title: "Artículo sobre: " + topic,
        body,
        createdAt: new Date().toISOString(),
        source: "template"
      };
    }

    exports.handler = async (event) => {
      const records = event.Records ?? [];

      for (const r of records) {
        const req   = JSON.parse(r.body || "{}");
        const topic = req.topic || "Tema sin título";
        const id    = req.id || crypto.randomUUID();

        const now  = new Date();
        const yyyy = now.getUTCFullYear();
        const mm   = String(now.getUTCMonth() + 1).padStart(2, "0");
        const dd   = String(now.getUTCDate()).padStart(2, "0");
        const key  = yyyy + "/" + mm + "/" + dd + "/" + id + ".json";

        const generated = generateArticle(topic);

        await s3.send(new PutObjectCommand({
          Bucket: process.env.ARTICLES_BUCKET,
          Key: key,
          Body: JSON.stringify(generated, null, 2),
          ContentType: "application/json"
        }));

        await sqs.send(new SendMessageCommand({
          QueueUrl: process.env.NOTIFY_QUEUE_URL,
          MessageBody: JSON.stringify({ title: generated.title, id })
        }));

        console.log("Artículo generado y guardado:", key);
      }

      return { ok: true, processed: records.length };
    };
  EOF
}

data "archive_file" "zip" {
  type        = "zip"
  output_path = "${path.module}/generator.zip"
  source {
    content  = local.index_js
    filename = "index.js"
  }
}

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

data "aws_iam_policy_document" "doc" {
  # Logs
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["arn:aws:logs:*:*:log-group:/aws/lambda/${var.function_name}:*"]
  }

  # Leer de cola generate
  statement {
    effect = "Allow"
    actions = [
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
      "sqs:GetQueueUrl"
    ]
    resources = ["arn:aws:sqs:*:*:${var.generate_queue_name}"]
  }

  # Enviar a cola notify
  statement {
    effect = "Allow"
    actions = [
      "sqs:SendMessage",
      "sqs:GetQueueUrl"
    ]
    resources = ["*"]
  }

  # Guardar artículos en S3
  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:PutObjectAcl"
    ]
    resources = ["arn:aws:s3:::${var.articles_bucket_name}/*"]
  }
}

resource "aws_iam_policy" "policy" {
  name   = "${var.function_name}-policy"
  policy = data.aws_iam_policy_document.doc.json
}

resource "aws_iam_role_policy_attachment" "attach" {
  role       = aws_iam_role.role.name
  policy_arn = aws_iam_policy.policy.arn
}

resource "aws_cloudwatch_log_group" "lg" {
  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = 14
  tags              = var.tags
}

resource "aws_lambda_function" "this" {
  function_name    = var.function_name
  role             = aws_iam_role.role.arn
  runtime          = var.runtime
  handler          = "index.handler"
  filename         = data.archive_file.zip.output_path
  source_code_hash = data.archive_file.zip.output_base64sha256

  architectures = ["arm64"]
  memory_size   = 256
  timeout       = 30

  environment {
    variables = {
      ARTICLES_BUCKET  = var.articles_bucket_name
      NOTIFY_QUEUE_URL = var.notify_queue_url
      OPENAI_API_KEY   = var.openai_api_key
      OPENAI_MODEL     = var.openai_model
    }
  }

  depends_on = [aws_cloudwatch_log_group.lg]
  tags       = var.tags
}

resource "aws_lambda_event_source_mapping" "esm" {
  event_source_arn                   = var.generate_queue_arn
  function_name                      = aws_lambda_function.this.arn
  batch_size                         = 1
  maximum_batching_window_in_seconds = 5
  enabled                            = true
}
