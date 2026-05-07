from django.db import models

# Create your models here.


class MyProfileModel(models.Model):
    name = models.CharField(max_length=50)
    image = models.ImageField(
        upload_to='images/uploads/%Y/%m/%d', default='image.jpg')

    def __str__(self):
        return f"{self.name}"

    class Meta:
        verbose_name = "My Profile"
        verbose_name_plural = "My Profiles"
        db_table = "my_profile"
