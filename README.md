###### refarch-cloudnative-micro-catalog

# Catalog Service

*This project is part of the 'IBM Cloud Native Reference Architecture' suite, available at
https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes*

## Table of Contents

* [Introduction](#introduction)
* [Implementation](#implementation)
* [References](#references)

## Introduction

This project is built to demonstrate Microservice Apps Integration with ElasticSearch. This application serves as a cache to [Inventory](https://github.com/ibm-cloud-architecture/refarch-cloudnative-micro-inventory/tree/microprofile/inventory) by leveraging Elasticsearch as its datasource.

- Elasticsearch is used as the [Catalog](https://github.com/ibm-cloud-architecture/refarch-cloudnative-micro-inventory/tree/microprofile/catalog) microservice's data source.

<p align="center">
    <img src="images/inventory-catalog.png">
</p>

## Implementation

- [Microprofile](../../tree/microprofile/) - leverages the Microprofile framework.
- [Spring](../../tree/spring/) - leverages Spring Boot as the Java programming model of choice.

## References

- [Java MicroProfile](https://microprofile.io/)
- [Spring Boot](https://projects.spring.io/spring-boot/)
- [Kubernetes](https://kubernetes.io/)
- [Minikube](https://kubernetes.io/docs/getting-started-guides/minikube/)
- [Docker Edge](https://docs.docker.com/edge/)
- [IBM Cloud](https://www.ibm.com/cloud/)
- [IBM Cloud Private](https://www.ibm.com/cloud-computing/products/ibm-cloud-private/)

