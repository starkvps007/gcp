#!/bin/bash

# Function to get the default billing account
get_default_billing_account() {
  gcloud billing accounts list --filter="open=true" --format="value(name)" --limit=1
}

# Function to enable Compute Engine API for existing projects
enable_compute_api_for_existing_projects() {
  echo "Checking for existing projects..."
  existing_projects=$(gcloud projects list --format="value(projectId)")

  if [[ -n "$existing_projects" ]]; then
    echo "Found existing projects. Enabling Compute Engine API..."
    for project in $existing_projects; do
      echo "Enabling Compute Engine API for $project"
      gcloud services enable compute.googleapis.com --project="$project"
    done
  else
    echo "No existing projects found."
  fi
}

# Function to create a project and set billing account
create_project() {
  local project_id="$1"
  local billing_account="$2"

  echo "Creating project: $project_id"
  gcloud projects create $project_id

  if [[ $? -eq 0 ]]; then
    echo "Project $project_id created successfully."

    # Link billing account
    gcloud beta billing projects link $project_id --billing-account=$billing_account

    # Enable Cloud APIs
    gcloud services enable \
        serviceusage.googleapis.com \
        compute.googleapis.com \
        container.googleapis.com \
        cloudapis.googleapis.com \
        --project=$project_id  

    return 0
  else
    echo "Failed to create project $project_id."
    return 1
  fi
}

# Get the default billing account
DEFAULT_BILLING_ACCOUNT=$(get_default_billing_account)

if [[ -z "$DEFAULT_BILLING_ACCOUNT" ]]; then
  echo "No default billing account found. Please create a billing account and set it as default."
  exit 1
else
  echo "Default billing account: $DEFAULT_BILLING_ACCOUNT"
fi

# Enable Compute Engine API for existing projects
enable_compute_api_for_existing_projects

# Create the projects
PROJECT_ID_1="project-1-$(date +%s)"
PROJECT_ID_2="project-2-$(date +%s)"

create_project "$PROJECT_ID_1" "$DEFAULT_BILLING_ACCOUNT"
create_project "$PROJECT_ID_2" "$DEFAULT_BILLING_ACCOUNT"

# List all projects
echo -e "\nListing all projects:"
gcloud projects list
