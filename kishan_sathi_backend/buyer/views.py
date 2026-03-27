from decimal import Decimal
from django.db import transaction
from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.shortcuts import get_object_or_404
from .models import Cart, CartItem
from .serializers import CartSerializer, CartItemSerializer
from farmer.models import Product


class CartViewSet(viewsets.ViewSet):
    """
    ViewSet for cart operations
    """
    permission_classes = [IsAuthenticated]

    def list(self, request):
        """Get buyer's cart with all items"""
        cart, created = Cart.objects.get_or_create(buyer=request.user)
        serializer = CartSerializer(cart)
        return Response(serializer.data)

    @action(detail=False, methods=['post'])
    def add_item(self, request):
        """Add item to cart or update quantity if already exists"""
        product_id = request.data.get('product_id')
        quantity = request.data.get('quantity', 1)

        if not product_id:
            return Response(
                {'error': 'product_id is required'},
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            product = Product.objects.get(id=product_id)
        except Product.DoesNotExist:
            return Response(
                {'error': 'Product not found'},
                status=status.HTTP_404_NOT_FOUND
            )

        # Check if product is available
        if product.status != 'available':
            return Response(
                {'error': 'Product is not available'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Check stock availability
        if Decimal(str(quantity)) > Decimal(str(product.quantity)):
            return Response(
                {'error': f'Only {product.quantity} {product.unit} available in stock'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Get or create cart
        cart, created = Cart.objects.get_or_create(buyer=request.user)

        # Check if item already in cart
        cart_item, item_created = CartItem.objects.get_or_create(
            cart=cart,
            product=product,
            defaults={'quantity': quantity}
        )

        if not item_created:
            # Item already exists, update quantity
            new_quantity = Decimal(str(cart_item.quantity)) + Decimal(str(quantity))
            if new_quantity > Decimal(str(product.quantity)):
                return Response(
                    {'error': f'Cannot add more. Only {product.quantity} {product.unit} available'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            cart_item.quantity = new_quantity
            cart_item.save()

        serializer = CartItemSerializer(cart_item)
        return Response(
            {
                'message': 'Item added to cart successfully',
                'item': serializer.data
            },
            status=status.HTTP_201_CREATED if item_created else status.HTTP_200_OK
        )

    @action(detail=False, methods=['put'], url_path='update_item/(?P<item_id>[^/.]+)')
    def update_item(self, request, item_id=None):
        """Update quantity of cart item"""
        quantity = request.data.get('quantity')

        if quantity is None:
            return Response(
                {'error': 'quantity is required'},
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            cart = Cart.objects.get(buyer=request.user)
            cart_item = CartItem.objects.get(id=item_id, cart=cart)
        except (Cart.DoesNotExist, CartItem.DoesNotExist):
            return Response(
                {'error': 'Cart item not found'},
                status=status.HTTP_404_NOT_FOUND
            )

        # Validate quantity
        if Decimal(str(quantity)) <= 0:
            return Response(
                {'error': 'Quantity must be greater than 0'},
                status=status.HTTP_400_BAD_REQUEST
            )

        if Decimal(str(quantity)) > Decimal(str(cart_item.product.quantity)):
            return Response(
                {'error': f'Only {cart_item.product.quantity} {cart_item.product.unit} available'},
                status=status.HTTP_400_BAD_REQUEST
            )

        cart_item.quantity = quantity
        cart_item.save()

        serializer = CartItemSerializer(cart_item)
        return Response({
            'message': 'Cart item updated successfully',
            'item': serializer.data
        })

    @action(detail=False, methods=['delete'], url_path='remove_item/(?P<item_id>[^/.]+)')
    def remove_item(self, request, item_id=None):
        """Remove item from cart"""
        try:
            cart = Cart.objects.get(buyer=request.user)
            cart_item = CartItem.objects.get(id=item_id, cart=cart)
            cart_item.delete()
            return Response(
                {'message': 'Item removed from cart'},
                status=status.HTTP_200_OK
            )
        except (Cart.DoesNotExist, CartItem.DoesNotExist):
            return Response(
                {'error': 'Cart item not found'},
                status=status.HTTP_404_NOT_FOUND
            )

    @action(detail=False, methods=['delete'])
    def clear(self, request):
        """Clear all items from cart"""
        try:
            cart = Cart.objects.get(buyer=request.user)
            cart.items.all().delete()
            return Response(
                {'message': 'Cart cleared successfully'},
                status=status.HTTP_200_OK
            )
        except Cart.DoesNotExist:
            return Response(
                {'message': 'Cart is already empty'},
                status=status.HTTP_200_OK
            )

    @action(detail=False, methods=['get'])
    def count(self, request):
        """Get total number of items in cart"""
        try:
            cart = Cart.objects.get(buyer=request.user)
            return Response({
                'count': cart.total_items,
                'total_price': cart.total_price
            })
        except Cart.DoesNotExist:
            return Response({
                'count': 0,
                'total_price': 0
            })

    @action(detail=False, methods=['post'])
    def complete_purchase(self, request):
        """Finalize checkout: decrement stock for all cart items, then clear cart."""
        try:
            cart = Cart.objects.get(buyer=request.user)
        except Cart.DoesNotExist:
            return Response(
                {'error': 'Cart not found'},
                status=status.HTTP_404_NOT_FOUND,
            )

        cart_items = list(cart.items.select_related('product').all())
        if not cart_items:
            return Response(
                {'error': 'Cart is empty'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        with transaction.atomic():
            for item in cart_items:
                product = Product.objects.select_for_update().get(id=item.product_id)

                if product.status != 'available':
                    return Response(
                        {'error': f'{product.name} is not available'},
                        status=status.HTTP_400_BAD_REQUEST,
                    )

                if Decimal(str(item.quantity)) > Decimal(str(product.quantity)):
                    return Response(
                        {
                            'error': (
                                f'Only {product.quantity} {product.unit} available for {product.name}'
                            )
                        },
                        status=status.HTTP_400_BAD_REQUEST,
                    )

                product.quantity = Decimal(str(product.quantity)) - Decimal(str(item.quantity))
                if product.quantity <= 0:
                    product.quantity = Decimal('0')
                    product.status = 'sold_out'
                product.save(update_fields=['quantity', 'status', 'updated_at'])

            cart.items.all().delete()

        return Response(
            {'message': 'Purchase completed successfully'},
            status=status.HTTP_200_OK,
        )

