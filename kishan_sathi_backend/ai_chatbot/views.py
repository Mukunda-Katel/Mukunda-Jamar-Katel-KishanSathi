from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status
import requests
import json
from decouple import config
from .models import ChatMessage
from .serializers import ChatMessageSerializer


def _extract_provider_error_details(response):
    """Return the most helpful upstream error detail available."""
    try:
        payload = response.json()
        error_obj = payload.get('error', {}) if isinstance(payload, dict) else {}
        metadata = error_obj.get('metadata', {}) if isinstance(error_obj, dict) else {}
        raw_message = metadata.get('raw') if isinstance(metadata, dict) else None
        if raw_message:
            return str(raw_message)

        message = error_obj.get('message') if isinstance(error_obj, dict) else None
        if message:
            return str(message)

        return str(payload)
    except Exception:
        return response.text


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
        
        primary_model = config('OPENROUTER_MODEL', default='google/gemma-3-4b-it:free').strip()
        fallback_models_raw = config('OPENROUTER_FALLBACK_MODELS', default='').strip()
        fallback_models = [
            model_name.strip() for model_name in fallback_models_raw.split(',') if model_name.strip()
        ]

        model_candidates = [primary_model]
        for fallback_model in fallback_models:
            if fallback_model not in model_candidates:
                model_candidates.append(fallback_model)

        last_rate_limit_details = None
        rate_limited_models = []

        for selected_model in model_candidates:
            response = requests.post(
                url="https://openrouter.ai/api/v1/chat/completions",
                headers={
                    "Authorization": f"Bearer {api_key}",
                    "Content-Type": "application/json",
                    "HTTP-Referer": "https://kisansathi.app",
                    "X-Title": "Kishan Sathi",
                },
                data=json.dumps({
                    "model": selected_model,
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
                    'model_used': selected_model,
                    'success': True
                }, status=status.HTTP_200_OK)

            details = _extract_provider_error_details(response)

            if response.status_code == 429:
                last_rate_limit_details = details
                rate_limited_models.append(selected_model)
                continue

            if response.status_code == 401:
                return Response({
                    'error': 'AI provider authentication failed. Please verify OPENROUTER_API_KEY.',
                    'details': details,
                    'success': False
                }, status=status.HTTP_502_BAD_GATEWAY)

            return Response({
                'error': f'AI API error: {response.status_code}',
                'details': details,
                'model_used': selected_model,
                'success': False
            }, status=status.HTTP_502_BAD_GATEWAY)

        if rate_limited_models:
            return Response({
                'error': 'AI provider rate limit exceeded. Please retry shortly.',
                'details': last_rate_limit_details,
                'rate_limited_models': rate_limited_models,
                'retry_after_seconds': 60,
                'success': False
            }, status=status.HTTP_429_TOO_MANY_REQUESTS)

        return Response({
            'error': 'AI service unavailable. No response from provider.',
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
