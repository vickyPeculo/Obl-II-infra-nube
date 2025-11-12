variable "name" {
  type        = string
  description = "Nombre del tópico SNS"
}

variable "email" {
  type        = string
  description = "Email para suscripción al tópico SNS"
}

variable "tags" {
  type    = map(string)
  default = {}
}
