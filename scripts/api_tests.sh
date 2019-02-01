#!/bin/bash

function parse_arguments() {
	# CATALOG_HOST
	if [ -z "${CATALOG_HOST}" ]; then
		echo "CATALOG_HOST not set. Using parameter \"$1\"";
		CATALOG_HOST=$1;
	fi

	if [ -z "${CATALOG_HOST}" ]; then
		echo "CATALOG_HOST not set. Using default key";
		CATALOG_HOST=localhost;
	fi

	# CATALOG_PORT
	if [ -z "${CATALOG_PORT}" ]; then
		echo "CATALOG_PORT not set. Using parameter \"$2\"";
		CATALOG_PORT=$2;
	fi

	if [ -z "${CATALOG_PORT}" ]; then
		echo "CATALOG_PORT not set. Using default key";
		CATALOG_PORT=9082;
	fi

	echo "Using http://${CATALOG_HOST}:${CATALOG_PORT}"
}

function get_items() {
	CURL=$(curl -X GET http://${CATALOG_HOST}:${CATALOG_PORT}/catalog/rest/items | jq '.[0].id' | sed -e 's/^"//' -e 's/"$//'))
	echo "Found \"${CURL}\"" # Remove the jq parsing to see whole list

	# CATALOG_POD=$(kubectl get pods | grep catalog-catalog | awk '{print $1}')
  # kubectl describe pod $CATALOG_POD
  # kubectl logs $CATALOG_POD
	# INVENTORY_POD=$(kubectl get pods | grep -v "inventory-inventory-job" | grep inventory-inventory | awk '{print $1}')
	# kubectl describe pod $INVENTORY_POD
  # kubectl logs $INVENTORY_POD

	if [[ $CURL != "13405" ]]; then
		echo "get_items: ❌ could not get items";
        exit 1;
    else
    	echo "get_items: ✅";
	fi
}

# Setup
parse_arguments $1 $2

# API Tests
echo "Starting Tests"
get_items