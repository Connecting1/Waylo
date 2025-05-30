from users.models import CustomToken  # ✅ 모델 경로 정확하게 지정
from rest_framework.authentication import TokenAuthentication

class CustomTokenAuthentication(TokenAuthentication):
    model = CustomToken  # ✅ CustomToken 모델을 사용
