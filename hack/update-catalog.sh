#!/bin/bash

LATEST="quay.io/redhat-user-workloads/cluster-observabilit-tenant/cluster-observability-operator/cluster-observability-operator-bundle@sha256:ef40641c8ad7af9627ba723a671dc9628a442a561a9fe77f762388f0ce3fd509"

VALUE="$LATEST" yq -i '.entries[-1].image=strenv(VALUE)' catalog/catalog-template.yaml
