locals {
  nova = {
    iot = {
      label = "IoT",
      user = "nova_iot",
      account_id = var.nova_iot_aws_account_id,
      vpc_id = var.nova_iot_vpc_id,
      sg_id = var.nova_iot_rds_access_security_group,
      cidr = var.nova_iot_vpc_private_subnet_cidr,
      rule_number = 600
    }
    mobile = { 
      label = "Mobile",
      user = "nova_mobile",
      account_id = var.nova_mobile_aws_account_id,
      vpc_id = var.nova_mobile_vpc_id,
      sg_id = var.nova_mobile_rds_access_security_group,
      cidr = var.nova_mobile_vpc_private_subnet_cidr,
      rule_number = 700
    }
  }
  foundation = {
    oracle = {
      mobile = { 
        user = "mobile_oracle"
        iam_name = "rds-mobile-oracle-user-access"
      }
      iot = {
        user = "iot_oracle"
        iam_name = "rds-iot-oracle-user-access"
      }
    }
    web = {
      web = { 
        user = "web"
        iam_name = "rds-web-user-access"
      }
    }
  }
}