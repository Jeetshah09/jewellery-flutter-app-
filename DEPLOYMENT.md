# Deployment

## Full stack with Docker

1. Review the development credentials in `docker-compose.yml`.
2. Set a long random `JWT_SECRET`, a strong admin password, and production CORS origins before deployment.
3. Keep `PAYMENT_MODE=demo` until Stripe keys and URLs are configured.
4. Run:

```powershell
docker compose up --build
```

The website is available at `http://localhost:8080`. The API is available at `http://localhost:8000` and its docs at `http://localhost:8000/docs`.

## Production checklist

- Compose provisions PostgreSQL 16 and seeds the catalogue automatically.
- For a managed database, set `DATABASE_URL=postgresql+psycopg://...`.
- Set `PAYMENT_MODE=stripe` and `STRIPE_SECRET_KEY` only in the deployment secret store.
- Configure Stripe webhook handling before marking orders as paid.
- Serve the Flutter web build behind HTTPS and set `API_BASE_URL` to the deployed API.
- Replace the default admin credentials before exposing the API.
