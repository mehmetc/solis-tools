# SOLIS cheatsheet
## Token

## Endpoints 
#### JSON:API client.
```HTTP
GET https://base_url/_vandal
Content-Type: text/html
```

#### JSON:API representation of the model
```HTTP
GET https://base_url/schema.json
Content-Type: application/json
```

#### Documentation URL
```HTTP
GET https://base_url/_doc
Content-Type: text/html
```

#### This page
```HTTP
GET https://base_url/_help
Content-Type: text/html
```

#### SPARQL client
```HTTP
GET https://base_url/_yas
Content-Type: text/html
```

#### Possible available record formats
```HTTP
GET https://base_url/_formats
```

#### SPAQL endpoint
```HTTP
POST https://base_url/_sparql
```

#### Model diagram
If no ```Content-Type``` is given then you will be redirected to a PlantUML service to render the puml data.
```HTTP
GET https://base_url/_model
Content-Type: image/png, image/svg, application/puml, application/shacl, application/owl

```
## CRUD operations
### READ data
```HTTP
GET https://base_url/
```
Get a list of available entities
```HTTP
GET https://base_url/entity
```
READ all record for entity. Use Vandal to create complex queries
### CREATE data
```HTTP
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
```HTTP
PUT https://base_url/entity/id_of_entity
Content-Type: application/json

{
    "p1": "text text"
}
```

### DELETE data
```HTTP
DELETE https://base_url/entity/id_of_entity
```

