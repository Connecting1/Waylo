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

class User(AbstractUser):  # ✅ Django 인증 시스템을 유지하며 커스텀 모델 적용
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    email = models.EmailField(unique=True)
    password = models.CharField(max_length=128, null=True, blank=True)  # ✅ Django 기본 설정에 맞춤
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

    USERNAME_FIELD = "email"  # ✅ 로그인에 사용할 필드 (email을 ID로 사용)
    REQUIRED_FIELDS = ["username"]  # ✅ 필수 입력 필드 (비밀번호는 자동 포함됨)

    class Meta:
        db_table = '"users"."users"'  # ✅ PostgreSQL의 "users.users" 테이블을 사용하도록 설정
