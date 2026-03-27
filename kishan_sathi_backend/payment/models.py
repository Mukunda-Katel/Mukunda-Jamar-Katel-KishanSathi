from django.conf import settings
from django.db import models


class BusinessKhaltiAccount(models.Model):
	"""Store a seller-side Khalti account used for receiving payments."""

	business = models.OneToOneField(
		settings.AUTH_USER_MODEL,
		on_delete=models.CASCADE,
		related_name='khalti_account',
		limit_choices_to={'role': 'farmer'},
	)
	khalti_id = models.CharField(
		max_length=20,
		help_text='Business Khalti ID (phone number)',
	)
	account_name = models.CharField(
		max_length=255,
		help_text='Name on the Khalti account',
	)
	is_active = models.BooleanField(default=True)
	created_at = models.DateTimeField(auto_now_add=True)
	updated_at = models.DateTimeField(auto_now=True)

	class Meta:
		db_table = 'business_khalti_account'
		verbose_name = 'Business Khalti Account'
		verbose_name_plural = 'Business Khalti Accounts'

	def __str__(self):
		return f"{self.business.full_name} - Khalti: {self.khalti_id}"


class KhaltiPaymentRecord(models.Model):
	"""Record Khalti payment lifecycle and map it to internal references."""

	STATUS_CHOICES = [
		('initiated', 'Initiated'),
		('success', 'Success'),
		('failed', 'Failed'),
		('verified', 'Verified'),
	]

	buyer = models.ForeignKey(
		settings.AUTH_USER_MODEL,
		on_delete=models.CASCADE,
		related_name='khalti_payments',
		limit_choices_to={'role': 'buyer'},
	)
	cart = models.ForeignKey(
		'buyer.Cart',
		on_delete=models.SET_NULL,
		related_name='khalti_payments',
		null=True,
		blank=True,
		help_text='Related buyer cart at checkout time',
	)
	transaction_reference = models.CharField(
		max_length=255,
		blank=True,
		null=True,
		help_text='Internal transaction reference created after verification',
	)
	amount = models.DecimalField(max_digits=12, decimal_places=2)
	pidx = models.CharField(max_length=255, blank=True, null=True)
	khalti_transaction_id = models.CharField(max_length=255, blank=True, null=True)
	purchase_order_id = models.CharField(max_length=255)
	status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='initiated')
	khalti_response_data = models.JSONField(null=True, blank=True)
	created_at = models.DateTimeField(auto_now_add=True)
	updated_at = models.DateTimeField(auto_now=True)

	class Meta:
		db_table = 'khalti_payment_record'
		verbose_name = 'Khalti Payment Record'
		verbose_name_plural = 'Khalti Payment Records'
		ordering = ['-created_at']

	def __str__(self):
		return f"Khalti Payment #{self.id} - Rs.{self.amount} ({self.status})"
