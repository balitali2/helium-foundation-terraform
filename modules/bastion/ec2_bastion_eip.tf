resource "aws_eip" "bastion_eip" {
  domain                    = "vpc"
  instance                  = aws_instance.bastion.id
  associate_with_private_ip = var.ec2_bastion_private_ip
}