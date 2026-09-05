resource "aws_instance" "web" {
  ami                    = data.aws_ami.amiID.id
  instance_type          = "t3.micro"
  key_name               = aws_key_pair.dove-key.key_name
  vpc_security_group_ids = [aws_security_group.dove-sg.id]
  availability_zone      = var.zone1
  tags = {
    Name    = "Dove-Instance"
    Project = "Dove-web"
  }
  connection {
    type        = "ssh"
    user        = var.webuser
    private_key = file("./dove-key")
    host        = self.public_ip
  }
  provisioner "file" {
    source      = "web.sh"
    destination = "/tmp/web.sh"
  }
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/web.sh",
      "sudo /tmp/web.sh"
    ]
  }
  provisioner "local-exec" {
    command = "echo ${aws_instance.web.private_ip} >> private_ips.txt"
  }
}

output "webPublicIP" {
  description = "Public IP of the web instance"
  value       = aws_instance.web.public_ip
}

output "webPrivateIP" {
  description = "Private IP of the web instance"
  value       = aws_instance.web.private_ip
}


 