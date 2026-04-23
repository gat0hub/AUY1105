# ==========================================
# 1. CONFIGURACIÓN DEL PROVEEDOR
# ==========================================
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      # Se define la última versión mayor actual (5.x)
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1" # Puedes cambiar la región según necesites
}

# ==========================================
# 2. REDES Y SEGURIDAD
# ==========================================

# VPC: Bloque CIDR 10.1.0.0/16
resource "aws_vpc" "main_vpc" {
  cidr_block           = "10.1.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "AUY1105-duocapp-vpc"
  }
}

# Subred: Rango /24
resource "aws_subnet" "main_subnet" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.1.1.0/24"
  map_public_ip_on_launch = true # Ideal si necesitas conectar por SSH directamente

  tags = {
    Name = "AUY1105-duocapp-subnet"
  }
}

# (Opcional pero recomendado) Internet Gateway para que la subred tenga salida a internet
resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "AUY1105-duocapp-igw"
  }
}

# (Opcional pero recomendado) Tabla de rutas para el IGW
resource "aws_route_table" "main_rt" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_igw.id
  }

  tags = {
    Name = "AUY1105-duocapp-rt"
  }
}

resource "aws_route_table_association" "main_rta" {
  subnet_id      = aws_subnet.main_subnet.id
  route_table_id = aws_route_table.main_rt.id
}

# Security Group: Permite solo SSH (Puerto 22) entrante
resource "aws_security_group" "ssh_sg" {
  name        = "allow_ssh"
  description = "Permitir trafico entrante SSH"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    description = "SSH desde cualquier lugar"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # En un entorno real, restringe esto a tu IP
  }

  egress {
    description = "Permitir todo el trafico saliente"
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
# 3. CÓMPUTO (EC2)
# ==========================================

# Data source para obtener dinámicamente la última AMI oficial de Ubuntu 24.04 LTS
data "aws_ami" "ubuntu_24_04" {
  most_recent = true
  owners      = ["099720109477"] # ID del propietario oficial de Canonical (Ubuntu)

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
}

# Instancia EC2
resource "aws_instance" "web_server" {
  ami                    = data.aws_ami.ubuntu_24_04.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.main_subnet.id
  vpc_security_group_ids = [aws_security_group.ssh_sg.id]

  tags = {
    Name = "AUY1105-duocapp-ec2"
  }
}
