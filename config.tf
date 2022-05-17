# AWS General Settings
variable "region" {
  description = "The AWS region to deploy ressources to"
  default     = "ap-southeast-1"
}
variable "availability_zone" {
  description = "The AWS availability zone to deploy ressources to"
  default     = "ap-southeast-1a"
}


# EC2 Settings
variable "my_ip_address" {
  description = "The name of the resource group in which the resources will be created"
}
variable "public_key_loc" {
  description = "Location of the public key associated with the public key."
}
variable "private_key_loc" {
  description = "Location of the private key associated with the public key."
}
variable "ami" {
  description = "AMI to use for the EC2 creation. Check https://cloud-images.ubuntu.com/locator/ec2/ for reference."
  default     = "ami-00c76c78e78a3dcd4"
}


# Red Team Infra Settings
variable "cs_password" {
  description = "Password to start the CS server."
}
variable "nb_redirectors" {
  description = "Number of redirectors in infrastructure."
  default     = 1
}
variable "nb_c2servers" {
  description = "Number of c2 servers in infrastructure."
  default     = 1
}