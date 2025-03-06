from django.urls import path
from . import views

urlpatterns = [
    path('<uuid:user_id>/widgets/', views.get_album_widgets, name='get_album_widgets'),
    path('<uuid:user_id>/widgets/create/', views.create_widget, name='create_widget'),
    path('<uuid:user_id>/widgets/<uuid:widget_id>/update/', views.update_widget, name='update_widget'),
    path('<uuid:user_id>/widgets/<uuid:widget_id>/delete/', views.delete_widget, name='delete_widget'),
]
