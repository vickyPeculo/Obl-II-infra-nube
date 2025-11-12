variable "name" { type = string }
variable "visibility" { type = number }
variable "retention_secs" { type = number }

variable "tags" {
  type    = map(string)
  default = {}
}
