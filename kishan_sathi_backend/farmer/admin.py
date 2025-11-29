from django.contrib import admin
from django.utils.html import format_html
from .models import Category, Product, ProductImage


@admin.register(Category)
class CategoryAdmin(admin.ModelAdmin):
    list_display = ['name', 'icon', 'product_count', 'created_at']
    search_fields = ['name', 'description']
    readonly_fields = ['created_at']
    
    def product_count(self, obj):
        count = obj.products.count()
        return format_html(
            '<span style="font-weight: bold; color: #28a745;">{}</span>',
            count
        )
    product_count.short_description = 'Products'


class ProductImageInline(admin.TabularInline):
    model = ProductImage
    extra = 1
    fields = ['image', 'caption', 'image_preview']
    readonly_fields = ['image_preview', 'uploaded_at']
    
    def image_preview(self, obj):
        if obj.image:
            return format_html(
                '<img src="{}" style="max-height: 100px; max-width: 150px;" />',
                obj.image.url
            )
        return '-'
    image_preview.short_description = 'Preview'


@admin.register(Product)
class ProductAdmin(admin.ModelAdmin):
    list_display = [
        'name',
        'farmer_name',
        'category',
        'price_display',
        'quantity_display',
        'status_badge',
        'is_organic_badge',
        'created_at',
    ]
    
    list_filter = [
        'status',
        'is_organic',
        'is_active',
        'category',
        'created_at',
    ]
    
    search_fields = [
        'name',
        'farmer__full_name',
        'farmer__email',
        'location',
        'district',
    ]
    
    readonly_fields = [
        'created_at',
        'updated_at',
        'views_count',
        'image_preview',
    ]
    
    fieldsets = (
        ('Product Information', {
            'fields': ('farmer', 'category', 'name', 'description')
        }),
        ('Pricing & Inventory', {
            'fields': ('price', 'quantity', 'unit', 'status')
        }),
        ('Product Details', {
            'fields': ('is_organic', 'harvest_date', 'location', 'district')
        }),
        ('Media', {
            'fields': ('image', 'image_preview')
        }),
        ('Settings', {
            'fields': ('is_active', 'views_count'),
            'classes': ('collapse',)
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
    
    inlines = [ProductImageInline]
    
    actions = ['mark_as_available', 'mark_as_sold_out', 'activate_products', 'deactivate_products']
    
    def farmer_name(self, obj):
        return obj.farmer.full_name
    farmer_name.short_description = 'Farmer'
    farmer_name.admin_order_field = 'farmer__full_name'
    
    def price_display(self, obj):
        return format_html(
            '<span style="font-weight: bold; color: #28a745;">NPR {}</span>',
            obj.price
        )
    price_display.short_description = 'Price'
    price_display.admin_order_field = 'price'
    
    def quantity_display(self, obj):
        return f"{obj.quantity} {obj.get_unit_display()}"
    quantity_display.short_description = 'Quantity'
    
    def status_badge(self, obj):
        colors = {
            'available': '#28a745',
            'sold_out': '#dc3545',
            'pending': '#ffc107',
        }
        return format_html(
            '<span style="background-color: {}; color: white; padding: 5px 10px; '
            'border-radius: 5px; font-weight: bold; font-size: 11px;">{}</span>',
            colors.get(obj.status, '#6c757d'),
            obj.get_status_display().upper()
        )
    status_badge.short_description = 'Status'
    
    def is_organic_badge(self, obj):
        if obj.is_organic:
            return format_html(
                '<span style="color: #28a745; font-weight: bold;">✓ Organic</span>'
            )
        return '-'
    is_organic_badge.short_description = 'Organic'
    
    def image_preview(self, obj):
        if obj.image:
            return format_html(
                '<img src="{}" style="max-height: 200px; max-width: 300px; border-radius: 8px;" />',
                obj.image.url
            )
        return '-'
    image_preview.short_description = 'Product Image'
    
    def mark_as_available(self, request, queryset):
        updated = queryset.update(status='available')
        self.message_user(request, f'{updated} product(s) marked as available.')
    mark_as_available.short_description = '✓ Mark as Available'
    
    def mark_as_sold_out(self, request, queryset):
        updated = queryset.update(status='sold_out')
        self.message_user(request, f'{updated} product(s) marked as sold out.')
    mark_as_sold_out.short_description = '✗ Mark as Sold Out'
    
    def activate_products(self, request, queryset):
        updated = queryset.update(is_active=True)
        self.message_user(request, f'{updated} product(s) activated.')
    activate_products.short_description = 'Activate selected products'
    
    def deactivate_products(self, request, queryset):
        updated = queryset.update(is_active=False)
        self.message_user(request, f'{updated} product(s) deactivated.')
    deactivate_products.short_description = 'Deactivate selected products'


@admin.register(ProductImage)
class ProductImageAdmin(admin.ModelAdmin):
    list_display = ['product', 'caption', 'image_thumbnail', 'uploaded_at']
    list_filter = ['uploaded_at']
    search_fields = ['product__name', 'caption']
    readonly_fields = ['uploaded_at', 'image_preview']
    
    def image_thumbnail(self, obj):
        if obj.image:
            return format_html(
                '<img src="{}" style="max-height: 50px; max-width: 75px; border-radius: 4px;" />',
                obj.image.url
            )
        return '-'
    image_thumbnail.short_description = 'Thumbnail'
    
    def image_preview(self, obj):
        if obj.image:
            return format_html(
                '<img src="{}" style="max-height: 300px; max-width: 400px; border-radius: 8px;" />',
                obj.image.url
            )
        return '-'
    image_preview.short_description = 'Image Preview'
