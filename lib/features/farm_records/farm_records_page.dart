import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:uuid/uuid.dart';
import '../../core/models/farm_record.dart';
import '../../core/services/offline_storage.dart';
import '../../core/services/connectivity_service.dart';
import '../../l10n/app_localizations.dart';

class FarmRecordsPage extends StatefulWidget {
  const FarmRecordsPage({super.key});

  @override
  State<FarmRecordsPage> createState() => _FarmRecordsPageState();
}

class _FarmRecordsPageState extends State<FarmRecordsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<FarmRecord> _records = [];
  bool _isLoading = true;
  FarmAnalytics? _analytics;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadRecords();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRecords() async {
    setState(() => _isLoading = true);

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    // Load from local storage first
    final localRecords = OfflineStorage.getAllFarmRecords();
    if (localRecords.isNotEmpty) {
      _records = localRecords.map((r) => FarmRecord.fromJson(r)).toList();
      _analytics = FarmAnalytics.fromRecords(_records);
      setState(() {});
    }

    // Try to fetch from Firestore
    final connectivity = Provider.of<ConnectivityService>(context, listen: false);
    if (connectivity.isOnline) {
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('farmers')
            .doc(userId)
            .collection('records')
            .orderBy('date', descending: true)
            .get();

        _records = snapshot.docs
            .map((doc) => FarmRecord.fromJson(doc.data()))
            .toList();
        
        // Update local cache
        for (final record in _records) {
          await OfflineStorage.saveFarmRecord(record.id, record.toJson());
        }
        
        _analytics = FarmAnalytics.fromRecords(_records);
      } catch (e) {
        debugPrint('[FarmRecords] Error loading from Firestore: $e');
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addRecord() async {
    final result = await Navigator.push<FarmRecord>(
      context,
      MaterialPageRoute(
        builder: (context) => const AddRecordPage(),
      ),
    );

    if (result != null) {
      await _saveRecord(result);
    }
  }

  Future<void> _saveRecord(FarmRecord record) async {
    // Save locally
    await OfflineStorage.saveFarmRecord(record.id, record.toJson());

    // Try to save to Firestore
    final connectivity = Provider.of<ConnectivityService>(context, listen: false);
    if (connectivity.isOnline) {
      try {
        await FirebaseFirestore.instance
            .collection('farmers')
            .doc(record.userId)
            .collection('records')
            .doc(record.id)
            .set(record.toJson());
      } catch (e) {
        debugPrint('[FarmRecords] Error saving to Firestore: $e');
        await OfflineStorage.addToSyncQueue('farm_record', record.toJson());
      }
    } else {
      await OfflineStorage.addToSyncQueue('farm_record', record.toJson());
    }

    await _loadRecords();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final connectivity = Provider.of<ConnectivityService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.farmRecords),
        backgroundColor: const Color(0xFF6A1B9A),
        foregroundColor: Colors.white,
        actions: [
          if (!connectivity.isOnline)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(Icons.cloud_off, color: Colors.orange),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRecords,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: loc.records, icon: const Icon(Icons.list)),
            Tab(text: loc.analytics, icon: const Icon(Icons.analytics)),
            Tab(text: loc.summary, icon: const Icon(Icons.pie_chart)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildRecordsList(),
                _buildAnalyticsTab(),
                _buildSummaryTab(),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addRecord,
        backgroundColor: const Color(0xFF6A1B9A),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(loc.addRecord),
      ),
    );
  }

  Widget _buildRecordsList() {
    final loc = AppLocalizations.of(context);

    if (_records.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.book_outlined, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              loc.noRecords,
              style: TextStyle(color: Colors.grey[600], fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              loc.tapToAddRecord,
              style: TextStyle(color: Colors.grey[400]),
            ),
          ],
        ),
      );
    }

    // Group records by month
    final grouped = <String, List<FarmRecord>>{};
    for (final record in _records) {
      final key = '${record.date.year}-${record.date.month.toString().padLeft(2, '0')}';
      grouped.putIfAbsent(key, () => []).add(record);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: grouped.entries.expand((entry) {
        final monthRecords = entry.value;
        return [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              entry.key,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF6A1B9A),
              ),
            ),
          ),
          ...monthRecords.map((record) => _buildRecordCard(record)),
        ];
      }).toList(),
    );
  }

  Widget _buildRecordCard(FarmRecord record) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getRecordColor(record.type).withOpacity(0.1),
          child: Icon(
            _getRecordIcon(record.type),
            color: _getRecordColor(record.type),
          ),
        ),
        title: Text(
          record.description,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${record.cropName} • ${record.type.displayName}'),
            Text(
              '${record.date.day}/${record.date.month}/${record.date.year}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
        trailing: record.amount != null
            ? Text(
                '${record.amount!.toStringAsFixed(0)} ${record.currency}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: record.type == RecordType.income
                      ? Colors.green
                      : Colors.red,
                ),
              )
            : null,
        onTap: () => _showRecordDetails(record),
      ),
    );
  }

  void _showRecordDetails(FarmRecord record) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => RecordDetailsSheet(record: record),
    );
  }

  Widget _buildAnalyticsTab() {
    final loc = AppLocalizations.of(context);

    if (_analytics == null || _records.isEmpty) {
      return Center(
        child: Text(loc.noDataForAnalytics),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary Cards
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                loc.totalExpenses,
                '${_analytics!.totalExpenses.toStringAsFixed(0)} ETB',
                Colors.red,
                Icons.arrow_downward,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                loc.totalIncome,
                '${_analytics!.totalIncome.toStringAsFixed(0)} ETB',
                Colors.green,
                Icons.arrow_upward,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                loc.netProfit,
                '${_analytics!.netProfit.toStringAsFixed(0)} ETB',
                _analytics!.netProfit >= 0 ? Colors.green : Colors.red,
                _analytics!.netProfit >= 0 ? Icons.trending_up : Icons.trending_down,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                loc.laborHours,
                '${_analytics!.totalLaborHours} hrs',
                Colors.blue,
                Icons.access_time,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Income by Month Chart
        if (_analytics!.incomeByMonth.isNotEmpty) ...[
          Text(
            loc.incomeByMonth,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: _buildIncomeChart(),
          ),
          const SizedBox(height: 24),
        ],

        // Harvest by Crop Chart
        if (_analytics!.harvestByCrop.isNotEmpty) ...[
          Text(
            loc.harvestByCrop,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: _buildHarvestChart(),
          ),
        ],
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(color: color, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeChart() {
    final entries = _analytics!.incomeByMonth.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    
    if (entries.isEmpty) return const SizedBox.shrink();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: entries.map((e) => e.value).reduce((a, b) => a > b ? a : b) * 1.2,
        barGroups: entries.asMap().entries.map((entry) {
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: entry.value.value,
                color: const Color(0xFF4CAF50),
                width: 16,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          );
        }).toList(),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() < entries.length) {
                  final month = entries[value.toInt()].key.split('-').last;
                  return Text(month, style: const TextStyle(fontSize: 10));
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${(value / 1000).toStringAsFixed(0)}K',
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
      ),
    );
  }

  Widget _buildHarvestChart() {
    final entries = _analytics!.harvestByCrop.entries.toList();
    
    if (entries.isEmpty) return const SizedBox.shrink();

    final colors = [
      const Color(0xFF4CAF50),
      const Color(0xFF2196F3),
      const Color(0xFFFFC107),
      const Color(0xFFE91E63),
      const Color(0xFF9C27B0),
    ];

    return PieChart(
      PieChartData(
        sections: entries.asMap().entries.map((entry) {
          return PieChartSectionData(
            value: entry.value.value,
            title: '${entry.value.key}\n${entry.value.value.toStringAsFixed(0)}',
            color: colors[entry.key % colors.length],
            radius: 80,
            titleStyle: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        }).toList(),
        sectionsSpace: 2,
        centerSpaceRadius: 0,
      ),
    );
  }

  Widget _buildSummaryTab() {
    final loc = AppLocalizations.of(context);

    if (_analytics == null || _records.isEmpty) {
      return Center(child: Text(loc.noDataForAnalytics));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Expenses by Category
        Text(
          loc.expensesByCategory,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        ..._analytics!.expensesByCategory.entries.map((entry) {
          final total = _analytics!.totalExpenses;
          final percent = total > 0 ? (entry.value / total * 100) : 0;
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(entry.key),
                    Text(
                      '${entry.value.toStringAsFixed(0)} ETB (${percent.toStringAsFixed(1)}%)',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percent / 100,
                    backgroundColor: Colors.grey[200],
                    valueColor: const AlwaysStoppedAnimation(Color(0xFF6A1B9A)),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Color _getRecordColor(RecordType type) {
    switch (type) {
      case RecordType.expense:
        return Colors.red;
      case RecordType.income:
        return Colors.green;
      case RecordType.input:
        return Colors.orange;
      case RecordType.harvest:
        return Colors.blue;
      case RecordType.labor:
        return Colors.purple;
      case RecordType.observation:
        return Colors.grey;
    }
  }

  IconData _getRecordIcon(RecordType type) {
    switch (type) {
      case RecordType.expense:
        return Icons.money_off;
      case RecordType.income:
        return Icons.attach_money;
      case RecordType.input:
        return Icons.inventory;
      case RecordType.harvest:
        return Icons.grass;
      case RecordType.labor:
        return Icons.people;
      case RecordType.observation:
        return Icons.visibility;
    }
  }
}

// Add Record Page
class AddRecordPage extends StatefulWidget {
  const AddRecordPage({super.key});

  @override
  State<AddRecordPage> createState() => _AddRecordPageState();
}

class _AddRecordPageState extends State<AddRecordPage> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _quantityController = TextEditingController();
  final _notesController = TextEditingController();

  RecordType _selectedType = RecordType.expense;
  String _selectedCrop = 'Teff';
  ExpenseCategory _selectedCategory = ExpenseCategory.other;
  DateTime _selectedDate = DateTime.now();

  final List<String> _crops = [
    'Teff', 'Wheat', 'Maize', 'Sorghum', 'Barley',
    'Coffee', 'Sesame', 'Chickpea', 'Lentil', 'General',
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.addRecord),
        backgroundColor: const Color(0xFF6A1B9A),
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Record Type
            Text(loc.recordType, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: RecordType.values.map((type) {
                final isSelected = _selectedType == type;
                return ChoiceChip(
                  label: Text(type.displayName),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedType = type);
                  },
                  selectedColor: const Color(0xFF6A1B9A),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Crop
            DropdownButtonFormField<String>(
              value: _selectedCrop,
              decoration: InputDecoration(
                labelText: loc.crop,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: _crops.map((crop) {
                return DropdownMenuItem(value: crop, child: Text(crop));
              }).toList(),
              onChanged: (value) => setState(() => _selectedCrop = value ?? _selectedCrop),
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: loc.description,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (value) => value?.isEmpty == true ? loc.required : null,
            ),
            const SizedBox(height: 16),

            // Amount
            if (_selectedType != RecordType.observation) ...[
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: '${loc.amount} (ETB)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Category (for expenses)
            if (_selectedType == RecordType.expense || _selectedType == RecordType.input) ...[
              DropdownButtonFormField<ExpenseCategory>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  labelText: loc.category,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: ExpenseCategory.values.map((cat) {
                  return DropdownMenuItem(value: cat, child: Text(cat.displayName));
                }).toList(),
                onChanged: (value) => setState(() => _selectedCategory = value ?? _selectedCategory),
              ),
              const SizedBox(height: 16),
            ],

            // Quantity (for harvest/input)
            if (_selectedType == RecordType.harvest || _selectedType == RecordType.input) ...[
              TextFormField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: '${loc.quantity} (kg)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Date
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: Text(loc.date),
              subtitle: Text('${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() => _selectedDate = date);
                }
              },
            ),
            const SizedBox(height: 16),

            // Notes
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: loc.notes,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),

            // Save Button
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: _saveRecord,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6A1B9A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(loc.save, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveRecord() {
    if (!_formKey.currentState!.validate()) return;

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final now = DateTime.now();
    final record = FarmRecord(
      id: const Uuid().v4(),
      userId: userId,
      type: _selectedType,
      cropName: _selectedCrop,
      date: _selectedDate,
      description: _descriptionController.text.trim(),
      amount: double.tryParse(_amountController.text),
      currency: 'ETB',
      expenseCategory: _selectedCategory,
      quantity: double.tryParse(_quantityController.text),
      unit: 'kg',
      harvestQuantity: _selectedType == RecordType.harvest
          ? double.tryParse(_quantityController.text)
          : null,
      harvestUnit: 'kg',
      notes: _notesController.text.trim(),
      isSynced: false,
      createdAt: now,
      updatedAt: now,
    );

    Navigator.pop(context, record);
  }
}

// Record Details Sheet
class RecordDetailsSheet extends StatelessWidget {
  final FarmRecord record;

  const RecordDetailsSheet({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getRecordIcon(record.type),
                color: _getRecordColor(record.type),
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.description,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${record.cropName} • ${record.type.displayName}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 32),
          if (record.amount != null) ...[
            _buildDetailRow('Amount', '${record.amount!.toStringAsFixed(0)} ${record.currency}'),
          ],
          if (record.quantity != null || record.harvestQuantity != null) ...[
            _buildDetailRow('Quantity', '${record.quantity ?? record.harvestQuantity} ${record.unit ?? 'kg'}'),
          ],
          _buildDetailRow('Date', '${record.date.day}/${record.date.month}/${record.date.year}'),
          if (record.notes?.isNotEmpty == true) ...[
            const SizedBox(height: 16),
            const Text('Notes', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(record.notes!),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Color _getRecordColor(RecordType type) {
    switch (type) {
      case RecordType.expense:
        return Colors.red;
      case RecordType.income:
        return Colors.green;
      case RecordType.input:
        return Colors.orange;
      case RecordType.harvest:
        return Colors.blue;
      case RecordType.labor:
        return Colors.purple;
      case RecordType.observation:
        return Colors.grey;
    }
  }

  IconData _getRecordIcon(RecordType type) {
    switch (type) {
      case RecordType.expense:
        return Icons.money_off;
      case RecordType.income:
        return Icons.attach_money;
      case RecordType.input:
        return Icons.inventory;
      case RecordType.harvest:
        return Icons.grass;
      case RecordType.labor:
        return Icons.people;
      case RecordType.observation:
        return Icons.visibility;
    }
  }
}

