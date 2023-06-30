# Provider configuration
provider "aws" {
  region = "us-west-2"  # Replace with your desired region
}

# IAM role
resource "aws_iam_role" "ec2_role" {
  name = "my-ec2-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# IAM role policy
resource "aws_iam_role_policy_attachment" "ec2_role_policy_attachment" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"  # Replace with your desired policy ARN
}

# Security group
resource "aws_security_group" "ec2_sg" {
  name        = "my-ec2-sg"
  description = "Security group for EC2 instance"

  ingress {
    from_port   = 3389  # RDP
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Volume
resource "aws_ebs_volume" "ec2_volume" {
  availability_zone = "us-west-2a"  # Replace with your desired availability zone
  size              = 50  # Replace with your desired volume size
  tags = {
    Name = "my-ec2-volume"
  }
}

# EC2 instance
resource "aws_instance" "ec2_instance" {
  ami           = "ami-xxxxxxxxxxxxxxxxx"  # Replace with your desired Windows AMI ID
  instance_type = "t2.micro"  # Replace with your desired instance type
  key_name      = "my-key-pair"  # Replace with your desired key pair

  iam_instance_profile = aws_iam_role.ec2_role.name
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  root_block_device {
    volume_type = "gp2"
    volume_size = 30  # Replace with your desired root volume size
  }

  ebs_block_device {
    device_name = "/dev/sdf"
    volume_id   = aws_ebs_volume.ec2_volume.id
  }
}
