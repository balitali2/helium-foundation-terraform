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

variable "name_override" {
  description = "Override for budget name"
  type        = string
  default     = ""
}

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