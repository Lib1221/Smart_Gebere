import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../core/models/market_price.dart';
import '../../core/services/offline_storage.dart';
import '../../core/services/connectivity_service.dart';
import '../../core/services/ai_reliability.dart';
import '../../settings/app_settings.dart';
import '../../l10n/app_localizations.dart';

class MarketPricesPage extends StatefulWidget {
  const MarketPricesPage({super.key});

  @override
  State<MarketPricesPage> createState() => _MarketPricesPageState();
}

class _MarketPricesPageState extends State<MarketPricesPage> {
  List<MarketPrice> _prices = [];
  bool _isLoading = true;
  String? _error;
  String _selectedCrop = 'Teff';
  GenerativeModel? _model;
  SellRecommendation? _recommendation;
  bool _isLoadingRecommendation = false;

  final List<String> _crops = [
    'Teff', 'Wheat', 'Maize', 'Sorghum', 'Barley',
    'Coffee', 'Sesame', 'Chickpea', 'Lentil', 'Faba Bean',
  ];

  @override
  void initState() {
    super.initState();
    _initializeModel();
    _loadPrices();
  }

  Future<void> _initializeModel() async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey != null && apiKey.isNotEmpty) {
      final modelName = dotenv.env['GEMINI_MODEL'] ?? 'gemini-1.5-flash';
      _model = GenerativeModel(model: modelName, apiKey: apiKey);
    }
  }

  Future<void> _loadPrices() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    // Try cache first
    final cached = OfflineStorage.getCachedMarketPrices('ethiopia');
    if (cached != null) {
      setState(() {
        _prices = cached.map((p) => MarketPrice.fromJson(p)).toList();
        _isLoading = false;
      });
    }

    // Generate prices via AI or use fallback
    final connectivity = Provider.of<ConnectivityService>(context, listen: false);
    if (connectivity.isOnline && _model != null) {
      try {
        await _fetchAIPrices();
      } catch (e) {
        debugPrint('[MarketPrices] AI error: $e');
        _useFallbackPrices();
      }
    } else if (_prices.isEmpty) {
      _useFallbackPrices();
    }

    setState(() => _isLoading = false);
  }

  Future<void> _fetchAIPrices() async {
    final settings = Provider.of<AppSettings>(context, listen: false);
    final language = settings.aiLanguageName();
    
    final prompt = '''
You are an Ethiopian agricultural market analyst. Generate current market prices for major crops in Ethiopia.

Respond in $language.

Return a JSON array with prices for: Teff, Wheat, Maize, Sorghum, Barley, Coffee, Sesame, Chickpea, Lentil, Faba Bean.

Each item should have:
{
  "id": "unique-id",
  "cropName": "crop name",
  "price": price_in_ETB_per_kg,
  "unit": "kg",
  "currency": "ETB",
  "market": "market name",
  "region": "region",
  "trend": "up" or "down" or "stable",
  "changePercent": percentage_change,
  "source": "market name"
}

Base prices on realistic Ethiopian market conditions. Add slight variations for realism.
Return ONLY the JSON array, no other text.
''';

    final response = await _model!.generateContent([Content.text(prompt)]);
    final text = response.text ?? '';
    
    debugPrint('[MarketPrices] AI Response: $text');
    
    final parsed = AIReliability.extractJsonArray(text);
    if (parsed != null && parsed.isNotEmpty) {
      final prices = parsed
          .map((p) => MarketPrice.fromJson(p as Map<String, dynamic>))
          .toList();
      
      // Cache the prices
      await OfflineStorage.cacheMarketPrices(
        'ethiopia',
        prices.map((p) => p.toJson()).toList(),
      );
      
      if (mounted) {
        setState(() => _prices = prices);
      }
    }
  }

  void _useFallbackPrices() {
    final fallback = AIReliability.fallbackMarketPrices();
    setState(() {
      _prices = fallback.map((p) => MarketPrice.fromJson(p)).toList();
    });
  }

  Future<void> _getSellRecommendation(String cropName) async {
    if (_model == null) return;

    setState(() {
      _isLoadingRecommendation = true;
      _recommendation = null;
    });

    final settings = Provider.of<AppSettings>(context, listen: false);
    final language = settings.aiLanguageName();
    
    final cropPrice = _prices.firstWhere(
      (p) => p.cropName.toLowerCase() == cropName.toLowerCase(),
      orElse: () => _prices.first,
    );

    final prompt = '''
You are an Ethiopian agricultural market advisor. Based on current market conditions, provide a selling recommendation.

Crop: $cropName
Current Price: ${cropPrice.formattedPrice}
Price Trend: ${cropPrice.trend.displayName}

Respond in $language.

Consider:
- Current price relative to typical prices
- Price trend direction
- Seasonal factors in Ethiopia
- Storage costs

Return a JSON object:
{
  "recommendation": "sell_now" or "hold" or "wait",
  "reason": "brief explanation in $language"
}

Return ONLY the JSON object.
''';

    try {
      final response = await _model!.generateContent([Content.text(prompt)]);
      final text = response.text ?? '';
      
      final parsed = AIReliability.extractJson(text);
      if (parsed != null && mounted) {
        setState(() {
          _recommendation = SellRecommendation(
            cropName: cropName,
            recommendation: parsed['recommendation'] ?? 'hold',
            reason: parsed['reason'] ?? 'Unable to determine recommendation',
            confidenceScore: 0.75,
            generatedAt: DateTime.now(),
          );
        });
      }
    } catch (e) {
      debugPrint('[MarketPrices] Recommendation error: $e');
    }

    if (mounted) {
      setState(() => _isLoadingRecommendation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final connectivity = Provider.of<ConnectivityService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.marketPrices),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        actions: [
          if (!connectivity.isOnline)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(Icons.cloud_off, color: Colors.orange),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPrices,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _loadPrices,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Price Chart
                      _buildPriceChart(),
                      const SizedBox(height: 24),

                      // Crop Selector
                      _buildCropSelector(),
                      const SizedBox(height: 16),

                      // Sell Recommendation
                      _buildSellRecommendation(),
                      const SizedBox(height: 24),

                      // Price List
                      Text(
                        loc.currentPrices,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._prices.map((price) => _buildPriceCard(price)),
                    ],
                  ),
                ),
    );
  }

  Widget _buildPriceChart() {
    final loc = AppLocalizations.of(context);
    
    // Generate mock historical data for chart
    final selectedPrices = _prices.where(
      (p) => p.cropName.toLowerCase() == _selectedCrop.toLowerCase(),
    ).toList();

    if (selectedPrices.isEmpty) {
      return const SizedBox.shrink();
    }

    final currentPrice = selectedPrices.first.price;
    
    // Generate 6 months of mock data
    final chartData = List.generate(6, (i) {
      final variance = (i - 3) * (currentPrice * 0.05);
      return FlSpot(i.toDouble(), currentPrice + variance);
    });

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$_selectedCrop ${loc.priceHistory}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}',
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final months = ['Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov'];
                        if (value.toInt() < months.length) {
                          return Text(
                            months[value.toInt()],
                            style: const TextStyle(fontSize: 10),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: chartData,
                    isCurved: true,
                    color: const Color(0xFF1565C0),
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF1565C0).withOpacity(0.1),
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

  Widget _buildCropSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _crops.map((crop) {
          final isSelected = _selectedCrop == crop;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(crop),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedCrop = crop);
                  _getSellRecommendation(crop);
                }
              },
              selectedColor: const Color(0xFF1565C0),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSellRecommendation() {
    final loc = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _recommendation != null
              ? [
                  Color(_recommendation!.colorHex).withOpacity(0.1),
                  Color(_recommendation!.colorHex).withOpacity(0.05),
                ]
              : [Colors.grey[100]!, Colors.grey[50]!],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _recommendation != null
              ? Color(_recommendation!.colorHex)
              : Colors.grey[300]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.insights,
                color: _recommendation != null
                    ? Color(_recommendation!.colorHex)
                    : Colors.grey,
              ),
              const SizedBox(width: 8),
              Text(
                '${loc.sellRecommendation}: $_selectedCrop',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isLoadingRecommendation)
            const Center(child: CircularProgressIndicator())
          else if (_recommendation != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Color(_recommendation!.colorHex),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _recommendation!.displayRecommendation,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _recommendation!.reason,
              style: TextStyle(color: Colors.grey[700]),
            ),
          ] else
            ElevatedButton.icon(
              onPressed: () => _getSellRecommendation(_selectedCrop),
              icon: const Icon(Icons.lightbulb_outline),
              label: Text(loc.getRecommendation),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPriceCard(MarketPrice price) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Color(price.trendColorHex).withOpacity(0.1),
          child: Text(
            price.trendIcon,
            style: TextStyle(
              fontSize: 20,
              color: Color(price.trendColorHex),
            ),
          ),
        ),
        title: Text(
          price.cropName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('${price.market} • ${price.source}'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              price.formattedPrice,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            if (price.changePercent != null)
              Text(
                '${price.changePercent! > 0 ? '+' : ''}${price.changePercent!.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: Color(price.trendColorHex),
                  fontSize: 12,
                ),
              ),
          ],
        ),
        onTap: () {
          setState(() => _selectedCrop = price.cropName);
          _getSellRecommendation(price.cropName);
        },
      ),
    );
  }
}

