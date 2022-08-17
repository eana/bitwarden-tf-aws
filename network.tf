resource "aws_security_group" "this" {
  name        = var.name
  vpc_id      = aws_vpc.this.id
  description = "Security group for EC2 instance ${var.name}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] #tfsec:ignore:AWS009
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ssh_cidr
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] #tfsec:ignore:AWS008
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] #tfsec:ignore:AWS008
  }

  tags = local.default_tags
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

    tags = {
        Name = "Bitminder Internet Gateway"
    }
}


resource "aws_route_table" "this" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name = "Public Route Table"
  }
}

resource "aws_route_table_association" "this" {
  subnet_id      = aws_subnet.this.id
  route_table_id = aws_route_table.this.id
}

resource "aws_network_interface" "this" {
  security_groups   = [aws_security_group.this.id]
  subnet_id         = aws_subnet.this.id
  source_dest_check = false
  description       = "ENI for EC2 instance ${var.name}"
  tags              = local.default_tags
}

resource "aws_eip" "this" {
  network_interface = aws_network_interface.this.id
  tags              = local.default_tags
}

resource "aws_route53_record" "this" {
  zone_id = data.aws_route53_zone.this.zone_id
  name    = var.domain
  type    = "A"
  ttl     = "300"
  records = [aws_eip.this.public_ip]
}
