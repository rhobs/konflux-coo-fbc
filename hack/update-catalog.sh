#!/bin/bash

LATEST="quay.io/redhat-user-workloads/cluster-observabilit-tenant/cluster-observability-operator/cluster-observability-operator-bundle@sha256:1bc393d5802a038b59b724828b67fa26dd955795f2151649b764515f6e0cb1d0"

VALUE="$LATEST" yq -i '.entries[-1].image=strenv(VALUE)' catalog/catalog-template.yaml
