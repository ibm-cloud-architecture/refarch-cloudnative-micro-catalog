#!/bin/bash
source scripts/uri_parser.sh

function parse_from_uri() {
	# Do the URL parsing
	uri_parser $1

	# Construct elasticsearch url
	el_url="${uri_schema}://${uri_host}:${uri_port}"
	el_user=${uri_user}
	el_password=${uri_password}

    JAVA_OPTS="${JAVA_OPTS} -Delasticsearch.url=${el_url}"
    JAVA_OPTS="${JAVA_OPTS} -Delasticsearch.user=${el_user}"
    JAVA_OPTS="${JAVA_OPTS} -Delasticsearch.password=${el_password}"	
}

function parse_elasticsearch() {
	echo "Parsing elasticsearch info"

	if [ -n "$ELASTICSEARCH_URI" ]; then
		echo "Getting elements from ELASTICSEARCH_URI"
		parse_from_uri $ELASTICSEARCH_URI

	elif [ -n "$elastic" ]; then
		echo "Running in Kubernetes";
	    el_uri=$(echo $elastic | jq -r .uri)
	    parse_from_uri $el_uri

    else
	    echo "Could not parse elasticsearch info";
	fi
}