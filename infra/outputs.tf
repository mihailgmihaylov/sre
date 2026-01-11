output "load_balancer_ip" {
  description = "External IP address of the HTTP load balancer."
  value       = google_compute_global_address.lb.address
}

output "load_balancer_url" {
  description = "URL served by the sample web application."
  value       = "http://${google_compute_global_address.lb.address}"
}

output "database_internal_ip" {
  description = "Internal IP address of the database VM."
  value       = google_compute_instance.database.network_interface[0].network_ip
}

output "database_connection_hint" {
  description = "Command to connect to the database from the web subnet."
  value       = "mysql -h ${google_compute_instance.database.network_interface[0].network_ip} -u appuser -p"
  sensitive   = true
}
