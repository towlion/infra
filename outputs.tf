output "server_ip" {
  description = "Public IP address of the provisioned server"
  value       = var.provider == "digitalocean" ? module.digitalocean[0].server_ip : module.aws[0].server_ip
}

output "ssh_command" {
  description = "SSH command to connect to the server"
  value       = var.provider == "digitalocean" ? module.digitalocean[0].ssh_command : module.aws[0].ssh_command
}

output "bootstrap_command" {
  description = "Command to bootstrap the server with Towlion"
  value       = var.provider == "digitalocean" ? module.digitalocean[0].bootstrap_command : module.aws[0].bootstrap_command
}

output "nameservers" {
  description = "Nameservers to configure at your domain registrar"
  value       = var.domain == "" ? [] : (
    var.provider == "digitalocean" ? module.digitalocean[0].nameservers : module.aws[0].nameservers
  )
}
