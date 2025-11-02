#!/bin/bash

LATEST="quay.io/redhat-user-workloads/cluster-observabilit-tenant/cluster-observability-operator/cluster-observability-operator-bundle@sha256:97538285c10f54b7b82ef42ffad6bc56b06c2e67f028f541d57425531209ce42"

VALUE="$LATEST" yq -i '.entries[-1].image=strenv(VALUE)' catalog/catalog-template.yaml
