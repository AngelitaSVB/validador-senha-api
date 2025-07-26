provider "aws" {
  region = "sa-east-1" 
}

resource "aws_s3_bucket" "placeholder" {
  bucket = "validador-dev-placeholder"
}
