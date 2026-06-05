# Geolocation API

A RESTful JSON:API service that stores geolocation data for IP addresses and URLs, backed by a swappable external geolocation provider ([ipstack](https://ipstack.com/) out of the box).

## Quickstart (Docker)

```sh
docker compose up --build
```

That's it. The API is served on `http://localhost:3000`, the database is created and seeded with sample data, and no external account or API key is required (see [Providers](#providers)).

```sh
TOKEN="secret-demo-token"

# List stored geolocations
curl -H "Authorization: Bearer $TOKEN" http://localhost:3000/geolocations

# Store a geolocation for an IP
curl -X POST http://localhost:3000/geolocations \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"ip":"9.9.9.9"}'

# Store a geolocation for a URL (host is resolved to an IP)
curl -X POST http://localhost:3000/geolocations \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"url":"https://github.com"}'

# Fetch by IP or URL
curl -H "Authorization: Bearer $TOKEN" "http://localhost:3000/geolocations?ip=9.9.9.9"
curl -H "Authorization: Bearer $TOKEN" "http://localhost:3000/geolocations?url=https://github.com"

# Delete by IP or URL
curl -X DELETE -H "Authorization: Bearer $TOKEN" "http://localhost:3000/geolocations?ip=9.9.9.9"
```

> **Why does the container run in production mode?** The image is production-built (development/test gems are excluded), and production config is what makes error handling observable: in development mode Rails renders HTML debug pages for exceptions, while in production the API returns the structured JSON:API errors documented below.

### Using the real ipstack provider

```sh
GEOLOCATION_PROVIDER=ipstack IPSTACK_API_KEY=your_key docker compose up
```

## API

All endpoints (except `GET /up`) require a bearer token:
`Authorization: Bearer <API_TOKEN>` (default in Docker: `secret-demo-token`).

Responses follow the [JSON:API](https://jsonapi.org/) specification. Request bodies are accepted both as plain JSON (`{"ip": "8.8.8.8"}`) and as a JSON:API envelope (`{"data": {"type": "geolocations", "attributes": {"ip": "8.8.8.8"}}}`).

| Method | Path | Description |
|---|---|---|
| `POST` | `/geolocations` | Store geolocation for an `ip` or `url` (body) |
| `GET` | `/geolocations` | List all stored geolocations |
| `GET` | `/geolocations?ip=…` / `?url=…` | Fetch one stored geolocation |
| `DELETE` | `/geolocations?ip=…` / `?url=…` | Delete a stored geolocation |
| `GET` | `/up` | Health check (public) |

Notes:

- A URL input is normalized (bare hosts get `https://`), its host is DNS-resolved, and the geolocation is stored under the resolved IP together with the URL.
- IPs are stored in canonical form, so `2001:DB8::1` and `2001:db8::1` address the same record. IPv4 and IPv6 are both supported.
- `GET` reads stored data only — it never calls the external provider. `POST` is the only endpoint that does.

### Error handling

All errors are JSON:API error objects: `{"errors":[{"status":"…","title":"…","detail":"…"}]}`.

| Condition | Status |
|---|---|
| Missing/invalid bearer token | `401` |
| Malformed JSON body | `400` |
| Missing `ip`/`url` parameter, or both at once | `400` |
| Invalid IP format or unparseable URL | `422` |
| URL host fails DNS resolution | `422` |
| Record not found, or unknown route | `404` |
| IP already stored | `409` |
| Provider down / timed out / rate-limited / bad key | `502` |
| Anything unexpected | `500` (JSON, never an HTML error page) |

## Providers

The geolocation provider is an adapter behind a small interface (`Providers::Base#lookup(ip) → Providers::Result`), selected at runtime via `GEOLOCATION_PROVIDER`:

- `fake` (default) — deterministic offline data; no account, no network. Used by Docker and the test suite.
- `ipstack` — real lookups via ipstack; requires `IPSTACK_API_KEY`.

Adding a provider = implement `Providers::Base`, map the payload into `Providers::Result`, and register the class in `Providers::REGISTRY`. Nothing else in the application changes.

```
app/lib/providers.rb        # registry, error taxonomy
app/lib/providers/base.rb   # the interface
app/lib/providers/result.rb # normalized data struct
app/lib/providers/ipstack.rb
app/lib/providers/fake.rb
```

## Configuration

| Variable | Default | Purpose |
|---|---|---|
| `GEOLOCATION_PROVIDER` | `fake` | `fake` or `ipstack` |
| `IPSTACK_API_KEY` | — | Required when provider is `ipstack` |
| `API_TOKEN` | unset (`secret-demo-token` in Docker) | Bearer token; auth is disabled when unset |

Copy `.env.example` to `.env` for local development.

## Local development

### With Docker

```sh
docker compose -f docker-compose.dev.yml up --build
```

Runs in development mode with the source bind-mounted into the container — code changes apply without rebuilding. Gems live in a named volume. Authentication works exactly like the production compose setup (same `secret-demo-token` default), and error responses are the same JSON:API objects, because errors are handled inside the application (including unknown routes) rather than by environment-specific error pages.

### Without Docker

Requires Ruby 4.0.0 (see `.ruby-version`).

```sh
bundle install
bin/rails db:prepare db:seed
bin/rails server  # http://localhost:3000, fake provider, auth disabled
```

## Tests

```sh
bundle exec rspec
```

The suite covers the model, the provider adapters (success and every failure mode, with HTTP stubbed via WebMock), the services, and request specs for the full error matrix above. CI runs the suite plus RuboCop and Brakeman.

## Design notes & future work

- **SQLite** keeps the setup zero-config; swapping to PostgreSQL is a `database.yml`/adapter change.
- **No TTL/refresh**: stored geolocations never expire. A production cache would refresh stale records (e.g. a `PUT` endpoint or background job).
- **URL lookups match the stored, normalized URL string.** Equivalent-but-different URLs (`www.` vs apex) are distinct records by design.
- **No pagination** on the list endpoint; fine for evaluation datasets.
