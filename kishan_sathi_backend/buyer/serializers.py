from rest_framework import serializers
from .models import Cart, CartItem
from farmer.serializers import ProductListSerializer


class CartItemSerializer(serializers.ModelSerializer):
    """Serializer for cart items with product details"""
    product = ProductListSerializer(read_only=True)
    product_id = serializers.IntegerField(write_only=True)
    subtotal = serializers.DecimalField(max_digits=12, decimal_places=2, read_only=True)

    class Meta:
        model = CartItem
        fields = [
            'id',
            'product',
            'product_id',
            'quantity',
            'subtotal',
            'added_at',
            'updated_at'
        ]
        read_only_fields = ['id', 'added_at', 'updated_at']

    def validate_quantity(self, value):
        """Ensure quantity is positive"""
        if value <= 0:
            raise serializers.ValidationError("Quantity must be greater than 0")
        return value

    def validate(self, data):
        """Validate product availability and stock"""
        product_id = data.get('product_id')
        quantity = data.get('quantity')

        if product_id and quantity:
            from farmer.models import Product
            try:
                product = Product.objects.get(id=product_id)
                if product.status != 'available':
                    raise serializers.ValidationError(
                        {"product": "This product is not available"}
                    )
                if quantity > product.quantity:
                    raise serializers.ValidationError(
                        {"quantity": f"Only {product.quantity} {product.unit} available in stock"}
                    )
            except Product.DoesNotExist:
                raise serializers.ValidationError(
                    {"product": "Product not found"}
                )
        
        return data


class CartSerializer(serializers.ModelSerializer):
    """Serializer for shopping cart with all items"""
    items = CartItemSerializer(many=True, read_only=True)
    total_items = serializers.IntegerField(read_only=True)
    total_price = serializers.DecimalField(max_digits=12, decimal_places=2, read_only=True)

    class Meta:
        model = Cart
        fields = [
            'id',
            'buyer',
            'items',
            'total_items',
            'total_price',
            'created_at',
            'updated_at'
        ]
        read_only_fields = ['id', 'buyer', 'created_at', 'updated_at']
