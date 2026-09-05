terraform {
  backend "s3" {
    bucket = "terraformnakka27"
    key    = "terraform/backend"
    region = "us-east-1"
  }
}