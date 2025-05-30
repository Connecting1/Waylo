from rest_framework.authentication import TokenAuthentication
from users.models import CustomToken

class CustomTokenAuthentication(TokenAuthentication):  # ✅ 기본 Token 대신 CustomToken 적용
    model = CustomToken
