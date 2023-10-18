#!/bin/bash

source .env

echo "------------"
echo "We are about to run terraform destroy. Make sure you are running this script in the gitops-playground/azure-infra directory."
sleep 10
terraform destroy
