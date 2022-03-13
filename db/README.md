# CMPT 756 DB service

This service provides a consistent interface to whichever storage service is used as a backend for the application. The current version uses Amazon DynamoDB.  This could be replaced with another service, such as MongoDB without changing the higher-level services S1 (User) and S2 (Music), which are insulated from the underlying storage service by this layer.