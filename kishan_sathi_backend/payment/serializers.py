from rest_framework import serializers

from .models import BusinessKhaltiAccount, KhaltiPaymentRecord


class BusinessKhaltiAccountSerializer(serializers.ModelSerializer):
	business_name = serializers.CharField(source='business.full_name', read_only=True)

	class Meta:
		model = BusinessKhaltiAccount
		fields = [
			'id',
			'khalti_id',
			'account_name',
			'is_active',
			'business_name',
			'created_at',
			'updated_at',
		]
		read_only_fields = ['id', 'business_name', 'created_at', 'updated_at']


class CreateBusinessKhaltiAccountSerializer(serializers.Serializer):
	khalti_id = serializers.CharField(max_length=20)
	account_name = serializers.CharField(max_length=255)

	def validate_khalti_id(self, value):
		cleaned = value.replace(' ', '').replace('-', '')
		if not cleaned.startswith('9'):
			raise serializers.ValidationError(
				'Khalti ID should be a valid Nepali phone number starting with 9'
			)
		if len(cleaned) != 10 or not cleaned.isdigit():
			raise serializers.ValidationError('Khalti ID should be a 10-digit phone number')
		return cleaned


class InitiateKhaltiPaymentSerializer(serializers.Serializer):
	# Keep compatibility with your reference payload while mapping to current project model.
	relationship_id = serializers.IntegerField(required=False)
	cart_id = serializers.IntegerField(required=False)
	amount = serializers.DecimalField(max_digits=12, decimal_places=2)
	description = serializers.CharField(max_length=255, required=False, allow_blank=True)

	def validate_amount(self, value):
		if value <= 0:
			raise serializers.ValidationError('Amount must be greater than 0')
		return value

	def validate(self, attrs):
		relationship_id = attrs.get('relationship_id')
		cart_id = attrs.get('cart_id')

		if relationship_id is None and cart_id is None:
			raise serializers.ValidationError('Either relationship_id or cart_id is required')

		# Map reference field to current project field.
		if cart_id is None:
			attrs['cart_id'] = relationship_id

		return attrs


class VerifyKhaltiPaymentSerializer(serializers.Serializer):
	payment_record_id = serializers.IntegerField()
	pidx = serializers.CharField(max_length=255)
	transaction_id = serializers.CharField(max_length=255, required=False, allow_blank=True)
	status = serializers.CharField(max_length=40, required=False, allow_blank=True)
	total_amount = serializers.CharField(max_length=50, required=False, allow_blank=True)
	khalti_response = serializers.DictField(required=False)


class KhaltiPaymentRecordSerializer(serializers.ModelSerializer):
	relationship_id = serializers.IntegerField(source='cart_id', read_only=True)

	class Meta:
		model = KhaltiPaymentRecord
		fields = [
			'id',
			'buyer',
			'cart',
			'relationship_id',
			'amount',
			'pidx',
			'khalti_transaction_id',
			'purchase_order_id',
			'status',
			'created_at',
			'updated_at',
		]
		read_only_fields = ['id', 'created_at', 'updated_at']


class BusinessKhaltiStatusSerializer(serializers.Serializer):
	has_khalti = serializers.BooleanField()
	khalti_id = serializers.CharField(allow_null=True, required=False)
	account_name = serializers.CharField(allow_null=True, required=False)
	is_active = serializers.BooleanField(default=False)
