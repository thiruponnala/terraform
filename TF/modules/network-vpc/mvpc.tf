data aws_availability_zones "azs"{
}
resource aws_vpc "vpc1"{
    cidr_block=var.v_vpc_cidr
	tags = {
    Name = var.v_tags
  }
}
resource aws_subnet "sn1"{
   count=length(data.aws_availability_zones.azs.names)*2
   cidr_block=cidrsubnet(var.v_vpc_cidr, 8,count.index)
   vpc_id=aws_vpc.vpc1.id
   availability_zone=data.aws_availability_zones.azs.names[count.index%length(data.aws_availability_zones.azs.names)]
   map_public_ip_on_launch=length(data.aws_availability_zones.azs.names)>count.index?true:false
   tags={
    "Name"=count.index<3? join("-", [var.v_tags,"Pub",count.index]):join("-", [var.v_tags,"Prv",count.index])
   }
}
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc1.id
  tags = {
    "Name" = var.v_tags
  }
}
resource "aws_route_table" "rt1" {
  vpc_id = aws_vpc.vpc1.id
   tags = {
    "Name" = join("-",["Pub",var.v_tags])
  }
}
resource "aws_route_table" "rt2" {
  vpc_id = aws_vpc.vpc1.id
   tags = {
    Name = join("-",["Prv",var.v_tags])
  }
}
resource "aws_route" "rt1igw" {
  route_table_id            = aws_route_table.rt1.id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id=aws_internet_gateway.igw.id
}
resource "aws_route_table_association" "sn1rt1" {
  count=length(data.aws_availability_zones.azs.names)
  subnet_id      = aws_subnet.sn1.*.id[count.index]
  route_table_id = aws_route_table.rt1.id
} 
resource "aws_eip" "natip" {
  
}
resource "aws_nat_gateway" "ngw" {
  allocation_id = aws_eip.natip.id
  subnet_id     = aws_subnet.sn1.*.id[0]
  tags = {
    Name = var.v_tags
  }
}
resource "aws_route" "rt2nat" {
  route_table_id            = aws_route_table.rt2.id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id=aws_nat_gateway.ngw.id
}  
resource "aws_route_table_association" "sn2rt2" {
  count=length(data.aws_availability_zones.azs.names)
  subnet_id      = aws_subnet.sn1.*.id[count.index+length(data.aws_availability_zones.azs.names)]
  route_table_id = aws_route_table.rt2.id
}

output "v_vpc_id"{
   value=aws_vpc.vpc1.id
}
output "v_sn1"{
   value=aws_subnet.sn1.*.id
}

