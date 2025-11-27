class ChatMessage {
  final String id;
  final String text;
  final bool isFromUser;
  final bool isTyping; // Untuk loading state
  final bool isError;  // Untuk error state

  ChatMessage({
    required this.id,
    required this.text,
    required this.isFromUser,
    this.isTyping = false,
    this.isError = false,
  });
}