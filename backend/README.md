# Aurelia API

FastAPI and SQLAlchemy backend for the jewellery catalogue.

## Run locally

```powershell
cd backend
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
copy .env.example .env
uvicorn main:app --reload --port 8000
```

The API seeds the catalogue on first start. Open `http://127.0.0.1:8000/docs` for the interactive API documentation.

The development admin account defaults to `admin@aurelia.test` / `change-this-password`; replace both values in `.env` before deployment.

## Database

The default database is SQLite at `backend/aurelia.db`. Set `DATABASE_URL` in `.env` to a PostgreSQL connection string for production, for example `postgresql+psycopg://user:password@host:5432/aurelia` and add `psycopg[binary]` to the requirements.

## Endpoints

- `GET /health`
- `GET /api/products`
- `GET /api/products?search=ring&category=Rings&sort=price_asc&skip=0&limit=24`
- `GET /api/categories`
- `GET /api/products/{product_id}`
- `POST /api/orders`
- `GET /api/orders/{order_id}`
- `GET /api/me/orders`
- `GET/POST /api/me/addresses`
- `GET /api/me/cart`, `PUT /api/me/cart`
- `GET /api/me/wishlist`, `POST/DELETE /api/me/wishlist/{product_id}`
- `GET/POST /api/products/{product_id}/reviews`
- `POST /api/auth/login`
- `POST /api/auth/register`
- `POST /api/auth/customer-login`
- `POST /api/admin/products` (JWT required)
- `PUT /api/admin/products/{product_id}` (JWT required)
- `DELETE /api/admin/products/{product_id}` (JWT required)
- `POST /api/payments/create-session` (demo mode by default, Stripe when configured)
- `GET /api/admin/dashboard` (JWT required)

## Confirmation email

Set `SMTP_HOST`, `SMTP_USERNAME`, `SMTP_PASSWORD`, and `SMTP_FROM` to send order confirmations. With SMTP unset, local development prints the confirmation event to the API log instead.

The seed routine is safe to run repeatedly and only inserts missing product/category names. It does not delete customer or order data.
