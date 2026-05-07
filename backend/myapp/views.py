from rest_framework import generics
from .serializers import MyProfileSerializers
from .models import MyProfileModel


class MyProfileListView(generics.ListCreateAPIView):
    '''This class is a view that lists all the MyProfileModel objects
    and allows to create new ones'''
    queryset = MyProfileModel.objects.all()
    serializer_class = MyProfileSerializers


class MyProfileDetailView(generics.RetrieveUpdateDestroyAPIView):
    '''This class allows to retrieve, update, or
    delete a specific instance of the MyProfileModel'''
    queryset = MyProfileModel.objects.all()
    serializer_class = MyProfileSerializers
