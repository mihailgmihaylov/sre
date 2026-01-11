variable "project_id" {
  description = "Google Cloud project ID."
  type        = string
}

variable "region" {
  description = "Region for regional resources."
  type        = string
  default     = "us-central1"
}

variable "web_zone" {
  description = "Zone where the web instance group runs."
  type        = string
  default     = "us-central1-a"
}

variable "db_zone" {
  description = "Zone for the database VM."
  type        = string
  default     = "us-central1-a"
}

variable "web_instance_count" {
  description = "Number of VM instances in the web managed instance group."
  type        = number
  default     = 2
}

variable "database_password" {
  description = "Password for the application MySQL user."
  type        = string
  sensitive   = true
}

variable "database_root_password" {
  description = "Password for the MySQL root user."
  type        = string
  sensitive   = true
}
