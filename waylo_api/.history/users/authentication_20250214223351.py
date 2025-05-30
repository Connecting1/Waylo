from django.utils.translation import gettext_lazy as _
from rest_framework.authentication import TokenAuthentication
from users.models import CustomToken  # ✅ `CustomToken` 임포트 확인

class CustomTokenAuthentication(TokenAuthentication):
    model = CustomToken  # ✅ CustomToken을 사용할 수 있도록 수정
