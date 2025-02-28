# SOLIS
## Token

## Endpoints 
```http request
GET https://base_url/_vandal
```
JSON:API client. 
```http request
GET https://base_url/schema.json
```
JSON:API representation of the model
```http request
GET https://base_url/_doc
```
Documentation URL
```http request
GET https://base_url/_help
```
This page
```http request
GET https://base_url/_yas
```
SPARQL client
```http request
GET https://base_url/_formats
```
Possible available record formats
```http request
POST https://base_url/_sparql
```
SPAQL endpoint
```http request
GET https://base_url/_model
```
## CRUD operations
### READ data
```http request
GET https://base_url/
```
Get a list of available entities
```http request
GET https://base_url/entity
```
READ all record for entity. Use Vandal to create complex queries
### CREATE data
```http request
POST https://base_url/entity
Content-Type: application/json

{
    "p1": "text",
    "p2": {
        "id": "active"
    }
}
```
### UPDATE data
```http request
PUT https://base_url/entity/id_of_entity
Content-Type: application/json

{
    "p1": "text text"
}
```

### DELETE data
```http request
DELETE https://base_url/entity/id_of_entity
```

