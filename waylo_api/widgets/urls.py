from django.urls import path
from . import views

urlpatterns = [
    path('<uuid:user_id>/', views.get_album_widgets, name='get_album_widgets'),  # 특정 사용자의 앨범 위젯 목록 조회
    path('<uuid:user_id>/create/', views.create_widget, name='create_widget'),  # 새 위젯 생성
    path('<uuid:user_id>/<uuid:widget_id>/update/', views.update_widget, name='update_widget'),  # 위젯 업데이트
    path('<uuid:user_id>/<uuid:widget_id>/delete/', views.delete_widget, name='delete_widget'),  # 위젯 삭제
]