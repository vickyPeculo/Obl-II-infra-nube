variable "lambda_function_name" { type = string }
variable "sqs_queue_name" { type = string }
variable "sns_topic_arn" { type = string }

variable "sqs_oldest_age_seconds" {
  type    = number
  default = 60
}

variable "period_seconds" {
  type    = number
  default = 60
}

variable "eval_periods" {
  type    = number
  default = 5
}

variable "tags" {
  type    = map(string)
  default = {}
}
