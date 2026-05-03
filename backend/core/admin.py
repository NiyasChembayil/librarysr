from django.contrib import admin
from .models import Category, ReadingProgress, AmbientSound

# Register your models here.

admin.site.register(Category)
admin.site.register(ReadingProgress)
admin.site.register(AmbientSound)
