resource "aws_cloudwatch_log_group" "ecs_log_group" {
  name = "/ecs/my-ecs-application" # Name your log group
  retention_in_days = 30           # Set log retention policy (optional)
}
