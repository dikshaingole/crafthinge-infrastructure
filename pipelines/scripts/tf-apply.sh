#!/usr/bin/env bash
# Applies EXACTLY the plan that was reviewed and approved. If anything changed
# in Azure or in state since the plan was made, Terraform refuses ("stale plan").
source "$(dirname "$0")/tf-env.sh"
terraform apply -input=false -lock-timeout=5m "${PLAN_FILE:?}"
