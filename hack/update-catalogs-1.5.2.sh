#!/bin/bash
# Bundle digest for operator version 1.5.2.
#
# This file is a data source, not meant to be executed directly.
# It is sourced by hack/generate-catalogs.sh during catalog generation.
#
# To update the digest (e.g. after a Konflux component rebuild):
#   edit the LATEST= line below, then push to main.
#   The GitHub Actions workflow will regenerate catalogs automatically.

BUNDLE_VERSION="1.5.2"
LATEST="quay.io/redhat-user-workloads/cluster-observabilit-tenant/cluster-observability-operator/cluster-observability-operator-bundle@sha256:27b9d072d3895c668667a1fb35e2919fa69b2e45206244de8442b53c50de11be"
