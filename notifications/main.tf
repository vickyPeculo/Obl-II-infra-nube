terraform {
  required_version = ">= 1.6"
  required_providers {
    aws     = { source = "hashicorp/aws", version = ">= 5.0" }
    archive = { source = "hashicorp/archive", version = ">= 2.4" }
  }
}

provider "aws" {
  region = var.region
}

module "sqs_articles" {
  source                     = "./modules/sqs-queue"
  name                       = "certeza360-articles-queue"
  message_retention_seconds  = 345600
  visibility_timeout_seconds = 30
  max_message_size           = 262144
  receive_wait_time_seconds  = 0
  tags                       = { Name = "sqs-articles" }
}

module "sns_alerts" {
  source = "./modules/sns-topic"
  name   = "certeza360-alerts"
  email  = var.alert_email
  tags   = { Name = "sns-alerts" }
}

module "lambda_notify" {
  source          = "./modules/lambda-sqs-to-sns"
  function_name   = "certeza360-notify"
  sqs_queue_arn   = module.sqs_articles.arn
  sqs_queue_name  = module.sqs_articles.name
  sns_topic_arn   = module.sns_alerts.arn
  runtime         = "nodejs20.x"
  batch_size      = 5
  batching_window = 10
  tags            = { Name = "lambda-notify" }
}

module "cw_alarms" {
  source                 = "./modules/cw-alarms"
  lambda_function_name   = module.lambda_notify.function_name
  sqs_queue_name         = module.sqs_articles.name
  sns_topic_arn          = module.sns_alerts.arn
  sqs_oldest_age_seconds = 60
  period_seconds         = 60
  eval_periods           = 5
  tags                   = { Name = "cw-notify-alarms" }
}
