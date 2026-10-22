variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-2"
}

variable "instance_type" {
  description = "Use a *.metal type for real KVM; t3.large is fine for everything else"
  type        = string
  default     = "t3.large"
}

variable "key_name" {
  description = "Name of an existing EC2 key pair"
  type        = string
}

variable "my_ip_cidr" {
  description = "Your public IP in CIDR form, e.g. 203.0.113.5/32 (SSH is restricted to this)"
  type        = string
}
