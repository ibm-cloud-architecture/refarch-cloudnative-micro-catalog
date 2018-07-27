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

	# Protocol
	if [ -n "$ES_PROTOCOL" ]; then
		echo "Protocol defined. Using ${ES_PROTOCOL}"
		PROTOCOL=${ES_PROTOCOL}
	else
		echo "Protocol NOT defined. Using http"
		PROTOCOL=http
	fi

	# URI
	if [ -n "$ELASTICSEARCH_URI" ]; then
		echo "Getting elements from ELASTICSEARCH_URI"
		parse_from_uri $ELASTICSEARCH_URI

	elif [ -n "$elastic" ]; then
		echo "Running in Kubernetes";
	    el_uri=$(echo $elastic | jq -r .uri)
	    parse_from_uri $el_uri

    elif [ -n "$ES_USER" ] && [ -n "$ES_PASSWORD" ]; then
	    echo "Username and Password set. Using Elasticsearch Community Chart"
	    parse_from_uri "${PROTOCOL}://${ES_USER}:${ES_PASSWORD}@${ES_HOST}:${ES_PORT}"

	elif [ -n "$ES_USER" ]; then
	    echo "No Password was set. Using Elasticsearch Community Chart"
	    parse_from_uri "${PROTOCOL}://${ES_USER}@${ES_HOST}:${ES_PORT}"

	else
	    echo "No Password or User was set. Using Elasticsearch Community Chart"
	    parse_from_uri "${PROTOCOL}://${ES_HOST}:${ES_PORT}"
	fi
}