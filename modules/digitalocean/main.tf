resource "digitalocean_ssh_key" "towlion" {
  name       = var.server_name
  public_key = var.ssh_public_key
}

resource "digitalocean_volume" "data" {
  region                  = var.region
  name                    = "${var.server_name}-data"
  size                    = 50
  initial_filesystem_type = "ext4"
}

resource "digitalocean_droplet" "server" {
  name     = var.server_name
  image    = "debian-12-x64"
  size     = "s-2vcpu-4gb"
  region   = var.region
  ssh_keys = [digitalocean_ssh_key.towlion.fingerprint]

  user_data = file("${path.root}/cloud-init.sh")
}

resource "digitalocean_volume_attachment" "data" {
  droplet_id = digitalocean_droplet.server.id
  volume_id  = digitalocean_volume.data.id
}

resource "digitalocean_firewall" "server" {
  name        = "${var.server_name}-firewall"
  droplet_ids = [digitalocean_droplet.server.id]

  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "80"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "443"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "tcp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "udp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "icmp"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
}
