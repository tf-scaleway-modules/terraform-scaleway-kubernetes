################################################################################
# Data Sources
################################################################################

data "scaleway_iam_organization" "this" {
  name = var.organization_name
}

data "scaleway_account_project" "this" {
  name            = var.project_name
  organization_id = data.scaleway_iam_organization.this.id
}
