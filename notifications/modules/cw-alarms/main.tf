# Errores de Lambda
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "${var.lambda_function_name}-errors"
  alarm_description   = "Errores en Lambda ${var.lambda_function_name}"
  namespace           = "AWS/Lambda"
  metric_name         = "Errors"
  statistic           = "Sum"
  period              = var.period_seconds
  evaluation_periods  = var.eval_periods
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"

  dimensions = { FunctionName = var.lambda_function_name }

  alarm_actions = [var.sns_topic_arn]
  ok_actions    = [var.sns_topic_arn]
  tags          = var.tags
}

# Envejecimiento de mensajes en SQS
resource "aws_cloudwatch_metric_alarm" "sqs_oldest_age" {
  alarm_name          = "${var.sqs_queue_name}-oldest-age"
  alarm_description   = "SQS ${var.sqs_queue_name} acumula mensajes (age > ${var.sqs_oldest_age_seconds}s)"
  namespace           = "AWS/SQS"
  metric_name         = "ApproximateAgeOfOldestMessage"
  statistic           = "Maximum"
  period              = var.period_seconds
  evaluation_periods  = var.eval_periods
  threshold           = var.sqs_oldest_age_seconds
  comparison_operator = "GreaterThanThreshold"

  dimensions = { QueueName = var.sqs_queue_name }

  alarm_actions = [var.sns_topic_arn]
  ok_actions    = [var.sns_topic_arn]
  tags          = var.tags
}
