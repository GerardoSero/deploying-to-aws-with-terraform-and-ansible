# Get Linux AMI ID using SSM Parameter endpoint in us-east-1
data "aws_ssm_parameter" "linuxAmi" {
  provider = aws.region_main
  name     = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

# Get Linux AMI ID using SSM Parameter endpoint in us-west-2
data "aws_ssm_parameter" "linuxAmiOregon" {
  provider = aws.region_worker
  name     = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

# Create key-pair for logging into EC2 in us-east-1
resource "aws_key_pair" "main_key" {
  provider   = aws.region_main
  key_name   = "jenkins"
  public_key = file("~/.ssh/id_rsa.pub")
}

# Create key-pair for logging into EC2 in us-west-2
resource "aws_key_pair" "worker_key" {
  provider   = aws.region_worker
  key_name   = "jenkins"
  public_key = file("~/.ssh/id_rsa.pub")
}

# Create and bootstrap EC2 in us-east-1
resource "aws_instance" "jenkins_main" {
  provider                    = aws.region_main
  ami                         = data.aws_ssm_parameter.linuxAmi.value
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.main_key.key_name
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.jenkins_sg.id]
  subnet_id                   = aws_subnet.subnet_1.id
  tags = {
    Name = "jenkins_master_tf"
  }
  depends_on = [
    aws_main_route_table_association.set_master_default_rt_assoc
  ]

  provisioner "local-exec" {
    command = <<EOF
aws --profile ${var.profile} ec2 wait instance-status-ok --region ${var.region_main} --instance-ids ${self.id}
ansible-playbook --extra-vars 'passed_in_hosts=tag_Name_${self.tags.Name}' ansible_templates/install_jenkins_master.yaml
EOF
  }
}

# Create and bootstrap EC2 in us-west-2
resource "aws_instance" "jenkins_worker" {
  provider                    = aws.region_worker
  count                       = var.workers_count
  ami                         = data.aws_ssm_parameter.linuxAmiOregon.value
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.worker_key.key_name
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.jenkins_sg_oregon.id]
  subnet_id                   = aws_subnet.subnet_1_oregon.id
  tags = {
    Name = join("_", ["jenkins_worker_tf", count.index + 1])
  }
  depends_on = [
    aws_main_route_table_association.set_worker_default_rt_assoc,
    aws_instance.jenkins_main
  ]

  provisioner "local-exec" {
    command = <<EOF
aws --profile ${var.profile} ec2 wait instance-status-ok --region ${var.region_worker} --instance-ids ${self.id}
ansible-playbook --extra-vars 'passed_in_hosts=tag_Name_${self.tags.Name} master_ip=${aws_instance.jenkins_main.private_ip}' ansible_templates/install_jenkins_worker.yaml
EOF
  }

  # provisioner "remote-exec" {
  #   when = destroy
  #   inline = [
  #     "java -jar /home/ec2-user/jenkins_cli.jar -auth @/home/ec2-user/jenkins_auth -s https://${aws_instance.jenkins_main.private_ip}:8080 delete-node ${self.private_ip}"
  #   ]
  #   connection {
  #     type        = "ssh"
  #     user        = "ec2-user"
  #     private_key = file("~/.ssh/id_rsa")
  #     host        = self.public_ip
  #   }
  # }
}