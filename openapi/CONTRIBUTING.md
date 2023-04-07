## OpenAPI Specification

For those not familiar with the OpenAPI specification, the full documentation available here: https://swagger.io/specification/ and there is a good set of tutorials here: https://swagger.io/docs/specification/about/.  There is also an online editor available here: https://editor.swagger.io/.

## Layout of Files

Each of the endpoints is split out into individual files. The file name is the endpoint name, and the contents are the OpenAPI specification for that endpoint.  All filenames are in lower case, even if the endpoint is not.

## Tags

The endpoints have been logically grouped into those that have been documented (no tag is present and it therefore gets grouped under "default") and those undocumented with a tag of "Undocumented".

### Undocumented

Endpoints with a description and tags of "Undocumented" have either not been converted from the README to OpenAPI, or have not been documented in the README.

```yaml
  description: Undocumented
  tags:
    - Undocumented
```

Please only remove the Undocumented description and tags if you have added example(s) _and_ added a description of the endpoint.

### Deprecated

Endpoints with a field `deprecated: true` and tag of "Deprecated" have been removed by Tesla and are no longer present in a future version of the Powerwall API.

```yaml
get:
  deprecated: true
  tags:
    - Deprecated
```

At the time of writing this CONTRIBUTING.md file, there are no deprecated endpoints - those not present when converting to OpenAPI spec have been removed.