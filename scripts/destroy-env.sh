#!/usr/bin/env bash
# Tear down an environment when you're not practising (AKS nodes and App
# Gateway are the main costs). The shared stack (state + ACR) is kept.
#   ./scripts/destroy-env.sh dev
set -euo pipefail
ENV="${1:?usage: destroy-env.sh <dev|qa>}"
[[ "$ENV" == "prod" ]] && { echo "Refusing to destroy prod from a script."; exit 1; }
cd "$(dirname "$0")/../terraform"
terraform init -backend-config="backends/$ENV.hcl" -reconfigure
terraform destroy -var-file="environments/$ENV.tfvars"
