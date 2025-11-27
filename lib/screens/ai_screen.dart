import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:uuid/uuid.dart';
import '../constants.dart';
import '../models/chat_message.dart';
import '../services/gemini_service.dart';

class AiScreen extends StatefulWidget {
  const AiScreen({super.key});

  @override
  State<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends State<AiScreen> {
  // Ubah menjadi nullable agar bisa dicek apakah sudah init atau belum
  GeminiService? _geminiService; 
  
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final Uuid _uuid = const Uuid();
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initGemini();
  }

  // Fungsi terpisah untuk inisialisasi agar lebih rapi
  void _initGemini() {
    try {
      _geminiService = GeminiService();
    } catch (e) {
      debugPrint("Error init Gemini: $e");
      // Tampilkan error ke chat jika inisialisasi gagal (misal .env hilang)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _messages.add(ChatMessage(
              id: _uuid.v4(),
              text: "Gagal memuat sistem AI: $e. Pastikan file .env sudah benar.",
              isFromUser: false,
              isError: true,
            ));
          });
        }
      });
    }
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    if (_textController.text.trim().isEmpty) return;

    // Cek apakah service sudah siap
    if (_geminiService == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("AI belum siap. Cek koneksi atau restart aplikasi.")),
      );
      return;
    }

    final userMessageText = _textController.text;
    _textController.clear();

    setState(() {
      _isLoading = true;
      // 1. Pesan User
      _messages.add(ChatMessage(
        id: _uuid.v4(),
        text: userMessageText,
        isFromUser: true,
      ));
      _scrollDown();

      // 2. Indikator Typing
      _messages.add(ChatMessage(
        id: _uuid.v4(),
        text: '...',
        isFromUser: false,
        isTyping: true,
      ));
      _scrollDown();
    });

    try {
      // Gunakan service yang sudah dicek null-nya
      final responseText = await _geminiService!.sendMessage(userMessageText);
      
      if (!mounted) return;
      setState(() {
        _messages.removeWhere((msg) => msg.isTyping);
        // 3. Respon AI Sukses
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
        
        // --- PERBAIKAN PENTING DI SINI ---
        // Tampilkan pesan error ASLI dari service agar kita tahu masalahnya
        // Hapus tulisan "Exception:" agar lebih bersih
        final errorMessage = e.toString().replaceAll("Exception: ", "");
        
        _messages.add(ChatMessage(
          id: _uuid.v4(),
          text: errorMessage, // Tampilkan error spesifik (misal: API Key Invalid)
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("ASISTEN MEKANIK"),
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
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
          _buildInputBar(),
        ],
      ),
    );
  }

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
      bubbleColor = AppColors.primary;
    } else {
      bubbleColor = AppColors.surface;
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

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.surface,
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
                fillColor: Colors.black12,
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