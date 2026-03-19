output "server_ip" {
  value = digitalocean_droplet.server.ipv4_address
}

output "ssh_command" {
  value = "ssh -i keys/towlion root@${digitalocean_droplet.server.ipv4_address}"
}

output "bootstrap_command" {
  value = "scp -i keys/towlion bootstrap-server.sh root@${digitalocean_droplet.server.ipv4_address}:/root/ && ssh -i keys/towlion root@${digitalocean_droplet.server.ipv4_address} 'bash /root/bootstrap-server.sh'"
}
