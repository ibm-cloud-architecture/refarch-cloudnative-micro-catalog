#!/bin/bash

function parse_arguments() {
	#set -x;
	# CATALOG_HOST
	if [ -z "${CATALOG_HOST}" ]; then
		echo "CATALOG_HOST not set. Using parameter \"$1\"";
		CATALOG_HOST=$1;
	fi

	if [ -z "${CATALOG_HOST}" ]; then
		echo "CATALOG_HOST not set. Using default key";
		CATALOG_HOST=127.0.0.1;
	fi

	# CATALOG_PORT
	if [ -z "${CATALOG_PORT}" ]; then
		echo "CATALOG_PORT not set. Using parameter \"$2\"";
		CATALOG_PORT=$2;
	fi

	if [ -z "${CATALOG_PORT}" ]; then
		echo "CATALOG_PORT not set. Using default key";
		CATALOG_PORT=8081;
	fi

	#set +x;
}

function get_items() {
	CURL=$(curl -s --max-time 5 http://${CATALOG_HOST}:${CATALOG_PORT}/micro/items | jq '. | length');
	#echo "Found items with \"${CURL}\" items"

	if [ ! "$CURL" -gt "0" ]; then
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