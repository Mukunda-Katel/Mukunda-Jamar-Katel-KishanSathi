"""
Django settings for kishan_sathi_backend project.
"""

from pathlib import Path
from decouple import config, Csv
from urllib.parse import urlparse, unquote
# from django.contrib.auth import get_user_model
# import os



# Build paths inside the project like this: BASE_DIR / 'subdir'.
BASE_DIR = Path(__file__).resolve().parent.parent


# SECURITY WARNING: keep the secret key used in production secret!
SECRET_KEY = config('SECRET_KEY', default='django-insecure-your-secret-key-here-change-in-production')

# SECURITY WARNING: don't run with debug turned on in production!
DEBUG = config('DEBUG', default=True, cast=bool)

ALLOWED_HOSTS = config('ALLOWED_HOSTS', default='*', cast=Csv())


# Application definition

INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    
    # Third-party apps
    
    
]

EXTERNAL_APPS = [
    'Users',
    'authentication',
    'farmer',
    'buyer',
    'payment',
    'chat',
    'posts',
    'consultation',
    'notifications',
    'ai_chatbot',
    'admin_panel',
]

INSTALLED_APPS += EXTERNAL_APPS




# For third party apps 
THIRD_PARTY_APPS = [
    'rest_framework',
    'rest_framework.authtoken',
    'rest_framework_simplejwt',
    'corsheaders',
    'django_filters',
    'channels',
]

INSTALLED_APPS += THIRD_PARTY_APPS

# Cloudinary apps are added only when credentials are configured.
CLOUDINARY_CLOUD_NAME = config('CLOUDINARY_CLOUD_NAME', default='').strip()
CLOUDINARY_API_KEY = config('CLOUDINARY_API_KEY', default='').strip()
CLOUDINARY_API_SECRET = config('CLOUDINARY_API_SECRET', default='').strip()
USE_CLOUDINARY_STORAGE = all([
    CLOUDINARY_CLOUD_NAME,
    CLOUDINARY_API_KEY,
    CLOUDINARY_API_SECRET,
])

if USE_CLOUDINARY_STORAGE:
    INSTALLED_APPS += [
        'cloudinary_storage',
        'cloudinary',
    ]

MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'corsheaders.middleware.CorsMiddleware',  # Must be before CommonMiddleware
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

ROOT_URLCONF = 'kishan_sathi_backend.urls'

# ADD THIS TEMPLATES CONFIGURATION
TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [BASE_DIR / 'templates'],  # Optional: for custom templates
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'kishan_sathi_backend.wsgi.application'
ASGI_APPLICATION = 'kishan_sathi_backend.asgi.application'

# Channel Layers Configuration for WebSocket
REDIS_URL = config('REDIS_URL', default='').strip()

if REDIS_URL:
    CHANNEL_LAYERS = {
        'default': {
            'BACKEND': 'channels_redis.core.RedisChannelLayer',
            'CONFIG': {
                'hosts': [REDIS_URL],
            },
        }
    }
else:
    CHANNEL_LAYERS = {
        'default': {
            'BACKEND': 'channels.layers.InMemoryChannelLayer',
        }
    }

# DATABASES = {
#     'default': {
#         'ENGINE': 'django.db.backends.postgresql',
#         'NAME': 'neondb',
#         'USER': 'neondb_owner',
#         'PASSWORD': 'npg_7waMHO6SIoWk',
#         'HOST': 'ep-sparkling-pine-an66lupo.c-6.us-east-1.aws.neon.tech',
#         'PORT': '5432',
#         'OPTIONS': {
#             'sslmode': 'require',
#         },
#     }
# }


# Database
# https://docs.djangoproject.com/en/5.1/ref/settings/#databases

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': BASE_DIR / 'db.sqlite3',
    }
}



# DATABASES = {

#     'default': {

#         'ENGINE': 'django.db.backends.postgresql_psycopg2',

#         'NAME': 'kishansathi',

#         'USER': 'postgres',

#         'PASSWORD': '1234',

#         'HOST': 'localhost',

#         'PORT': '5433',

#     }

# }

# DATABASE_URL = config('DATABASE_URL', default='').strip()

# if DATABASE_URL:
#     parsed_db_url = urlparse(DATABASE_URL)
#     DATABASES = {
#         'default': {
#             'ENGINE': 'django.db.backends.postgresql',
#             'NAME': parsed_db_url.path.lstrip('/'),
#             'USER': unquote(parsed_db_url.username or ''),
#             'PASSWORD': unquote(parsed_db_url.password or ''),
#             'HOST': parsed_db_url.hostname or '',
#             'PORT': str(parsed_db_url.port or ''),
#         }
#     }
# else:
#     DATABASES = {
#         'default': {
#             'ENGINE': 'django.db.backends.sqlite3',
#             'NAME': BASE_DIR / 'db.sqlite3',
#         }
#     }

# Password validation
# https://docs.djangoproject.com/en/5.1/ref/settings/#auth-password-validators

AUTH_PASSWORD_VALIDATORS = [
    {
        'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator',
    },
]


# Internationalization
# https://docs.djangoproject.com/en/5.1/topics/i18n/

LANGUAGE_CODE = 'en-us'

TIME_ZONE = 'UTC'

USE_I18N = True

USE_TZ = True


# Static files (CSS, JavaScript, Images)
# https://docs.djangoproject.com/en/5.1/howto/static-files/

STATIC_URL = 'static/'
STATIC_ROOT = BASE_DIR / 'staticfiles'

# Media files (User uploads)
# Uses Cloudinary in environments where Cloudinary credentials are provided.
MEDIA_URL = '/media/'
MEDIA_ROOT = BASE_DIR / 'media'
SERVE_LOCAL_MEDIA = True

if USE_CLOUDINARY_STORAGE:
    CLOUDINARY_STORAGE = {
        'CLOUD_NAME': CLOUDINARY_CLOUD_NAME,
        'API_KEY': CLOUDINARY_API_KEY,
        'API_SECRET': CLOUDINARY_API_SECRET,
        # Keep public IDs clean (e.g. products/file.jpg) instead of prefixing MEDIA_URL.
        'PREFIX': '',
    }

    STORAGES = {
        'default': {
            'BACKEND': 'cloudinary_storage.storage.MediaCloudinaryStorage',
        },
        'staticfiles': {
            'BACKEND': 'django.contrib.staticfiles.storage.StaticFilesStorage',
        },
    }
    SERVE_LOCAL_MEDIA = False

# ADD: File upload settings
FILE_UPLOAD_MAX_MEMORY_SIZE = 10485760  
DATA_UPLOAD_MAX_MEMORY_SIZE = 10485760  

# Allowed file extensions for doctor certificates
ALLOWED_CERTIFICATE_EXTENSIONS = ['.pdf', '.jpg', '.jpeg', '.png']

# Default primary key field type
# https://docs.djangoproject.com/en/5.1/ref/settings/#default-auto-field

DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

# Custom User Model
AUTH_USER_MODEL = 'Users.User'

# REST Framework Configuration
REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': [
        'rest_framework.authentication.TokenAuthentication',
        'rest_framework_simplejwt.authentication.JWTAuthentication',
        'rest_framework.authentication.SessionAuthentication',
    ],
    'DEFAULT_PERMISSION_CLASSES': [
        'rest_framework.permissions.AllowAny',  # For registration/login
    ],
    'DEFAULT_RENDERER_CLASSES': [
        'rest_framework.renderers.JSONRenderer',
        'rest_framework.renderers.BrowsableAPIRenderer',
    ],
}

# Simple JWT Configuration
from datetime import timedelta
SIMPLE_JWT = {
    'ACCESS_TOKEN_LIFETIME': timedelta(minutes=60),
    'REFRESH_TOKEN_LIFETIME': timedelta(days=7),
    'ROTATE_REFRESH_TOKENS': True,
    'BLACKLIST_AFTER_ROTATION': True,
    'AUTH_HEADER_TYPES': ('Bearer',),
    'USER_ID_FIELD': 'id',
    'USER_ID_CLAIM': 'user_id',
}
# CORS Configuration (Development only)
CORS_ALLOW_ALL_ORIGINS = True  
CORS_ALLOW_CREDENTIALS = True

CORS_ALLOW_METHODS = [
    'DELETE',
    'GET',
    'OPTIONS',
    'PATCH',
    'POST',
    'PUT',
]

CORS_ALLOW_HEADERS = [
    'accept',
    'accept-encoding',
    'authorization',
    'content-type',
    'dnt',
    'origin',
    'user-agent',
    'x-csrftoken',
    'x-requested-with',
]

# Email Configuration
EMAIL_BACKEND = config('EMAIL_BACKEND', default='django.core.mail.backends.console.EmailBackend')
EMAIL_HOST = config('EMAIL_HOST', default='smtp.gmail.com')
EMAIL_PORT = config('EMAIL_PORT', default=587, cast=int)
EMAIL_USE_TLS = config('EMAIL_USE_TLS', default=True, cast=bool)
EMAIL_HOST_USER = config('EMAIL_HOST_USER', default='')
EMAIL_HOST_PASSWORD = config('EMAIL_HOST_PASSWORD', default='')
DEFAULT_FROM_EMAIL = config('DEFAULT_FROM_EMAIL', default='Kishan Sathi <noreply@kishansathi.com>')
ADMIN_EMAIL = config('ADMIN_EMAIL', default='admin@kishansathi.com')

# Weather API Configuration
WEATHER_API_KEY = config('WEATHER_API_KEY', default='')

# Khalti Configuration
KHALTI_SECRET_KEY = config('KHALTI_SECRET_KEY', default='')
KHALTI_PUBLIC_KEY = config('KHALTI_PUBLIC_KEY', default='')
KHALTI_BASE_URL = config('KHALTI_BASE_URL', default='https://khalti.com')
KHALTI_WEBSITE_URL = config('KHALTI_WEBSITE_URL', default='https://example.com')
KHALTI_RETURN_URL = config('KHALTI_RETURN_URL', default='')

# Firebase Cloud Messaging Configuration (V1 API)
# Download service account JSON from Firebase Console > Project Settings > Service Accounts
# Place it in your project directory and specify the path here
FIREBASE_SERVICE_ACCOUNT_KEY = config(
    'FIREBASE_SERVICE_ACCOUNT_KEY',
    default=str(BASE_DIR / 'firebase-service-account.json')
)



# For admin account as the vercel shell is not freee 
# def create_superuser():
#     User = get_user_model()
#     username = os.environ.get("DJANGO_SUPERUSER_USERNAME")
#     email = os.environ.get("DJANGO_SUPERUSER_EMAIL")
#     password = os.environ.get("DJANGO_SUPERUSER_PASSWORD")

#     if username and email and password:
#         if not User.objects.filter(username=username).exists():
#             User.objects.create_superuser(username, email, password)
#             print("Superuser created")

# create_superuser()