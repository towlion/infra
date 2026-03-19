data "aws_ami" "debian" {
  most_recent = true
  owners      = ["136693071363"]

  filter {
    name   = "name"
    values = ["debian-12-amd64-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_key_pair" "towlion" {
  key_name   = var.server_name
  public_key = var.ssh_public_key
}

resource "aws_security_group" "server" {
  name        = "${var.server_name}-sg"
  description = "Towlion server security group"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "server" {
  ami                    = data.aws_ami.debian.id
  instance_type          = "t3.medium"
  key_name               = aws_key_pair.towlion.key_name
  vpc_security_group_ids = [aws_security_group.server.id]

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  user_data = file("${path.root}/cloud-init.sh")

  tags = {
    Name = var.server_name
  }
}

resource "aws_ebs_volume" "data" {
  availability_zone = aws_instance.server.availability_zone
  size              = 50
  type              = "gp3"

  tags = {
    Name = "${var.server_name}-data"
  }
}

resource "aws_volume_attachment" "data" {
  device_name = "/dev/xvdf"
  volume_id   = aws_ebs_volume.data.id
  instance_id = aws_instance.server.id
}
