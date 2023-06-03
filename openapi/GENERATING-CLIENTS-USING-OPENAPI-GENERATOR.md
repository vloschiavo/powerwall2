## Generating a client using openapi-generator-cli

From [their GitHub documentation](https://github.com/OpenAPITools/openapi-generator/) "OpenAPI Generator allows generation of API client libraries (SDK generation), server stubs, documentation and configuration automatically given an OpenAPI Spec".

Below is an example of using the openapi-generator-cli to generate a java client from the octopus-energy-api.yaml file:

```
cd openapi

docker run \
    --rm \
    -v "${PWD}:/files" \
    openapitools/openapi-generator-cli \
    generate \
    -i /files/spec.yaml \
    -g java \
    -o /files/client/
```

See https://github.com/OpenAPITools/openapi-generator/ for full documentation on the openapi-generator.
