resource "aws_sns_topic" "this" {
  name = var.name
  tags = var.tags
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn                       = aws_sns_topic.this.arn
  protocol                        = "email"
  endpoint                        = var.email
  confirmation_timeout_in_minutes = 1
}
