# ***************************************
# VPC
# ***************************************
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"

  # Basic VPC details
  name = var.vpc_name
  cidr = var.cidr_block
  azs  = var.aws_azs

  # Public subnets
  public_subnets     = var.public_subnets
  public_subnet_tags = var.public_subnet_tags
  
  # Private subnets
  private_subnets     = var.private_subnets
  private_subnet_tags = var.private_subnet_tags

  # Database subnets
  database_subnets                   = var.database_subnets
  create_database_subnet_group       = length(var.database_subnets) > 0 ? true : false
  create_database_subnet_route_table = length(var.database_subnets) > 0 ? true : false

  # NAT gateway 
  enable_nat_gateway     = var.deploy_cost_infrastructure
  one_nat_gateway_per_az = var.deploy_cost_infrastructure # Each availability zone will get a NAT gateway, done so for high availability
  single_nat_gateway     = false

  # VPN gateway
  enable_vpn_gateway = true # Not sure if we need this

  # DNS parameters
  enable_dns_hostnames = true
  enable_dns_support   = true

  # VPC Flow logs to S3 bucket in Log Archive Account
  enable_flow_log           = var.enable_flow_log
  flow_log_destination_type = var.enable_flow_log ? "s3" : null
  flow_log_destination_arn  = var.enable_flow_log ? "arn:aws:s3:::vpc-flow-logs-${data.aws_caller_identity.current.account_id}" : null
}

# ***************************************
# VPC Peering Connections
# Create connections with specified Nova IoT and Mobile AWS accounts
# ***************************************
resource "aws_vpc_peering_connection" "nova_vpc_peering_connection" {
  for_each = var.create_nova_dependent_resources ? local.nova : {}

  vpc_id        = module.vpc.vpc_id
  peer_vpc_id   = each.value.vpc_id
  peer_owner_id = each.value.account_id

  tags = {
    Name = "VPC Peering to Nova ${each.value.label}"
  }
}

# ***************************************
# Database Route Table Updates
# Add route to "availability zone a" route table allowing connection to specified private Nova IoT and Mobile subnets via VPC peering connection
# ***************************************
resource "aws_route" "database_route_table_route_to_nova_az_a" {
  for_each = var.create_nova_dependent_resources && length(var.database_subnets) > 0 ? local.nova : {}

  route_table_id            = module.vpc.database_route_table_ids[0]
  destination_cidr_block    = each.value.cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.nova_vpc_peering_connection[each.key].id
}

# ***************************************
# Database Route Table Updates
# Add route to "availability zone b" route table allowing connection to specified private Nova IoT and Mobile subnets via VPC peering connection
# ***************************************
resource "aws_route" "database_route_table_route_to_nova_az_b" {
  for_each = var.create_nova_dependent_resources && length(var.database_subnets) > 0 ? local.nova : {}

  route_table_id            = module.vpc.database_route_table_ids[1]
  destination_cidr_block    = each.value.cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.nova_vpc_peering_connection[each.key].id
}

# ***************************************
# VPC Endpoint - S3
# Add VPC Enpoint to S3 (save $$$ by not using NAT Gateway)
# ***************************************
resource "aws_vpc_endpoint" "s3_vpc_endpoint" {
  vpc_id       = module.vpc.vpc_id
  service_name = "com.amazonaws.${var.aws_region}.s3"
}

resource "aws_vpc_endpoint_route_table_association" "route_table_entry_for_s3_vpc_endpoint_1" {
  route_table_id  = module.vpc.private_route_table_ids[0]
  vpc_endpoint_id = aws_vpc_endpoint.s3_vpc_endpoint.id
}

resource "aws_vpc_endpoint_route_table_association" "route_table_entry_for_s3_vpc_endpoint_2" {
  route_table_id  = module.vpc.private_route_table_ids[1]
  vpc_endpoint_id = aws_vpc_endpoint.s3_vpc_endpoint.id
}