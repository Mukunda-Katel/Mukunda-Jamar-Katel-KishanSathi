from django.core.management.base import BaseCommand
from farmer.models import Category


class Command(BaseCommand):
    help = 'Create initial product categories'

    def handle(self, *args, **kwargs):
        categories = [
            {'name': 'Vegetables', 'description': 'Fresh vegetables and greens', 'icon': '🥬'},
            {'name': 'Fruits', 'description': 'Fresh seasonal fruits', 'icon': '🍎'},
            {'name': 'Grains', 'description': 'Rice, wheat, corn and other grains', 'icon': '🌾'},
            {'name': 'Pulses', 'description': 'Lentils, beans and legumes', 'icon': '🫘'},
            {'name': 'Dairy', 'description': 'Milk, cheese, yogurt and dairy products', 'icon': '🥛'},
            {'name': 'Poultry', 'description': 'Chicken, eggs and poultry products', 'icon': '🐔'},
            {'name': 'Spices', 'description': 'Herbs, spices and seasonings', 'icon': '🌶️'},
            {'name': 'Honey', 'description': 'Natural honey and bee products', 'icon': '🍯'},
            {'name': 'Organic Products', 'description': 'Certified organic produce', 'icon': '🌱'},
            {'name': 'Seeds', 'description': 'Seeds for planting', 'icon': '🌰'},
        ]

        created_count = 0
        for category_data in categories:
            category, created = Category.objects.get_or_create(
                name=category_data['name'],
                defaults={
                    'description': category_data['description'],
                    'icon': category_data['icon']
                }
            )
            if created:
                created_count += 1
                self.stdout.write(
                    self.style.SUCCESS(f'✓ Created category: {category.name}')
                )
            else:
                self.stdout.write(
                    self.style.WARNING(f'- Category already exists: {category.name}')
                )

        self.stdout.write(
            self.style.SUCCESS(f'\n Successfully created {created_count} categories')
        )
