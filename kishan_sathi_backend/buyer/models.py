from django.db import models
from django.conf import settings
from decimal import Decimal
from farmer.models import Product


class Cart(models.Model):
    """
    Shopping cart for buyers
    """
    buyer = models.OneToOneField(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='cart',
        limit_choices_to={'role': 'buyer'}
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'buyer_cart'
        verbose_name = 'Cart'
        verbose_name_plural = 'Carts'

    def __str__(self):
        return f"Cart for {self.buyer.get_full_name()}"

    @property
    def total_items(self):
        """Get total number of items in cart"""
        return sum(int(item.quantity) for item in self.items.all())

    @property
    def total_price(self):
        """Calculate total price of all items in cart"""
        total = sum(item.subtotal for item in self.items.all())
        return Decimal('0.00') if not total else total


class CartItem(models.Model):
    """
    Individual items in shopping cart
    """
    cart = models.ForeignKey(
        Cart,
        on_delete=models.CASCADE,
        related_name='items'
    )
    product = models.ForeignKey(
        Product,
        on_delete=models.CASCADE,
        related_name='cart_items'
    )
    quantity = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=1
    )
    added_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'buyer_cart_item'
        verbose_name = 'Cart Item'
        verbose_name_plural = 'Cart Items'
        unique_together = ['cart', 'product']
        ordering = ['-added_at']

    def __str__(self):
        return f"{self.quantity} x {self.product.name}"

    @property
    def subtotal(self):
        """Calculate subtotal for this item"""
        # Ensure both values are Decimal for proper calculation
        return Decimal(str(self.product.price)) * Decimal(str(self.quantity))

    def save(self, *args, **kwargs):
        """Validate quantity before saving"""
        if self.quantity <= 0:
            raise ValueError("Quantity must be greater than 0")
        if self.quantity > self.product.quantity:
            raise ValueError(f"Requested quantity ({self.quantity}) exceeds available stock ({self.product.quantity})")
        super().save(*args, **kwargs)

