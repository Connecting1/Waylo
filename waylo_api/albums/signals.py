from django.db.models.signals import post_save
from django.dispatch import receiver
from users.models import User  # User 모델 가져오기
from .models import Album  # Album 모델 가져오기

@receiver(post_save, sender=User)
def create_album_for_new_user(sender, instance, created, **kwargs):
    """ 새로운 유저가 생성될 때 자동으로 앨범 생성 """
    if created:  # User가 새로 생성된 경우만 실행
        Album.objects.create(user=instance)
        print(f"자동 생성된 앨범 for {instance.username}")
