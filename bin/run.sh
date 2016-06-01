#!/usr/bin/env bash

set -e

mkdir -p ${PWD}/results

echo "Running analysis on Mongo DB in container '$1'..."
bin/run/mongo-analysis.sh $*

echo ""
echo ""
echo "Fixing JSON format in result files."
bin/run/fix-json.sh

echo ""
echo ""
echo "Done."
