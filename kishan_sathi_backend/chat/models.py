from django.db import models
from django.utils import timezone
from Users.models import User


class ChatRoom(models.Model):
    """
    Represents a 1-to-1 chat room between two users.
    Uses participant_one / participant_two ForeignKeys for efficient lookups,
    while keeping the M2M ``participants`` for backward compatibility with
    existing REST views and serializers.
    """
    participant_one = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='chat_rooms_as_one',
        null=True,
        blank=True,
    )
    participant_two = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='chat_rooms_as_two',
        null=True,
        blank=True,
    )

    # Kept for backward compatibility with existing REST views/serializers
    participants = models.ManyToManyField(User, related_name='chat_rooms', blank=True)

    last_message_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-updated_at']

    def __str__(self):
        p1 = self.participant_one.full_name if self.participant_one else '?'
        p2 = self.participant_two.full_name if self.participant_two else '?'
        return f"ChatRoom {self.pk}: {p1} \u2194 {p2}"

    # ---- Convenience alias matching the spec ----
    @property
    def chat_room_id(self):
        return self.pk

    # ---- Core helper used by the WebSocket consumer ----
    def is_participant(self, user) -> bool:
        """Return True if *user* is one of the two FK participants OR in M2M."""
        # Check FKs first (fast)
        if self.participant_one_id and self.participant_two_id:
            return user.pk in (self.participant_one_id, self.participant_two_id)
        # Fallback to M2M for rooms created before migration
        return self.participants.filter(pk=user.pk).exists()

    @property
    def last_message(self):
        return self.messages.order_by('-timestamp').first()

    def save(self, *args, **kwargs):
        """Ensure participant_one.pk < participant_two.pk for consistency."""
        if (
            self.participant_one_id
            and self.participant_two_id
            and self.participant_one_id > self.participant_two_id
        ):
            self.participant_one_id, self.participant_two_id = (
                self.participant_two_id,
                self.participant_one_id,
            )
        super().save(*args, **kwargs)


class Message(models.Model):
    """
    A single message inside a ChatRoom.
    """
    MESSAGE_TYPE_CHOICES = [
        ('text', 'Text'),
        ('image', 'Image'),
        ('file', 'File'),
    ]

    chat_room = models.ForeignKey(
        ChatRoom,
        on_delete=models.CASCADE,
        related_name='messages',
    )
    sender = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='sent_messages',
    )
    content = models.TextField(blank=True, default='')
    message_type = models.CharField(
        max_length=10,
        choices=MESSAGE_TYPE_CHOICES,
        default='text',
    )
    image = models.ImageField(upload_to='chat_images/', blank=True, null=True)
    is_read = models.BooleanField(default=False)
    read_at = models.DateTimeField(null=True, blank=True)
    timestamp = models.DateTimeField(auto_now_add=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['timestamp']

    # ---- Convenience alias matching the spec ----
    @property
    def message_id(self):
        return self.pk

    def __str__(self):
        preview = (self.content or '')[:50]
        return f"{self.sender.full_name}: {preview}"
