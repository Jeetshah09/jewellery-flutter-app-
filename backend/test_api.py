import os
import unittest

from fastapi.testclient import TestClient

os.environ.setdefault("ADMIN_EMAIL", "admin@aurelia.test")
os.environ.setdefault("ADMIN_PASSWORD", "change-this-password")

from main import app  # noqa: E402


class ApiSmokeTests(unittest.TestCase):
    def setUp(self) -> None:
        self.client = TestClient(app)

    def test_health_and_catalogue_filters(self) -> None:
        self.assertEqual(self.client.get("/health").status_code, 200)
        response = self.client.get("/api/products", params={"category": "Rings", "limit": 2})
        self.assertEqual(response.status_code, 200)
        self.assertLessEqual(len(response.json()), 2)
        self.assertTrue(all(item["category"] == "Rings" for item in response.json()))

    def test_admin_login_and_dashboard(self) -> None:
        login = self.client.post(
            "/api/auth/login",
            json={"email": "admin@aurelia.test", "password": "change-this-password"},
        )
        self.assertEqual(login.status_code, 200)
        token = login.json()["access_token"]
        dashboard = self.client.get("/api/admin/dashboard", headers={"Authorization": f"Bearer {token}"})
        self.assertEqual(dashboard.status_code, 200)
        self.assertIn("total_products", dashboard.json())

    def test_private_order_requires_authentication(self) -> None:
        self.assertEqual(self.client.get("/api/orders/1").status_code, 401)


if __name__ == "__main__":
    unittest.main()
