## How to use the Swagger UI Try it out feature against your own Powerwall

**NOTE**: _the below does require technical knowledge of how to use nginx or the equivalent reverse proxy._

One of the advantages of the Swagger UI is that you can use the "Try it out" button to test the endpoints against your own Powerwall.

To use the Swagger UI to make requests to your Powerwall, you will need a reverse proxy that can route requests to your Powerwall.
    The reverse proxy is required because the Swagger UI will make requests to your from a different origin than your Powerwall hostname
    [CORS](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS).  Using a reverse proxy enables you to add additional headers,
    required to fulfill the CORS request requirements.

The following is an example of a reverse proxy configuration that will work with the Swagger UI.  This example uses nginx, but you
    can use any reverse proxy that supports CORS.

```nginx
# upgrade all http requests to https
server {
    listen              80;
    server_name         powerwall.example.co.uk;
    return              301 https://powerwall.example.co.uk$request_uri;
}

server {
    listen              443 ssl;
    server_name         powerwall.example.co.uk;
    ssl_certificate     /certbot/example.co.uk/fullchain.pem;
    ssl_certificate_key /certbot/example.co.uk/privkey.pem;

    location / {
    if ($request_method = OPTIONS ) {
        # if the repository is forked, you would need to change the below github address to your username
        add_header 'Access-Control-Allow-Origin' "https://vloschiavo.github.io" always;
        add_header 'Access-Control-Allow-Headers' "authorization, content-type" always;
        return 200;
    }
    # this ip address is the address of your Tesla Powerwall
    proxy_pass        https://192.168.0.XX:443;
    # if the repository is forked, you would need to change the below github address to your username
    add_header 'Access-Control-Allow-Origin' "https://vloschiavo.github.io" always;
    }
}
```

Once the nginx configuration is in place, you can use the Swagger UI to make requests to your Powerwall. Change the server->hostname
    variable to point to your nginx instance.  You can now try out the endpoints by clicking the "Try it out" button.