variable "aws_region" {
  type    = string
  default = "us-east-2"
}

variable "aws_profile" {
  type    = string
  default = "terraform"
}

variable "db_username" {
  type    = string
  default = "root"
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "alert_email" {
  type    = string
  default = "m.vicky.peculo@gmail.com"
}

variable "image_tag" {
  type = string
}
