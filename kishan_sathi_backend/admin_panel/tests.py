"""
Admin Panel API Tests

Run these tests to verify admin panel integration:
python manage.py test admin_panel
"""

from django.test import TestCase
from rest_framework.test import APIClient
from rest_framework import status
from Users.models import User
from farmer.models import Product, Category
from rest_framework.authtoken.models import Token


class AdminPanelTests(TestCase):
    """Test suite for admin panel APIs"""

    def setUp(self):
        """Set up test data"""
        # Create admin user
        self.admin_user = User.objects.create_user(
            email='admin@test.com',
            password='admin123',
            full_name='Admin User',
            role='admin'
        )
        self.admin_user.is_staff = True
        self.admin_user.save()

        # Create regular users
        self.farmer = User.objects.create_user(
            email='farmer@test.com',
            password='farmer123',
            full_name='Test Farmer',
            role='farmer'
        )

        self.buyer = User.objects.create_user(
            email='buyer@test.com',
            password='buyer123',
            full_name='Test Buyer',
            role='buyer'
        )

        self.doctor = User.objects.create_user(
            email='doctor@test.com',
            password='doctor123',
            full_name='Test Doctor',
            role='doctor',
            specialization='Agricultural Consultant',
            experience_years=5,
            license_number='DOC123',
            doctor_status='pending'
        )

        # Create category and product
        self.category = Category.objects.create(name='Test Category')
        self.product = Product.objects.create(
            name='Test Product',
            description='Test Description',
            price=100,
            quantity=10,
            farmer=self.farmer,
            category=self.category
        )

        # Get admin token
        self.token = Token.objects.create(user=self.admin_user)
        self.client = APIClient()
        self.client.credentials(HTTP_AUTHORIZATION=f'Token {self.token.key}')

    def test_admin_login(self):
        """Test admin can login"""
        client = APIClient()
        response = client.post('/api/auth/login/', {
            'email': 'admin@test.com',
            'password': 'admin123'
        })
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('token', response.data)
        self.assertEqual(response.data['user']['role'], 'admin')

    def test_dashboard_stats(self):
        """Test dashboard statistics endpoint"""
        response = self.client.get('/api/admin/stats/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        # Check stats structure
        self.assertIn('total_users', response.data)
        self.assertIn('total_farmers', response.data)
        self.assertIn('total_buyers', response.data)
        self.assertIn('pending_doctors', response.data)

    def test_list_users(self):
        """Test listing all users"""
        response = self.client.get('/api/admin/users/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)

    def test_toggle_user_status(self):
        """Test toggling user active status"""
        response = self.client.post(f'/api/admin/users/{self.farmer.id}/toggle_active/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)

    def test_approve_doctor(self):
        """Test approving a doctor"""
        response = self.client.post(f'/api/admin/doctors/{self.doctor.id}/approve/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)


# Run tests with:
# python manage.py test admin_panel.tests

