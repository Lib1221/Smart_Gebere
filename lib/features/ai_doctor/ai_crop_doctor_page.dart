import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:smart_gebere/settings/app_settings.dart';
import 'package:smart_gebere/l10n/app_localizations.dart';

class AICropDoctorPage extends StatefulWidget {
  const AICropDoctorPage({super.key});

  @override
  State<AICropDoctorPage> createState() => _AICropDoctorPageState();
}

class _AICropDoctorPageState extends State<AICropDoctorPage>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  GenerativeModel? _model;
  ChatSession? _chatSession;
  final ImagePicker _picker = ImagePicker();

  // Quick suggestion prompts - context-aware for Ethiopian farming
  final List<Map<String, dynamic>> _quickPrompts = [
    {'icon': '🌿', 'text': 'My teff leaves are turning yellow, what should I do?'},
    {'icon': '🐛', 'text': 'How do I control stem borers organically?'},
    {'icon': '💧', 'text': 'Best irrigation schedule for Ethiopian highlands'},
    {'icon': '🌱', 'text': 'When is the best time to plant wheat in Ethiopia?'},
    {'icon': '🧪', 'text': 'How to improve clay soil fertility naturally?'},
    {'icon': '🌾', 'text': 'Signs of nitrogen deficiency in maize'},
    {'icon': '☕', 'text': 'How to prevent coffee berry disease?'},
    {'icon': '🌽', 'text': 'Optimal spacing for sorghum planting'},
  ];

  // Strong system instruction for Gemini
  static const String _systemPrompt = '''
You are **Dr. Gebere**, an expert AI agricultural advisor and crop doctor specifically trained for Ethiopian farmers. You have deep expertise in:

## Your Expertise Areas:
1. **Ethiopian Crops**: Teff, wheat, barley, maize, sorghum, finger millet, coffee, enset (false banana), noug, chickpea, lentils, faba beans, field pea, sesame, cotton, sugarcane
2. **Ethiopian Climate Zones**: Highland (Dega), Mid-altitude (Woina Dega), Lowland (Kolla), and their specific agricultural conditions
3. **Traditional & Modern Practices**: Both indigenous Ethiopian farming knowledge and modern sustainable agriculture
4. **Disease Diagnosis**: Plant pathology, pest identification, and integrated pest management
5. **Soil Management**: Ethiopian soil types, fertility management, composting, crop rotation

## Response Guidelines:

### When Answering Questions:
- Be **specific and actionable** - farmers need practical steps they can take today
- Consider **Ethiopian context**: local availability of inputs, economic constraints, seasonal patterns (Kiremt/Meher, Belg)
- Suggest **locally available solutions** before imported alternatives
- Include **prevention strategies** not just treatments
- Mention when to consult **local agricultural extension officers** (Development Agents)
- Be **encouraging and supportive** - farming is challenging work

### For Disease/Pest Diagnosis:
1. Ask clarifying questions if needed (what crop, symptoms, when started, weather conditions)
2. Provide **most likely diagnosis** with confidence level
3. Explain **symptoms to look for** to confirm
4. Give **immediate action steps**
5. Recommend **prevention for future**
6. Warn about **similar-looking conditions** to rule out

### For Image Analysis:
1. Describe what you observe in the plant/crop
2. Identify the crop type if possible
3. Note any visible issues (discoloration, spots, wilting, pest damage, nutrient deficiency)
4. Provide diagnosis with confidence level (high/medium/low)
5. Give treatment recommendations
6. Suggest prevention measures

### Format Guidelines:
- Use **bullet points** for action steps
- Use **emojis** sparingly for visual clarity (✅ for recommendations, ⚠️ for warnings)
- Keep responses **concise but complete** (aim for 150-300 words unless more detail requested)
- Use **simple language** that translates well

### Important Reminders:
- If you're not confident, say so and recommend professional consultation
- Never recommend banned or dangerous pesticides
- Promote **sustainable and organic practices** when possible
- Consider **economic constraints** of smallholder farmers
- Be culturally sensitive and respectful

You are a trusted advisor helping Ethiopian farmers succeed. Your guidance directly impacts food security and livelihoods.
''';

  @override
  void initState() {
    super.initState();
    _initializeAI();
    _addWelcomeMessage();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addWelcomeMessage() {
    // Welcome message is in English to be universally understood on first load
    _messages.add(ChatMessage(
      text: '''👋 **Selam! I'm Dr. Gebere, your AI Crop Doctor.**

I'm here to help Ethiopian farmers with all agricultural questions. I specialize in:

• 🌾 **Ethiopian Crops**: Teff, wheat, maize, coffee, enset & more
• 🔬 **Disease Diagnosis**: Send photos or describe symptoms
• 🐛 **Pest Control**: Organic & sustainable solutions
• 🌱 **Planting Advice**: When & how to plant
• 🧪 **Soil & Fertilizer**: Improve your land's fertility
• 💧 **Irrigation**: Water management tips

**Tip**: You can send me a photo of your plant for diagnosis! 📸

How can I help you today?''',
      isUser: false,
      timestamp: DateTime.now(),
    ));
  }

  Future<void> _initializeAI() async {
    try {
      // Try multiple API key environment variable names
      String apiKey = dotenv.env['GEMINI_API_KEY'] ?? 
                      dotenv.env['API_KEY'] ?? 
                      dotenv.env['GOOGLE_API_KEY'] ?? '';
      
      if (apiKey.isEmpty) {
        debugPrint('[AICropDoctor] No API key found in environment');
        _showError('AI service not configured. Please check your API key.');
        return;
      }

      // Prefer the latest model for best performance
      final modelName = dotenv.env['GEMINI_MODEL'] ?? 'gemini-1.5-flash';
      
      _model = GenerativeModel(
        model: modelName,
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.7,
          topK: 40,
          topP: 0.95,
          maxOutputTokens: 2048,
        ),
        systemInstruction: Content.text(_systemPrompt),
        safetySettings: [
          SafetySetting(HarmCategory.harassment, HarmBlockThreshold.high),
          SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.high),
          SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.high),
          SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.medium),
        ],
      );

      _chatSession = _model!.startChat();
      debugPrint('[AICropDoctor] AI initialized successfully with model: $modelName');
    } catch (e) {
      debugPrint('[AICropDoctor] Error initializing AI: $e');
      _showError('Failed to initialize AI. Please check your connection.');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _sendMessage(String text, {XFile? image}) async {
    if (text.trim().isEmpty && image == null) return;
    if (_isLoading) return;
    if (_model == null) {
      _showError('AI service is not ready. Please wait...');
      await _initializeAI();
      return;
    }

    final settings = Provider.of<AppSettings>(context, listen: false);
    final language = settings.aiLanguageName();

    // Add user message
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
        imageFile: image,
      ));
      _isLoading = true;
    });

    _messageController.clear();
    _scrollToBottom();

    try {
      String response;
      
      if (image != null) {
        // Enhanced image-based diagnosis with strong prompt
        final bytes = await image.readAsBytes();
        final prompt = '''
## Image Analysis Request

**User's Question**: ${text.isNotEmpty ? text : 'Please analyze this plant and tell me if there are any problems.'}

**Instructions for Analysis**:
1. First, identify what you can see (plant type, growth stage, overall health)
2. Look for any abnormalities:
   - Leaf discoloration (yellowing, browning, spots)
   - Wilting or drooping
   - Pest presence or damage signs
   - Disease symptoms (lesions, mold, decay)
   - Nutrient deficiency indicators
3. Provide diagnosis with confidence level
4. Give specific, actionable treatment recommendations
5. Include prevention tips for the future

**Important**: 
- Be specific about what you observe
- If the image is unclear, ask for a better photo
- Consider Ethiopian farming context
- Suggest locally available solutions

Please respond in **$language**.
''';
        
        final content = [
          Content.multi([
            TextPart(prompt),
            DataPart('image/jpeg', bytes),
          ])
        ];
        
        final result = await _model!.generateContent(content);
        response = result.text ?? 'I could not analyze the image. Please try again with a clearer photo.';
      } else {
        // Enhanced text-based query with context
        final enhancedPrompt = '''
**Farmer's Question**: $text

**Context**: This question is from an Ethiopian farmer seeking practical agricultural advice.

**Instructions**:
- Provide specific, actionable advice
- Consider Ethiopian climate, soil, and available resources
- Suggest locally available solutions
- Include both immediate actions and long-term recommendations
- Be encouraging and supportive

Please respond in **$language**.
''';
        
        final result = await _chatSession!.sendMessage(Content.text(enhancedPrompt));
        response = result.text ?? 'I could not process your request. Please try again.';
      }

      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            text: response,
            isUser: false,
            timestamp: DateTime.now(),
          ));
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('[AICropDoctor] Error: $e');
      
      String errorMessage = 'Sorry, I encountered an error.';
      final errorStr = e.toString().toLowerCase();
      
      if (errorStr.contains('network') || errorStr.contains('connection')) {
        errorMessage = '📶 No internet connection. Please check your network and try again.';
      } else if (errorStr.contains('quota') || errorStr.contains('limit')) {
        errorMessage = '⚠️ Service temporarily unavailable. Please try again later.';
      } else if (errorStr.contains('not found') || errorStr.contains('not supported')) {
        // Try fallback model
        await _tryFallbackModel();
        return;
      } else {
        errorMessage = '❌ Something went wrong. Please try again or rephrase your question.';
      }
      
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            text: errorMessage,
            isUser: false,
            timestamp: DateTime.now(),
            isError: true,
          ));
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _tryFallbackModel() async {
    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'] ?? 
                     dotenv.env['API_KEY'] ?? '';
      
      _model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.7,
          maxOutputTokens: 2048,
        ),
        systemInstruction: Content.text(_systemPrompt),
      );
      
      _chatSession = _model!.startChat();
      
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            text: '🔄 Reconnected to AI service. Please try your question again.',
            isUser: false,
            timestamp: DateTime.now(),
          ));
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[AICropDoctor] Fallback failed: $e');
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            text: '❌ AI service unavailable. Please try again later.',
            isUser: false,
            timestamp: DateTime.now(),
            isError: true,
          ));
          _isLoading = false;
        });
      }
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

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        _sendMessage(_messageController.text, image: image);
      }
    } catch (e) {
      debugPrint('[AICropDoctor] Image picker error: $e');
      _showError('Could not access camera/gallery. Please check permissions.');
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '📸 Add Photo for Diagnosis',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Take a close-up photo of the affected plant part',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildImageSourceOption(
                  icon: Icons.camera_alt,
                  label: 'Camera',
                  color: const Color(0xFF4CAF50),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                _buildImageSourceOption(
                  icon: Icons.photo_library,
                  label: 'Gallery',
                  color: const Color(0xFF2196F3),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSourceOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('🩺', style: TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dr. Gebere - AI Crop Doctor',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _model != null ? Colors.greenAccent : Colors.orange,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _model != null ? 'Online' : 'Connecting...',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'New Conversation',
            onPressed: () {
              setState(() {
                _messages.clear();
                _addWelcomeMessage();
                _chatSession = _model?.startChat();
              });
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'tips') {
                _showTipsDialog();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'tips',
                child: Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: Colors.amber),
                    SizedBox(width: 8),
                    Text('Tips for Better Diagnosis'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isLoading) {
                  return _buildTypingIndicator();
                }
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),

          // Quick prompts (show only if minimal messages)
          if (_messages.length <= 1)
            Container(
              height: 50,
              margin: const EdgeInsets.only(bottom: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _quickPrompts.length,
                itemBuilder: (context, index) {
                  final prompt = _quickPrompts[index];
                  final promptText = prompt['text'] as String? ?? '';
                  final promptIcon = prompt['icon'] as String? ?? '💬';
                  return GestureDetector(
                    onTap: () => _sendMessage(promptText),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF4CAF50).withAlpha(77)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(13),
                            blurRadius: 5,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(promptIcon, style: const TextStyle(fontSize: 16)),
                          const SizedBox(width: 6),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 200),
                            child: Text(
                              promptText,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey[700],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

          // Input area
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // Image button
                  GestureDetector(
                    onTap: _showImageSourceDialog,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Color(0xFF4CAF50),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Text input
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Ask about your crops...',
                          hintStyle: GoogleFonts.poppins(
                            color: Colors.grey[500],
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                        ),
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                        onSubmitted: (text) => _sendMessage(text),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Send button
                  GestureDetector(
                    onTap: () => _sendMessage(_messageController.text),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4CAF50).withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.send, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showTipsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Text('💡', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Text(
              'Tips for Better Results',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTip('📸', 'For photos, take close-up shots of affected areas'),
              _buildTip('🌡️', 'Mention your location and current weather'),
              _buildTip('📅', 'Tell me when the problem started'),
              _buildTip('🌱', 'Specify the crop type and growth stage'),
              _buildTip('💊', 'List any treatments you\'ve already tried'),
              _buildTip('📍', 'Describe if the problem is widespread or localized'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Got it!',
              style: GoogleFonts.poppins(
                color: const Color(0xFF2E7D32),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTip(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        child: Column(
          crossAxisAlignment:
              message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Image if present
            if (message.imageFile != null)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: kIsWeb
                      ? Image.network(
                          message.imageFile!.path,
                          height: 180,
                          fit: BoxFit.cover,
                        )
                      : Image.file(
                          File(message.imageFile!.path),
                          height: 180,
                          fit: BoxFit.cover,
                        ),
                ),
              ),
            // Message bubble
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: message.isUser
                    ? const Color(0xFF2E7D32)
                    : message.isError
                        ? Colors.red[50]
                        : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(message.isUser ? 18 : 4),
                  bottomRight: Radius.circular(message.isUser ? 4 : 18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: SelectableText(
                message.text,
                style: GoogleFonts.poppins(
                  color: message.isUser
                      ? Colors.white
                      : message.isError
                          ? Colors.red[700]
                          : Colors.grey[800],
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
            // Timestamp
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
              child: Text(
                _formatTime(message.timestamp),
                style: GoogleFonts.poppins(
                  color: Colors.grey[500],
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '🩺',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(width: 8),
            Text(
              'Analyzing',
              style: GoogleFonts.poppins(
                color: Colors.grey[600],
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 4),
            _buildDot(0),
            const SizedBox(width: 4),
            _buildDot(1),
            const SizedBox(width: 4),
            _buildDot(2),
          ],
        ),
      ),
    );
  }

  Widget _buildDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + (index * 200)),
      builder: (context, value, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: const Color(0xFF4CAF50).withOpacity(0.3 + (0.7 * value)),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final XFile? imageFile;
  final bool isError;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.imageFile,
    this.isError = false,
  });
}
