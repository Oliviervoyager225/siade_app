# 🚀 IMPLÉMENTATION COMPLÈTE - SYSTÈME DE MESSAGERIE EN TEMPS RÉEL

## PARTIE 1: BACKEND DJANGO - WEBSOCKET & MESSAGING

---

## ÉTAPE 1: INSTALLATION

Exécutez ces commandes dans votre terminal (au niveau du projet Django):

```bash
pip install channels channels-redis daphne
```

Ou ajoutez à requirements.txt:
```
channels==4.0.0
channels-redis==4.1.0
daphne==4.0.0
```

---

## FICHIER 1: settings.py (Configuration Django)

```python
INSTALLED_APPS = [
    'daphne',  # ⚠️ DOIT ÊTRE EN PREMIER
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'rest_framework',
    'channels',
    'corsheaders',
    'chat',  # Votre app de messagerie
]

MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'corsheaders.middleware.CorsMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
]

# ═══════════════════════════════════════════════════════════════════════════
# ASGI & CHANNELS CONFIGURATION
# ═══════════════════════════════════════════════════════════════════════════

ASGI_APPLICATION = 'your_project.asgi.application'

CHANNEL_LAYERS = {
    'default': {
        'BACKEND': 'channels_redis.core.RedisChannelLayer',
        'CONFIG': {
            "hosts": [('127.0.0.1', 6379)],
        },
    },
}

# Pour le développement local, vous pouvez utiliser InMemoryChannelLayer
# (décommentez si Redis n'est pas disponible):
# CHANNEL_LAYERS = {
#     'default': {
#         'BACKEND': 'channels.layers.InMemoryChannelLayer'
#     }
# }

# Configuration CORS (pour Flutter)
CORS_ALLOWED_ORIGINS = [
    "http://localhost:3000",
    "http://localhost:8000",
    "http://127.0.0.1:8000",
]

REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': [
        'rest_framework_simplejwt.authentication.JWTAuthentication',
    ],
    'DEFAULT_PAGINATION_CLASS': 'rest_framework.pagination.PageNumberPagination',
    'PAGE_SIZE': 50,
}
```

---

## FICHIER 2: your_project/asgi.py (Routing WebSocket)

```python
import os
from django.core.asgi import get_asgi_application
from channels.routing import ProtocolTypeRouter, URLRouter
from channels.auth import AuthMiddlewareStack
from channels.security.websocket import AllowedHostsOriginValidator

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'your_project.settings')

django_asgi_app = get_asgi_application()

# Importer les URL patterns WebSocket
from chat.routing import websocket_urlpatterns

application = ProtocolTypeRouter({
    "http": django_asgi_app,
    "websocket": AllowedHostsOriginValidator(
        AuthMiddlewareStack(
            URLRouter(websocket_urlpatterns)
        )
    ),
})
```

---

## FICHIER 3: chat/models.py (Modèles de Messagerie)

```python
from django.db import models
from django.contrib.auth import get_user_model

User = get_user_model()

class Conversation(models.Model):
    """Représente une conversation entre utilisateurs"""
    participants = models.ManyToManyField(User, related_name='conversations')
    name = models.CharField(max_length=255, blank=True, null=True)  # Pour les groupes
    is_group = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-updated_at']
    
    def __str__(self):
        if self.is_group:
            return self.name or f"Groupe #{self.id}"
        return f"Conversation {self.id}"


class Message(models.Model):
    """Représente un message dans une conversation"""
    conversation = models.ForeignKey(
        Conversation, 
        on_delete=models.CASCADE, 
        related_name='messages'
    )
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    content = models.TextField()
    is_read = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['created_at']
        indexes = [
            models.Index(fields=['conversation', 'created_at']),
        ]
    
    def __str__(self):
        return f"{self.user.username}: {self.content[:50]}"


class UserStatus(models.Model):
    """Suivi du statut en ligne des utilisateurs"""
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='status')
    is_online = models.BooleanField(default=False)
    last_seen = models.DateTimeField(auto_now=True)
    
    def __str__(self):
        return f"{self.user.username} - {'Online' if self.is_online else 'Offline'}"
```

---

## FICHIER 4: chat/consumers.py (WebSocket Consumer)

```python
import json
from channels.generic.websocket import AsyncWebsocketConsumer
from channels.db import database_sync_to_async
from django.contrib.auth import get_user_model
from .models import Message, Conversation, UserStatus
from django.utils import timezone

User = get_user_model()

class ChatConsumer(AsyncWebsocketConsumer):
    """Consumer pour la gestion des chats en temps réel"""
    
    async def connect(self):
        """Appelé quand un client WebSocket se connecte"""
        self.conversation_id = self.scope['url_route']['kwargs']['conversation_id']
        self.room_group_name = f'chat_{self.conversation_id}'
        self.user = self.scope['user']
        
        # Vérifier que l'utilisateur est un participant
        is_participant = await self.verify_participant()
        
        if not is_participant:
            await self.close()
            return
        
        # Joindre le groupe de conversation
        await self.channel_layer.group_add(
            self.room_group_name,
            self.channel_name
        )
        
        # Accepter la connexion
        await self.accept()
        
        # Mettre à jour le statut utilisateur
        await self.update_user_status(True)
        
        # Notifier les autres que l'utilisateur est en ligne
        await self.channel_layer.group_send(
            self.room_group_name,
            {
                'type': 'user_status',
                'user_id': self.user.id,
                'user_name': self.user.username,
                'status': 'online'
            }
        )
        
        print(f"✅ {self.user.username} connecté à la conversation {self.conversation_id}")

    async def disconnect(self, close_code):
        """Appelé quand un client WebSocket se déconnecte"""
        
        # Mettre à jour le statut utilisateur
        await self.update_user_status(False)
        
        # Notifier les autres que l'utilisateur est hors ligne
        await self.channel_layer.group_send(
            self.room_group_name,
            {
                'type': 'user_status',
                'user_id': self.user.id,
                'user_name': self.user.username,
                'status': 'offline'
            }
        )
        
        # Quitter le groupe
        await self.channel_layer.group_discard(
            self.room_group_name,
            self.channel_name
        )
        
        print(f"❌ {self.user.username} déconnecté de la conversation {self.conversation_id}")

    async def receive(self, text_data):
        """Appelé quand le serveur reçoit un message du WebSocket"""
        try:
            data = json.loads(text_data)
            message_type = data.get('type')
            
            if message_type == 'message':
                # Sauvegarder et broadcaster le message
                message = await self.save_message(
                    conversation_id=self.conversation_id,
                    user_id=self.user.id,
                    content=data['content']
                )
                
                # Broadcaster à tous les participants
                await self.channel_layer.group_send(
                    self.room_group_name,
                    {
                        'type': 'chat_message',
                        'message': {
                            'id': message.id,
                            'content': message.content,
                            'user_id': message.user.id,
                            'user_name': message.user.username,
                            'timestamp': message.created_at.isoformat(),
                            'is_read': message.is_read,
                        }
                    }
                )
                
            elif message_type == 'typing':
                # Indicateur "en train d'écrire..."
                await self.channel_layer.group_send(
                    self.room_group_name,
                    {
                        'type': 'typing_indicator',
                        'user_id': self.user.id,
                        'user_name': self.user.username,
                        'is_typing': data.get('is_typing', False)
                    }
                )
                
            elif message_type == 'mark_read':
                # Marquer les messages comme lus
                await self.mark_messages_as_read(
                    conversation_id=self.conversation_id,
                    user_id=self.user.id
                )
                
        except json.JSONDecodeError:
            print("Erreur: JSON invalide")
        except Exception as e:
            print(f"Erreur lors de la réception: {e}")

    # Handlers pour envoyer les événements aux clients
    
    async def chat_message(self, event):
        """Envoyer un message au client"""
        await self.send(text_data=json.dumps({
            'type': 'message',
            'data': event['message']
        }))

    async def typing_indicator(self, event):
        """Envoyer l'indicateur de frappe au client"""
        # Ne pas envoyer au client qui tape
        if event['user_id'] != self.user.id:
            await self.send(text_data=json.dumps({
                'type': 'typing',
                'user_id': event['user_id'],
                'user_name': event['user_name'],
                'is_typing': event['is_typing']
            }))

    async def user_status(self, event):
        """Envoyer le statut utilisateur au client"""
        await self.send(text_data=json.dumps({
            'type': 'status',
            'user_id': event['user_id'],
            'user_name': event['user_name'],
            'status': event['status']
        }))

    # Méthodes asynchrones base de données
    
    @database_sync_to_async
    def verify_participant(self):
        """Vérifier que l'utilisateur est participant de la conversation"""
        try:
            conversation = Conversation.objects.get(id=self.conversation_id)
            return conversation.participants.filter(id=self.user.id).exists()
        except Conversation.DoesNotExist:
            return False

    @database_sync_to_async
    def save_message(self, conversation_id, user_id, content):
        """Sauvegarder un message en base de données"""
        try:
            user = User.objects.get(id=user_id)
            conversation = Conversation.objects.get(id=conversation_id)
            
            message = Message.objects.create(
                conversation=conversation,
                user=user,
                content=content
            )
            
            # Mettre à jour le timestamp de la conversation
            conversation.updated_at = timezone.now()
            conversation.save()
            
            return message
        except (User.DoesNotExist, Conversation.DoesNotExist) as e:
            print(f"Erreur lors de la sauvegarde: {e}")
            return None

    @database_sync_to_async
    def update_user_status(self, is_online):
        """Mettre à jour le statut en ligne de l'utilisateur"""
        try:
            status, created = UserStatus.objects.get_or_create(user=self.user)
            status.is_online = is_online
            status.last_seen = timezone.now()
            status.save()
        except Exception as e:
            print(f"Erreur lors de la mise à jour du statut: {e}")

    @database_sync_to_async
    def mark_messages_as_read(self, conversation_id, user_id):
        """Marquer les messages comme lus"""
        try:
            Message.objects.filter(
                conversation_id=conversation_id
            ).exclude(
                user_id=user_id
            ).update(is_read=True)
        except Exception as e:
            print(f"Erreur lors du marquage: {e}")
```

---

## FICHIER 5: chat/routing.py (Routing WebSocket)

```python
from django.urls import re_path
from . import consumers

websocket_urlpatterns = [
    re_path(
        r'ws/chat/(?P<conversation_id>\d+)/$',
        consumers.ChatConsumer.as_asgi()
    ),
]
```

---

## FICHIER 6: chat/serializers.py (Sérialisation DRF)

```python
from rest_framework import serializers
from .models import Message, Conversation, UserStatus
from django.contrib.auth import get_user_model

User = get_user_model()

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'first_name', 'last_name']
        read_only_fields = ['id']


class UserStatusSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)
    
    class Meta:
        model = UserStatus
        fields = ['user', 'is_online', 'last_seen']


class MessageSerializer(serializers.ModelSerializer):
    user_name = serializers.CharField(source='user.username', read_only=True)
    user = UserSerializer(read_only=True)
    
    class Meta:
        model = Message
        fields = ['id', 'content', 'user_id', 'user', 'user_name', 'created_at', 'is_read']
        read_only_fields = ['id', 'created_at']


class ConversationSerializer(serializers.ModelSerializer):
    participants = UserSerializer(many=True, read_only=True)
    messages = MessageSerializer(many=True, read_only=True)
    last_message = serializers.SerializerMethodField()
    
    class Meta:
        model = Conversation
        fields = ['id', 'name', 'is_group', 'participants', 'messages', 'last_message', 'created_at', 'updated_at']
        read_only_fields = ['id', 'created_at', 'updated_at']
    
    def get_last_message(self, obj):
        """Retourner le dernier message de la conversation"""
        last_msg = obj.messages.last()
        if last_msg:
            return MessageSerializer(last_msg).data
        return None


class ConversationListSerializer(serializers.ModelSerializer):
    """Sérialiser pour la liste des conversations (moins de données)"""
    participants = UserSerializer(many=True, read_only=True)
    last_message_content = serializers.SerializerMethodField()
    last_message_time = serializers.SerializerMethodField()
    
    class Meta:
        model = Conversation
        fields = ['id', 'name', 'is_group', 'participants', 'last_message_content', 'last_message_time', 'updated_at']
    
    def get_last_message_content(self, obj):
        last_msg = obj.messages.last()
        return last_msg.content[:100] if last_msg else ''
    
    def get_last_message_time(self, obj):
        last_msg = obj.messages.last()
        return last_msg.created_at if last_msg else None
```

---

## FICHIER 7: chat/views.py (API REST - DRF)

```python
from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.shortcuts import get_object_or_404
from .models import Message, Conversation, UserStatus
from .serializers import (
    MessageSerializer, 
    ConversationSerializer, 
    ConversationListSerializer,
    UserStatusSerializer
)


class ConversationViewSet(viewsets.ModelViewSet):
    """API pour gérer les conversations"""
    serializer_class = ConversationSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        """Retourner seulement les conversations de l'utilisateur"""
        return Conversation.objects.filter(participants=self.request.user)
    
    def get_serializer_class(self):
        """Utiliser un serializer different pour la liste"""
        if self.action == 'list':
            return ConversationListSerializer
        return ConversationSerializer
    
    @action(detail=True, methods=['get'])
    def messages(self, request, pk=None):
        """
        GET /api/conversations/{id}/messages/
        Récupérer l'historique des messages
        """
        conversation = self.get_object()
        messages = conversation.messages.all().order_by('created_at')
        
        # Pagination
        limit = request.query_params.get('limit', 50)
        messages = messages[:int(limit)]
        
        serializer = MessageSerializer(messages, many=True)
        return Response(serializer.data)
    
    @action(detail=True, methods=['post'])
    def add_message(self, request, pk=None):
        """
        POST /api/conversations/{id}/add_message/
        Ajouter un message à une conversation
        """
        conversation = self.get_object()
        
        message = Message.objects.create(
            conversation=conversation,
            user=request.user,
            content=request.data.get('content')
        )
        
        serializer = MessageSerializer(message)
        return Response(serializer.data, status=status.HTTP_201_CREATED)
    
    @action(detail=False, methods=['post'])
    def create_or_get(self, request):
        """
        POST /api/conversations/create_or_get/
        Créer ou récupérer une conversation entre deux utilisateurs
        """
        other_user_id = request.data.get('other_user_id')
        
        # Chercher une conversation existante
        conversation = Conversation.objects.filter(
            participants=request.user,
            is_group=False
        ).filter(
            participants=other_user_id
        ).first()
        
        if not conversation:
            # Créer une nouvelle conversation
            conversation = Conversation.objects.create(is_group=False)
            conversation.participants.add(request.user, other_user_id)
        
        serializer = self.get_serializer(conversation)
        return Response(serializer.data)
    
    @action(detail=False, methods=['post'])
    def create_group(self, request):
        """
        POST /api/conversations/create_group/
        Créer une conversation de groupe
        """
        name = request.data.get('name')
        participant_ids = request.data.get('participant_ids', [])
        
        conversation = Conversation.objects.create(
            name=name,
            is_group=True
        )
        
        conversation.participants.add(request.user)
        conversation.participants.add(*participant_ids)
        
        serializer = self.get_serializer(conversation)
        return Response(serializer.data, status=status.HTTP_201_CREATED)


class MessageViewSet(viewsets.ModelViewSet):
    """API pour gérer les messages"""
    serializer_class = MessageSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        """Retourner seulement les messages des conversations de l'utilisateur"""
        return Message.objects.filter(
            conversation__participants=self.request.user
        )
    
    @action(detail=False, methods=['post'])
    def mark_as_read(self, request):
        """
        POST /api/messages/mark_as_read/
        Marquer les messages comme lus
        """
        conversation_id = request.data.get('conversation_id')
        
        Message.objects.filter(
            conversation_id=conversation_id
        ).exclude(
            user=request.user
        ).update(is_read=True)
        
        return Response({'status': 'messages marked as read'})


class UserStatusViewSet(viewsets.ReadOnlyModelViewSet):
    """API pour consulter le statut des utilisateurs"""
    serializer_class = UserStatusSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        """Retourner le statut de tous les utilisateurs"""
        return UserStatus.objects.all()
```

---

## FICHIER 8: chat/urls.py (URL Routing REST)

```python
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import views

router = DefaultRouter()
router.register(r'conversations', views.ConversationViewSet, basename='conversation')
router.register(r'messages', views.MessageViewSet, basename='message')
router.register(r'user-status', views.UserStatusViewSet, basename='user-status')

urlpatterns = [
    path('', include(router.urls)),
]
```

---

## FICHIER 9: chat/admin.py (Admin Django)

```python
from django.contrib import admin
from .models import Conversation, Message, UserStatus

@admin.register(Conversation)
class ConversationAdmin(admin.ModelAdmin):
    list_display = ('id', 'name', 'is_group', 'created_at', 'updated_at')
    list_filter = ('is_group', 'created_at')
    search_fields = ('name',)
    filter_horizontal = ('participants',)


@admin.register(Message)
class MessageAdmin(admin.ModelAdmin):
    list_display = ('id', 'user', 'conversation', 'content_preview', 'is_read', 'created_at')
    list_filter = ('is_read', 'created_at', 'conversation')
    search_fields = ('content', 'user__username')
    readonly_fields = ('created_at', 'updated_at')
    
    def content_preview(self, obj):
        return obj.content[:50] + '...' if len(obj.content) > 50 else obj.content
    content_preview.short_description = 'Content'


@admin.register(UserStatus)
class UserStatusAdmin(admin.ModelAdmin):
    list_display = ('user', 'is_online', 'last_seen')
    list_filter = ('is_online', 'last_seen')
    search_fields = ('user__username',)
    readonly_fields = ('last_seen',)
```

---

## FICHIER 10: chat/apps.py

```python
from django.apps import AppConfig

class ChatConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'chat'
    verbose_name = 'Chat & Messaging'
```

---

## ÉTAPES D'INSTALLATION FINALE

1. **Créer l'app Django:**
   ```bash
   python manage.py startapp chat
   ```

2. **Copier tous les fichiers** (models.py, views.py, etc.)

3. **Ajouter à votre projet urls.py:**
   ```python
   from django.urls import path, include
   
   urlpatterns = [
       path('api/', include('chat.urls')),
   ]
   ```

4. **Exécuter les migrations:**
   ```bash
   python manage.py makemigrations
   python manage.py migrate
   ```

5. **Créer un superutilisateur:**
   ```bash
   python manage.py createsuperuser
   ```

6. **Installer et démarrer Redis:**
   ```bash
   # Sur macOS:
   brew install redis
   redis-server
   
   # Sur Linux:
   sudo apt-get install redis-server
   redis-server
   ```

7. **Démarrer le serveur avec Daphne:**
   ```bash
   daphne -b 0.0.0.0 -p 8000 your_project.asgi:application
   
   # Ou avec manage.py:
   python manage.py runserver
   ```

---

## ENDPOINTS API REST

### 📝 CONVERSATIONS:
- `GET    /api/conversations/`                  → Lister toutes les conversations
- `POST   /api/conversations/`                  → Créer une conversation
- `GET    /api/conversations/{id}/`             → Détails d'une conversation
- `PUT    /api/conversations/{id}/`             → Modifier une conversation
- `DELETE /api/conversations/{id}/`             → Supprimer une conversation
- `GET    /api/conversations/{id}/messages/`    → Historique des messages
- `POST   /api/conversations/{id}/add_message/` → Ajouter un message
- `POST   /api/conversations/create_or_get/`    → Créer/Récupérer conversation 1-1
- `POST   /api/conversations/create_group/`     → Créer une conversation de groupe

### 💬 MESSAGES:
- `GET    /api/messages/`                       → Lister tous les messages
- `POST   /api/messages/`                       → Créer un message
- `GET    /api/messages/{id}/`                  → Détails d'un message
- `PUT    /api/messages/{id}/`                  → Modifier un message
- `DELETE /api/messages/{id}/`                  → Supprimer un message
- `POST   /api/messages/mark_as_read/`          → Marquer comme lu

### 👥 STATUT UTILISATEUR:
- `GET    /api/user-status/`                    → Lister les statuts
- `GET    /api/user-status/{id}/`               → Statut d'un utilisateur

---

## WEBSOCKET MESSAGES (Format JSON)

### 1. ENVOYER UN MESSAGE:
```json
{
    "type": "message",
    "content": "Bonjour, comment ça va?"
}
```

### 2. INDICATEUR DE FRAPPE:
```json
{
    "type": "typing",
    "is_typing": true
}
```

### 3. MARQUER COMME LU:
```json
{
    "type": "mark_read"
}
```

### 4. RÉPONDRE: NOUVEAU MESSAGE (Broadcast):
```json
{
    "type": "message",
    "data": {
        "id": 123,
        "content": "Bonjour, comment ça va?",
        "user_id": 1,
        "user_name": "Alice",
        "timestamp": "2025-02-04T14:30:00Z",
        "is_read": false
    }
}
```

### 5. RÉPONDRE: INDICATEUR DE FRAPPE:
```json
{
    "type": "typing",
    "user_id": 2,
    "user_name": "Bob",
    "is_typing": true
}
```

### 6. RÉPONDRE: STATUT UTILISATEUR:
```json
{
    "type": "status",
    "user_id": 1,
    "user_name": "Alice",
    "status": "online|offline"
}
```

---

## NOTES IMPORTANTES

### ✅ POINTS À VÉRIFIER:

1. Daphne doit être EN PREMIER dans INSTALLED_APPS
2. Redis doit être en cours d'exécution avant de démarrer le serveur
3. ASGI_APPLICATION doit pointer vers votre asgi.py
4. Les URL patterns WebSocket utilisent des nombres (conversation_id)
5. Les authentifications JWT doivent être configurées
6. CORS doit être configuré pour permettre les requêtes depuis Flutter

### ⚠️ CONFIGURATION LOCALE (Développement):

Pour développer localement sans Redis, vous pouvez utiliser:
```python
CHANNEL_LAYERS = {
    'default': {
        'BACKEND': 'channels.layers.InMemoryChannelLayer'
    }
}
```

Mais pour la production, utilisez Redis!

### 🔐 SÉCURITÉ:

- Toujours utiliser HTTPS/WSS en production
- Ajouter une authentification JWT/Token
- Valider les données côté serveur
- Limiter la taille des messages
- Implémenter un rate limiting

---

**Status**: ✅ Implémentation Complète et Prête
**Date**: 04 Février 2026
**Framework**: Django + Channels + DRF
