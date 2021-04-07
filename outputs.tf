output "Jenkins_Main-Node-Public-IP" {
  value = aws_instance.jenkins_main.public_ip
}

output "Jenkins-Worker-Public-IP" {
  value = {
    for instance in aws_instance.jenkins_worker :
    instance.id => instance.public_ip
  }
}

output "LB-dns_name" {
  value = aws_lb.application_lb.dns_name
}

output "public_url" {
  value = aws_route53_record.jenkins.fqdn
}