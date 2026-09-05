variable "REGION" {
  default = "us-east-1"
}

variable "zone1" {
  default = "us-east-1a"
}

variable "amiID" {
  type = map(any)
  default = {
    us-east-1 = "ami-0abcdef1234567890"
    us-east-2 = "ami-0fedcba0987654321"
  }
}

variable "webuser" {
  default = "ubuntu"
}