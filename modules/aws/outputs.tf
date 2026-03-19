output "server_ip" {
  value = aws_instance.server.public_ip
}

output "ssh_command" {
  value = "ssh -i keys/towlion root@${aws_instance.server.public_ip}"
}

output "bootstrap_command" {
  value = "scp -i keys/towlion bootstrap-server.sh root@${aws_instance.server.public_ip}:/root/ && ssh -i keys/towlion root@${aws_instance.server.public_ip} 'bash /root/bootstrap-server.sh'"
}
