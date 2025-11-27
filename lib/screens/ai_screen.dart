import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:uuid/uuid.dart';
import '../constants.dart'; // Menggunakan style repo Anda
import '../models/chat_message.dart';
import '../services/gemini_service.dart';

class AiScreen extends StatefulWidget {
  const AiScreen({super.key});

  @override
  State<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends State<AiScreen> {
  late final GeminiService _geminiService; // Menggunakan late untuk inisialisasi
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final Uuid _uuid = const Uuid();
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Inisialisasi service
    try {
      _geminiService = GeminiService();
    } catch (e) {
      debugPrint("Error init Gemini: $e");
    }
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      },
    );
  }

  Future<void> _sendMessage() async {
    if (_textController.text.trim().isEmpty) return;

    final userMessageText = _textController.text;
    _textController.clear();
    // FocusScope.of(context).unfocus(); // Opsional: Tutup keyboard

    setState(() {
      _isLoading = true;
      // 1. Tambah pesan User
      _messages.add(ChatMessage(
        id: _uuid.v4(),
        text: userMessageText,
        isFromUser: true,
      ));
      _scrollDown();

      // 2. Tambah indikator typing AI
      _messages.add(ChatMessage(
        id: _uuid.v4(),
        text: '...',
        isFromUser: false,
        isTyping: true,
      ));
      _scrollDown();
    });

    try {
      final responseText = await _geminiService.sendMessage(userMessageText);
      
      if (!mounted) return;
      setState(() {
        // Hapus indikator typing
        _messages.removeWhere((msg) => msg.isTyping);
        // 3. Tambah respon AI
        _messages.add(ChatMessage(
          id: _uuid.v4(),
          text: responseText,
          isFromUser: false,
        ));
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.removeWhere((msg) => msg.isTyping);
        _messages.add(ChatMessage(
          id: _uuid.v4(),
          text: 'Maaf, koneksi bermasalah. Pastikan internet lancar dan API Key benar.',
          isFromUser: false,
          isError: true,
        ));
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        _scrollDown();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Style dari constants.dart Anda
    return Scaffold(
      backgroundColor: AppColors.background, // Hitam pekat (#121212)
      appBar: AppBar(
        title: const Text("ASISTEN MEKANIK"),
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // --- AREA CHAT LIST ---
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      return _buildMessageBubble(_messages[index]);
                    },
                  ),
          ),

          // --- INPUT BAR ---
          _buildInputBar(),
        ],
      ),
    );
  }

  // Widget tampilan kosong
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_awesome, size: 60, color: AppColors.primary.withOpacity(0.5)),
          const SizedBox(height: 10),
          const Text(
            "Tanya masalah motormu di sini!",
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  // Widget Bubble Chat (Diadaptasi ke Style AppColors)
  Widget _buildMessageBubble(ChatMessage message) {
    if (message.isTyping) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
          ),
          child: const SizedBox(
            width: 20, height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
          ),
        ),
      );
    }

    Color bubbleColor;
    Color textColor = Colors.white;

    if (message.isError) {
      bubbleColor = Colors.red.shade900;
    } else if (message.isFromUser) {
      bubbleColor = AppColors.primary; // Merah Honda (#D32F2F)
    } else {
      bubbleColor = AppColors.surface; // Abu Gelap (#1E1E1E)
    }

    return Align(
      alignment: message.isFromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: message.isFromUser ? const Radius.circular(18) : Radius.zero,
            bottomRight: message.isFromUser ? Radius.zero : const Radius.circular(18),
          ),
        ),
        child: MarkdownBody(
          data: message.text,
          selectable: true,
          styleSheet: MarkdownStyleSheet(
            p: TextStyle(color: textColor),
            strong: TextStyle(color: textColor, fontWeight: FontWeight.bold),
            code: const TextStyle(backgroundColor: Colors.black26, fontFamily: 'monospace'),
          ),
        ),
      ),
    );
  }

  // Widget Input Bar (Diadaptasi ke Style AppColors)
  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.surface, // Warna background input bar
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Ketik pertanyaan...',
                hintStyle: const TextStyle(color: AppColors.textSecondary),
                filled: true,
                fillColor: Colors.black12, // Lebih gelap dari surface
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1),
                ),
              ),
              onSubmitted: (_) => _isLoading ? null : _sendMessage(),
            ),
          ),
          const SizedBox(width: 10),
          CircleAvatar(
            backgroundColor: _isLoading ? Colors.grey : AppColors.primary,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: _isLoading ? null : _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}