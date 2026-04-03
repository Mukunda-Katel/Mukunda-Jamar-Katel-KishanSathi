from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status
import requests
import json
from decouple import config
from .models import ChatMessage
from .serializers import ChatMessageSerializer


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def chat_with_ai(request):
    """
    AI Chatbot endpoint using OpenRouter API with Google Gemma 3 4B (free) model.
    
    Expects JSON body:
    {
        "message": "User's question",
        "conversation_history": [
            {"role": "user", "content": "previous message"},
            {"role": "assistant", "content": "previous response"}
        ]
    }
    """
    try:
        message = request.data.get('message')
        conversation_history = request.data.get('conversation_history', [])
        
        if not message:
            return Response(
                {'error': 'Message is required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Get API key from environment variable.
        api_key = config('OPENROUTER_API_KEY', default='').strip()
        if not api_key:
            return Response({
                'error': 'AI service is not configured. Missing OPENROUTER_API_KEY.',
                'success': False
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
        
        # System prompt for farming assistant 
        system_context = '''You are an expert agricultural AI assistant for Kishan Sathi, a farming support platform. 
Your role is to help farmers with:
- Crop cultivation advice and best practices
- Pest and disease management
- Soil health and fertilizer recommendations
- Weather-based farming tips
- Market price information and selling strategies
- Government schemes and subsidies for farmers
- Irrigation and water management
- Organic farming techniques
- Seasonal crop planning

Always provide practical, actionable advice in simple language. Be encouraging and supportive. 
If the question is not related to farming, politely redirect to agricultural topics.
You can respond in English or Nepali based on the user's language.

'''
        
        
        messages = []
        
        # If this is the first message, prepend system context
        if not conversation_history:
            messages.append({
                'role': 'user',
                'content': system_context + message
            })
        else:
            messages = [*conversation_history, {
                'role': 'user',
                'content': message
            }]
        
        # Call OpenRouter API
        response = requests.post(
            url="https://openrouter.ai/api/v1/chat/completions",
            headers={
                "Authorization": f"Bearer {api_key}",
                "Content-Type": "application/json",
                "HTTP-Referer": "https://kisansathi.app",
                "X-Title": "Kishan Sathi",
            },
            data=json.dumps({
                "model": "google/gemma-3-4b-it:free",
                "messages": messages,
                "temperature": 0.7,
                "max_tokens": 1000,
            }),
            timeout=30
        )
        
        if response.status_code == 200:
            data = response.json()
            ai_response = data['choices'][0]['message']['content']
            
            # Save chat message to database
            try:
                ChatMessage.objects.create(
                    user=request.user,
                    message=message,
                    response=ai_response
                )
            except Exception as save_error:
                print(f"Error saving chat message: {save_error}")
                # Continue even if save fails
            
            return Response({
                'response': ai_response,
                'success': True
            }, status=status.HTTP_200_OK)
        else:
            details = response.text
            try:
                error_payload = response.json()
                details = error_payload.get('error', {}).get('message') or response.text
            except Exception:
                pass

            if response.status_code == 401:
                return Response({
                    'error': 'AI provider authentication failed. Please verify OPENROUTER_API_KEY.',
                    'details': details,
                    'success': False
                }, status=status.HTTP_502_BAD_GATEWAY)

            if response.status_code == 429:
                return Response({
                    'error': 'AI provider rate limit exceeded. Please try again later.',
                    'details': details,
                    'success': False
                }, status=status.HTTP_503_SERVICE_UNAVAILABLE)

            return Response({
                'error': f'AI API error: {response.status_code}',
                'details': details,
                'success': False
            }, status=status.HTTP_502_BAD_GATEWAY)
            
    except requests.exceptions.Timeout:
        return Response({
            'error': 'Request timeout. Please try again.',
            'success': False
        }, status=status.HTTP_408_REQUEST_TIMEOUT)
        
    except Exception as e:
        return Response({
            'error': str(e),
            'success': False
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_chat_history(request):
    """
    Get chat history for the authenticated user.
    Optional query parameter: limit (default: 50)
    """
    try:
        limit = int(request.GET.get('limit', 50))
        
        # Get user's chat messages
        chat_messages = ChatMessage.objects.filter(user=request.user).order_by('-created_at')[:limit]
        
        # Serialize and return
        serializer = ChatMessageSerializer(chat_messages, many=True)
        
        return Response({
            'messages': serializer.data,
            'success': True
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        return Response({
            'error': str(e),
            'success': False
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['DELETE'])
@permission_classes([IsAuthenticated])
def clear_chat_history(request):
    """
    Clear all chat history for the authenticated user.
    """
    try:
        deleted_count = ChatMessage.objects.filter(user=request.user).delete()[0]
        
        return Response({
            'message': f'Deleted {deleted_count} messages',
            'success': True
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        return Response({
            'error': str(e),
            'success': False
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
