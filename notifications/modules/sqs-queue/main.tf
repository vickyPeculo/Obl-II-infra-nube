resource "aws_sqs_queue" "this" {
  name                       = var.name
  message_retention_seconds  = var.message_retention_seconds
  visibility_timeout_seconds = var.visibility_timeout_seconds
  max_message_size           = var.max_message_size
  receive_wait_time_seconds  = var.receive_wait_time_seconds
  tags                       = var.tags
}
