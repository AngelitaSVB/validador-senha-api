
variable "image_url" {
  description = "Docker image usada pelo ECS"
  type        = string
}

variable "client_id" {
  description = "Client ID para autenticação"
  type        = string
}

variable "client_secret" {
  description = "Client Secret para autenticação"
  type        = string
}

variable "vpc_id" {
  description = "ID da VPC"
  type        = string
}

variable "subnet_ids" {
  description = "Lista de Subnets"
  type        = list(string)
}
