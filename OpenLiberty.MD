###### refarch-cloudnative-micro-catalog

## Deploy Catalog Application on Open Liberty

You can run your Spring Boot applications on Open Liberty. Open Liberty will be the packaged server and the application will run on it instead of the default embedded server. Below are steps to run the Catalog application on Open Liberty.

## Table of Contents
+ [Deploy the Elasticsearch Docker Container](#deploy-the-elasticsearch-docker-container)
+ [Deploy the Catalog locally](#deploy-the-catalog-locally)
+ [Deploy the Catalog Docker Container](#deploy-the-catalog-docker-container)

Before deploying the Catalog service locally using Maven or on Docker, make sure that the Inventory service and all its dependencies like MySQL are up and running. If not follow the instructions [here](https://github.com/ibm-cloud-architecture/refarch-cloudnative-micro-inventory/blob/spring/OpenLiberty.MD) to start the Inventory service.

## Deploy the Elasticsearch Docker Container

Run the Elasticsearch as a Docker container. Below is the command to start it.
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
* Deploy the Inventory Docker container as shown [here](https://github.com/ibm-cloud-architecture/refarch-cloudnative-micro-inventory/blob/spring/OpenLiberty.MD#deploy-the-inventory-docker-container)
* Deploy the Elasticsearch Docker container as shown in [here](#deploy-the-elasticsearch-docker-container)

Once all the above is done, we can run the Spring Boot Catalog application locally as follows:

1. Open [`src/main/resources/application.yml`](src/main/resources/application.yml) file, enter the following values for the fields below, and save the file:
    
```
# Server configuration
server:
  context-path: /micro
  port: 8081

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
  url: http://127.0.0.1:9080
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
$ curl http://localhost:8081/micro/items
```

That's it, you have successfully deployed and tested the Catalog microservice.

## Deploy the Catalog Docker Container

In this section you will run the Spring Boot application on Open Liberty using Docker. Before we show you how to do so, you will need to do the following.
* Deploy a MySQL Docker container as shown [here](https://github.com/ibm-cloud-architecture/refarch-cloudnative-micro-inventory/blob/spring/OpenLiberty.MD#deploy-the-mysql-docker-container)
* Populate MySQL database with data as shown [here](https://github.com/ibm-cloud-architecture/refarch-cloudnative-micro-inventory/blob/spring/OpenLiberty.MD#populate-the-mysql-database) 
* Deploy the Inventory Docker container as shown [here](https://github.com/ibm-cloud-architecture/refarch-cloudnative-micro-inventory/blob/spring/OpenLiberty.MD#deploy-the-inventory-docker-container)
* Deploy the Elasticsearch Docker container as shown in [here](#deploy-the-elasticsearch-docker-container)

Once all of them are ready and deployed, we can run the Spring Boot Catalog application on Open Liberty docker as follows:

1. Open [`src/main/resources/application.yml`](src/main/resources/application.yml) file, enter the following values as follows, and save the file:

```
# Server configuration
server:
  context-path: /micro
  port: 8081

# Spring properties
spring:
  application:
     name: catalog-microservice

# Elasticsearch
elasticsearch:
  url: http://catalogelasticsearch:9200
  user: elastic
  password: changeme
  index: micro
  doc_type: items

inventoryService:
  url: http://inventory:9080
```

2. Modify your POM file to generate the Docker image. Follow the below steps.
- Open [`pom.xml`](pom.xml)
- Modify the `boost-maven-plugin` as below.

```
            <plugin>
                <groupId>io.openliberty.boost</groupId>
                <artifactId>boost-maven-plugin</artifactId>
                <version>0.1</version>
                <executions>
                  <execution>
                    <!-- <phase>package</phase>
                    <goals>
                        <goal>package</goal>
                    </goals> -->
                    <goals>
                      <goal>docker-build</goal>
                    </goals>
                  </execution>
                </executions>
            </plugin>
```

3. To deploy the Catalog container, run the following commands:

Before building the Docker image, make sure there are no other dockerfiles in your repo. If a dockerfile already exists, please remove it.

```bash
# Build the Docker Image
$ mvn clean install 
```

Once done, a Docker image named `liberty-catalog-spring:latest` will be built automatically for you.

Run the Docker container as follows.

```
# Start the Catalog Container
$ docker run --name catalog \
    -e ES_HOST=catalogelasticsearch \
    -e ES_PORT=9200 \
    -e ES_USER=elastic \
    -e ES_PASSWORD=changeme \
    -e INVENTORY_URL=http://inventory:9080 \
    -p 9082:9080 \
    --link inventorymysql:inventorymysql \
    --link catalogelasticsearch:catalogelasticsearch \
    --link inventory:inventory \
    -d liberty-catalog-spring:latest
```

If everything works successfully, you should be able to get some data when you run the following command:
```bash
$ curl http://localhost:9082/micro/items
```


