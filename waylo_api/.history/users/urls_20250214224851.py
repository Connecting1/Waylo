from django.urls import path
from .views import user_create_view, user_login_view  # 로그인 뷰

urlpatterns = [
    path('create/', user_create_view, name='user-create'),  # 회원가입 API
    path('login/', check_email_exists, name='user-login'),  # 로그인 API
]
