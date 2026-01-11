terraform {
  required_version = ">= 1.5.0"

  backend "gcs" {
    bucket = "sre-terraform-state-mihail-mihaylov"
    prefix = "terraform/state"
  }
}
