from django.db.models.signals import post_save
from django.dispatch import receiver
from users.models import User
from .models import Album

@receiver(post_save, sender=User)
def create_album_for_new_user(sender, instance, created, **kwargs):
    """
    새로운 유저가 생성될 때 자동으로 앨범 생성
    """
    if created:
        Album.objects.create(user=instance)
