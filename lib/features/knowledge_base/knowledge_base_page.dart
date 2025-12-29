import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/models/knowledge_article.dart';
import '../../core/services/offline_storage.dart';
import '../../core/services/connectivity_service.dart';
import '../../settings/app_settings.dart';
import '../../l10n/app_localizations.dart';

class KnowledgeBasePage extends StatefulWidget {
  const KnowledgeBasePage({super.key});

  @override
  State<KnowledgeBasePage> createState() => _KnowledgeBasePageState();
}

class _KnowledgeBasePageState extends State<KnowledgeBasePage> {
  List<KnowledgeArticle> _articles = [];
  bool _isLoading = true;
  ArticleCategory? _selectedCategory;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadArticles();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadArticles() async {
    setState(() => _isLoading = true);

    // Load from local cache first
    final cachedArticles = OfflineStorage.getAllKnowledgeArticles();
    if (cachedArticles.isNotEmpty) {
      _articles = cachedArticles.map((a) => KnowledgeArticle.fromJson(a)).toList();
      setState(() {});
    }

    // Try to fetch from Firestore
    final connectivity = Provider.of<ConnectivityService>(context, listen: false);
    if (connectivity.isOnline) {
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('knowledge_base')
            .orderBy('viewCount', descending: true)
            .get();

        if (snapshot.docs.isNotEmpty) {
          _articles = snapshot.docs
              .map((doc) => KnowledgeArticle.fromJson(doc.data()))
              .toList();
          
          // Update local cache
          for (final article in _articles) {
            await OfflineStorage.cacheKnowledgeArticle(article.id, article.toJson());
          }
        }
      } catch (e) {
        debugPrint('[KnowledgeBase] Error loading from Firestore: $e');
      }
    }

    // If no articles loaded, use default Ethiopian crop guides
    if (_articles.isEmpty) {
      _articles = EthiopianCropGuides.getDefaultArticles();
      // Cache them locally
      for (final article in _articles) {
        await OfflineStorage.cacheKnowledgeArticle(article.id, article.toJson());
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  List<KnowledgeArticle> get _filteredArticles {
    var filtered = _articles;

    // Filter by category
    if (_selectedCategory != null) {
      filtered = filtered.where((a) => a.category == _selectedCategory).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      final langCode = Provider.of<AppSettings>(context, listen: false).locale.languageCode;
      
      filtered = filtered.where((a) {
        final title = a.getTitle(langCode).toLowerCase();
        final content = a.getContent(langCode).toLowerCase();
        final tags = a.tags.join(' ').toLowerCase();
        return title.contains(query) || content.contains(query) || tags.contains(query);
      }).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final connectivity = Provider.of<ConnectivityService>(context);
    final langCode = Provider.of<AppSettings>(context).locale.languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.knowledgeBase),
        backgroundColor: const Color(0xFF00695C),
        foregroundColor: Colors.white,
        actions: [
          if (!connectivity.isOnline)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(Icons.cloud_off, color: Colors.orange),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search Bar
                Container(
                  padding: const EdgeInsets.all(16),
                  color: const Color(0xFF00695C).withOpacity(0.1),
                  child: Column(
                    children: [
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: loc.searchArticles,
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        onChanged: (value) => setState(() => _searchQuery = value),
                      ),
                      const SizedBox(height: 12),
                      // Category Filter
                      SizedBox(
                        height: 36,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            _buildCategoryChip(null, loc.all),
                            ...ArticleCategory.values.map((cat) =>
                                _buildCategoryChip(cat, cat.displayName)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Articles List
                Expanded(
                  child: _filteredArticles.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.book_outlined, size: 80, color: Colors.grey[300]),
                              const SizedBox(height: 16),
                              Text(
                                loc.noArticlesFound,
                                style: TextStyle(color: Colors.grey[600], fontSize: 18),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredArticles.length,
                          itemBuilder: (context, index) {
                            final article = _filteredArticles[index];
                            return _buildArticleCard(article, langCode);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildCategoryChip(ArticleCategory? category, String label) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() => _selectedCategory = selected ? category : null);
        },
        selectedColor: const Color(0xFF00695C),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black,
          fontSize: 12,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
    );
  }

  Widget _buildArticleCard(KnowledgeArticle article, String langCode) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openArticle(article),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image (if available)
            if (article.imageUrl != null)
              Image.network(
                article.imageUrl!,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 100,
                  color: const Color(0xFF00695C).withOpacity(0.1),
                  child: const Center(
                    child: Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
                  ),
                ),
              )
            else
              Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF00695C).withOpacity(0.1),
                      const Color(0xFF00695C).withOpacity(0.2),
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(
                    _getCategoryIcon(article.category),
                    size: 48,
                    color: const Color(0xFF00695C),
                  ),
                ),
              ),
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Featured badge
                  if (article.isFeatured)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        '★ Featured',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  
                  // Title
                  Text(
                    article.getTitle(langCode),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  
                  // Category and views
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00695C).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          article.category.displayName,
                          style: const TextStyle(
                            color: Color(0xFF00695C),
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.visibility, size: 16, color: Colors.grey[400]),
                      const SizedBox(width: 4),
                      Text(
                        '${article.viewCount}',
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Tags
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: article.tags.take(4).map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '#$tag',
                          style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openArticle(KnowledgeArticle article) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ArticleDetailPage(article: article),
      ),
    );
  }

  IconData _getCategoryIcon(ArticleCategory category) {
    switch (category) {
      case ArticleCategory.cropGuide:
        return Icons.grass;
      case ArticleCategory.pestControl:
        return Icons.bug_report;
      case ArticleCategory.diseaseManagement:
        return Icons.healing;
      case ArticleCategory.soilHealth:
        return Icons.landscape;
      case ArticleCategory.irrigation:
        return Icons.water_drop;
      case ArticleCategory.fertilizer:
        return Icons.science;
      case ArticleCategory.harvesting:
        return Icons.agriculture;
      case ArticleCategory.storage:
        return Icons.warehouse;
      case ArticleCategory.marketing:
        return Icons.store;
      case ArticleCategory.weather:
        return Icons.cloud;
      case ArticleCategory.general:
        return Icons.info;
    }
  }
}

// Article Detail Page
class ArticleDetailPage extends StatelessWidget {
  final KnowledgeArticle article;

  const ArticleDetailPage({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    final langCode = Provider.of<AppSettings>(context).locale.languageCode;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with Image
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: const Color(0xFF00695C),
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                article.getTitle(langCode),
                style: const TextStyle(fontSize: 16),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              background: article.imageUrl != null
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          article.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildPlaceholderBackground(),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.7),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : _buildPlaceholderBackground(),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category and Tags
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00695C),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          article.category.displayName,
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.visibility, size: 16, color: Colors.grey[400]),
                      const SizedBox(width: 4),
                      Text('${article.viewCount} views'),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Tags
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: article.tags.map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '#$tag',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Content (Markdown)
                  MarkdownBody(
                    data: article.getContent(langCode),
                    styleSheet: MarkdownStyleSheet(
                      h1: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00695C),
                      ),
                      h2: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00695C),
                      ),
                      h3: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      p: const TextStyle(fontSize: 16, height: 1.6),
                      listBullet: const TextStyle(fontSize: 16),
                    ),
                  ),

                  // Video link if available
                  if (article.videoUrl != null) ...[
                    const SizedBox(height: 24),
                    OutlinedButton.icon(
                      onPressed: () {
                        // Open video URL
                      },
                      icon: const Icon(Icons.play_circle_outline),
                      label: const Text('Watch Video Guide'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF00695C),
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF00695C), Color(0xFF004D40)],
        ),
      ),
      child: const Center(
        child: Icon(Icons.book, size: 80, color: Colors.white24),
      ),
    );
  }
}

