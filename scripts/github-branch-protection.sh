#!/usr/bin/env bash
# Applies GitHub *rulesets* (the modern replacement for classic branch
# protection) to the three CraftHinge repos. Requires: gh CLI, logged in as an
# org/repo admin.  Rulesets on PRIVATE repos need GitHub Team/Pro or above.
#
# Usage:
#   OWNER=my-github-user-or-org ./scripts/github-branch-protection.sh
#
# Status-check names must match what Azure Pipelines reports on PRs
# (open any PR once and copy the check name). Override if yours differ.
set -euo pipefail
OWNER="${OWNER:?set OWNER=<github user or org>}"
APP_CHECK="${APP_CHECK:-crafthinge-app-ci}"
INFRA_CHECK="${INFRA_CHECK:-crafthinge-infra-terraform}"

apply_ruleset() {
  local repo="$1" json="$2"
  local existing
  existing=$(gh api "repos/$OWNER/$repo/rulesets" --jq '.[] | select(.name=="protect-main") | .id' || true)
  if [[ -n "$existing" ]]; then
    echo "Updating ruleset on $repo"
    gh api -X PUT "repos/$OWNER/$repo/rulesets/$existing" --input - <<<"$json" >/dev/null
  else
    echo "Creating ruleset on $repo"
    gh api -X POST "repos/$OWNER/$repo/rulesets" --input - <<<"$json" >/dev/null
  fi
}

# Common rules: no direct pushes, no force-push, no deletion, linear history,
# 1 approval incl. CODEOWNER, stale approvals dismissed, conversations resolved.
pr_rule='{"type":"pull_request","parameters":{"required_approving_review_count":1,"dismiss_stale_reviews_on_push":true,"require_code_owner_review":true,"require_last_push_approval":true,"required_review_thread_resolution":true}}'
base_rules='{"type":"deletion"},{"type":"non_fast_forward"},{"type":"required_linear_history"}'

checks_rule() { # $1 = check context name
  echo "{\"type\":\"required_status_checks\",\"parameters\":{\"strict_required_status_checks_policy\":true,\"required_status_checks\":[{\"context\":\"$1\"}]}}"
}

# --- crafthinge-app: protect main AND develop, CI must pass -----------------
apply_ruleset crafthinge-app "{
  \"name\":\"protect-main\",\"target\":\"branch\",\"enforcement\":\"active\",
  \"conditions\":{\"ref_name\":{\"include\":[\"~DEFAULT_BRANCH\",\"refs/heads/develop\"],\"exclude\":[]}},
  \"rules\":[${base_rules},${pr_rule},$(checks_rule "$APP_CHECK")]
}"

# --- crafthinge-infrastructure: terraform plan must pass ---------------------
apply_ruleset crafthinge-infrastructure "{
  \"name\":\"protect-main\",\"target\":\"branch\",\"enforcement\":\"active\",
  \"conditions\":{\"ref_name\":{\"include\":[\"~DEFAULT_BRANCH\"],\"exclude\":[]}},
  \"rules\":[${base_rules},${pr_rule},$(checks_rule "$INFRA_CHECK")]
}"

# --- crafthinge-gitops: PRs for humans; the CI deploy key may push DEV tags --
# Deploy keys are the only bypass actor. The key is write-enabled, scoped to
# this single repo, and stored as a secure file in Azure DevOps.
apply_ruleset crafthinge-gitops "{
  \"name\":\"protect-main\",\"target\":\"branch\",\"enforcement\":\"active\",
  \"conditions\":{\"ref_name\":{\"include\":[\"~DEFAULT_BRANCH\"],\"exclude\":[]}},
  \"bypass_actors\":[{\"actor_type\":\"DeployKey\",\"bypass_mode\":\"always\"}],
  \"rules\":[${base_rules},${pr_rule}]
}"

echo "Done. Verify under Settings > Rules > Rulesets in each repo."
