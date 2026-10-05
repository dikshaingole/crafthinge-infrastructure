#!/usr/bin/env bash
# Sourced inside an AzureCLI@2 task that has addSpnToEnvironment: true and a
# Workload Identity Federation service connection. That task exposes
# $servicePrincipalId, $tenantId and a short-lived $idToken (OIDC).
# Terraform exchanges the token for an Entra access token: no client secret
# exists anywhere.
set -euo pipefail
export ARM_CLIENT_ID="${servicePrincipalId:?not set - is addSpnToEnvironment true?}"
export ARM_TENANT_ID="${tenantId:?}"
export ARM_OIDC_TOKEN="${idToken:?idToken missing - service connection must use workload identity federation}"
export ARM_USE_OIDC=true
export ARM_SUBSCRIPTION_ID="$(az account show --query id -o tsv)"
export TF_IN_AUTOMATION=true
export TF_INPUT=0
