###### refarch-cloudnative-micro-inventory

## Deploy Inventory Application on Open Liberty

You can run your Spring Boot applications on Open Liberty. Open Liberty will be the packaged server and the application will run on it instead of the default embedded server. Below are steps to run the Inventory application on Open Liberty.

## Table of Contents
+ [Deploy the Elasticsearch Docker Container](#deploy-the-elasticsearch-docker-container)
+ [Deploy the Catalog locally](#deploy-the-catalog-locally)
+ [Deploy the Catalog Docker Container](#deploy-the-catalog-docker-container)

Before deploying the Catalog service locally using maven or on docker, make sure that the Inventory Service and all its dependencies like MySQL are up and running. If not follow the instructions [here](https://github.com/ibm-cloud-architecture/refarch-cloudnative-micro-inventory/blob/spring/OpenLiberty.MD) to start the Inventory service.

## Deploy the Elasticsearch Docker Container

Run the Elasticsearch as a docker container. Below is the command to start it.
```bash
# Start a Elasticsearch Container with a database user, a password, and create a new database
$ docker run --name catalogelasticsearch \
    -e "discovery.type=single-node" \
    -p 9200:9200 \
    -p 9300:9300 \
    -d docker.elastic.co/elasticsearch/elasticsearch:6.3.2
```

## Deploy the Catalog locally

In this section you will build and run the Spring Boot application on Open Liberty locally using Maven. Before we show you how to do so, you will need to do the following:
* Deploy a MySQL Docker container as shown [here](https://github.com/ibm-cloud-architecture/refarch-cloudnative-micro-inventory/blob/spring/OpenLiberty.MD#deploy-the-mysql-docker-container)
* Populate MySQL database with data as shown [here](https://github.com/ibm-cloud-architecture/refarch-cloudnative-micro-inventory/blob/spring/OpenLiberty.MD#populate-the-mysql-database) 
* Deploy the Inventory Docker Container as shown [here](https://github.com/ibm-cloud-architecture/refarch-cloudnative-micro-inventory/blob/spring/OpenLiberty.MD#deploy-the-inventory-docker-container)
* Deploy the Elasticsearch Docker Container as shown in [here](#deploy-the-elasticsearch-docker-container)

Once all the above is done, we can run the Spring Boot Catalog application locally as follows:

1. Open [`src/main/resources/application.yml`](src/main/resources/application.yml) file, enter the following values for the fields below, and save the file:
    
```
# Server configuration
server:
  context-path: /micro
  port: 8080

# Spring properties
spring:
  application:
     name: catalog-microservice

# Elasticsearch
elasticsearch:
  url: http://127.0.0.1:9200
  user: elastic
  password: changeme
  index: micro
  doc_type: items

inventoryService:
  url: http://127.0.0.1:9081
```

2. Build the application as follows.
```bash
$ mvn package
```

3. Run the application on localhost.
```bash
$ java -jar target/liberty-catalog-spring-0.1-SNAPSHOT.jar
```

Once it is deployed, you will see something like below.

```
2018-10-11 12:50:01.813  INFO 22006 --- [cTaskExecutor-1] catalog.ElasticSearch                    : Adding/updating item:
13406: {"id":13406,"name":"Collator","description":"The 85 collator performed many card filing and selection operations. It simultaneously could feed two sets of cards, merging the matched cards and selecting unmatched cards. In addition, the machine could check the sequence of the primary file of cards. It fed up to 120 cards per minute in each feed. IBM withdrew the 85 collator from marketing on September 7, 1978.","price":2799,"imgAlt":"Collator","img":"collator.jpg","stock":1000}
2018-10-11 12:50:01.814  INFO 22006 --- [cTaskExecutor-1] catalog.ElasticSearch                    : Adding/updating item:
13412: {"id":13412,"name":"Selectric Typewriter","description":"Unveiled in 1961, the revolutionary Selectric typewriter eliminated the need for conventional type bars and movable carriages by using an innovative typing element on a head-and-rocker assembly, which, in turn, was mounted on a small carrier to move from left to right while typing.","price":2199,"imgAlt":"Selectric Typewriter","img":"selectric.jpg","stock":1000}
```

4. Validate. You should get a list of all catalog items:
```bash
$ curl http://localhost:8080/micro/items
```

That's it, you have successfully deployed and tested the Catalog microservice.

