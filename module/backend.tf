terraform {
  backend "s3" {
    bucket  = "teera-tf" # Replace with your bucket name
    key     = "prometheus/terraform.tfstate"
    region  = "eu-north-1"
    encrypt = true
  }
}