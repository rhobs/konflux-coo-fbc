#!/bin/bash
# Bundle digest for operator version 1.4.0.
#
# This file is a data source, not meant to be executed directly.
# It is sourced by hack/generate-catalogs.sh during catalog generation.
#
# To update the digest (e.g. after a Konflux component rebuild):
#   edit the LATEST= line below, then push to main.
#   The GitHub Actions workflow will regenerate catalogs automatically.

BUNDLE_VERSION="1.4.0"
LATEST="quay.io/redhat-user-workloads/cluster-observabilit-tenant/cluster-observability-operator/cluster-observability-operator-bundle@sha256:0415e8263a185c51897bcd5d3ac2f5fe68e4818282a2f9dc89f215ee3b9dd1ed"
