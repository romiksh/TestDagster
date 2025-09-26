resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = merge(local.tags, { Name = "${local.name}-vpc" })
}
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.this.id
  tags   = merge(local.tags, { Name = "${local.name}-igw" })
}
resource "aws_subnet" "public" {
  for_each                = { a = 0, b = 1 }
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidrs[each.value]
  availability_zone       = data.aws_availability_zones.available.names[each.value]
  map_public_ip_on_launch = true
  tags                    = merge(local.tags, { Name = "${local.name}-public-${each.key}", Tier = "public" })
}
resource "aws_subnet" "private" {
  for_each          = { a = 0, b = 1 }
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnet_cidrs[each.value]
  availability_zone = data.aws_availability_zones.available.names[each.value]
  tags              = merge(local.tags, { Name = "${local.name}-private-${each.key}", Tier = "private" })
}
resource "aws_eip" "nat" {
  domain = "vpc"
  tags = merge(local.tags, {
    Name = "${local.name}-nat-eip"
  })
}
resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public["a"].id
  tags = merge(local.tags, {
    Name = "${local.name}-nat"
  })
  depends_on = [aws_internet_gateway.igw]
}
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  tags = merge(local.tags, {
    Name = "${local.name}-public-rt"
  })
}

resource "aws_route" "public_inet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}
resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public["a"].id
  route_table_id = aws_route_table.public.id
}
resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public["b"].id
  route_table_id = aws_route_table.public.id
}
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id
  tags = merge(local.tags, {
    Name = "${local.name}-private-rt"
  })
}
resource "aws_route" "private_nat" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this.id
}
resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private["a"].id
  route_table_id = aws_route_table.private.id
}
resource "aws_route_table_association" "private_b" {
  subnet_id      = aws_subnet.private["b"].id
  route_table_id = aws_route_table.private.id
}
