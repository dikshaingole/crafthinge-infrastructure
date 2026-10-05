#!/usr/bin/env bash
# Runs plan, saves the binary plan for the Apply stage, and tells the pipeline
# whether anything changed (so Apply/approval is skipped when there is nothing to do).
source "$(dirname "$0")/tf-env.sh"
set +e
terraform plan -input=false -lock-timeout=5m -var-file="${TFVARS_FILE:?}" -out=tfplan -detailed-exitcode
rc=$?
set -e
case $rc in
  0) has_changes=false ;;
  2) has_changes=true ;;
  *) echo "##vso[task.logissue type=error]terraform plan failed"; exit $rc ;;
esac
echo "Changes detected: $has_changes"
echo "##vso[task.setvariable variable=hasChanges;isOutput=true]$has_changes"
terraform show -no-color tfplan > tfplan.txt
mkdir -p "$BUILD_ARTIFACTSTAGINGDIRECTORY/plan"
cp tfplan tfplan.txt .terraform.lock.hcl "$BUILD_ARTIFACTSTAGINGDIRECTORY/plan/"
