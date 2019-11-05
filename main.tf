provider "aws" {
  region = "eu-west-1"
}

# launch first EC2 instance

resource "aws_instance" "app_instance" {
  ami = "${var.app_ami_id}"
  instance_type = "${var.instance_type_default}"
  associate_public_ip_address = true
  subnet_id = "${aws_subnet.subn.id}"
  vpc_security_group_ids = ["${aws_security_group.shark-secu-group.id}"]
  key_name = "${aws_key_pair.deployer.key_name}"
  user_data = "${data.template_file.app_instance.rendered}"
  tags = {
    Name = "${var.name}-instance"
  }
}

resource "aws_subnet" "subn" {
  vpc_id     = "${var.vpcid}"
  cidr_block = "10.10.101.0/24"
  tags = {
    Name = "${var.name}-subnet"
  }
}

resource "aws_security_group" "shark-secu-group" {
  name        = "shark-secu-group"
  vpc_id     = "${var.vpcid}"
  description = "Allow TLS inbound traffic"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["212.161.55.68/32"]
    description = "Allows ssh"
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["86.173.71.40/32"]
    description = "Allows ssh"
  }

  tags = {
    Name = "${var.name}-securitygroup"
  }
}


resource "aws_route_table" "public" {
  vpc_id = "${var.vpcid}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${data.aws_internet_gateway.default.id}"
  }

  tags = {
    Name = "${var.name}main"
  }
}

# data command --- ###
# grabbing a reference to the internet gateway_id for our VPC

data "aws_internet_gateway" "default" {
  filter{
    name = "attachment.vpc-id"
    values = ["${var.vpcid}"]
  }
}


# Route tables associations
resource "aws_route_table_association" "assoc"{
  subnet_id   = "${aws_subnet.subn.id}"
  route_table_id = "${aws_route_table.public.id}"
}

# sending scripts
data "template_file" "app_instance"{
  template = "${file("./scripts/app/init.sh.tpl")}"
}

resource "aws_key_pair" "deployer" {
  key_name = "shark-terra"
  public_key = "${var.public_ssh}"
}
