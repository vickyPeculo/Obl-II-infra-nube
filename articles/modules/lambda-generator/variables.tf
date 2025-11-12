variable "function_name" { type = string }
variable "runtime" { type = string }
variable "generate_queue_arn" { type = string }
variable "generate_queue_name" { type = string }
variable "articles_bucket_name" { type = string }
variable "notify_queue_url" { type = string }

variable "openai_api_key" { type = string }
variable "openai_model" { type = string }

variable "tags" {
  type    = map(string)
  default = {}
}
