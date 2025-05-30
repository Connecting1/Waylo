# from django.db import models
# from django.contrib.auth.models import AbstractUser
# import uuid

# class User(models.Model):
#     id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
#     email = models.EmailField(unique=True)
#     password = models.TextField(null=True, blank=True)
#     gender = models.CharField(max_length=20, choices=[
#         ('male', 'Male'),
#         ('female', 'Female'),
#         ('other', 'Other'),
#         ('non-binary', 'Non-binary'),
#         ('prefer not to say', 'Prefer not to say'),
#     ])
#     username = models.CharField(max_length=30, unique=True)
#     phone_number = models.CharField(max_length=20, unique=True, null=True, blank=True)
#     provider = models.CharField(max_length=50, default='local')
#     profile_image = models.TextField(null=True, blank=True)
#     created_at = models.DateTimeField(auto_now_add=True)

#     REQUIRED_FIELDS = ["email"]

#     class Meta:
#         db_table = '"users"."users"'

# class CustomToken(models.Model):  # ✅ 기존 Token 모델을 대체하는 CustomToken 추가
#     id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
#     user = models.OneToOneField(User, on_delete=models.CASCADE, related_name="custom_auth_token")
#     key = models.CharField(max_length=40, unique=True)
#     created = models.DateTimeField(auto_now_add=True)

#     def save(self, *args, **kwargs):
#         if not self.key:
#             self.key = uuid.uuid4().hex  # ✅ UUID 기반 토큰 생성
#         return super().save(*args, **kwargs)




from django.db import models
from django.contrib.auth.models import AbstractUser
import uuid

class User(AbstractUser):  # ✅ Django 인증 시스템과 완벽히 호환되도록 수정
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    email = models.EmailField(unique=True)
    
    # ✅ Django 기본 인증 필드 추가 (현재 데이터베이스에 없어서 추가해야 함)
    last_login = models.DateTimeField(null=True, blank=True)
    is_superuser = models.BooleanField(default=False)
    is_staff = models.BooleanField(default=False)
    is_active = models.BooleanField(default=True)

    gender = models.CharField(max_length=20, choices=[
        ('male', 'Male'),
        ('female', 'Female'),
        ('other', 'Other'),
        ('non-binary', 'Non-binary'),
        ('prefer not to say', 'Prefer not to say'),
    ])
    phone_number = models.CharField(max_length=20, unique=True, null=True, blank=True)
    provider = models.CharField(max_length=50, default='local')
    profile_image = models.TextField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    USERNAME_FIELD = "email"
    REQUIRED_FIELDS = ["username"]

    class Meta:
        db_table = '"users"."users"'
