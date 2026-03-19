variable "provider" {
  description = "Cloud provider to use: aws or digitalocean"
  type        = string

  validation {
    condition     = contains(["aws", "digitalocean"], var.provider)
    error_message = "Provider must be 'aws' or 'digitalocean'."
  }
}

variable "ssh_public_key" {
  description = "SSH public key content for server access"
  type        = string
}

variable "region" {
  description = "Cloud provider region (defaults: nyc3 for DO, us-east-1 for AWS)"
  type        = string
  default     = ""
}

variable "server_name" {
  description = "Name for the server and related resources"
  type        = string
  default     = "towlion"
}
