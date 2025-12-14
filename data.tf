################################################################################
# Data Sources
################################################################################

data "scaleway_account_project" "this" {
  name            = var.project_name
  organization_id = var.organization_id
}
