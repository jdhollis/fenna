#!/usr/bin/env bash

backend_profile=$(cat .fenna/backend/profile)

if [[ -f ".fenna/suffix" ]]
then
  terraform init \
    -backend-config .fenna/backend/current \
    -backend-config "profile=${backend_profile}" \
    -backend-config "key=$(cat .fenna/service_name)-$(cat .fenna/suffix)/terraform.tfstate" \
    ${1-}
else
  terraform init \
    -backend-config .fenna/backend/current \
    -backend-config "profile=${backend_profile}" \
    ${1-}
fi
