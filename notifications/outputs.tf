output "sqs_queue_url" {
  value = module.sqs_articles.url
}

output "sns_topic_arn" {
  value = module.sns_alerts.arn
}

output "lambda_name" {
  value = module.lambda_notify.function_name
}
