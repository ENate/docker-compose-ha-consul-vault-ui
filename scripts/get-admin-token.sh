#!/bin/bash
# This script uses the Vault root token to create a temporary token associated
# with the admin policy.  This is better than using the root token for
# everything in order to perform initial scripting admin tasks.

set -e

if ( ! type -P gawk && type -P awk ) &> /dev/null; then
  function gawk() { awk "$@"; }
fi

if [ "$#" -gt 1 ]; then
  echo 'ERROR: must pass zero or one arguments.' >&2
  exit 1
fi

function get-secret-txt() {
  if [ -r secret.txt ]; then
    cat secret.txt
  elif [ -r secret.txt.gpg ]; then
    gpg -d secret.txt.gpg
  else
    echo 'ERROR: no secret.txt or secret.txt.gpg found.' >&2
    return 1
  fi
}

VAULT_ROOT_TOKEN="$(get-secret-txt | gawk '$0 ~ /Initial Root Token/ { print $NF;exit }')"
[ -n "$VAULT_ROOT_TOKEN" ]
docker compose exec -Te VAULT_TOKEN="$VAULT_ROOT_TOKEN" vault \
  vault token create -policy=admin -orphan -period="${1:-15m}" | \
  gawk '$1 == "token" { print $2; exit}'
