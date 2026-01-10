   terraform {
     backend "gcs" {
       bucket  = "sre-terraform-state-mihail-mihaylov"
       prefix  = "terraform/state"
     }
   }
