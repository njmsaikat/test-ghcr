from rest_framework import serializers
from .models import MyProfileModel


class MyProfileSerializers(serializers.ModelSerializer):
    class Meta:
        model = MyProfileModel
        fields = '__all__'
