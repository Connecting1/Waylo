import logging
from django.contrib.auth.hashers import check_password
from django.contrib.auth import get_user_model
from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status
from .serializers import UserSerializer
from django.db import connection

# ✅ 중복 제거: get_user_model()을 한 번만 정의
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










# from django.contrib.auth.hashers import check_password  # ✅ 비밀번호 확인을 위해 추가

# @api_view(['POST'])
# def user_login_view(request):
#     print(f"🔵 로그인 요청 데이터: {request.data}")  

#     # 데이터베이스 연결 확인
#     try:
#         connection.ensure_connection()
#         print("✅ 데이터베이스 연결 성공")
#     except Exception as e:
#         print(f"❌ 데이터베이스 연결 실패: {e}")
#         return Response({"error": f"Database connection failed: {str(e)}"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

#     # 이메일(email)과 비밀번호(password) 확인
#     email = request.data.get("email")  # 요청에서 email 가져오기
#     password = request.data.get("password")  # 요청에서 password 가져오기

#     if not email or not password:
#         return Response({"error": "이메일과 비밀번호를 입력하세요."}, status=status.HTTP_400_BAD_REQUEST)

#     # 🔹 이메일로 사용자 조회
#     try:
#         user = User.objects.get(email=email)
#     except User.DoesNotExist:
#         return Response({"error": "이메일을 찾을 수 없습니다."}, status=status.HTTP_404_NOT_FOUND)

#     # 🔹 비밀번호 확인
#     if check_password(password, user.password):  # ✅ 비밀번호 비교 추가
#         return Response({"message": "로그인 성공"}, status=status.HTTP_200_OK)
#     else:
#         return Response({"error": "비밀번호가 일치하지 않습니다."}, status=status.HTTP_401_UNAUTHORIZED)





@api_view(['POST'])
def user_login_view(request):
    print(f"🔵 로그인 요청 데이터: {request.data}")  

    # 데이터베이스 연결 확인
    try:
        connection.ensure_connection()
        print("✅ 데이터베이스 연결 성공")
    except Exception as e:
        print(f"❌ 데이터베이스 연결 실패: {e}")
        return Response({"error": f"Database connection failed: {str(e)}"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

    # 이메일(email) 존재 여부 확인
    email = request.data.get("email")  # 요청에서 email 가져오기

    if not email:
        return Response({"error": "이메일(email)을 입력하세요."}, status=status.HTTP_400_BAD_REQUEST)

    # 🔹 SQL 쿼리 로그 출력
    queryset = User.objects.filter(email=email)
    print(f"🟡 실행된 SQL 쿼리: {queryset.query}")  # SQL 쿼리 로그 출력

    user_exists = queryset.exists()  # 존재 여부 확인

    if user_exists:
        return Response({"message": "이메일이 등록되어 있습니다."}, status=status.HTTP_200_OK)
    else:
        return Response({"error": "이메일을 찾을 수 없습니다."}, status=status.HTTP_404_NOT_FOUND)




