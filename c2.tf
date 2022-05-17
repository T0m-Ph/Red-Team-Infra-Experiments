resource "aws_security_group" "sg_c2server" {
  name        = format("%s-sg_c2server", "${var.region}")
  description = "Security group for C2Server_01"
  ingress {
    description = "SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.my_ip_address}/32"]
  }
  ingress {
    description = "Cobalt Strike Client connections"
    from_port   = 50050
    to_port     = 50050
    protocol    = "tcp"
    cidr_blocks = ["${var.my_ip_address}/32"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  tags = {
    Name = format("%s-sg_c2server", "${var.region}")
  }
}

resource "aws_security_group_rule" "sg_c2server_http" {
  count             = var.nb_redirectors
  security_group_id = aws_security_group.sg_c2server.id
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["${aws_instance.ec2_redirector[count.index].public_ip}/32"]
  type              = "ingress"
}

resource "aws_security_group_rule" "sg_c2server_https" {
  count             = var.nb_redirectors
  security_group_id = aws_security_group.sg_c2server.id
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["${aws_instance.ec2_redirector[count.index].public_ip}/32"]
  type              = "ingress"
}

resource "aws_instance" "ec2_c2server" {
  count                       = var.nb_c2servers
  ami                         = var.ami
  instance_type               = "t2.micro"
  associate_public_ip_address = true
  key_name                    = aws_key_pair.rte-ec2.key_name
  security_groups             = [aws_security_group.sg_c2server.name]
  root_block_device {
    volume_size           = "8"
    volume_type           = "gp2"
    encrypted             = true
    delete_on_termination = true
  }
  tags = {
    Name = format("%s-ec2_c2server-%03d", "${var.region}", count.index + 1)
  }
}

output "c2servers_ips" {
  value = ["${aws_instance.ec2_c2server.*.public_ip}"]
}


resource "null_resource" "init_c2server" {
  count = var.nb_c2servers
  provisioner "remote-exec" {
    inline = [
      "sudo su <<EOF",
      "add-apt-repository ppa:webupd8team/java -y",
      "apt-get update",
      "apt-get install openjdk-18-jre-headless -y",
      "apt-get install p7zip -y",
      "cd /opt",
      "git clone https://github.com/trewisscotch/CobaltStr4.4.git",
      "cd /opt/CobaltStr4.4/cobaltstrike4.4/",
      "7zr e cobaltstrike.7z",
      "chmod +x teamserver",
      "./teamserver ${aws_instance.ec2_c2server[count.index].public_ip} ${var.cs_password} &"
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("${var.private_key_loc}")
      host        = aws_instance.ec2_c2server[count.index].public_ip
    }
  }
}