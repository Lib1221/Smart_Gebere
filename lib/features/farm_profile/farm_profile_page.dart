import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/models/farm_profile.dart';
import '../../core/services/offline_storage.dart';
import '../../core/services/connectivity_service.dart';
import '../../l10n/app_localizations.dart';

class FarmProfilePage extends StatefulWidget {
  const FarmProfilePage({super.key});

  @override
  State<FarmProfilePage> createState() => _FarmProfilePageState();
}

class _FarmProfilePageState extends State<FarmProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _farmSizeController = TextEditingController();
  final _marketController = TextEditingController();
  final _marketDistanceController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  FarmProfile? _existingProfile;

  // Dropdown values
  String _selectedRegion = 'Oromia';
  String _selectedZone = '';
  String _selectedWoreda = '';
  String _selectedKebele = '';
  String _selectedSoilType = 'Unknown';
  String _selectedIrrigationType = 'Rain-fed';
  String _selectedFarmingType = 'subsistence';
  String _selectedExperience = '1-5 years';
  bool _hasWaterAccess = false;
  bool _usesChemicalFertilizers = false;
  bool _usesOrganic = true;
  bool _hasTransport = false;
  
  List<String> _preferredCrops = [];
  List<String> _currentCrops = [];
  List<String> _availableEquipment = [];

  final List<String> _allCrops = [
    'Teff', 'Wheat', 'Barley', 'Maize', 'Sorghum', 'Millet',
    'Coffee', 'Sesame', 'Niger Seed', 'Flax', 'Sunflower',
    'Chickpea', 'Lentil', 'Faba Bean', 'Field Pea', 'Haricot Bean',
    'Potato', 'Onion', 'Tomato', 'Pepper', 'Cabbage', 'Carrot',
    'Enset', 'Banana', 'Mango', 'Papaya', 'Avocado', 'Orange',
    'Chat', 'Sugar Cane', 'Cotton', 'Tobacco',
  ];

  final List<String> _allEquipment = [
    'Hand hoe', 'Oxen plow', 'Tractor', 'Thresher',
    'Sprayer', 'Pump', 'Storage silo', 'Cart', 'Wheelbarrow',
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _farmSizeController.dispose();
    _marketController.dispose();
    _marketDistanceController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    // Try local first
    final localData = OfflineStorage.getFarmProfile();
    if (localData != null) {
      _populateForm(FarmProfile.fromJson(localData));
    }

    // Then try Firestore
    try {
      final doc = await FirebaseFirestore.instance
          .collection('farmers')
          .doc(userId)
          .get();
      
      if (doc.exists && doc.data() != null) {
        final profile = FarmProfile.fromJson(doc.data()!);
        _populateForm(profile);
        // Update local cache
        await OfflineStorage.saveFarmProfile(profile.toJson());
      }
    } catch (e) {
      debugPrint('[FarmProfile] Error loading from Firestore: $e');
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _populateForm(FarmProfile profile) {
    _existingProfile = profile;
    _nameController.text = profile.farmerName;
    _phoneController.text = profile.phoneNumber;
    _farmSizeController.text = profile.farmSizeHectares.toString();
    _marketController.text = profile.nearestMarket;
    _marketDistanceController.text = profile.distanceToMarketKm.toString();
    _selectedRegion = profile.region;
    _selectedZone = profile.zone;
    _selectedWoreda = profile.woreda;
    _selectedKebele = profile.kebele;
    _selectedSoilType = profile.soilType;
    _selectedIrrigationType = profile.irrigationType;
    _selectedFarmingType = profile.farmingType;
    _selectedExperience = profile.farmingExperience;
    _hasWaterAccess = profile.hasAccessToWater;
    _usesChemicalFertilizers = profile.usesChemicalFertilizers;
    _usesOrganic = profile.usesOrganic;
    _hasTransport = profile.hasTransport;
    _preferredCrops = List.from(profile.preferredCrops);
    _currentCrops = List.from(profile.currentCrops);
    _availableEquipment = List.from(profile.availableEquipment);
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login first')),
      );
      setState(() => _isSaving = false);
      return;
    }

    final now = DateTime.now();
    final profile = FarmProfile(
      id: _existingProfile?.id ?? const Uuid().v4(),
      userId: userId,
      farmerName: _nameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      region: _selectedRegion,
      zone: _selectedZone,
      woreda: _selectedWoreda,
      kebele: _selectedKebele,
      latitude: _existingProfile?.latitude,
      longitude: _existingProfile?.longitude,
      elevation: _existingProfile?.elevation,
      farmSizeHectares: double.tryParse(_farmSizeController.text) ?? 0.0,
      soilType: _selectedSoilType,
      irrigationType: _selectedIrrigationType,
      hasAccessToWater: _hasWaterAccess,
      farmingExperience: _selectedExperience,
      preferredCrops: _preferredCrops,
      currentCrops: _currentCrops,
      farmingType: _selectedFarmingType,
      availableEquipment: _availableEquipment,
      usesChemicalFertilizers: _usesChemicalFertilizers,
      usesOrganic: _usesOrganic,
      nearestMarket: _marketController.text.trim(),
      distanceToMarketKm: double.tryParse(_marketDistanceController.text) ?? 0.0,
      hasTransport: _hasTransport,
      createdAt: _existingProfile?.createdAt ?? now,
      updatedAt: now,
    );

    // Save locally first
    await OfflineStorage.saveFarmProfile(profile.toJson());

    // Try to save to Firestore
    final connectivity = Provider.of<ConnectivityService>(context, listen: false);
    if (connectivity.isOnline) {
      try {
        await FirebaseFirestore.instance
            .collection('farmers')
            .doc(userId)
            .set(profile.toJson(), SetOptions(merge: true));
      } catch (e) {
        debugPrint('[FarmProfile] Error saving to Firestore: $e');
        // Add to sync queue for later
        await OfflineStorage.addToSyncQueue('farm_profile', profile.toJson());
      }
    } else {
      // Offline - add to sync queue
      await OfflineStorage.addToSyncQueue('farm_profile', profile.toJson());
    }

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).profileSaved)),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(loc.farmProfile)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.farmProfile),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Section: Basic Info
            _buildSectionHeader(loc.basicInfo, Icons.person),
            const SizedBox(height: 8),
            _buildTextField(_nameController, loc.farmerName, Icons.person_outline),
            const SizedBox(height: 12),
            _buildTextField(_phoneController, loc.phoneNumber, Icons.phone, 
                keyboard: TextInputType.phone),
            
            const SizedBox(height: 24),
            
            // Section: Location
            _buildSectionHeader(loc.location, Icons.location_on),
            const SizedBox(height: 8),
            _buildDropdown(
              value: _selectedRegion,
              label: loc.region,
              items: EthiopianRegion.values.map((r) => r.displayName).toList(),
              onChanged: (v) => setState(() => _selectedRegion = v ?? _selectedRegion),
            ),
            const SizedBox(height: 12),
            _buildTextField(
              TextEditingController(text: _selectedZone)
                ..addListener(() => _selectedZone = _selectedZone),
              loc.zone,
              Icons.map_outlined,
              onChanged: (v) => _selectedZone = v,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              TextEditingController(text: _selectedWoreda)
                ..addListener(() => _selectedWoreda = _selectedWoreda),
              loc.woreda,
              Icons.map,
              onChanged: (v) => _selectedWoreda = v,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              TextEditingController(text: _selectedKebele)
                ..addListener(() => _selectedKebele = _selectedKebele),
              loc.kebele,
              Icons.home,
              onChanged: (v) => _selectedKebele = v,
            ),

            const SizedBox(height: 24),
            
            // Section: Farm Details
            _buildSectionHeader(loc.farmDetails, Icons.agriculture),
            const SizedBox(height: 8),
            _buildTextField(_farmSizeController, loc.farmSizeHectares, Icons.square_foot,
                keyboard: TextInputType.number),
            const SizedBox(height: 12),
            _buildDropdown(
              value: _selectedSoilType,
              label: loc.soilType,
              items: SoilType.values.map((s) => s.displayName).toList(),
              onChanged: (v) => setState(() => _selectedSoilType = v ?? _selectedSoilType),
            ),
            const SizedBox(height: 12),
            _buildDropdown(
              value: _selectedIrrigationType,
              label: loc.irrigationType,
              items: IrrigationType.values.map((i) => i.displayName).toList(),
              onChanged: (v) => setState(() => _selectedIrrigationType = v ?? _selectedIrrigationType),
            ),
            const SizedBox(height: 12),
            _buildSwitch(loc.hasWaterAccess, _hasWaterAccess, 
                (v) => setState(() => _hasWaterAccess = v)),
            
            const SizedBox(height: 24),
            
            // Section: Farming Practice
            _buildSectionHeader(loc.farmingPractice, Icons.eco),
            const SizedBox(height: 8),
            _buildDropdown(
              value: _selectedFarmingType,
              label: loc.farmingType,
              items: const ['subsistence', 'commercial', 'mixed'],
              itemLabels: [loc.subsistence, loc.commercial, loc.mixed],
              onChanged: (v) => setState(() => _selectedFarmingType = v ?? _selectedFarmingType),
            ),
            const SizedBox(height: 12),
            _buildDropdown(
              value: _selectedExperience,
              label: loc.experience,
              items: const ['< 1 year', '1-5 years', '5-10 years', '> 10 years'],
              onChanged: (v) => setState(() => _selectedExperience = v ?? _selectedExperience),
            ),
            const SizedBox(height: 12),
            _buildSwitch(loc.usesChemicalFertilizers, _usesChemicalFertilizers,
                (v) => setState(() => _usesChemicalFertilizers = v)),
            _buildSwitch(loc.usesOrganic, _usesOrganic,
                (v) => setState(() => _usesOrganic = v)),

            const SizedBox(height: 24),
            
            // Section: Crops
            _buildSectionHeader(loc.crops, Icons.grass),
            const SizedBox(height: 8),
            _buildChipSelector(
              label: loc.currentCrops,
              selected: _currentCrops,
              options: _allCrops,
              onChanged: (crops) => setState(() => _currentCrops = crops),
            ),
            const SizedBox(height: 12),
            _buildChipSelector(
              label: loc.preferredCrops,
              selected: _preferredCrops,
              options: _allCrops,
              onChanged: (crops) => setState(() => _preferredCrops = crops),
            ),

            const SizedBox(height: 24),
            
            // Section: Equipment
            _buildSectionHeader(loc.equipment, Icons.build),
            const SizedBox(height: 8),
            _buildChipSelector(
              label: loc.availableEquipment,
              selected: _availableEquipment,
              options: _allEquipment,
              onChanged: (eq) => setState(() => _availableEquipment = eq),
            ),

            const SizedBox(height: 24),
            
            // Section: Market Access
            _buildSectionHeader(loc.marketAccess, Icons.store),
            const SizedBox(height: 8),
            _buildTextField(_marketController, loc.nearestMarket, Icons.storefront),
            const SizedBox(height: 12),
            _buildTextField(_marketDistanceController, loc.distanceToMarketKm, Icons.straighten,
                keyboard: TextInputType.number),
            const SizedBox(height: 12),
            _buildSwitch(loc.hasTransport, _hasTransport,
                (v) => setState(() => _hasTransport = v)),

            const SizedBox(height: 32),
            
            // Save Button
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(loc.saveProfile, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF2E7D32)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E7D32),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType keyboard = TextInputType.text,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required String label,
    required List<String> items,
    List<String>? itemLabels,
    required void Function(String?) onChanged,
  }) {
    // Ensure value is in items, otherwise use first item
    final safeValue = items.contains(value) ? value : items.first;
    
    return DropdownButtonFormField<String>(
      value: safeValue,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      items: items.asMap().entries.map((entry) {
        final idx = entry.key;
        final item = entry.value;
        return DropdownMenuItem(
          value: item,
          child: Text(itemLabels != null && idx < itemLabels.length ? itemLabels[idx] : item),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildSwitch(String label, bool value, void Function(bool) onChanged) {
    return SwitchListTile(
      title: Text(label),
      value: value,
      onChanged: onChanged,
      activeColor: const Color(0xFF2E7D32),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildChipSelector({
    required String label,
    required List<String> selected,
    required List<String> options,
    required void Function(List<String>) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = selected.contains(option);
            return FilterChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (sel) {
                final newList = List<String>.from(selected);
                if (sel) {
                  newList.add(option);
                } else {
                  newList.remove(option);
                }
                onChanged(newList);
              },
              selectedColor: const Color(0xFF2E7D32).withOpacity(0.2),
              checkmarkColor: const Color(0xFF2E7D32),
            );
          }).toList(),
        ),
      ],
    );
  }
}

