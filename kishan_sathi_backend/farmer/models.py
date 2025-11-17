from django.db import models

# Create your models here.
class Farmers(models.Model):
    name = models.CharField(max_length=100, unique=True)
    location = models.CharField(max_length=200)
    contact_number = models.CharField()
    