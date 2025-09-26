locals {
  name       = var.project
  dagit_port = 3000
  tags       = { Project = var.project }
}
