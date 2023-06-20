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

## Submitting Pull Requests

### Testing the Swagger UI on your forked copy

Before submitting a pull request, please try out the Swagger UI on your forked copy.  You will either need to enable GitHub Pages on your forked copy, and then you can access the Swagger UI at `https://<your-github-username>.github.io/powerwall2/openapi/`.  E.g. https://vloschiavo.github.io/powerwall2/openapi/, or you can use nginx to run up the Swagger UI locally.

#### Using GitHub pages

To enable GitHub Pages go to your forked copy of the repository, Settings --> Pages --> Source: Deploy from a branch --> Branch: <your branch name> --> Save.

![Enabling GitHub Pages on branch](enable-github-pages-on-branch.png)

#### Using nginx

To run up the Swagger UI viewer using nginx, you can use the docker compose file by running the following from the terminal: 

```
cd openapi

docker compose up
```

### Pre-Commit Checks

Before submitting pull request changes to the OpenAPI specification, please try to run the pre-commit checks.  You can do this by installing [pre-commit](https://pre-commit.com/index.html#install) or by running a docker container with pre-commit already installed.  E.g.

```bash
docker run --rm -v $(pwd):/data fxinnovation/pre-commit
```

### Repointing exampleValue references to vloschiavo's repository

Before submitting a pull request, please ensure that any exampleValue references are pointing to vloschiavo/powerwall2's repository.  You can do this by searching and replacing or using the following script:

```bash
./point-externalValue-examples-at-vloschiavo-powerwall2-master.sh
```