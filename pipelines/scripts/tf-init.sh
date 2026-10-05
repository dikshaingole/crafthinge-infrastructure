#!/usr/bin/env bash
source "$(dirname "$0")/tf-env.sh"
terraform init -input=false -backend-config="${BACKEND_CONFIG:?}"
