#!/bin/bash
# Bundle digest for operator version 1.5.1.
#
# This file is a data source, not meant to be executed directly.
# It is sourced by hack/generate-catalogs.sh during catalog generation.
#
# To update the digest (e.g. after a Konflux component rebuild):
#   edit the LATEST= line below, then push to main.
#   The GitHub Actions workflow will regenerate catalogs automatically.

BUNDLE_VERSION="1.5.1"
LATEST="quay.io/redhat-user-workloads/cluster-observabilit-tenant/cluster-observability-operator/cluster-observability-operator-bundle@sha256:6578f6e0bf83cf924d724dd110abca715f6fd656477c1bf033cf9707650a0279"
