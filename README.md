# Geo IP Server

The Geo IP Server service provides geolocation data for given IP addresses. It exposes an endpoint at `/geoips/{:ip}`, which returns data in JSON format.

This repository serves as a template for anyone interested in running a similar service in their own hosting environment. While it's configured for fly.io hosting out of the box, you can easly adapt it for other platforms. To get started, make sure to obtain your own MaxMind license key and create a fly.io account.

The see it in action, visit https://geo-ip-server-demo.fly.dev. It should display your country's flag, demonstrating how the service works.

## Data Management and Caching

IP addresses are automatically loaded twice a week from the [MaxMind's GeoLite2](https://dev.maxmind.com/geoip/geolite2-free-geolocation-data) City database into a PostgreSQL instance. MaxMind and other geoip data providers such as [TransUnion/Neustar](https://www.transunion.com/solution/truvalidate/digital-insights/ip-intelligence), [IP2Location](https://www.ip2location.com), and others ship their databases containing IP address ranges (in CIDR format, both for IPv4 and IPv6). To allow efficient querying of IP ranges with individual addresses, `cidr` PostgreSQL data type and `gist` index were used.

Fetching geolocation data from the database is internally cached by the service using [nebulex](https://github.com/cabol/nebulex). The cache is purged on each successful import of fresh data from CSV files.

## Running the Service Locally

You can start the server in development in two ways: by running a mix task `phx.server` or by using a Docker container with a Docker Compose configuration file.

### Using the Mix Task

To start the service locally with mix, run the following command:
```bash
$ mix phx.server
```

If you encounter `[error] Postgrex.Protocol (#PID<0.277.0>) failed to connect:` errors, ensure that you run the PostgreSQL server beforehand. You can run a Dockerized version with this command:
```bash
$ docker run -d -p 5432:5432 -e POSTGRES_HOST_AUTH_METHOD=trust postgres:latest
```

Once you have the PostgreSQL server running, you might still encounter errors:
```
[error] Postgrex.Protocol (#PID<0.274.0>) failed to connect: ** (Postgrex.Error) FATAL
3D000 (invalid_catalog_name) database "geo_ip_server_dev" does not exist
```

Run the following script to create the initial database and run migrations:
```bash
mix ecto.setup
```

### Using Docker Compose

For running the containerized service (including its PostgreSQL dependency), use the following command:
```bash
$ docker-compose up
```

This will start both the PostgreSQL server and REST API server, create the database, and run migrations. The service runs web server exposed on port 4000. Once you've imported some geoip data (as explained in the next [section](#importing-from-csv)), you can try the following command:
```bash
$ curl -u admin:admin http://localhost:4000/geoips/1.0.81.9
HTTP/1.1 200 OK
{"records":[{"city_name":"Kumari","continent_code":"AS","continent_name":"Asia","country_iso_code":"JP"}]}
```

## Importing from CSV

To populate the database with geoip data, the service can import the IP address data from MaxMind's Geolite2 City database in CSV format. To run the import manually, use the following command:
```bash
$ GEOLITE2_CITY_LICENSE_KEY=<secret_key> mix import_geolite2
```

Make sure to replace `<secret_key>` with a valid MaxMind's [license key](https://support.maxmind.com/hc/en-us/articles/4407111582235-Generate-a-License-Key).

In the production environment, use this command:
```bash
$ GEOLITE2_CITY_LICENSE_KEY=<secret_key> /app/bin/import_geolite2
```

A cronjob is run twice a week (in production):
```
51 23 * * 1,4 /app/bin/import_geolite2
```

## Querying the Gelocation Data

 You can retrieve geolocation data from the `/api/geoips` endpoint. Ensure you use the correct basic authentication credentials to avoid receiving 401 errors. If the database does not contain an entry for the provided IP address, a 404 error is returned. Here are a few examples of service queries and responses:

```bash
$ curl -i -u USERNAME:PASSWORD http://geo-ip-server.local/api/geoips/1.0.81.9
HTTP/1.1 200 OK
{"records":[{"city_name":"Kumari","continent_code":"AS","continent_name":"Asia","country_iso_code":"JP"}]}

$ curl -i -u USERNAME:PASSWORD http://geo-ip-server.local/api/geoips/192.168.0.1
HTTP/1.1 404 Not Found
{"error":"Not Found"}

$ curl -i -u USERNAME:PASSWORD http://geo-ip-server.local/api/geoips/badip
HTTP/1.1 400 Bad Request
{"error":"Bad Request"}
```

## Deployment to fly.io

Deploying `geo-ip-server` to production is straightforward when using fly.io, a platform for hosting Dockerized micro VMs. After authenticating the `flyctl` CLI app with a valid fly.io account, you need to deploy a PostgreSQL application first and then the service itself.

### PostgreSQL Deployment

The PostgreSQL instance, ready to be deployed as a backend for the `geo-ip-server` application can be found in a separate [geo-ip-server-db](https://github.com/okulik/geo-ip-server-db) repository. It was forked from fli.io's PostgreSQL template to remove unnecessary extensions. Check the repository's README.md for further instructions.

### Geo IP Server Deployment

Deploying the service should be simple if you use the included [fly.io configuration](https://github.com/okulik/geo-ip-server/blob/main/fly.toml) file. Ensure that the region suits your needs and matches PostgreSQL's region. Choose a region that's closest to your service's users. Here are all the necessary steps:
```bash
$ fly launch --no-deploy
$ fly secrets set API_BASIC_AUTH_USERNAME=<user> API_BASIC_AUTH_PASSWORD=<password> \
    ADMIN_BASIC_AUTH_USERNAME=<user2> ADMIN_BASIC_AUTH_PASSWORD=<password2> \
    DATABASE_URL=postgres://postgres:<password3>@mygeoipserverdb.internal/geo-ip-srv \
    GEOLITE2_CITY_LICENSE_KEY=<license>
$ fly deploy
```

## Customizing Running the Service

The `geo-ip-server` depends on several environment variables where secrets or behaviour customisations are stored:
* DATABASE_URL - Sets full database connection string (required in prod).
* POOL_SIZE - Sets the size of ecto repo's pool size, defaults to 10 (prod only).
* API_BASIC_AUTH_USERNAME - Sets api endpoint authentication user name (required, defaults to 'admin' if not in prod).
* API_BASIC_AUTH_PASSWORD - Sets api endpoint authentication password (required, defaults to 'admin' if not in prod).
* ADMIN_BASIC_AUTH_USERNAME - Sets admin endpoint authentication user name (required, defaults to 'admin' if not in prod).
* ADMIN_BASIC_AUTH_PASSWORD - Sets admin endpoint authentication password (required, defaults to 'admin' if not in prod).
* GEOLITE2_CITY_LICENSE_KEY - Your personal MaxMind license key (required)
