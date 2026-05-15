#!/bin/bash

LATEST="quay.io/redhat-user-workloads/cluster-observabilit-tenant/cluster-observability-operator/cluster-observability-operator-bundle@sha256:c2d2f4aefc5629fbe7dd1b3f9e72485523edee64a224da18c6094bfb0d9ea078"

VALUE="$LATEST" yq -i '.entries[-1].image=strenv(VALUE)' catalog/catalog-template.yaml
