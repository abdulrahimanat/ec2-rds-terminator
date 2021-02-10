variable "schedule_terminate_expression" {
  default     = "cron(5 * * * ? *)"
  description = "the aws cloudwatch event rule scheule expression that specifies when the scheduler runs. Default is 5 minuts past the hour. for debugging use 'rate(5 minutes)'. See https://docs.aws.amazon.com/AmazonCloudWatch/latest/events/ScheduledEvents.html"
}


variable "permissions_boundary" {
  type 		  = string
  default 	  = ""
  description = "AWS IAM Permissions Boundary ARN to be attached to the IAM Role"
}


variable "security_group_ids" {
  type        = list(string)
  default     = []
  description = "list of the vpc security groups to run lambda scheduler in."
}

variable "subnet_ids" {
  type        = list(string)
  default     = []
  description = "list of subnet_ids that the scheduler runs in."
}

variable "resource_name_prefix" {
  default     = ""
  description = "a prefix to apply to resource names created by this module."
}
