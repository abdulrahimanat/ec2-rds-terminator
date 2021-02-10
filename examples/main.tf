provider "aws" {
region = "us-east-1" 
}

module "ec2" {
    source = "../.././ec2-rds-terminate"
    schedule_terminate_expression  = "cron(0 0 ? * FRI *)"
}
