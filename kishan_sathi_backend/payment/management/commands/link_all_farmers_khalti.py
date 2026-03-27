from django.core.management.base import BaseCommand
from django.db import transaction

from Users.models import User
from payment.models import BusinessKhaltiAccount


class Command(BaseCommand):
    help = 'Create or update active Khalti account links for all farmers (test-friendly).'

    def add_arguments(self, parser):
        parser.add_argument(
            '--prefix',
            default='980000',
            help='6-digit phone prefix for generated test Khalti IDs (default: 980000)',
        )
        parser.add_argument(
            '--dry-run',
            action='store_true',
            help='Preview changes without writing to database',
        )

    def _generated_khalti_id(self, prefix: str, farmer_id: int) -> str:
        # Ensures 10-digit Nepali-like number starting with 9.
        suffix = str(farmer_id % 10000).zfill(4)
        return f'{prefix}{suffix}'

    @transaction.atomic
    def handle(self, *args, **options):
        prefix = str(options['prefix']).strip()
        dry_run = bool(options['dry_run'])

        if len(prefix) != 6 or not prefix.isdigit() or not prefix.startswith('9'):
            self.stderr.write(self.style.ERROR('Prefix must be exactly 6 digits and start with 9.'))
            return

        farmers = User.objects.filter(role='farmer').order_by('id')

        if not farmers.exists():
            self.stdout.write(self.style.WARNING('No farmers found. Nothing to link.'))
            return

        created_count = 0
        updated_count = 0

        for farmer in farmers:
            generated_khalti_id = self._generated_khalti_id(prefix=prefix, farmer_id=farmer.id)
            account_name = (farmer.full_name or farmer.email or f'Farmer {farmer.id}').strip()

            account = BusinessKhaltiAccount.objects.filter(business=farmer).first()

            if account is None:
                if not dry_run:
                    BusinessKhaltiAccount.objects.create(
                        business=farmer,
                        khalti_id=generated_khalti_id,
                        account_name=account_name,
                        is_active=True,
                    )
                created_count += 1
                self.stdout.write(
                    self.style.SUCCESS(
                        f'Created Khalti link for farmer #{farmer.id} ({farmer.email}) -> {generated_khalti_id}'
                    )
                )
                continue

            should_update = (
                account.khalti_id != generated_khalti_id
                or account.account_name != account_name
                or not account.is_active
            )

            if should_update:
                if not dry_run:
                    account.khalti_id = generated_khalti_id
                    account.account_name = account_name
                    account.is_active = True
                    account.save(update_fields=['khalti_id', 'account_name', 'is_active', 'updated_at'])
                updated_count += 1
                self.stdout.write(
                    self.style.SUCCESS(
                        f'Updated Khalti link for farmer #{farmer.id} ({farmer.email}) -> {generated_khalti_id}'
                    )
                )
            else:
                self.stdout.write(
                    f'No change for farmer #{farmer.id} ({farmer.email}); already linked and active.'
                )

        if dry_run:
            transaction.set_rollback(True)
            self.stdout.write(self.style.WARNING('Dry-run mode enabled: all changes rolled back.'))

        self.stdout.write(
            self.style.SUCCESS(
                f'Completed. Farmers processed: {farmers.count()}, created: {created_count}, updated: {updated_count}.'
            )
        )
