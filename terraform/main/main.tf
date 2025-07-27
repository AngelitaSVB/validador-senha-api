provider "aws" {
  region = "sa-east-1"
}

resource "aws_s3_bucket" "placeholder" {
  bucket = "validador-prod-placeholder"

  lifecycle {
    prevent_destroy = true
    ignore_changes  = all
  }
}
