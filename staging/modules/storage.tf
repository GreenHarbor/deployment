resource "aws_s3_bucket" "my_bucket" {
  bucket = "greenharbor-bucket"

  tags = {
    Name        = "greenharbor-bucket"
    Environment = "production"
  }
}
