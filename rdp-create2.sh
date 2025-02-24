#!/bin/bash

# Fetch active project IDs dynamically
PROJECTS=($(gcloud projects list --format="value(projectId)"))

# Define available locations (zones)
ZONES=("us-central1-c")

# Define instance configuration
INSTANCE_COUNT=1
MACHINE_TYPE="n1-standard-4"  # 4 vCPU, 16GB RAM
IMAGE_NAME="windows-server-2019-dc-v20250213"
IMAGE_PROJECT="windows-cloud"
DISK_SIZE="50"  # 100GB SSD
DISK_TYPE="pd-ssd"

# Function to create an RDP instance
create_instance() {
  local project_id="$1"
  local zone="$2"
  local instance_name="$3"

  echo "Creating instance: $instance_name in project: $project_id (Zone: $zone)"

  gcloud compute instances create "$instance_name" \
    --project="$project_id" \
    --zone="$zone" \
    --machine-type="$MACHINE_TYPE" \
    --image="$IMAGE_NAME" \
    --image-project="$IMAGE_PROJECT" \
    --boot-disk-size="$DISK_SIZE" \
    --boot-disk-type="$DISK_TYPE" \
    --metadata enable-oslogin=FALSE \
    --tags=rdp-instance \
    --scopes=cloud-platform

  if [ $? -eq 0 ]; then
    echo "Instance $instance_name created successfully!"
  else
    echo "Failed to create instance: $instance_name" >&2
  fi
}

# Loop through projects and create RDP instances
for i in "${!PROJECTS[@]}"; do
  project="${PROJECTS[$i]}"
  zone="${ZONES[$((i % ${#ZONES[@]}))]}"  # Distribute instances across zones

  for j in $(seq 1 "$INSTANCE_COUNT"); do
    instance_name="rdp-${project}-${j}"
    create_instance "$project" "$zone" "$instance_name"
  done
done

echo "All RDP instances have been created!"
