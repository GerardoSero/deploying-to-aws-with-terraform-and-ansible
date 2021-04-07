variable "profile" {
  type    = string
  default = "default"
}

variable "region-main" {
  type    = string
  default = "us-east-1"
}

variable "region-worker" {
  type    = string
  default = "us-west-2"
}

variable "external_ip" {
  type    = string
  default = "0.0.0.0/0"
}

variable "workers_count" {
  type    = number
  default = 2
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "webserver-port" {
  type    = number
  default = 8080
}

variable "dns-name" {
  type    = string
}

output "public_url" {
  value = aws_route53_record.jenkins.fqdn
}