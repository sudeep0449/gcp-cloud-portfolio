output "vpc_name" {
  value = google_compute_network.vpc.name
}

output "subnets" {
  value = { for k, s in google_compute_subnetwork.tiers : k => s.ip_cidr_range }
}

output "app_vm_internal_ip" {
  value = google_compute_instance.app.network_interface[0].network_ip
}

output "ssh_command" {
  value = "gcloud compute ssh ${google_compute_instance.app.name} --zone=${var.zone} --tunnel-through-iap"
}
