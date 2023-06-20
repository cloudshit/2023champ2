resource "aws_eip" "bastion" {
  vpc = true
  instance = aws_instance.bastion.id
  associate_with_private_ip = aws_instance.bastion.private_ip
}

resource "aws_security_group" "bastion" {
  name = "dev-skills-bastion-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    from_port = "22"
    to_port = "22"
  }

  egress {
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    from_port = "0"
    to_port = "0"
  }
}

resource "aws_iam_role" "bastion" {
  name = "dev-skills-role-bastion"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  managed_policy_arns = ["arn:aws:iam::aws:policy/AdministratorAccess"]
}

resource "aws_iam_instance_profile" "bastion" {
  name = "dev-skills-profile-bastion"
  role = aws_iam_role.bastion.name
}

resource "aws_instance" "bastion" {
  instance_type = "t3.micro"
  subnet_id = aws_subnet.public_a.id
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.bastion.id]
  iam_instance_profile = aws_iam_instance_profile.bastion.name
  key_name = aws_key_pair.keypair.key_name
  
  ami = "ami-035da6a0773842f64"

  tags = {
    Name = "log-generator"
  }

  user_data = <<-EOF
    #!/bin/bash
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    ./aws/install

    yum install -y jq curl aws-kinesis-agent

    mkdir /etc/aws-kinesis
    aws s3 cp s3://${aws_s3_bucket.bucket.bucket}/scripts/agent.json /etc/aws-kinesis/agent.json
    
    mkdir /opt/script
    aws s3 cp s3://${aws_s3_bucket.bucket.bucket}/scripts/generator.sh /opt/script/generator.sh
    chmod a+rwx /opt/script/generator.sh

    aws s3 cp s3://${aws_s3_bucket.bucket.bucket}/scripts/generator.service /etc/systemd/system/generator.service

    service aws-kinesis-agent start
    chkconfig aws-kinesis-agent on
    systemctl enable --now generator
  EOF
}
