import logging
from django.contrib.auth.hashers import check_password
from django.contrib.auth import get_user_model
from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status
from .serializers import UserSerializer
from django.db.models import Q
from users.models import User

User = get_user_model()

logger = logging.getLogger(__name__)

@api_view(['POST'])
def user_create_view(request):
    logger.info(f"🔵 요청 데이터: {request.data}")  
    serializer = UserSerializer(data=request.data)

    if serializer.is_valid():
        user = serializer.save()
        logger.info(f"✅ 저장 성공! ID: {user.id}")  
        return Response(serializer.data, status=status.HTTP_201_CREATED)
    
    logger.error(f"❌ 저장 실패! 오류: {serializer.errors}")  
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)






@api_view(["POST"])
def user_login_view(request):
    email = request.data.get("email")
    password = request.data.get("password")

    if not email or not password:
        return Response({"error": "Email and password are required"}, status=400)

    user = User.objects.filter(email=email).first()

    if not user or not user.password:  # ✅ 유저가 없거나 비밀번호가 없으면 False 반환
        return Response({"exists": False})

    password_match = check_password(password, user.password)  # ✅ 해싱된 비밀번호 검증

    return Response({"exists": password_match})  # ✅ 비밀번호가 맞으면 True, 틀리면 False





# @api_view(["POST"])
# def user_login_view(request):
#     email = request.data.get("email")
#     # password = request.data.get("password")

#     if not email or not password:
#         return Response({"error": "Email and password are required"}, status=400)

#     user = User.objects.filter(Q(email__iexact=email)).first()

#     if not user:
#         return Response({"exists": False})  # 유저가 없으면 False 반환

#     # 비밀번호 비교
#     password_match = check_password(password, user.password)

#     return Response({"exists": password_match})  # 비밀번호가 맞으면 True, 틀리면 False


# @api_view(["POST"])
# def user_login_view(request):
#     email = request.data.get("email")

#     if not email:
#         return Response({"error": "Email is required"}, status=400)

#     exists = User.objects.filter(Q(email__iexact=email)).exists()
#     return Response({"exists": exists})








# @api_view(["POST"])
# def user_login_view(request):
#     email = request.data.get("email")
#     password = request.data.get("password")

#     print(f"📩 로그인 요청 이메일: {email}")  # ✅ 요청된 이메일 출력
#     user = User.objects.filter(Q(email__iexact=email)).first()
#     print(f"🔍 찾은 유저: {user}")  # ✅ 유저가 있는지 확인

#     if not user:
#         return Response({"error": "User not found"}, status=404)

#     print(f"🔑 입력된 비밀번호: {password}")
#     print(f"🔒 저장된 해시된 비밀번호: {user.password}")

#     if check_password(password, user.password):
#         return Response({"token": "abc123def456"})  # ✅ 로그인 성공
#     else:
#         return Response({"error": "Invalid password"}, status=401)