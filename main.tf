# ==========================================
# REDES Y SEGURIDAD
# ==========================================

# VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.1.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "AUY1105-duocapp-vpc"
  }
}

# Subred pública 1
resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.1.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "AUY1105-duocapp-subnet-pub1"
  }
}

# Subred pública 2
resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.1.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "AUY1105-duocapp-subnet-pub2"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "AUY1105-duocapp-igw"
  }
}

# Route Table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "AUY1105-duocapp-rt"
  }
}

# Asociaciones de rutas
resource "aws_route_table_association" "rta1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "rta2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public_rt.id
}

# ==========================================
# SECURITY GROUP (INSEGURO A PROPÓSITO)
# ==========================================

resource "aws_security_group" "ssh_sg" {
  name        = "AUY1105-duocapp-sg"
  description = "Permitir SSH (inseguro para analisis)"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH desde cualquier lugar (INSEGURO)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # ❌ Esto hará fallar Checkov y OPA
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "AUY1105-duocapp-sg"
  }
}

# ==========================================
# EC2
# ==========================================

# AMI Ubuntu 24.04 LTS dinámica
data "aws_ami" "ubuntu_24_04" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
}

# Instancia EC2
resource "aws_instance" "web" {
  ami                    = data.aws_ami.ubuntu_24_04.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public_1.id
  vpc_security_group_ids = [aws_security_group.ssh_sg.id]

  tags = {
    Name = "AUY1105-duocapp-ec2"
  }
}
