provider "aws" {
    region = "us-east-1"
    access_key = "AKIA3HC3WOYYBJBINPYT"
    secret_key = "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"
}

# CREATING EC2 INSTANCE
/* resource "aws_instance" "provision-ec2-server" {
    ami = "ami-09e67e426f25ce0d7"
    instance_type = "t2.micro"
    tags = {
      "Name" = "Ubuntu"
    }
} */

/* #Creating VPC and Subnet
resource "aws_vpc" "first-vpc" {
    cidr_block = "10.0.0.0/16"
    tags = {
      "Name" = "Staging"
    }
}

resource "aws_subnet" "staging-subnet" {
    vpc_id = aws_vpc.first-vpc.id
    cidr_block = "10.0.1.0/24"
    tags = {
      "Name" = "Staging-Subnet"
    }
}
 */
variable "tag_name" {
    description = "enter tag name"
    type = string
  
}

# 1. Create VPC
resource "aws_vpc" "vpc-web" {
    cidr_block = "10.0.0.0/16"
    tags = {
      "Name" = var.tag_name
    }
}

# 2. Create Internet Gateway
resource "aws_internet_gateway" "gw-web" {
  vpc_id = aws_vpc.vpc-web.id

  tags = {
    Name = "igw-web"
  }
}

# 3. Create a Custom Route Table
resource "aws_route_table" "prod-route-table" {
  vpc_id = aws_vpc.vpc-web.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw-web.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    gateway_id             = aws_internet_gateway.gw-web.id
  }

  tags = {
    Name = "route-table-web"
  }
}
# 4. Create a Subnet
resource "aws_subnet" "prod-subnet" {
    vpc_id = aws_vpc.vpc-web.id
    cidr_block = "10.0.1.0/24"
    availability_zone = "us-east-1a"
    tags = {
      "Name" = "prod-Subnet"
    }
}

# 5. Associate Subnet with a route table
resource "aws_route_table_association" "rt-subnet" {
  subnet_id      = aws_subnet.prod-subnet.id
  route_table_id = aws_route_table.prod-route-table.id
}

# 6. Create a Security Group to allow port 22,80,443
resource "aws_security_group" "allow_web" {
  name        = "allow_web"
  description = "Allow web traffic"
  vpc_id      = aws_vpc.vpc-web.id

  ingress {
    description      = "HTTPS"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  
  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_web"
  }
}

# 7. Create a Network Interface with an ip in the subnet that was created in step4
resource "aws_network_interface" "prod-interface" {
  subnet_id       = aws_subnet.prod-subnet.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_web.id]

}

# 8. Assign an elastic IP to the network interface created in step7
resource "aws_eip" "one" {
  vpc                       = true
  network_interface         = aws_network_interface.prod-interface.id
  associate_with_private_ip = "10.0.1.50"
  depends_on                = [aws_internet_gateway.gw-web]
}

# 9. Create Ubuntu server and install/enable apache
resource "aws_instance" "web-server-instance" {
    ami = "ami-09e67e426f25ce0d7"
    instance_type = "t2.micro"
    availability_zone = "us-east-1a"
    key_name = "AWS-REGION"

    network_interface {
      device_index = 0
      network_interface_id = aws_network_interface.prod-interface.id
    }

    user_data = <<-EOF
                #!/bin/bash
                sudo apt update -y
                sudo apt install apache2 -y
                sudo systemctl start apache2
                sudo bash -c 'echo your very first apache web server > /var/www/html/index.html'
                EOF
    tags = {
      "Name" = "web-server"
    }
}

output "server-public-ip" {
    value = aws_eip.one.public_ip
}

output "server-private-ip" {
    value = aws_instance.web-server-instance.private_ip
}