from django.conf import settings
from django.conf.urls.static import static
from django.contrib import admin
from django.urls import path, include

urlpatterns = [
    path('admin/', admin.site.urls),  # Django Admin
    path('api/users/', include('users.urls')),  # users API 통합
    path('api/albums/', include('albums.urls')),  # albums API 통합
]

# 미디어 파일 제공 (DEBUG=True일 때만 적용됨)
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
