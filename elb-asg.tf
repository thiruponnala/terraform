/*Security Group Creation For ELB */

data aws_availability_zones "azs"{
}
resource "aws_security_group" "elbsg" {
  name        = "tf-websg"
  description = "tf-websg"
  vpc_id      = var.v_vpc_id

  ingress {
    description = "http from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "https from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "http to webserver"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "TF-ELB-SG1"
  }
}
/*Clasic ELB Creation  ELB receive request
on port 80 and frwd to 80 of ec2 instance */

resource aws_elb "myelb"{
    
	 listener {
    instance_port     = "80"
    instance_protocol = "http"
    lb_port           = "80"
    lb_protocol       = "http"
  }
   health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 10
    target              = "HTTP:80/"
    interval            = 30
  }
  security_groups =[aws_security_group.elbsg.id]
  subnets=slice(var.v_sn1_ids,0,length(data.aws_availability_zones.azs.names))
  
}
/*Security Group for Webserver Instances */

resource "aws_security_group" "webserver" {
  name        = "tf-webserver-sg"
  description = "tf-webserver-sg"
  vpc_id      = var.v_vpc_id

  ingress {
    description = "http from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = [aws_security_group.elbsg.id]
  }
  ingress {
    description = "https from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.v_vpc_cidr]
  }
  egress {
    description = "http to webserver"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "TF-Webserver-SG1"
  }
}
/* upload pem key from local local machine*/

resource "aws_key_pair" "testkey" {
  key_name   = var.v_keyname
  public_key = file("./tfmykey.pub")
}


resource "aws_launch_configuration" "lc1" {
  image_id      = var.v_ami
  instance_type = var.v_it
  security_groups=[aws_security_group.webserver.id]
  key_name=aws_key_pair.testkey.key_name
  user_data=file("./1.sh")
  
}
/* ASG*/
resource "aws_autoscaling_group" "asg1" {
  name                      = "ASG1"
  max_size                  = var.v_max
  min_size                  = var.v_min
  health_check_grace_period = 300
  health_check_type         = "ELB"
  desired_capacity          = var.v_desire
  force_delete              = true
  launch_configuration      = aws_launch_configuration.lc1.name
  vpc_zone_identifier       =slice(var.v_sn1_ids,length(data.aws_availability_zones.azs.names),length(data.aws_availability_zones.azs.names)*2)
  load_balancers=            [aws_elb.myelb.name]
}

/*output "tami"{
  value=data.aws_ami.vami.id
}*/

