# --- Environment variables ------------------------------------------------
variable "env" {
  description = "Name of AWS enviroment that you're deploying to e.g., oracle, web, etc."
  type        = string
  default     = ""
}

variable "stage" {
  description = "Name of AWS stage that you're deploying to e.g., sdlc, prod"
  type        = string
  default     = ""
}

variable "aws_region" {
  description = "AWS region you're deploying to e.g., us-west-2"
  type        = string
  default     = ""
}

variable "aws_azs" {
  description = "List of AWS availabilty zone you're deploying to"
  type        = list(string)
  default     = []
}

variable "deploy_cost_infrastructure" {
  description = "Should cost incurring infrastructure be deployed?"
  type        = bool
  default     = false
}

# --- EKS variables ------------------------------------------------
variable "cluster_name" {
  description = "Name of EKS cluster"
  type        = string
  default     = "helium"
}

variable "eks_instance_type" {
  description = "EC2 instance type for EKS nodes"
  type        = string
  default     = ""
}

variable "cluster_version" {
  description = "K8s Version of EKS cluster"
  type        = string
  default     = "" // 1.24
}

variable "cluster_min_size" {
  description = "Minimum number of nodes in EKS cluster"
  type        = number
  default     = 1
}

variable "cluster_max_size" { 
  description = "Minimum number of nodes in EKS cluster"
  type        = number
  default     = 3
}

variable "cluster_desired_size" { 
  description = "Desired number of nodes in EKS cluster"
  type        = number
  default     = 2
}

variable "manage_aws_auth_configmap" {
  description = "Manage AWS auth configmap"
  type        = bool
  default     = true
}

variable "add_cluster_autoscaler" {
  description = "Add cluster autoscaler to EKS"
  type        = bool
  default     = true
}

variable "monitoring_account_id" {
  description = "Monitoring Account ID"
  type        = string
  default     = ""
}

# --- VPC variables ------------------------------------------------
variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
  default     = "helium"
}

variable "cidr_block" {
  description = "CIDR block for Private IP address allocation e.g., 10.1.0.0/16"
  type        = string
  default     = "10.20.0.0/16"
}

variable "public_subnets" {
  description = "List of public subnets from CIDR block"
  type        = list(string)
  default     = ["10.20.1.0/24", "10.20.2.0/24"]
}

variable "private_subnets" {
  description = "List of private subnets from CIDR block"
  type        = list(string)
  default     = ["10.20.101.0/24", "10.20.102.0/24"]
}

# --- Foundation Variables ------------------------------------------------
variable "hf_buckets" {
  description = "List of Foundation buckets for cross-account S3 object replication from Nova"
  type        = list(string)
  default     = []
}

variable "hf_manifest_bucket" {
  description = "Name of Foundation manifest bucket"
  type        = string
  default     = ""
}

variable "hf_poc_data_rp_bucket" {
  description = "Name of Foundation requester pays bucket for PoC Data"
  type        = string
  default     = ""
}

variable "hf_data_lake_rp_bucket" {
  description = "Name of Foundation requester pays bucket for Data Lake"
  type        = string
  default     = ""
}

variable "hf_data_lake_dev_bucket" {
  description = "Name of Foundation development bucket for Data Lake"
  type        = string
  default     = ""
}

# --- Nova variables ------------------------------------------------
variable "nova_iot_aws_account_id" {
  description = "The AWS account ID for the Nova IoT environment (e.g., dev or prod)."
  type        = string
  default     = ""
}

variable "nova_mobile_aws_account_id" {
  description = "The AWS account ID for the Nova Mobile environment (e.g., dev or prod)."
  type        = string
  default     = ""
}

variable "nova_buckets" {
  description = "List of Nova buckets for cross-account S3 object replication to Foundation"
  type        = list(string)
  default     = []
}

# --- Slack ------------------------------------------------
variable "slack_webhook_url" {
  description = "Slack Webhook URL for alerting."
  type        = string
  default     = ""
}

variable "slack_channel" {
  description = "Slack channel for alerting."
  type        = string
  default     = ""
}

# --- Misc ------------------------------------------------
variable "top_ledger_aws_account_id" {
  description = "AWS account ID for Top Ledger"
  type        = string
  default     = ""
}

# --- Budget & Cost Anomaly ------------------------------------------------
variable "budget_amount" {
  description = "Montly budget amount"
  type        = string
  default     = ""
}

variable "budget_email_list" {
  description = "Budget email list"
  type        = list(string)
  default     = []
}

variable "slack_email" {
  description = "Slack email for billing anomalies"
  type        = string
  default     = ""
}

variable "raise_amount_percent" {
  description = "The precentage increase in montly spend to trigger the billing anomaly detector"
  type        = string
  default     = "15"
}

variable "raise_amount_absolute" {
  description = "The absolute increase in USD to trigger the billing anomaly detector"
  type        = string
  default     = "500"
}