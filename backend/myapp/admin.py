
from django.contrib import admin
from .models import MyProfileModel
# Register your models here.


class MyProfileAdmin(admin.ModelAdmin):
    list_display = ('name', 'image')
    list_display_links = ('name', 'image',)
    search_fields = ('name', 'image',)
    list_per_page = 25
    list_filter = ('name',)


admin.site.register(MyProfileModel, MyProfileAdmin)
