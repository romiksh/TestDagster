resource "random_id" "suffix" { byte_length = 4 }
resource "aws_s3_bucket" "io" {
  bucket = "${local.name}-io-${random_id.suffix.hex}"
  tags   = local.tags
}
