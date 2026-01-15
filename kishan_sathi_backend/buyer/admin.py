from django.contrib import admin
from .models import Cart, CartItem


class CartItemInline(admin.TabularInline):
    model = CartItem
    extra = 0
    readonly_fields = ['subtotal', 'added_at', 'updated_at']
    fields = ['product', 'quantity', 'subtotal', 'added_at']


@admin.register(Cart)
class CartAdmin(admin.ModelAdmin):
    list_display = ['buyer', 'total_items', 'total_price', 'updated_at']
    search_fields = ['buyer__email', 'buyer__full_name']
    readonly_fields = ['created_at', 'updated_at']
    inlines = [CartItemInline]

    def total_items(self, obj):
        return obj.total_items
    total_items.short_description = 'Total Items'

    def total_price(self, obj):
        return f'Rs. {obj.total_price}'
    total_price.short_description = 'Total Price'


@admin.register(CartItem)
class CartItemAdmin(admin.ModelAdmin):
    list_display = ['cart', 'product', 'quantity', 'subtotal', 'added_at']
    list_filter = ['added_at', 'updated_at']
    search_fields = ['cart__buyer__email', 'product__name']
    readonly_fields = ['subtotal', 'added_at', 'updated_at']

    def subtotal(self, obj):
        return f'Rs. {obj.subtotal}'
    subtotal.short_description = 'Subtotal'

