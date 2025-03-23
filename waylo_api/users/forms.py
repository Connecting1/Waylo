from django import forms
from .models import User

class UserForm(forms.ModelForm):
    password = forms.CharField(widget=forms.PasswordInput)
    
    class Meta:
        model = User
        fields = [
            'email',
            'password',
            'gender',
            'username',
            'phone_number',
            'provider',
            'profile_image',
        ]
