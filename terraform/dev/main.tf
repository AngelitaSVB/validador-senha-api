resource "aws_s3_bucket" "placeholder" {
  bucket = "validador-dev-placeholder"
  region = "sa-east-1"

  lifecycle {
    prevent_destroy = true
    ignore_changes  = all
  }
}
