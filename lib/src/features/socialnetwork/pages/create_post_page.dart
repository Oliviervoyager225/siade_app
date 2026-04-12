import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:siade2/src/providers/providers.dart';
import 'package:siade2/src/theme/theme.dart';
import 'package:siade2/src/features/socialnetwork/pages/page.dart';
import 'package:siade2/src/core/services/post_service.dart';
import 'package:siade2/src/core/services/storage_service.dart';
import 'package:siade2/src/core/services/story_service.dart';

class CreatePostScreen extends StatefulWidget {
  final bool initialStoryMode;
  CreatePostScreen({Key? key, this.initialStoryMode = false}) : super(key: key);

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _textController = TextEditingController();
  final PostService _postService = PostService();
  final StoryService _storyService = StoryService();
  final StorageService _storageService = StorageService();
  final ImagePicker _imagePicker = ImagePicker();
  
  bool isExpanded = false;
  bool isPublishing = false;
  bool _isStoryMode = false;
  List<File> selectedImages = [];

  @override
  void initState() {
    super.initState();
    _isStoryMode = widget.initialStoryMode;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _textController.dispose();
    super.dispose();
  }

  // ── Avatar helpers ──────────────────────────────────────────────
  static const List<Color> _letterColors = [
    Color(0xFF1565C0), Color(0xFF6A1B9A), Color(0xFF00838F), Color(0xFFAD1457),
    Color(0xFF2E7D32), Color(0xFFE65100), Color(0xFF4527A0), Color(0xFF00695C),
    Color(0xFFC62828), Color(0xFF37474F), Color(0xFFD84315), Color(0xFF1B5E20),
    Color(0xFF880E4F), Color(0xFF0D47A1), Color(0xFF4A148C), Color(0xFF006064),
    Color(0xFFBF360C), Color(0xFF1A237E), Color(0xFF558B2F), Color(0xFF827717),
    Color(0xFF4E342E), Color(0xFF01579B), Color(0xFF33691E), Color(0xFF6D4C41),
    Color(0xFF283593), Color(0xFF004D40),
  ];

  Color _avatarColor(String initial) {
    if (initial.isEmpty || initial == '?') return const Color(0xFF423B69);
    final idx = initial.toUpperCase().codeUnitAt(0) - 'A'.codeUnitAt(0);
    if (idx < 0 || idx >= _letterColors.length) return const Color(0xFF423B69);
    return _letterColors[idx];
  }
  String? _getPhotoUrl(Map<String, dynamic>? user) {
    final url = (user?['photoURL'] ?? user?['photo'] ?? '').toString().trim();
    return url.isNotEmpty ? url : null;
  }

  String _getInitial(Map<String, dynamic>? user) {
    if (user == null) return '?';
    final first = (user['first_name'] ?? '').toString().trim();
    if (first.isNotEmpty) return first[0].toUpperCase();
    final username = (user['username'] ?? user['name'] ?? '').toString().trim();
    if (username.isNotEmpty && !username.contains('@')) return username[0].toUpperCase();
    if (username.contains('@')) {
      final local = username.split('@').first;
      if (local.isNotEmpty) return local[0].toUpperCase();
    }
    return '?';
  }

  /// Sélectionner des images depuis la galerie
  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          selectedImages = images.map((xFile) => File(xFile.path)).toList();
        });
      }
    } catch (e) {
      _showSnackBar('Erreur lors de la sélection des images', isError: true);
    }
  }

  /// Prendre une photo avec la caméra
  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(source: ImageSource.camera);
      if (photo != null) {
        setState(() {
          selectedImages.add(File(photo.path));
        });
      }
    } catch (e) {
      _showSnackBar('Erreur lors de la capture photo', isError: true);
    }
  }

  /// Publier le post ou la story
  Future<void> _publishPost() async {
    if (_isStoryMode) { await _publishStory(); return; }
    print('\n🟢 [CreatePost] ========== DÉBUT PUBLICATION ==========');
    final text = _textController.text.trim();
    
    print('🟢 [CreatePost] Texte: "$text"');
    print('🟢 [CreatePost] Nombre d\'images: ${selectedImages.length}');
    
    if (text.isEmpty && selectedImages.isEmpty) {
      print('⚠️ [CreatePost] Aucun contenu à publier');
      _showSnackBar('Ajoutez du texte ou des images', isError: true);
      return;
    }

    setState(() => isPublishing = true);

    try {
      // 1. Upload des images vers Firebase Storage
      List<String> imageUrls = [];
      if (selectedImages.isNotEmpty) {
        print('🟢 [CreatePost] ÉTAPE 1: Upload de ${selectedImages.length} image(s)...');
        _showSnackBar('Upload des images...');
        
        try {
          imageUrls = await _storageService.uploadMultipleImages(selectedImages);
          print('✅ [CreatePost] Upload terminé! ${imageUrls.length} URL(s) reçue(s)');
          for (int i = 0; i < imageUrls.length; i++) {
            print('   [${i + 1}] ${imageUrls[i].substring(0, 50)}...');
          }
        } catch (uploadError) {
          print('❌ [CreatePost] Erreur upload: $uploadError');
          throw Exception('Erreur upload images: $uploadError');
        }
      } else {
        print('🟢 [CreatePost] Aucune image à uploader');
      }

      // 2. Créer le post dans Firestore
      print('\n🟢 [CreatePost] ÉTAPE 2: Création du post dans Firestore...');
      try {
        final postId = await _postService.createPost(
          postLegend: text,
          postImages: imageUrls,
        );
        
        print('🟢 [CreatePost] Réponse PostService: postId = $postId');

        if (postId != null) {
          print('✅ [CreatePost] ========== SUCCÈS! Post ID: $postId ==========\n');
          _showSnackBar('✅ Post publié avec succès!');
          Navigator.pop(context, true); // Retourner true pour rafraîchir le feed
        } else {
          print('❌ [CreatePost] PostService a retourné null');
          _showSnackBar('Erreur lors de la publication', isError: true);
        }
      } catch (firestoreError) {
        print('❌ [CreatePost] Erreur Firestore: $firestoreError');
        throw Exception('Erreur création post: $firestoreError');
      }
    } catch (e, stackTrace) {
      print('❌ [CreatePost] ========== ERREUR GLOBALE ==========');
      print('❌ [CreatePost] Message: $e');
      print('❌ [CreatePost] Type: ${e.runtimeType}');
      print('❌ [CreatePost] Stack: $stackTrace');
      _showSnackBar('Erreur: $e', isError: true);
    } finally {
      setState(() => isPublishing = false);
      print('🟢 [CreatePost] ========== FIN PUBLICATION ==========\n');
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Publier une story
  Future<void> _publishStory() async {
    final text = _textController.text.trim();
    if (text.isEmpty && selectedImages.isEmpty) {
      _showSnackBar('Ajoutez du texte ou une image pour votre story', isError: true);
      return;
    }
    setState(() => isPublishing = true);
    try {
      String imageUrl = '';
      if (selectedImages.isNotEmpty) {
        _showSnackBar('Upload de la story...');
        final urls = await _storageService.uploadMultipleImages([selectedImages.first]);
        if (urls.isNotEmpty) imageUrl = urls.first;
      }
      final userProvider = context.read<UserProvider>();
      final userData = userProvider.user;
      final firstName = (userData?['first_name'] ?? '').toString().trim();
      final lastName = (userData?['last_name'] ?? '').toString().trim();
      final name = firstName.isNotEmpty
          ? (lastName.isNotEmpty ? '$firstName $lastName' : firstName)
          : (userData?['username'] ?? '').toString();
      final avatar = (userData?['photoURL'] ?? userData?['photo'] ?? '').toString();
      final storyId = await _storyService.createStory(
        caption: text,
        imageUrl: imageUrl,
        userName: name,
        userAvatar: avatar,
      );
      if (storyId != null) {
        _showSnackBar('✅ Story publiée !');
        Navigator.pop(context, true);
      } else {
        _showSnackBar('Erreur lors de la publication', isError: true);
      }
    } catch (e) {
      _showSnackBar('Erreur: $e', isError: true);
    } finally {
      setState(() => isPublishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Scaffold(
      backgroundColor: isLight ? Colors.white : Color(0xFF0A0E27),
      appBar: AppBar(
        backgroundColor: isLight ? Colors.white : Color(0xFF0A0E27),
        elevation: 0,
        leading: TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text(
            'Annuler',
            style: TextStyle(
                color: isLight ? AppColors.primaryBlue : Colors.blue,
                fontSize: 14),
          ),
        ),
        leadingWidth: 80,
        title: Text(
          _isStoryMode ? 'STORY' : 'CRÉER',
          style: TextStyle(
            color: isLight ? Color(0xFF60438C) : Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: EdgeInsets.only(right: 15),
            child: ElevatedButton(
              onPressed: isPublishing ? null : _publishPost,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xffF62E8E),
                disabledBackgroundColor: Colors.grey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              ),
              child: isPublishing
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Publier',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(15),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: _avatarColor(_getInitial(context.read<UserProvider>().user)),
                  foregroundImage: _getPhotoUrl(context.watch<UserProvider>().user) != null
                      ? NetworkImage(_getPhotoUrl(context.watch<UserProvider>().user)!)
                      : null,
                  onForegroundImageError: _getPhotoUrl(context.watch<UserProvider>().user) != null
                      ? (_, __) {}
                      : null,
                  child: Text(
                    _getInitial(context.read<UserProvider>().user),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _textController,
                    focusNode: _focusNode,
                    maxLines: null,
                    style: TextStyle(
                        color: isLight ? Color(0xFF60438C) : Colors.white,
                        fontSize: 16),
                    decoration: InputDecoration(
                      hintText: 'Quoi de neuf?',
                      hintStyle: TextStyle(
                          color: isLight
                              ? Color(0xFF60438C).withValues(alpha: 0.6)
                              : Colors.white54,
                          fontSize: 16),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: EdgeInsets.only(left: 15, bottom: 15),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        isExpanded = !isExpanded;
                      });
                    },
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: isLight
                            ? Color(0xFF60438C).withValues(alpha: 0.5)
                            : Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: isLight
                                ? Color(0xFF60438C).withValues(alpha: 0.3)
                                : Colors.white30,
                            width: 1.5),
                      ),
                      child: Icon(isExpanded ? Icons.close : Icons.add,
                          color: Colors.white, size: 20),
                    ),
                  ),
                  if (isExpanded) ...[
                    SizedBox(width: 12),
                    Container(
                      height: 36,
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Color(0xFF60438C),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: _pickImages,
                            child: Icon(Icons.image_outlined,
                                color: Colors.white, size: 20),
                          ),
                          SizedBox(width: 16),
                          GestureDetector(
                            onTap: _takePhoto,
                            child: Icon(Icons.camera_alt_outlined,
                                color: Colors.white, size: 20),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Affichage des images sélectionnées
          if (selectedImages.isNotEmpty)
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(15),
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: selectedImages.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            selectedImages[index],
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedImages.removeAt(index);
                              });
                            },
                            child: Container(
                              padding: EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),

          if (selectedImages.isEmpty)
          Spacer(),

          Center(
            child: Container(
              margin: EdgeInsets.only(bottom: 15),
              padding: EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.transparent,
                border: Border.all(
                    color: isLight
                        ? Color(0xFF60438C).withValues(alpha: 0.3)
                        : Colors.white24,
                    width: 1.5),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _isStoryMode = false),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: !_isStoryMode
                            ? (isLight
                                ? LinearGradient(
                                    colors: [Color(0xFF60438C), Color(0xFF9E87CE)],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  )
                                : LinearGradient(
                                    colors: [Color(0xFF07026F), Color(0xFFA01E38)],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ))
                            : null,
                        color: _isStoryMode ? Colors.transparent : null,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'POST',
                        style: TextStyle(
                          color: _isStoryMode
                              ? (isLight
                                  ? Color(0xFF60438C).withValues(alpha: 0.6)
                                  : Colors.white70)
                              : Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 5),
                  GestureDetector(
                    onTap: () => setState(() => _isStoryMode = true),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        gradient: _isStoryMode
                            ? LinearGradient(
                                colors: [Color(0xFF4A148C), Color(0xFF9E87CE)],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              )
                            : null,
                        color: _isStoryMode ? null : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'STORY',
                        style: TextStyle(
                          color: _isStoryMode
                              ? Colors.white
                              : (isLight
                                  ? Color(0xFF60438C).withValues(alpha: 0.6)
                                  : Colors.white70),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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
}
