data "scaleway_account_project" "project" {
  name            = var.project_name
  organization_id = var.organization_id
}