
variable "image_url" {}
variable "client_id" {}
variable "client_secret" {}
variable "vpc_id" {}
variable "subnet_ids" {
  type = list(string)
}
