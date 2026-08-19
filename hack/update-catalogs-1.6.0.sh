#!/bin/bash
# Bundle digest for operator version 1.6.0.
#
# This file is a data source, not meant to be executed directly.
# It is sourced by hack/generate-catalogs.sh during catalog generation.
#
# To update the digest (e.g. after a Konflux component rebuild):
#   edit the LATEST= line below, then push to main.
#   The GitHub Actions workflow will regenerate catalogs automatically.

BUNDLE_VERSION="1.6.0"
LATEST="quay.io/redhat-user-workloads/cluster-observabilit-tenant/cluster-observability-operator/cluster-observability-operator-bundle@sha256:34d61ce8379e39ac1445ff89a60696c2492ffde603937ea7f2c9e736bca625de"
