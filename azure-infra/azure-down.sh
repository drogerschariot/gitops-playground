#!/bin/bash

set -e

# Grab Azure env variables
if [[  ! -z "${IS_GITHUB_ACTIONS}" ]]; then
  echo "Using Actions ENVs"
else
  source .env
fi

echo "------------"
echo "We are about to run terraform destroy. Make sure you are running this script in the gitops-playground/azure-infra directory."
sleep 10

terraform init
# Grab Azure env variables
if [[  ! -z "${IS_GITHUB_ACTIONS}" ]]; then
  terraform destroy -auto-approve
else
  terraform destroy
fi
