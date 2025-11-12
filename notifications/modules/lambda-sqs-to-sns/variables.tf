variable "function_name" { type = string }
variable "runtime" { type = string }
variable "sqs_queue_arn" { type = string }
variable "sqs_queue_name" { type = string }
variable "sns_topic_arn" { type = string }

variable "batch_size" {
  type    = number
  default = 5
}

variable "batching_window" {
  type    = number
  default = 10
}

variable "tags" {
  type    = map(string)
  default = {}
}
