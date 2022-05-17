resource "aws_security_group" "sg_redirector" {
  name        = format("%s-sg_redirector", "${var.region}")
  description = "Security Group for redirectors"

  ingress {
    description = "SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.my_ip_address}/32"]
  }
  ingress {
    description = "All HTTP traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "All HTTPS traffic"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  tags = {
    Name = format("%s-sg_redirector", "${var.region}")
  }
}


resource "aws_instance" "ec2_redirector" {
  count                       = var.nb_redirectors
  ami                         = var.ami
  instance_type               = "t2.micro"
  associate_public_ip_address = true
  key_name                    = aws_key_pair.rte-ec2.key_name
  security_groups             = [aws_security_group.sg_redirector.name]
  root_block_device {
    volume_size           = "8"
    volume_type           = "gp2"
    encrypted             = true
    delete_on_termination = true
  }
  tags = {
    Name = format("%s-ec2_redirector-%03d", "${var.region}", count.index + 1)
  }
}


resource "null_resource" "init_redirector" {
  count = var.nb_redirectors

  provisioner "remote-exec" {
    inline = [
      "sudo su <<EOF",
      "apt-get update",
      "apt-get update",
      "apt-get install socat -y",
      "socat TCP4-LISTEN:80,fork TCP4:${aws_instance.ec2_c2server[count.index].public_ip}:80 &",
      "socat TCP4-LISTEN:443,fork TCP4:${aws_instance.ec2_c2server[count.index].public_ip}:443 &"
    ]
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("${var.private_key_loc}")
      host        = aws_instance.ec2_redirector[count.index].public_ip
    }
  }
}