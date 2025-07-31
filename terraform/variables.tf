variable "image_url" {
  description = "URL da imagem Docker"
  type        = string
}

variable "client_id" {
  description = "Client ID da aplicação"
  type        = string
}

variable "client_secret" {
  description = "Client Secret da aplicação"
  type        = string
}

variable "vpc_id" {
  description = "VPC onde o serviço será executado"
  type        = string
}

variable "subnet_ids" {
  description = "Subnets públicas da VPC"
  type        = list(string)
}

variable "jwt_secret" {
  description = "JWT secret for the backend"
  type        = string
}

variable "region" {
  description = "Região da AWS"
  default     = "sa-east-1"
}
