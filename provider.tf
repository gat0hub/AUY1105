terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      # Última versión mayor del proveedor (Serie 5.x)
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1" # Puedes cambiarla a la de tu preferencia
}
