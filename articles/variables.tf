variable "region" {
  type        = string
  description = "Región de despliegue (Lambda/S3/SQS)"
  default     = "us-east-2"
}

variable "articles_bucket_name" {
  type        = string
  description = "Nombre del bucket S3 para artículos"
  default     = "certeza360-articles-content"
}

variable "notify_queue_url" {
  type        = string
  description = "URL de la cola SQS que ya dispara notificaciones (certeza360-articles-queue)"
}

variable "openai_api_key" {
  type        = string
  description = "API key de OpenAI para generar artículos"
  sensitive   = true
}

variable "openai_model" {
  type        = string
  description = "Modelo de OpenAI a utilizar"
  default     = "gpt-4o-mini"
}
