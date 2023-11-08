locals {
  env = "production" 
}

terraform {
  before_hook "switch_workspace" {
    commands     = ["plan", "apply"]
    execute      = ["terraform", "workspace", "select", local.env]
    run_on_error = false
  }
}
