provider "aws" {
    region = "us-east-2"
    access_key = "AKIA3HC3WOYYBJBINPYT"
    secret_key = "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"
}

# Create Ubuntu Server and install Tomcat server
resource "aws_instance" "tomcat_instance" {
    ami = "ami-00399ec92321828f5"
    instance_type = "t2.micro"
    #availability_zone = "us-east-1a"
    key_name = "aws_prakash"
    vpc_security_group_ids = [aws_security_group.tomcat_sg.id]

    user_data = <<-EOF
                #!/bin/bash
                sudo apt update -y
                sudo apt-cache search tomcat
                sudo apt install tomcat9 tomcat9-admin -y
                sudo systemctl enable tomcat9
                sudo ufw allow from any to any port 8080 proto tcp
                EOF
    tags = {
      "Name" = "Tomcat-server"
    }
}

# Create a Security Group to allow port 22,80,443
resource "aws_security_group" "tomcat_sg" {
  name        = "tomcat_sg"
  description = "Allow web traffic"
  #vpc_id      = aws_vpc.vpc-web.id

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

  ingress {
    description      = "Tomcat"
    from_port        = 8080
    to_port          = 8080
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
    Name = "tomcat_sg"
  }
}

output "server-public-ip" {
  description = "Public IP address of EC2 Instance"
  value = aws_instance.tomcat_instance.public_ip
}

output "server-public-dns" {
  description = "Public DNS ip address of EC2 Instance"
  value = aws_instance.tomcat_instance.public_dns
}
