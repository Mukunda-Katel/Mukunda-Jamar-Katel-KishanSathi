import json
import logging
import uuid
from decimal import Decimal

import requests
from django.conf import settings
from django.db import transaction as db_transaction
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from buyer.models import Cart

from .models import BusinessKhaltiAccount, KhaltiPaymentRecord
from .serializers import (
	BusinessKhaltiAccountSerializer,
	BusinessKhaltiStatusSerializer,
	CreateBusinessKhaltiAccountSerializer,
	InitiateKhaltiPaymentSerializer,
	KhaltiPaymentRecordSerializer,
	VerifyKhaltiPaymentSerializer,
)

logger = logging.getLogger(__name__)


class KhaltiGatewayResponseError(Exception):
	def __init__(self, message: str, response_text: str = '', status_code: int = 502):
		super().__init__(message)
		self.response_text = response_text
		self.status_code = status_code


def _khalti_secret_key() -> str:
	return getattr(settings, 'KHALTI_SECRET_KEY', '').strip()


def _khalti_public_key() -> str:
	return getattr(settings, 'KHALTI_PUBLIC_KEY', '').strip()


def _khalti_base_url() -> str:
	return getattr(settings, 'KHALTI_BASE_URL', 'https://khalti.com').strip().rstrip('/')


def _is_test_gateway() -> bool:
	base_url = _khalti_base_url().lower()
	return 'dev.khalti.com' in base_url


def _resolve_website_url() -> str:
	return getattr(settings, 'KHALTI_WEBSITE_URL', 'https://example.com').strip() or 'https://example.com'


def _resolve_return_url() -> str:
	explicit = getattr(settings, 'KHALTI_RETURN_URL', '').strip()
	if explicit:
		return explicit
	return _resolve_website_url()


def _validate_khalti_config():
	secret_key = _khalti_secret_key()
	if not secret_key:
		return False, 'Khalti secret key is not configured on the server'
	return True, ''


def _sanitize_customer_phone(raw_phone):
	cleaned = ''.join(ch for ch in str(raw_phone or '') if ch.isdigit())
	if len(cleaned) == 10 and cleaned.startswith('9'):
		return cleaned
	return '9800000001'


def _post_json(url, payload, headers):
	response = requests.post(url, json=payload, headers=headers, timeout=20)
	response.raise_for_status()
	if not response.text:
		return {}
	try:
		return response.json()
	except ValueError as exc:
		raise KhaltiGatewayResponseError(
			'Khalti gateway returned a non-JSON response',
			response_text=(response.text or '')[:400],
			status_code=response.status_code,
		) from exc


def _extract_http_error_details(exc):
	response_body = ''
	parsed_body = {}
	message = 'Khalti request failed'
	status_code = 502

	response = getattr(exc, 'response', None)
	if response is not None:
		status_code = response.status_code
		response_body = response.text or ''
		try:
			parsed_body = response.json() if response_body else {}
		except ValueError:
			parsed_body = {}
	else:
		response_body = str(exc)

	if response_body and not parsed_body:
		try:
			parsed_body = json.loads(response_body)
		except Exception:
			parsed_body = {'raw': response_body}

	if parsed_body:
		message = (
			parsed_body.get('detail')
			or parsed_body.get('message')
			or parsed_body.get('error_key')
			or message
		)
	elif response_body:
		message = response_body

	return {
		'status': status_code,
		'message': message,
		'payload': parsed_body or {'raw': response_body or str(exc)},
	}


class BusinessKhaltiAccountView(APIView):
	permission_classes = [IsAuthenticated]

	def get(self, request):
		if request.user.role != 'farmer':
			return Response(
				{'status': 403, 'message': 'Only farmers can access Khalti business account', 'data': None},
				status=status.HTTP_403_FORBIDDEN,
			)

		try:
			account = BusinessKhaltiAccount.objects.get(business=request.user)
			serializer = BusinessKhaltiAccountSerializer(account)
			return Response(
				{'status': 200, 'message': 'Khalti account retrieved successfully', 'data': serializer.data},
				status=status.HTTP_200_OK,
			)
		except BusinessKhaltiAccount.DoesNotExist:
			return Response(
				{'status': 200, 'message': 'No Khalti account linked', 'data': None},
				status=status.HTTP_200_OK,
			)

	def post(self, request):
		if request.user.role != 'farmer':
			return Response(
				{'status': 403, 'message': 'Only farmers can link Khalti account', 'data': None},
				status=status.HTTP_403_FORBIDDEN,
			)

		if BusinessKhaltiAccount.objects.filter(business=request.user).exists():
			return Response(
				{
					'status': 400,
					'message': 'Khalti account already linked. Use PATCH to update.',
					'data': None,
				},
				status=status.HTTP_400_BAD_REQUEST,
			)

		serializer = CreateBusinessKhaltiAccountSerializer(data=request.data)
		serializer.is_valid(raise_exception=True)

		account = BusinessKhaltiAccount.objects.create(
			business=request.user,
			khalti_id=serializer.validated_data['khalti_id'],
			account_name=serializer.validated_data['account_name'],
		)

		return Response(
			{
				'status': 201,
				'message': 'Khalti account linked successfully',
				'data': BusinessKhaltiAccountSerializer(account).data,
			},
			status=status.HTTP_201_CREATED,
		)

	def patch(self, request):
		if request.user.role != 'farmer':
			return Response(
				{'status': 403, 'message': 'Only farmers can update Khalti account', 'data': None},
				status=status.HTTP_403_FORBIDDEN,
			)

		try:
			account = BusinessKhaltiAccount.objects.get(business=request.user)
		except BusinessKhaltiAccount.DoesNotExist:
			return Response(
				{'status': 404, 'message': 'No Khalti account linked', 'data': None},
				status=status.HTTP_404_NOT_FOUND,
			)

		serializer = CreateBusinessKhaltiAccountSerializer(data=request.data, partial=True)
		serializer.is_valid(raise_exception=True)

		if 'khalti_id' in serializer.validated_data:
			account.khalti_id = serializer.validated_data['khalti_id']
		if 'account_name' in serializer.validated_data:
			account.account_name = serializer.validated_data['account_name']
		account.save()

		return Response(
			{
				'status': 200,
				'message': 'Khalti account updated successfully',
				'data': BusinessKhaltiAccountSerializer(account).data,
			},
			status=status.HTTP_200_OK,
		)

	def delete(self, request):
		if request.user.role != 'farmer':
			return Response(
				{'status': 403, 'message': 'Only farmers can unlink Khalti account', 'data': None},
				status=status.HTTP_403_FORBIDDEN,
			)

		try:
			account = BusinessKhaltiAccount.objects.get(business=request.user)
			account.delete()
			return Response(
				{'status': 200, 'message': 'Khalti account unlinked successfully', 'data': None},
				status=status.HTTP_200_OK,
			)
		except BusinessKhaltiAccount.DoesNotExist:
			return Response(
				{'status': 404, 'message': 'No Khalti account linked', 'data': None},
				status=status.HTTP_404_NOT_FOUND,
			)


class CheckBusinessKhaltiStatusView(APIView):
	permission_classes = [IsAuthenticated]

	def get(self, request, relationship_id):
		# In this codebase, relationship_id maps to cart_id for compatibility.
		try:
			cart = Cart.objects.get(id=relationship_id)
		except Cart.DoesNotExist:
			return Response(
				{'status': 404, 'message': 'Cart not found', 'data': None},
				status=status.HTTP_404_NOT_FOUND,
			)

		if request.user.role != 'buyer' or cart.buyer_id != request.user.id:
			return Response(
				{'status': 403, 'message': 'Access denied', 'data': None},
				status=status.HTTP_403_FORBIDDEN,
			)

		farmer_ids = list(cart.items.values_list('product__farmer_id', flat=True).distinct())
		if not farmer_ids:
			return Response(
				{'status': 400, 'message': 'Cart is empty', 'data': None},
				status=status.HTTP_400_BAD_REQUEST,
			)
		if len(farmer_ids) != 1:
			return Response(
				{
					'status': 400,
					'message': 'Cart contains products from multiple farmers. Split payment per farmer.',
					'data': None,
				},
				status=status.HTTP_400_BAD_REQUEST,
			)

		try:
			account = BusinessKhaltiAccount.objects.get(business_id=farmer_ids[0], is_active=True)
			data = {
				'has_khalti': True,
				'khalti_id': account.khalti_id,
				'account_name': account.account_name,
				'is_active': account.is_active,
			}
		except BusinessKhaltiAccount.DoesNotExist:
			data = {
				'has_khalti': False,
				'khalti_id': None,
				'account_name': None,
				'is_active': False,
			}

		return Response(
			{'status': 200, 'message': 'Khalti status retrieved', 'data': BusinessKhaltiStatusSerializer(data).data},
			status=status.HTTP_200_OK,
		)


class InitiateKhaltiPaymentView(APIView):
	permission_classes = [IsAuthenticated]

	def post(self, request):
		serializer = InitiateKhaltiPaymentSerializer(data=request.data)
		serializer.is_valid(raise_exception=True)
		data = serializer.validated_data

		if request.user.role != 'buyer':
			return Response(
				{'status': 403, 'message': 'Only buyers can initiate Khalti payments', 'data': None},
				status=status.HTTP_403_FORBIDDEN,
			)

		try:
			cart = Cart.objects.get(id=data['cart_id'], buyer=request.user)
		except Cart.DoesNotExist:
			return Response(
				{'status': 404, 'message': 'Cart not found', 'data': None},
				status=status.HTTP_404_NOT_FOUND,
			)

		if not cart.items.exists():
			return Response(
				{'status': 400, 'message': 'Cart is empty', 'data': None},
				status=status.HTTP_400_BAD_REQUEST,
			)

		farmer_ids = list(cart.items.values_list('product__farmer_id', flat=True).distinct())
		if len(farmer_ids) != 1:
			return Response(
				{
					'status': 400,
					'message': 'Cart contains products from multiple farmers. Split payment per farmer.',
					'data': None,
				},
				status=status.HTTP_400_BAD_REQUEST,
			)

		try:
			business_account = BusinessKhaltiAccount.objects.get(business_id=farmer_ids[0], is_active=True)
		except BusinessKhaltiAccount.DoesNotExist:
			return Response(
				{'status': 400, 'message': 'This farmer has not linked a Khalti account', 'data': None},
				status=status.HTTP_400_BAD_REQUEST,
			)

		is_config_valid, config_error = _validate_khalti_config()
		if not is_config_valid:
			return Response(
				{'status': 500, 'message': config_error, 'data': None},
				status=status.HTTP_500_INTERNAL_SERVER_ERROR,
			)

		secret_key = _khalti_secret_key()
		public_key = _khalti_public_key()

		purchase_order_id = f'KS-KHALTI-{cart.id}-{uuid.uuid4().hex[:10]}'
		amount = data['amount']
		payment_record = KhaltiPaymentRecord.objects.create(
			buyer=request.user,
			cart=cart,
			amount=amount,
			purchase_order_id=purchase_order_id,
			status='initiated',
		)

		amount_paisa = int((Decimal(amount) * Decimal('100')).quantize(Decimal('1')))
		payload = {
			'return_url': _resolve_return_url(),
			'website_url': _resolve_website_url(),
			'amount': amount_paisa,
			'purchase_order_id': purchase_order_id,
			'purchase_order_name': (data.get('description') or f'Payment to {business_account.business.full_name}')[:100],
			'customer_info': {
				'name': (request.user.full_name or 'Customer').strip(),
				'email': (request.user.email or 'customer@example.com').strip(),
				'phone': _sanitize_customer_phone(request.user.phone_number),
			},
		}
		headers = {
			'Authorization': f'Key {secret_key}',
			'Content-Type': 'application/json',
		}

		try:
			khalti_response = _post_json(
				f'{_khalti_base_url()}/api/v2/epayment/initiate/',
				payload,
				headers,
			)
		except KhaltiGatewayResponseError as exc:
			payment_record.status = 'failed'
			payment_record.khalti_response_data = {
				'error': str(exc),
				'phase': 'initiate',
				'http_status': exc.status_code,
				'gateway_preview': exc.response_text,
				'request_payload': payload,
				'base_url': _khalti_base_url(),
			}
			payment_record.save()
			return Response(
				{
					'status': 502,
					'message': (
						'Khalti gateway returned an unexpected response. '
						'For test accounts, set KHALTI_BASE_URL=https://dev.khalti.com '
						'and use test keys on backend/frontend.'
					),
					'data': None,
				},
				status=status.HTTP_502_BAD_GATEWAY,
			)
		except requests.HTTPError as exc:
			details = _extract_http_error_details(exc)
			payment_record.status = 'failed'
			payment_record.khalti_response_data = {
				'error': details['message'],
				'http_status': details['status'],
				'khalti_payload': details['payload'],
				'phase': 'initiate',
				'request_payload': payload,
			}
			payment_record.save()
			return Response(
				{
					'status': details['status'],
					'message': f"Khalti initiate failed: {details['message']}",
					'data': None,
				},
				status=details['status'] if 400 <= details['status'] < 600 else status.HTTP_502_BAD_GATEWAY,
			)
		except (requests.Timeout, requests.ConnectionError, requests.RequestException) as exc:
			logger.error('Khalti initiate network failure: %s', exc)
			payment_record.status = 'failed'
			payment_record.khalti_response_data = {
				'error': str(exc),
				'phase': 'initiate',
				'request_payload': payload,
			}
			payment_record.save()
			return Response(
				{
					'status': 502,
					'message': 'Unable to reach Khalti gateway. Please try again.',
					'data': None,
				},
				status=status.HTTP_502_BAD_GATEWAY,
			)

		pidx = khalti_response.get('pidx')
		if not pidx:
			payment_record.status = 'failed'
			payment_record.khalti_response_data = khalti_response
			payment_record.save()
			return Response(
				{'status': 400, 'message': 'Khalti did not return a payment identifier', 'data': None},
				status=status.HTTP_400_BAD_REQUEST,
			)

		payment_record.pidx = pidx
		payment_record.khalti_response_data = khalti_response
		payment_record.save()

		return Response(
			{
				'status': 201,
				'message': 'Khalti payment initiated',
				'data': {
					'payment_record_id': payment_record.id,
					'pidx': pidx,
					'public_key': public_key,
					'is_test_environment': _is_test_gateway(),
					'amount': str(amount),
					'purchase_order_id': purchase_order_id,
					'purchase_order_name': payload['purchase_order_name'],
				},
			},
			status=status.HTTP_201_CREATED,
		)


class VerifyKhaltiPaymentView(APIView):
	permission_classes = [IsAuthenticated]

	def post(self, request):
		serializer = VerifyKhaltiPaymentSerializer(data=request.data)
		serializer.is_valid(raise_exception=True)
		data = serializer.validated_data

		try:
			with db_transaction.atomic():
				payment_record = KhaltiPaymentRecord.objects.select_for_update().get(
					id=data['payment_record_id']
				)

				if payment_record.status in ['verified', 'success']:
					return Response(
						{
							'status': 200,
							'message': 'Payment already verified',
							'data': KhaltiPaymentRecordSerializer(payment_record).data,
						},
						status=status.HTTP_200_OK,
					)

			if request.user.role != 'buyer' or payment_record.buyer_id != request.user.id:
				return Response(
					{'status': 403, 'message': 'Access denied', 'data': None},
					status=status.HTTP_403_FORBIDDEN,
				)

			secret_key = _khalti_secret_key()
			lookup_status = ''
			lookup_payload = {}

			if secret_key:
				headers = {
					'Authorization': f'Key {secret_key}',
					'Content-Type': 'application/json',
				}
				try:
					lookup_payload = _post_json(
						f'{_khalti_base_url()}/api/v2/epayment/lookup/',
						{'pidx': data['pidx']},
						headers,
					)
					lookup_status = str(lookup_payload.get('status', '')).lower()
				except Exception as exc:  # noqa: BLE001
					logger.error('Khalti lookup failed: %s', exc)
					lookup_payload = {'error': str(exc)}

			client_status = str(data.get('status', '')).lower()
			is_success = lookup_status == 'completed' or client_status in ['completed', 'complete', 'success']

			if is_success:
				with db_transaction.atomic():
					payment_record = KhaltiPaymentRecord.objects.select_for_update().get(id=payment_record.id)

					payment_record.pidx = data['pidx']
					payment_record.khalti_transaction_id = data.get('transaction_id') or lookup_payload.get(
						'transaction_id', ''
					)
					payment_record.status = 'verified'
					payment_record.khalti_response_data = {
						'client_response': data.get('khalti_response', {}),
						'lookup_response': lookup_payload,
					}
					payment_record.save()

				return Response(
					{
						'status': 200,
						'message': 'Payment verified successfully',
						'data': KhaltiPaymentRecordSerializer(payment_record).data,
					},
					status=status.HTTP_200_OK,
				)

			payment_record.status = 'failed'
			payment_record.khalti_response_data = {
				'client_response': data.get('khalti_response', {}),
				'lookup_response': lookup_payload,
			}
			payment_record.save()
			return Response(
				{
					'status': 400,
					'message': 'Khalti payment verification failed',
					'data': KhaltiPaymentRecordSerializer(payment_record).data,
				},
				status=status.HTTP_400_BAD_REQUEST,
			)

		except KhaltiPaymentRecord.DoesNotExist:
			return Response(
				{'status': 404, 'message': 'Payment record not found', 'data': None},
				status=status.HTTP_404_NOT_FOUND,
			)
