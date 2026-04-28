import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class AiScreen extends StatefulWidget {
  const AiScreen({super.key});

  @override
  State<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends State<AiScreen> {
  // API Key จากเว็บ Google AI Studio
  final String _apiKey = 'AIzaSyBXEPyN2Q2L5HNv_Wqq1Mmb-wmyFM5yJjk'; 

  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  late final GenerativeModel _model;
  late final ChatSession _chat;
  
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;

@override
  void initState() {
    super.initState();
    
    _model = GenerativeModel(
      model: 'gemini-3-flash-preview',
      apiKey: _apiKey,
    );
    
    // Setting AI Role
    _chat = _model.startChat(history: [
      Content.text('ต่อจากนี้คุณคือช่างผู้เชี่ยวชาญประจำแอป UTCC Campus SOS คอยให้คำปรึกษาเรื่องรถเสีย แบตหมด ยางรั่ว ให้คำแนะนำเบื้องต้นที่ปลอดภัยและเข้าใจง่าย ตอบเป็นภาษาไทยด้วยความสุภาพและเป็นกันเอง ห้ามหลุดบทบาทนี้เด็ดขาด'),
      Content.model([TextPart('รับทราบครับ ผมจะทำหน้าที่เป็นช่างผู้เชี่ยวชาญประจำแอป UTCC Campus SOS อย่างดีที่สุดครับ')])
    ]);
    
    // ข้อความต้อนรับบนหน้าจอ
    _messages.add({
      'role': 'ai',
      'text': 'สวัสดีครับ! ผมคือผู้ช่วย AI จาก UTCCCampus SOS รถมีปัญหาหรืออาการเป็นยังไงเล่าให้ผมฟังเบื้องต้นก่อนได้เลยครับ'
    });
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    // 1. เอาข้อความผู้ใช้แสดงบนจอ
    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _isLoading = true;
    });
    _textController.clear();
    _scrollToBottom();

    try {
      // ส่งข้อความไปหา Gemini
      final response = await _chat.sendMessage(Content.text(text));
      
      // เอาคำตอบจาก AI มาแสดง
      setState(() {
        _messages.add({'role': 'ai', 'text': response.text ?? 'ขออภัยครับ ผมไม่เข้าใจคำถาม'});
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      debugPrint('Error: $e');

      setState(() {
        _messages.add({'role': 'ai', 'text': 'เกิดข้อผิดพลาดในการเชื่อมต่อเครือข่ายครับ'});
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1828),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('AI Assistant', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // พื้นที่แสดงข้อความแชท
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isUser = message['role'] == 'user';
                return _buildChatBubble(message['text'], isUser);
              },
            ),
          ),
          
          // โชว์จุดโหลดตอน AI กำลังคิด
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(color: Colors.blueAccent),
            ),
            
          // ช่องพิมพ์ข้อความถาม AI
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildChatBubble(String text, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isUser ? Colors.blueAccent : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 0),
            bottomRight: Radius.circular(isUser ? 0 : 16),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(color: Colors.white, fontSize: 15),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1828),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.2), offset: const Offset(0, -2), blurRadius: 10),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'พิมพ์สอบถามอาการรถ...',
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.1),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle),
              child: const Icon(Icons.send, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}