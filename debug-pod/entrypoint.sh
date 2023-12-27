#!/bin/bash

# Get ASM Secret
JSON_SECRET=`aws secretsmanager get-secret-value \
    --secret-id db_creds  \
    --query SecretString \
    --output text`

# Convert JSON to environment variables
$( echo "$JSON_SECRET" | jq -r 'keys[] as $k | "export \($k)=\(.[$k])"' )


# Check env 
env | sort

# Hang so we can access pod
tail -f /dev/null
