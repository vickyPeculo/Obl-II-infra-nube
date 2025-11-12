resource "aws_sqs_queue" "this" {
  name                       = var.name
  visibility_timeout_seconds = var.visibility
  message_retention_seconds  = var.retention_secs
  max_message_size           = 262144
  receive_wait_time_seconds  = 0
  tags                       = var.tags
}

# DLQ mínima
resource "aws_sqs_queue" "dlq" {
  name                       = "${var.name}-dlq"
  visibility_timeout_seconds = 60
  message_retention_seconds  = 1209600
  tags                       = var.tags
}

resource "aws_sqs_queue_redrive_policy" "rp" {
  queue_url = aws_sqs_queue.this.url
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = 5
  })
}
