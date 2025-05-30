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







# @api_view(["POST"])
# def user_login_view(request):
#     password = request.data.get("password")

#     if not password:
#         return Response({"error": "Password is required"}, status=400)

#     # 고정된 이메일로 조회: bbb@bbb.com
#     user = User.objects.filter(email="bbb@bbb.com").first()

#     if not user or not user.password:
#         logger.warning("❌ 로그인 실패: 유저가 없거나 비밀번호가 저장되지 않음")
#         return Response({"exists": False}, status=401)

#     # 해시 없이 단순 문자열 비교
#     if user.password == password:
#         logger.info("✅ 로그인 성공: 비밀번호 일치")
#         return Response({"exists": True}, status=200)
#     else:
#         logger.warning("❌ 로그인 실패: 비밀번호 불일치")
#         return Response({"exists": False}, status=401)



# @api_view(["POST"])
# def user_login_view(request):
#     password = request.data.get("password")

#     if not password:
#         return Response({"error": "Password is required"}, status=400)

#     user = User.objects.filter(email="bbb@bbb.com").first()  # ✅ 첫 번째 유저의 비밀번호와 비교

#     if not user or not user.password:  # ✅ 유저가 없거나 비밀번호가 없으면 401 반환
#         return Response({"exists": False}, status=401)

#     password_match = check_password(password, user.password)  # ✅ 비밀번호 검증

#     if password_match:
#         return Response({"exists": True})  # ✅ 올바른 비밀번호 → 200 OK
#     else:
#         return Response({"exists": False}, status=401)  # ❌ 틀린 비밀번호 → 401 Unauthorized

























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


@api_view(["POST"])
def user_login_view(request):
    email = request.data.get("email")
    print(f"Received email: {email}")

    if not email:
        return Response({"error": "Email is required"}, status=400)

    exists = User.objects.filter(Q(email__iexact=email)).exists()
    return Response({"exists": exists})


# @api_view(["POST"])
# def user_login_view(request):
#     password = request.data.get("password")
#     logger.info(f"Received password: {password}")

#     if not password:
#         return Response({"error": "Email is required"}, status=400)

#     exists = User.objects.filter(Q(password__iexact=password)).exists()
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