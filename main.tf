# 1. VPC (10.1.0.0/16)
resource "aws_vpc" "main" {
  cidr_block = "10.1.0.0/16"

  tags = {
    Name = "AUY1105-duocapp-vpc"
  }
}

# 2. Subred (/24)
resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.1.1.0/24"

  tags = {
    Name = "AUY1105-duocapp-subnet"
  }
}

# 3. Security Group (Solo SSH)
resource "aws_security_group" "allow_ssh" {
  name        = "AUY1105-duocapp-sg"
  description = "Permitir trafico entrante SSH"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH desde IP especifica"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    # OJO: Se usa una IP privada ficticia en lugar de 0.0.0.0/0 
    # para cumplir por defecto con tu politica OPA del Paso 4.
    cidr_blocks = ["192.168.1.100/32"] 
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

# 4. Data Source para obtener la última AMI de Ubuntu 24.04 LTS
data "aws_ami" "ubuntu_24_04" {
  most_recent = true
  owners      = ["099720109477"] # Cuenta oficial de Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
}

# 5. Instancia EC2 (t2.micro)
resource "aws_instance" "web" {
  ami                    = data.aws_ami.ubuntu_24_04.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]

  tags = {
    Name = "AUY1105-duocapp-ec2"
  }
}
