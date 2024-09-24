#!/usr/bin/env bash

aws secretsmanager list-secrets --include-planned-deletion | \
    yq '.SecretList[] | select(.DeletedDate) | .Name' | \
    xargs -I % bash -c 'aws secretsmanager delete-secret --secret-id % --force-delete-without-recovery'

# aws secretsmanager list-secrets --include-planned-deletion --query 'SecretList[?DeletedDate].Name | [0]' | \
#    xargs -I % bash -c 'aws secretsmanager delete-secret --secret-id % --force-delete-without-recovery'