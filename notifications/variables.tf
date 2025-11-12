variable "region" {
  type        = string
  description = "AWS region"
  default     = "us-east-2"
}

variable "alert_email" {
  type        = string
  description = "Email destino de notificaciones"
}
