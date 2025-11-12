variable "name" { type = string }
variable "message_retention_seconds" { type = number }
variable "visibility_timeout_seconds" { type = number }
variable "max_message_size" { type = number }
variable "receive_wait_time_seconds" { type = number }

variable "tags" {
  type    = map(string)
  default = {}
}
