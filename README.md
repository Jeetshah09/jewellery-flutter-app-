# Aurelia Fine Jewellery

A Flutter web jewellery storefront backed by FastAPI, SQLAlchemy, and a persistent SQL database.

## Architecture

- Flutter frontend: responsive catalogue, search, category filtering, product details, favourites, cart, customer login/register, and order requests.
- Python backend: `backend/main.py`, FastAPI REST API, JWT auth, SQLAlchemy models, admin product CRUD, customer data, reviews, wishlist, cart, and dashboard metrics.
- Development database: SQLite at `backend/aurelia.db`.
- Container database: PostgreSQL 16 through `docker-compose.yml`.
- Payment: demo payment mode locally; Stripe Checkout when configured.
- Email: SMTP confirmations when configured; development confirmations are logged by the API.

## Run locally

Install Python dependencies from `backend/requirements.txt`, then run:

```powershell
.\run_dev.ps1
```

This starts the API on `http://127.0.0.1:8003` and the Flutter web app in Chrome. The API documentation is at `http://127.0.0.1:8003/docs`.

Run checks:

```powershell
flutter analyze
flutter test
cd backend
python -m unittest test_api.py
python -m py_compile main.py test_api.py
```

## Container deployment

Copy and configure `backend/.env.example`, set production secrets, then run:

```powershell
docker compose up --build
```

The containerized website is served at `http://localhost:8080`; the API is at `http://localhost:8000`.

## Development administrator

The local development administrator is configured in `backend/.env`. Change `ADMIN_EMAIL`, `ADMIN_PASSWORD`, and `JWT_SECRET` before any shared or production deployment. Never commit real secrets.

## Production notes

Configure PostgreSQL, Stripe keys and webhooks, SMTP credentials, HTTPS, secure CORS origins, a secret manager, and a real migration runner before production. The current development seed contains 40 demonstration products and uses legally accessible public image URLs; prices are illustrative, not live market rates.
