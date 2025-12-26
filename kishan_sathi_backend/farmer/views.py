from rest_framework import viewsets, status, filters
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, AllowAny
from django_filters.rest_framework import DjangoFilterBackend
from django.db.models import Q
from .models import Category, Product, ProductImage
from .serializers import (
    CategorySerializer,
    ProductListSerializer,
    ProductDetailSerializer,
    ProductCreateUpdateSerializer,
    ProductImageSerializer
)


class IsFarmer(IsAuthenticated):
    """Custom permission to only allow farmers"""
    def has_permission(self, request, view):
        return super().has_permission(request, view) and request.user.role == 'farmer'


class CategoryViewSet(viewsets.ReadOnlyModelViewSet):
    """
    ViewSet for viewing categories.
    Anyone can view categories.
    """
    queryset = Category.objects.all()
    serializer_class = CategorySerializer
    permission_classes = [AllowAny]
    filter_backends = [filters.SearchFilter]
    search_fields = ['name', 'description']


class ProductViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing products.
    - List/Retrieve: Anyone can view
    - Create/Update/Delete: Only farmers who own the product
    """
    queryset = Product.objects.select_related('farmer', 'category').prefetch_related('additional_images')
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['category', 'status', 'is_organic', 'farmer']
    search_fields = ['name', 'description', 'location', 'district']
    ordering_fields = ['price', 'created_at', 'quantity']
    ordering = ['-created_at']
    
    def get_serializer_class(self):
        if self.action == 'list':
            return ProductListSerializer
        elif self.action in ['create', 'update', 'partial_update']:
            return ProductCreateUpdateSerializer
        return ProductDetailSerializer
    
    def get_permissions(self):
        if self.action in ['create']:
            return [IsFarmer()]
        elif self.action in ['update', 'partial_update', 'destroy']:
            return [IsAuthenticated()]
        return [AllowAny()]
    
    def get_queryset(self):
        queryset = super().get_queryset()
        
        # Filter by farmer's own products if requested
        if self.request.query_params.get('my_products') == 'true':
            if self.request.user.is_authenticated:
                queryset = queryset.filter(farmer=self.request.user)
        
        # Filter by availability
        if self.request.query_params.get('available_only') == 'true':
            queryset = queryset.filter(status='available', is_active=True, quantity__gt=0)
        
        # Filter by location
        location = self.request.query_params.get('location')
        if location:
            queryset = queryset.filter(
                Q(location__icontains=location) | Q(district__icontains=location)
            )
        
        return queryset
    
    def perform_create(self, serializer):
        serializer.save(farmer=self.request.user)
    
    def create(self, request, *args, **kwargs):
        # Use ProductCreateUpdateSerializer for validation and creation
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        self.perform_create(serializer)
        
        # Return with ProductListSerializer to include all necessary fields
        instance = serializer.instance
        output_serializer = ProductListSerializer(instance, context={'request': request})
        headers = self.get_success_headers(output_serializer.data)
        return Response(output_serializer.data, status=status.HTTP_201_CREATED, headers=headers)
    
    def perform_update(self, serializer):
        # Ensure only the owner can update
        if serializer.instance.farmer != self.request.user:
            raise PermissionError("You can only update your own products")
        serializer.save()
    
    def perform_destroy(self, instance):
        # Ensure only the owner can delete
        if instance.farmer != self.request.user:
            raise PermissionError("You can only delete your own products")
        instance.delete()
    
    def retrieve(self, request, *args, **kwargs):
        instance = self.get_object()
        # Increment views count
        instance.views_count += 1
        instance.save(update_fields=['views_count'])
        serializer = self.get_serializer(instance)
        return Response(serializer.data)
    
    @action(detail=True, methods=['post'])
    def mark_sold(self, request, pk=None):
        """Mark product as sold out"""
        product = self.get_object()
        if product.farmer != request.user:
            return Response(
                {'error': 'You can only update your own products'},
                status=status.HTTP_403_FORBIDDEN
            )
        product.status = 'sold_out'
        product.save()
        return Response({'message': 'Product marked as sold out'})
    
    @action(detail=True, methods=['post'])
    def mark_available(self, request, pk=None):
        """Mark product as available"""
        product = self.get_object()
        if product.farmer != request.user:
            return Response(
                {'error': 'You can only update your own products'},
                status=status.HTTP_403_FORBIDDEN
            )
        product.status = 'available'
        product.save()
        return Response({'message': 'Product marked as available'})
    
    @action(detail=False, methods=['get'])
    def my_products(self, request):
        """Get all products for the authenticated farmer"""
        if not request.user.is_authenticated or request.user.role != 'farmer':
            return Response(
                {'error': 'Only farmers can access this endpoint'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        products = self.get_queryset().filter(farmer=request.user)
        page = self.paginate_queryset(products)
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)
        
        serializer = self.get_serializer(products, many=True)
        return Response(serializer.data)
    
    @action(detail=True, methods=['post'])
    def add_image(self, request, pk=None):
        #  FOr Add additional image to product
        product = self.get_object()
        if product.farmer != request.user:
            return Response(
                {'error': 'You can only add images to your own products'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        serializer = ProductImageSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save(product=product)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


