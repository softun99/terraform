# IAM role
resource "aws_iam_role" "mgst" {
  name = "microstrategy role"

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
resource "aws_iam_role_policy_attachment" "mgst_policy_attachment" {
  role       = aws_iam_role.mgst.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"  # Replace with your desired policy ARN
}


# create dataexchange servers
resource "aws_instance" "dex_linux" {
  ami           = data.aws_ami.linux.id
  instance_type = var.linux_instance_type
  subnet_id     = data.terraform_remote_state.vpc.outputs.jh_subnet_ids[0]
  user_data     = data.template_file.user_data.rendered
  key_name      = "dex-${var.environment_long}-key"
  monitoring    = false
  iam_instance_profile = aws_iam_role.mgst.name
  vpc_security_group_ids = ["sg-xxx", "sg-xx"]
  root_block_device {
    encrypted   = true
    volume_type = "gp3"
    kms_key_id  = data.terraform_remote_state.kms.outputs.afp_linux_ebs_arn
    volume_size = var.linux_storage_size
    tags = {
      ManagedBy = "Terraform"
      Environment = local.lenv
    }
  }
  tags = {
    Name          = var.linux_instance_name
    "App"         = "dataexchange"
    "Alert"       = "Data" 
  }
  #lifecycle {
  #  ignore_changes = [
  #    ami
  #  ]
  #}
}


resource "aws_ebs_volume" "dex_linux" {
  availability_zone = aws_instance.dex_linux.availability_zone
  size              = var.linux_data_size
  encrypted   = true
  type = "gp3"
  kms_key_id  = data.terraform_remote_state.kms.outputs.afp_linux_ebs_arn
}

resource "aws_volume_attachment" "ebs_att" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.dex_linux.id
  instance_id = aws_instance.dex_linux.id
}
