module "digitalocean" {
  source = "./modules/digitalocean"
  count  = var.cloud_provider == "digitalocean" ? 1 : 0

  server_name    = var.server_name
  ssh_public_key = var.ssh_public_key
  region         = var.region != "" ? var.region : "nyc3"
  domain         = var.domain
}

module "aws" {
  source = "./modules/aws"
  count  = var.cloud_provider == "aws" ? 1 : 0

  server_name    = var.server_name
  ssh_public_key = var.ssh_public_key
  region         = var.region != "" ? var.region : "us-east-1"
  domain         = var.domain
}
