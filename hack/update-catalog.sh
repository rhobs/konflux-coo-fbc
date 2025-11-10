#!/bin/bash

LATEST="quay.io/redhat-user-workloads/cluster-observabilit-tenant/cluster-observability-operator/cluster-observability-operator-bundle@sha256:7e4e1379cd275596238c1e9642f1517047fe70c54c9a8386bcbb46892b2c80bd"

VALUE="$LATEST" yq -i '.entries[-1].image=strenv(VALUE)' catalog/catalog-template.yaml
