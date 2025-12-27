from rest_framework import serializers
from .models import Category, Product, ProductImage
from Users.models import User


class CategorySerializer(serializers.ModelSerializer):
    product_count = serializers.IntegerField(source='products.count', read_only=True)
    
    class Meta:
        model = Category
        fields = ['id', 'name', 'description', 'icon', 'product_count', 'created_at']
        read_only_fields = ['created_at']


class ProductImageSerializer(serializers.ModelSerializer):
    class Meta:
        model = ProductImage
        fields = ['id', 'image', 'caption', 'uploaded_at']
        read_only_fields = ['uploaded_at']


class FarmerBasicSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'full_name', 'phone_number', 'email']


class ProductListSerializer(serializers.ModelSerializer):
    category_name = serializers.CharField(source='category.name', read_only=True)
    farmer_name = serializers.CharField(source='farmer.full_name', read_only=True)
    farmer_id = serializers.IntegerField(source='farmer.id', read_only=True)
    unit_display = serializers.CharField(source='get_unit_display', read_only=True)
    status_display = serializers.CharField(source='get_status_display', read_only=True)
    
    class Meta:
        model = Product
        fields = [
            'id', 'name', 'description', 'price', 'quantity', 'unit', 'unit_display',
            'status', 'status_display', 'is_organic', 'location', 'district',
            'image', 'category_name', 'farmer_name', 'farmer_id', 'created_at', 'is_available'
        ]


class ProductDetailSerializer(serializers.ModelSerializer):
    category = CategorySerializer(read_only=True)
    category_id = serializers.PrimaryKeyRelatedField(
        queryset=Category.objects.all(),
        source='category',
        write_only=True,
        required=False
    )
    farmer = FarmerBasicSerializer(read_only=True)
    additional_images = ProductImageSerializer(many=True, read_only=True)
    unit_display = serializers.CharField(source='get_unit_display', read_only=True)
    status_display = serializers.CharField(source='get_status_display', read_only=True)
    
    class Meta:
        model = Product
        fields = [
            'id', 'farmer', 'category', 'category_id', 'name', 'description',
            'price', 'quantity', 'unit', 'unit_display', 'status', 'status_display',
            'is_organic', 'harvest_date', 'location', 'district',
            'image', 'additional_images', 'is_active', 'views_count',
            'created_at', 'updated_at', 'is_available'
        ]
        read_only_fields = ['farmer', 'views_count', 'created_at', 'updated_at']
    
    def create(self, validated_data):
        # Set farmer from request user
        validated_data['farmer'] = self.context['request'].user
        return super().create(validated_data)


class ProductCreateUpdateSerializer(serializers.ModelSerializer):
    
    
    class Meta:
        model = Product
        fields = [
            'category', 'name', 'description', 'price', 'quantity', 'unit',
            'status', 'is_organic', 'harvest_date', 'location', 'district', 'image'
        ]
    
    def validate_price(self, value):
        if value <= 0:
            raise serializers.ValidationError("Price must be greater than 0")
        return value
    
    def validate_quantity(self, value):
        if value < 0:
            raise serializers.ValidationError("Quantity cannot be negative")
        return value
    
    def validate(self, data):
        # Ensure farmer is set from request
        request = self.context.get('request')
        if request and request.user:
            if request.user.role != 'farmer':
                raise serializers.ValidationError("Only farmers can create products")
        return data
    
    def create(self, validated_data):
        validated_data['farmer'] = self.context['request'].user
        return super().create(validated_data)
