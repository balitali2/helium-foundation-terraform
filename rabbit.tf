resource "aws_mq_broker" "rabbitmq" {
  broker_name = "rabbitmq"

  configuration {
    id       = aws_mq_configuration.test.id
    revision = aws_mq_configuration.test.latest_revision
  }

  engine_type        = "RabbitMQ"
  engine_version     = "5.15.9"
  host_instance_type = "mq.m5.large"
  security_groups = [data.aws_security_group.default.id]
  subnet_ids = module.vpc.private_subnets

  user {
    username = "strata"
    password = var.rabbit_password
  }
}
