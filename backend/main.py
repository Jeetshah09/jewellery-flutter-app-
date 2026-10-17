from __future__ import annotations

import os
import base64
import hashlib
import io
import secrets
import smtplib
from datetime import datetime, timezone
from decimal import Decimal
from email.message import EmailMessage
from typing import Generator

import jwt
import qrcode
import stripe
from dotenv import load_dotenv
from fastapi import Depends, FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from fastapi.responses import HTMLResponse
from pydantic import BaseModel, ConfigDict, Field
from sqlalchemy import DateTime, ForeignKey, Numeric, String, Text, UniqueConstraint, create_engine, func, inspect, select, text
from sqlalchemy.orm import DeclarativeBase, Mapped, Session, mapped_column, relationship, sessionmaker

load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./aurelia.db")
connect_args = {"check_same_thread": False} if DATABASE_URL.startswith("sqlite") else {}
engine = create_engine(DATABASE_URL, connect_args=connect_args)
SessionLocal = sessionmaker(bind=engine, autoflush=False, expire_on_commit=False)


class Base(DeclarativeBase):
    pass


class ProductRecord(Base):
    __tablename__ = "products"

    id: Mapped[int] = mapped_column(primary_key=True)
    name: Mapped[str] = mapped_column(String(120), unique=True, index=True)
    category: Mapped[str] = mapped_column(String(80), index=True)
    image: Mapped[str] = mapped_column(String(500))
    price: Mapped[Decimal] = mapped_column(Numeric(10, 2))
    description: Mapped[str] = mapped_column(Text)
    material: Mapped[str] = mapped_column(String(240))
    stock: Mapped[int] = mapped_column(default=0)
    is_featured: Mapped[bool] = mapped_column(default=False)


class OrderRecord(Base):
    __tablename__ = "orders"

    id: Mapped[int] = mapped_column(primary_key=True)
    customer_user_id: Mapped[int | None] = mapped_column(ForeignKey("users.id"), nullable=True)
    customer_name: Mapped[str] = mapped_column(String(120))
    customer_email: Mapped[str] = mapped_column(String(240))
    total: Mapped[Decimal] = mapped_column(Numeric(10, 2))
    status: Mapped[str] = mapped_column(String(40), default="requested")
    created_at: Mapped[datetime] = mapped_column(DateTime, default=lambda: datetime.now(timezone.utc))
    items: Mapped[list["OrderItemRecord"]] = relationship(back_populates="order", cascade="all, delete-orphan")


class UserRecord(Base):
    __tablename__ = "users"

    id: Mapped[int] = mapped_column(primary_key=True)
    name: Mapped[str] = mapped_column(String(120))
    email: Mapped[str] = mapped_column(String(240), unique=True, index=True)
    password_hash: Mapped[str] = mapped_column(String(300))
    created_at: Mapped[datetime] = mapped_column(DateTime, default=lambda: datetime.now(timezone.utc))


class CategoryRecord(Base):
    __tablename__ = "categories"

    id: Mapped[int] = mapped_column(primary_key=True)
    name: Mapped[str] = mapped_column(String(80), unique=True, index=True)
    slug: Mapped[str] = mapped_column(String(100), unique=True, index=True)


class AddressRecord(Base):
    __tablename__ = "addresses"

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), index=True)
    label: Mapped[str] = mapped_column(String(40), default="Home")
    recipient: Mapped[str] = mapped_column(String(120))
    line1: Mapped[str] = mapped_column(String(240))
    city: Mapped[str] = mapped_column(String(100))
    state: Mapped[str] = mapped_column(String(100))
    postal_code: Mapped[str] = mapped_column(String(20))
    country: Mapped[str] = mapped_column(String(80), default="India")


class WishlistRecord(Base):
    __tablename__ = "wishlists"
    __table_args__ = (UniqueConstraint("user_id", "product_id"),)

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), index=True)
    product_id: Mapped[int] = mapped_column(ForeignKey("products.id"), index=True)


class CartItemRecord(Base):
    __tablename__ = "cart_items"
    __table_args__ = (UniqueConstraint("user_id", "product_id"),)

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), index=True)
    product_id: Mapped[int] = mapped_column(ForeignKey("products.id"), index=True)
    quantity: Mapped[int] = mapped_column(default=1)


class ReviewRecord(Base):
    __tablename__ = "reviews"
    __table_args__ = (UniqueConstraint("user_id", "product_id"),)

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), index=True)
    product_id: Mapped[int] = mapped_column(ForeignKey("products.id"), index=True)
    rating: Mapped[int] = mapped_column()
    body: Mapped[str] = mapped_column(Text)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=lambda: datetime.now(timezone.utc))


class InventoryMovementRecord(Base):
    __tablename__ = "inventory_movements"

    id: Mapped[int] = mapped_column(primary_key=True)
    product_id: Mapped[int] = mapped_column(ForeignKey("products.id"), index=True)
    quantity: Mapped[int] = mapped_column()
    reason: Mapped[str] = mapped_column(String(120))
    created_at: Mapped[datetime] = mapped_column(DateTime, default=lambda: datetime.now(timezone.utc))


class OrderItemRecord(Base):
    __tablename__ = "order_items"

    id: Mapped[int] = mapped_column(primary_key=True)
    order_id: Mapped[int] = mapped_column(ForeignKey("orders.id"))
    product_id: Mapped[int] = mapped_column(ForeignKey("products.id"))
    quantity: Mapped[int] = mapped_column(default=1)
    unit_price: Mapped[Decimal] = mapped_column(Numeric(10, 2))
    order: Mapped[OrderRecord] = relationship(back_populates="items")


class AdminLogin(BaseModel):
    email: str
    password: str


class RegisterIn(BaseModel):
    name: str = Field(min_length=2, max_length=120)
    email: str = Field(min_length=5, max_length=240)
    password: str = Field(min_length=8, max_length=128)


class UserOut(BaseModel):
    id: int
    name: str
    email: str


class AddressIn(BaseModel):
    label: str = "Home"
    recipient: str = Field(min_length=2, max_length=120)
    line1: str = Field(min_length=3, max_length=240)
    city: str = Field(min_length=2, max_length=100)
    state: str = Field(min_length=2, max_length=100)
    postal_code: str = Field(min_length=3, max_length=20)
    country: str = "India"


class AddressOut(AddressIn):
    model_config = ConfigDict(from_attributes=True)
    id: int


class CartItemIn(BaseModel):
    product_id: int
    quantity: int = Field(ge=1, le=20)


class ReviewIn(BaseModel):
    rating: int = Field(ge=1, le=5)
    body: str = Field(min_length=3, max_length=1000)


class ReviewOut(ReviewIn):
    model_config = ConfigDict(from_attributes=True)
    id: int
    product_id: int
    user_id: int
    created_at: datetime


class CategoryOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    name: str
    slug: str


class TokenOut(BaseModel):
    access_token: str
    token_type: str = "bearer"


class ProductIn(BaseModel):
    name: str = Field(min_length=2, max_length=120)
    category: str = Field(min_length=2, max_length=80)
    image: str
    price: Decimal = Field(gt=0)
    description: str
    material: str
    stock: int = Field(ge=0)
    is_featured: bool = False


class PaymentIn(BaseModel):
    order_id: int


class PaymentOut(BaseModel):
    mode: str
    checkout_url: str
    reference: str


class ProductOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    name: str
    category: str
    image: str
    price: Decimal
    description: str
    material: str
    stock: int
    is_featured: bool


class OrderItemIn(BaseModel):
    product_id: int
    quantity: int = Field(default=1, ge=1, le=20)


class OrderIn(BaseModel):
    customer_name: str = Field(min_length=2, max_length=120)
    customer_email: str = Field(min_length=5, max_length=240)
    items: list[OrderItemIn] = Field(min_length=1)


class OrderOut(BaseModel):
    id: int
    status: str
    total: Decimal
    created_at: datetime


SEED_PRODUCTS = [
    {"name": "Lumiere Ring", "category": "Rings", "image": "https://images.unsplash.com/photo-1605100804763-247f67b3557e?w=900&q=85", "price": 599, "description": "A luminous silhouette for every day.", "material": "18k recycled gold, lab-grown diamond", "stock": 8, "is_featured": True},
    {"name": "Solene Necklace", "category": "Necklaces", "image": "https://images.unsplash.com/photo-1599643478518-a784e5dc4c8f?w=900&q=85", "price": 899, "description": "Delicate gold, designed to layer.", "material": "18k recycled gold, freshwater pearl", "stock": 5, "is_featured": True},
    {"name": "Pearl Arc Earrings", "category": "Earrings", "image": "https://images.unsplash.com/photo-1535632066927-ab7c9ab60908?w=900&q=85", "price": 299, "description": "Soft luster with a modern curve.", "material": "Sterling silver, freshwater pearl", "stock": 12, "is_featured": False},
    {"name": "Celine Bracelet", "category": "Bracelets", "image": "https://images.unsplash.com/photo-1611652022419-a9419f74343d?w=900&q=85", "price": 399, "description": "A quiet statement in polished metal.", "material": "Gold vermeil, recycled silver", "stock": 6, "is_featured": False},
    {"name": "Nocturne Pendant", "category": "Necklaces", "image": "https://images.unsplash.com/photo-1515562141207-7a88fb7ce338?w=900&q=85", "price": 749, "description": "A moonlit pendant with an architectural edge.", "material": "18k gold, black spinel", "stock": 7, "is_featured": True},
    {"name": "Iris Hoops", "category": "Earrings", "image": "https://images.unsplash.com/photo-1635767798638-3e25273a8236?w=900&q=85", "price": 249, "description": "Sculptural hoops made for everyday movement.", "material": "Recycled sterling silver", "stock": 14, "is_featured": False},
    {"name": "Celeste Signet", "category": "Rings", "image": "https://images.unsplash.com/photo-1603561596112-db8d2a5b4a4b?w=900&q=85", "price": 679, "description": "A modern signet with a polished horizon.", "material": "18k recycled gold", "stock": 4, "is_featured": True},
    {"name": "Mira Cuff", "category": "Bracelets", "image": "https://images.unsplash.com/photo-1619119069152-a2b331eb?", "price": 459, "description": "An open cuff with a soft architectural curve.", "material": "Gold vermeil", "stock": 9, "is_featured": False},
    {"name": "Aster Charm", "category": "Charms", "image": "https://images.unsplash.com/photo-1602173574767-37ac01994b2a?w=900&q=85", "price": 189, "description": "A small constellation to carry close.", "material": "14k gold, white sapphire", "stock": 18, "is_featured": False},
    {"name": "Orion Chain", "category": "Necklaces", "image": "https://images.unsplash.com/photo-1611652022419-a9419f74343d?w=900&q=85", "price": 529, "description": "A fluid chain with a celestial glint.", "material": "Gold vermeil, lab-grown sapphire", "stock": 11, "is_featured": False},
    {"name": "Serein Drop", "category": "Earrings", "image": "https://images.unsplash.com/photo-1535632066927-ab7c9ab60908?w=900&q=85", "price": 339, "description": "A single drop of light, made to move.", "material": "Recycled silver, freshwater pearl", "stock": 10, "is_featured": True},
    {"name": "Vela Stack Ring", "category": "Rings", "image": "https://images.unsplash.com/photo-1603561596112-db8d2a5b4a4b?w=900&q=85", "price": 429, "description": "A slim stacker with a warm golden line.", "material": "14k recycled gold", "stock": 15, "is_featured": False},
]

_ADDITIONAL_SEED = [
    ("Maharani Halo", "Bridal", 1299, "18k gold, cubic zirconia"),
    ("Gulab Jhumka", "Traditional", 549, "22k gold vermeil, pearl"),
    ("Aria Band", "Rings", 359, "Sterling silver, white sapphire"),
    ("Kalyan Bangle", "Bangles", 799, "22k gold vermeil"),
    ("Atlas Chain", "Chains", 629, "925 silver, rhodium finish"),
    ("Nila Mangalsutra", "Mangalsutras", 699, "18k gold, onyx beads"),
    ("Saffron Studs", "Earrings", 229, "14k gold, citrine"),
    ("Rhea Tennis", "Bracelets", 1099, "Lab-grown diamond, silver"),
    ("Aarav Cufflinks", "Men's", 459, "Stainless steel, enamel"),
    ("Mogra Pendant", "Pendants", 289, "Sterling silver, pearl"),
    ("Meera Choker", "Bridal", 1499, "Gold vermeil, glass stones"),
    ("Kohinoor Studs", "Diamond", 899, "Lab-grown diamond, 18k gold"),
    ("Tara Toe Ring", "Traditional", 159, "Sterling silver"),
    ("Yuva Chain", "Men's", 379, "Stainless steel, PVD gold"),
    ("Anika Solitaires", "Diamond", 1199, "Lab-grown diamond, 14k gold"),
    ("Jasmine Layer", "Necklaces", 489, "Gold vermeil, freshwater pearl"),
    ("Rani Chandbali", "Traditional", 739, "Gold vermeil, cubic zirconia"),
    ("Platinum Whisper", "Platinum", 1599, "950 platinum"),
    ("Silver Tide", "Silver", 199, "925 recycled silver"),
    ("Golden Hour", "Gold", 979, "18k recycled gold"),
    ("Opal Muse", "Gifts", 419, "Sterling silver, lab opal"),
    ("Diwali Star", "Gifts", 249, "Gold vermeil, enamel"),
    ("Amara Stack", "Rings", 579, "14k recycled gold"),
    ("Sona Lariat", "Necklaces", 649, "18k gold vermeil"),
    ("Vriksha Leaf", "Pendants", 319, "Sterling silver, green zircon"),
    ("Zoya Pearl", "Earrings", 389, "Freshwater pearl, 14k gold"),
    ("Dev Bracelet", "Men's", 429, "Leather, stainless steel"),
    ("Nazar Charm", "Charms", 139, "Sterling silver, enamel"),
]
_SEED_IMAGES = [
    "https://images.unsplash.com/photo-1605100804763-247f67b3557e?w=900&q=85",
    "https://images.unsplash.com/photo-1599643478518-a784e5dc4c8f?w=900&q=85",
    "https://images.unsplash.com/photo-1535632066927-ab7c9ab60908?w=900&q=85",
    "https://images.unsplash.com/photo-1611652022419-a9419f74343d?w=900&q=85",
]
SEED_PRODUCTS.extend(
    {
        "name": name,
        "category": category,
        "image": _SEED_IMAGES[(index - 1) % len(_SEED_IMAGES)],
        "price": price,
        "description": f"A considered {category.lower()} piece from the Aurelia studio.",
        "material": material,
        "stock": 3 + (index % 16),
        "is_featured": index % 7 == 0,
    }
    for index, (name, category, price, material) in enumerate(_ADDITIONAL_SEED, start=1)
)

app = FastAPI(title="Aurelia Jewellery API", version="1.0.0")
origins = [origin.strip() for origin in os.getenv("CORS_ORIGINS", "*").split(",")]
app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials="*" not in origins,
    allow_methods=["*"],
    allow_headers=["*"],
)
security = HTTPBearer(auto_error=False)
optional_security = HTTPBearer(auto_error=False)


def get_db() -> Generator[Session, None, None]:
    with SessionLocal() as session:
        yield session


def seed_database() -> None:
    Base.metadata.create_all(engine)
    if "customer_user_id" not in {column["name"] for column in inspect(engine).get_columns("orders")}:
        with engine.begin() as connection:
            connection.execute(text("ALTER TABLE orders ADD COLUMN customer_user_id INTEGER"))
    with SessionLocal() as session:
        existing_names = set(session.scalars(select(ProductRecord.name)))
        missing = [ProductRecord(**product) for product in SEED_PRODUCTS if product["name"] not in existing_names]
        if missing:
            session.add_all(missing)
            session.commit()
        existing_categories = set(session.scalars(select(CategoryRecord.slug)))
        categories = {
            product["category"]: product["category"].lower().replace(" ", "-")
            for product in SEED_PRODUCTS
        }
        missing_categories = [
            CategoryRecord(name=name, slug=slug)
            for name, slug in categories.items()
            if slug not in existing_categories
        ]
        if missing_categories:
            session.add_all(missing_categories)
            session.commit()


@app.on_event("startup")
def startup() -> None:
    seed_database()


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok", "service": "aurelia-api"}


def password_hash(password: str, salt: str | None = None) -> str:
    salt = salt or secrets.token_hex(16)
    digest = hashlib.pbkdf2_hmac("sha256", password.encode(), salt.encode(), 120_000).hex()
    return f"{salt}${digest}"


def password_matches(password: str, stored: str) -> bool:
    salt, expected = stored.split("$", 1)
    actual = hashlib.pbkdf2_hmac("sha256", password.encode(), salt.encode(), 120_000).hex()
    return secrets.compare_digest(actual, expected)


def make_token(subject: str, role: str, user_id: int | None = None) -> str:
    payload = {"sub": subject, "role": role}
    if user_id is not None:
        payload["user_id"] = user_id
    return jwt.encode(payload, os.getenv("JWT_SECRET", "dev-only-secret"), algorithm="HS256")


def decode_token(credentials: HTTPAuthorizationCredentials | None) -> dict:
    if credentials is None:
        return {}
    try:
        return jwt.decode(credentials.credentials, os.getenv("JWT_SECRET", "dev-only-secret"), algorithms=["HS256"])
    except jwt.InvalidTokenError as error:
        raise HTTPException(status_code=401, detail="Invalid authentication token") from error


def send_order_confirmation(order: OrderRecord, email: str) -> None:
    host = os.getenv("SMTP_HOST")
    if not host:
        print(f"Development email: order #{order.id} for {email} is {order.status} and totals ${order.total}")
        return
    message = EmailMessage()
    message["Subject"] = f"Aurelia order #{order.id} confirmation"
    message["From"] = os.getenv("SMTP_FROM", "orders@aurelia.test")
    message["To"] = email
    message.set_content(f"Thank you for your order. Order #{order.id} is {order.status}. Total: ${order.total}.")
    with smtplib.SMTP(host, int(os.getenv("SMTP_PORT", "587"))) as server:
        server.starttls()
        server.login(os.environ["SMTP_USERNAME"], os.environ["SMTP_PASSWORD"])
        server.send_message(message)


def require_admin(credentials: HTTPAuthorizationCredentials = Depends(security)) -> str:
    if credentials is None:
        raise HTTPException(status_code=401, detail="Admin authentication required")
    try:
        payload = jwt.decode(credentials.credentials, os.getenv("JWT_SECRET", "dev-only-secret"), algorithms=["HS256"])
        if payload.get("role") != "admin":
            raise ValueError
        return str(payload["sub"])
    except (jwt.InvalidTokenError, KeyError, ValueError) as error:
        raise HTTPException(status_code=401, detail="Admin authentication required") from error


@app.post("/api/auth/login", response_model=TokenOut)
def login(credentials: AdminLogin) -> TokenOut:
    if credentials.email != os.getenv("ADMIN_EMAIL", "admin@aurelia.test") or credentials.password != os.getenv("ADMIN_PASSWORD", "change-this-password"):
        raise HTTPException(status_code=401, detail="Invalid admin credentials")
    return TokenOut(access_token=make_token(credentials.email, "admin"))


@app.post("/api/auth/register", response_model=TokenOut, status_code=201)
def register(user: RegisterIn, db: Session = Depends(get_db)) -> TokenOut:
    email = user.email.lower().strip()
    if db.scalar(select(UserRecord).where(UserRecord.email == email)) is not None:
        raise HTTPException(status_code=409, detail="An account with that email already exists")
    record = UserRecord(name=user.name.strip(), email=email, password_hash=password_hash(user.password))
    db.add(record)
    db.commit()
    db.refresh(record)
    return TokenOut(access_token=make_token(record.email, "customer", record.id))


@app.post("/api/auth/customer-login", response_model=TokenOut)
def customer_login(credentials: AdminLogin, db: Session = Depends(get_db)) -> TokenOut:
    user = db.scalar(select(UserRecord).where(UserRecord.email == credentials.email.lower().strip()))
    if user is None or not password_matches(credentials.password, user.password_hash):
        raise HTTPException(status_code=401, detail="Invalid email or password")
    return TokenOut(access_token=make_token(user.email, "customer", user.id))


def require_customer(credentials: HTTPAuthorizationCredentials = Depends(security)) -> UserRecord:
    if credentials is None:
        raise HTTPException(status_code=401, detail="Customer authentication required")
    identity = decode_token(credentials)
    if identity.get("role") != "customer" or not identity.get("user_id"):
        raise HTTPException(status_code=403, detail="Customer authentication required")
    with SessionLocal() as session:
        user = session.get(UserRecord, int(identity["user_id"]))
        if user is None:
            raise HTTPException(status_code=401, detail="Customer account not found")
        return user


@app.get("/api/categories", response_model=list[CategoryOut])
def list_categories(db: Session = Depends(get_db)) -> list[CategoryRecord]:
    return list(db.scalars(select(CategoryRecord).order_by(CategoryRecord.name)))


@app.get("/api/me", response_model=UserOut)
def current_user(user: UserRecord = Depends(require_customer)) -> UserRecord:
    return user


@app.get("/api/me/addresses", response_model=list[AddressOut])
def list_addresses(user: UserRecord = Depends(require_customer), db: Session = Depends(get_db)) -> list[AddressRecord]:
    return list(db.scalars(select(AddressRecord).where(AddressRecord.user_id == user.id).order_by(AddressRecord.id)))


@app.post("/api/me/addresses", response_model=AddressOut, status_code=201)
def add_address(address: AddressIn, user: UserRecord = Depends(require_customer), db: Session = Depends(get_db)) -> AddressRecord:
    record = AddressRecord(user_id=user.id, **address.model_dump())
    db.add(record)
    db.commit()
    db.refresh(record)
    return record


@app.get("/api/me/wishlist", response_model=list[ProductOut])
def get_wishlist(user: UserRecord = Depends(require_customer), db: Session = Depends(get_db)) -> list[ProductRecord]:
    statement = select(ProductRecord).join(WishlistRecord, WishlistRecord.product_id == ProductRecord.id).where(WishlistRecord.user_id == user.id)
    return list(db.scalars(statement))


@app.post("/api/me/wishlist/{product_id}")
def add_wishlist(product_id: int, user: UserRecord = Depends(require_customer), db: Session = Depends(get_db)) -> dict[str, bool]:
    if db.get(ProductRecord, product_id) is None:
        raise HTTPException(status_code=404, detail="Product not found")
    if db.scalar(select(WishlistRecord).where(WishlistRecord.user_id == user.id, WishlistRecord.product_id == product_id)) is None:
        db.add(WishlistRecord(user_id=user.id, product_id=product_id))
        db.commit()
    return {"ok": True}


@app.delete("/api/me/wishlist/{product_id}")
def remove_wishlist(product_id: int, user: UserRecord = Depends(require_customer), db: Session = Depends(get_db)) -> dict[str, bool]:
    record = db.scalar(select(WishlistRecord).where(WishlistRecord.user_id == user.id, WishlistRecord.product_id == product_id))
    if record is not None:
        db.delete(record)
        db.commit()
    return {"ok": True}


@app.get("/api/me/cart")
def get_cart(user: UserRecord = Depends(require_customer), db: Session = Depends(get_db)) -> list[dict]:
    rows = db.execute(select(CartItemRecord, ProductRecord).join(ProductRecord, ProductRecord.id == CartItemRecord.product_id).where(CartItemRecord.user_id == user.id)).all()
    return [{"quantity": item.quantity, "product": ProductOut.model_validate(product).model_dump(mode="json")} for item, product in rows]


@app.put("/api/me/cart")
def replace_cart(items: list[CartItemIn], user: UserRecord = Depends(require_customer), db: Session = Depends(get_db)) -> dict[str, bool]:
    db.query(CartItemRecord).filter(CartItemRecord.user_id == user.id).delete()
    for item in items:
        product = db.get(ProductRecord, item.product_id)
        if product is None or item.quantity > product.stock:
            raise HTTPException(status_code=409, detail="Cart item is unavailable")
        db.add(CartItemRecord(user_id=user.id, product_id=item.product_id, quantity=item.quantity))
    db.commit()
    return {"ok": True}


@app.get("/api/products/{product_id}/reviews", response_model=list[ReviewOut])
def list_reviews(product_id: int, db: Session = Depends(get_db)) -> list[ReviewRecord]:
    return list(db.scalars(select(ReviewRecord).where(ReviewRecord.product_id == product_id).order_by(ReviewRecord.created_at.desc())))


@app.post("/api/products/{product_id}/reviews", response_model=ReviewOut, status_code=201)
def create_review(product_id: int, review: ReviewIn, user: UserRecord = Depends(require_customer), db: Session = Depends(get_db)) -> ReviewRecord:
    if db.get(ProductRecord, product_id) is None:
        raise HTTPException(status_code=404, detail="Product not found")
    if db.scalar(select(ReviewRecord).where(ReviewRecord.user_id == user.id, ReviewRecord.product_id == product_id)) is not None:
        raise HTTPException(status_code=409, detail="You have already reviewed this product")
    record = ReviewRecord(user_id=user.id, product_id=product_id, **review.model_dump())
    db.add(record)
    db.commit()
    db.refresh(record)
    return record


@app.get("/api/products", response_model=list[ProductOut])
def list_products(
    category: str | None = Query(default=None),
    search: str | None = Query(default=None, max_length=100),
    min_price: Decimal | None = Query(default=None, ge=0),
    max_price: Decimal | None = Query(default=None, ge=0),
    sort: str = Query(default="newest", pattern="^(newest|price_asc|price_desc|featured)$"),
    skip: int = Query(default=0, ge=0),
    limit: int = Query(default=24, ge=1, le=100),
    db: Session = Depends(get_db),
) -> list[ProductRecord]:
    statement = select(ProductRecord).order_by(ProductRecord.id)
    if category:
        statement = statement.where(ProductRecord.category == category)
    if search:
        statement = statement.where(ProductRecord.name.ilike(f"%{search}%"))
    if min_price is not None:
        statement = statement.where(ProductRecord.price >= min_price)
    if max_price is not None:
        statement = statement.where(ProductRecord.price <= max_price)
    if sort == "price_asc":
        statement = statement.order_by(ProductRecord.price.asc())
    elif sort == "price_desc":
        statement = statement.order_by(ProductRecord.price.desc())
    elif sort == "featured":
        statement = statement.order_by(ProductRecord.is_featured.desc(), ProductRecord.id.desc())
    else:
        statement = statement.order_by(ProductRecord.id.desc())
    statement = statement.offset(skip).limit(limit)
    return list(db.scalars(statement))


@app.get("/api/products/{product_id}", response_model=ProductOut)
def get_product(product_id: int, db: Session = Depends(get_db)) -> ProductRecord:
    product = db.get(ProductRecord, product_id)
    if product is None:
        raise HTTPException(status_code=404, detail="Product not found")
    return product


@app.post("/api/admin/products", response_model=ProductOut, status_code=201)
def create_product(product: ProductIn, _: str = Depends(require_admin), db: Session = Depends(get_db)) -> ProductRecord:
    record = ProductRecord(**product.model_dump())
    db.add(record)
    db.commit()
    db.refresh(record)
    return record


@app.put("/api/admin/products/{product_id}", response_model=ProductOut)
def update_product(product_id: int, product: ProductIn, _: str = Depends(require_admin), db: Session = Depends(get_db)) -> ProductRecord:
    record = db.get(ProductRecord, product_id)
    if record is None:
        raise HTTPException(status_code=404, detail="Product not found")
    for key, value in product.model_dump().items():
        setattr(record, key, value)
    db.commit()
    db.refresh(record)
    return record


@app.delete("/api/admin/products/{product_id}")
def delete_product(product_id: int, _: str = Depends(require_admin), db: Session = Depends(get_db)) -> dict[str, bool]:
    record = db.get(ProductRecord, product_id)
    if record is None:
        raise HTTPException(status_code=404, detail="Product not found")
    db.delete(record)
    db.commit()
    return {"deleted": True}


@app.get("/api/admin/dashboard")
def admin_dashboard(_: str = Depends(require_admin), db: Session = Depends(get_db)) -> dict[str, int | str]:
    total_products = db.scalar(select(func.count(ProductRecord.id))) or 0
    low_stock = db.scalar(select(func.count(ProductRecord.id)).where(ProductRecord.stock <= 3)) or 0
    total_customers = db.scalar(select(func.count(UserRecord.id))) or 0
    total_orders = db.scalar(select(func.count(OrderRecord.id))) or 0
    pending_orders = db.scalar(select(func.count(OrderRecord.id)).where(OrderRecord.status.in_(["requested", "payment_pending"]))) or 0
    revenue = db.scalar(select(func.coalesce(func.sum(OrderRecord.total), 0)).where(OrderRecord.status == "paid")) or 0
    return {
        "total_products": int(total_products),
        "low_stock_products": int(low_stock),
        "total_customers": int(total_customers),
        "total_orders": int(total_orders),
        "pending_orders": int(pending_orders),
        "paid_revenue": str(revenue),
    }


@app.post("/api/orders", response_model=OrderOut, status_code=201)
def create_order(order: OrderIn, credentials: HTTPAuthorizationCredentials | None = Depends(optional_security), db: Session = Depends(get_db)) -> OrderRecord:
    product_ids = {item.product_id for item in order.items}
    products = {product.id: product for product in db.scalars(select(ProductRecord).where(ProductRecord.id.in_(product_ids)))}
    if len(products) != len(product_ids):
        raise HTTPException(status_code=400, detail="One or more products do not exist")

    identity = decode_token(credentials)
    customer_name = order.customer_name
    customer_email = order.customer_email
    customer_user_id = identity.get("user_id")
    if customer_user_id:
        user = db.get(UserRecord, customer_user_id)
        if user is not None:
            customer_name = user.name
            customer_email = user.email

    total = Decimal("0")
    order_record = OrderRecord(customer_user_id=customer_user_id, customer_name=customer_name, customer_email=customer_email, total=0)
    for item in order.items:
        product = products[item.product_id]
        if item.quantity > product.stock:
            raise HTTPException(status_code=409, detail=f"Not enough stock for {product.name}")
        product.stock -= item.quantity
        total += product.price * item.quantity
        order_record.items.append(OrderItemRecord(product_id=product.id, quantity=item.quantity, unit_price=product.price))
    order_record.total = total
    db.add(order_record)
    db.commit()
    db.refresh(order_record)
    send_order_confirmation(order_record, customer_email)
    return order_record


@app.get("/api/orders/{order_id}", response_model=OrderOut)
def get_order(order_id: int, credentials: HTTPAuthorizationCredentials = Depends(security), db: Session = Depends(get_db)) -> OrderRecord:
    order = db.get(OrderRecord, order_id)
    if order is None:
        raise HTTPException(status_code=404, detail="Order not found")
    if credentials is None:
        raise HTTPException(status_code=401, detail="Authentication required")
    identity = decode_token(credentials)
    if identity.get("role") != "admin" and order.customer_user_id != identity.get("user_id"):
        raise HTTPException(status_code=403, detail="You cannot access this order")
    return order


@app.get("/api/me/orders", response_model=list[OrderOut])
def customer_orders(user: UserRecord = Depends(require_customer), db: Session = Depends(get_db)) -> list[OrderRecord]:
    return list(db.scalars(select(OrderRecord).where(OrderRecord.customer_user_id == user.id).order_by(OrderRecord.created_at.desc())))


@app.post("/api/payments/create-session", response_model=PaymentOut)
def create_payment_session(payment: PaymentIn, db: Session = Depends(get_db)) -> PaymentOut:
    order = db.get(OrderRecord, payment.order_id)
    if order is None:
        raise HTTPException(status_code=404, detail="Order not found")
    if os.getenv("PAYMENT_MODE", "demo") != "stripe" or not os.getenv("STRIPE_SECRET_KEY"):
        order.status = "payment_pending"
        db.commit()
        demo_base_url = os.getenv("PUBLIC_API_URL", "http://127.0.0.1:8003")
        return PaymentOut(mode="demo", checkout_url=f"{demo_base_url}/api/payments/demo/{order.id}", reference=f"demo_{order.id}")
    stripe.api_key = os.environ["STRIPE_SECRET_KEY"]
    session = stripe.checkout.Session.create(
        mode="payment",
        line_items=[{"price_data": {"currency": "usd", "product_data": {"name": f"Aurelia order #{order.id}"}, "unit_amount": int(order.total * 100)}, "quantity": 1}],
        success_url=os.getenv("STRIPE_SUCCESS_URL", "http://localhost:5000/#/payment-success"),
        cancel_url=os.getenv("STRIPE_CANCEL_URL", "http://localhost:5000/#/payment-cancelled"),
        metadata={"order_id": str(order.id)},
    )
    order.status = "payment_pending"
    db.commit()
    return PaymentOut(mode="stripe", checkout_url=session.url, reference=session.id)


@app.get("/api/payments/demo/{order_id}", response_class=HTMLResponse)
def demo_payment_page(order_id: int, db: Session = Depends(get_db)) -> str:
    order = db.get(OrderRecord, order_id)
    if order is None:
        raise HTTPException(status_code=404, detail="Order not found")
    payload = f"upi://pay?pa=aurelia@upi&pn=Aurelia%20Jewellery&am={order.total}&cu=INR&tn=Order%20{order.id}"
    qr = qrcode.make(payload)
    buffer = io.BytesIO()
    qr.save(buffer, format="PNG")
    qr_image = base64.b64encode(buffer.getvalue()).decode("ascii")
    api_url = os.getenv("PUBLIC_API_URL", "http://127.0.0.1:8003")
    return f"""
    <!doctype html><html><head><meta name="viewport" content="width=device-width,initial-scale=1"><title>Aurelia Demo Payment</title>
    <style>body{{font-family:Georgia,serif;background:#f7f4f0;color:#272426;display:grid;place-items:center;min-height:100vh;margin:0;padding:20px}}main{{background:#fffaf7;padding:32px;max-width:430px;width:100%;border:1px solid #e4d6d1;border-radius:10px;text-align:center}}h1{{font-weight:500}}.eyebrow{{color:#9b4d5c;font-weight:bold;letter-spacing:2px;font-size:11px}}.amount{{font-size:30px;margin:18px}}.qr{{background:white;padding:12px;border:1px solid #e4d6d1;border-radius:6px;width:190px;height:190px}}.method{{border:1px solid #e4d6d1;padding:12px;border-radius:6px;margin:8px 0}}button{{background:#9b4d5c;color:white;border:0;padding:14px 18px;border-radius:5px;width:100%;font-weight:bold;cursor:pointer;margin-top:12px}}.muted{{color:#746b6d;font-size:13px;line-height:1.5}}#status{{margin-top:14px;color:#9b4d5c;font-weight:bold}}</style>
    </head><body><main><div class="eyebrow">AURELIA DEVELOPMENT CHECKOUT</div><h1>Complete your payment</h1><p class="muted">Safe local simulator. No real card or bank details are collected.</p><div class="amount">₹{order.total}</div><img class="qr" alt="Demo UPI QR code" src="data:image/png;base64,{qr_image}"><p class="muted">Scan with any UPI app or use the demo button below.</p><div class="method">UPI ID: <strong>aurelia@upi</strong></div><div class="method">Order reference: <strong>#{order.id}</strong></div><button onclick="completePayment()">I HAVE COMPLETED PAYMENT</button><div id="status"></div></main><script>async function completePayment(){{const status=document.getElementById('status');status.textContent='Confirming payment...';const response=await fetch('{api_url}/api/payments/demo/{order.id}/confirm',{{method:'POST'}});status.textContent=response.ok?'Payment confirmed. You may close this page.':'Could not confirm payment. Please try again.';}}</script></body></html>
    """


@app.post("/api/payments/demo/{order_id}/confirm", response_model=PaymentOut)
def confirm_demo_payment(order_id: int, db: Session = Depends(get_db)) -> PaymentOut:
    order = db.get(OrderRecord, order_id)
    if order is None:
        raise HTTPException(status_code=404, detail="Order not found")
    if order.status != "paid":
        order.status = "paid"
        db.commit()
        send_order_confirmation(order, order.customer_email)
    return PaymentOut(mode="demo", checkout_url=f"/api/payments/demo/{order.id}", reference=f"demo_{order.id}")
