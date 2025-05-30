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

    

#     class Meta:
#         db_table = 'users'

# class CustomToken(models.Model):  # ✅ 기존 Token 모델을 대체하는 CustomToken 추가
#     id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
#     user = models.OneToOneField(User, on_delete=models.CASCADE, related_name="custom_auth_token")
#     key = models.CharField(max_length=40, unique=True)
#     created = models.DateTimeField(auto_now_add=True)

#     def save(self, *args, **kwargs):
#         if not self.key:
#             self.key = uuid.uuid4().hex  # ✅ UUID 기반 토큰 생성
#         return super().save(*args, **kwargs)










# from django.db import models
# from django.contrib.auth.models import AbstractUser  # ✅ AbstractUser를 사용하도록 변경해야 함
# import uuid

# class User(AbstractUser):  # ✅ models.Model → AbstractUser로 변경해야 오류 해결됨
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

#     USERNAME_FIELD = 'email'  # ✅ 로그인 시 사용할 필드 추가
#     REQUIRED_FIELDS = ['username']  # ✅ Django에서 필수 필드 요구됨

#     class Meta:
#         db_table = 'users'

# class CustomToken(models.Model):  
#     id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
#     user = models.OneToOneField(User, on_delete=models.CASCADE, related_name="custom_auth_token")
#     key = models.CharField(max_length=40, unique=True)
#     created = models.DateTimeField(auto_now_add=True)

#     def save(self, *args, **kwargs):
#         if not self.key:
#             self.key = uuid.uuid4().hex  
#         return super().save(*args, **kwargs)















from django.db import models
from django.contrib.auth.models import AbstractUser
import uuid

class User(AbstractUser):  # ✅ AbstractUser 유지 (Django 기본 인증 사용)
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    email = models.EmailField(unique=True)
    password = models.TextField(null=True, blank=True)
    gender = models.CharField(max_length=20, choices=[
        ('male', 'Male'),
        ('female', 'Female'),
        ('other', 'Other'),
        ('non-binary', 'Non-binary'),
        ('prefer not to say', 'Prefer not to say'),
    ])
    username = models.CharField(max_length=30, unique=True)
    phone_number = models.CharField(max_length=20, unique=True, null=True, blank=True)
    provider = models.CharField(max_length=50, default='local')
    profile_image = models.TextField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    # ✅ Django 기본 필드 추가 (기본값 지정)
    last_login = models.DateTimeField(null=True, blank=True)  # 마지막 로그인 시간
    is_superuser = models.BooleanField(default=False)  # 슈퍼유저 여부
    is_staff = models.BooleanField(default=False)  # 관리자 페이지 접근 여부
    is_active = models.BooleanField(default=True)  # 계정 활성화 여부
    date_joined = models.DateTimeField(auto_now_add=True)  # 가입한 날짜

    class Meta:
        db_table = 'users'  # ✅ 기존 테이블 유지 (변경 없음)


