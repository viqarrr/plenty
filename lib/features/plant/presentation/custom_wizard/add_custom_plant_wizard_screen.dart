import 'package:flutter/material.dart';
import 'package:plenty/core/utils/widgets/custom_button.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/core/constants/app_typography.dart';
import 'package:plenty/core/utils/extensions/navigator_extension.dart';
import 'package:plenty/features/plant/data/repositories/plant_repository_impl.dart';
import 'package:plenty/features/plant/domain/entities/plant_entity.dart';
import 'package:plenty/features/plant/domain/repositories/plant_repository.dart';
import 'package:plenty/features/plant/presentation/custom_wizard/widgets/wizard_area_step.dart';
import 'package:plenty/features/plant/presentation/custom_wizard/widgets/wizard_environment_step.dart';
import 'package:plenty/features/plant/presentation/custom_wizard/widgets/wizard_light_step.dart';
import 'package:plenty/features/plant/presentation/custom_wizard/widgets/wizard_name_photo_step.dart';
import 'package:plenty/features/plant/presentation/custom_wizard/widgets/wizard_step_progress.dart';
import 'package:plenty/features/plant/presentation/custom_wizard/widgets/wizard_time_capsule_step.dart';

/// 5-Step interactive wizard for adding a custom plant with location, lighting, and time capsule.
class AddCustomPlantWizardScreen extends StatefulWidget {
  final PlantRepository? plantRepository;

  const AddCustomPlantWizardScreen({super.key, this.plantRepository});

  @override
  State<AddCustomPlantWizardScreen> createState() => _AddCustomPlantWizardScreenState();
}

class _AddCustomPlantWizardScreenState extends State<AddCustomPlantWizardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _timeCapsuleMessageController = TextEditingController();

  late final PlantRepository _plantRepository;

  int _currentStep = 0; // 0 to 4
  String _environment = 'Indoor';
  String _drainage = 'Ada Lubang Drainase';
  String _lightIntensity = 'Sinar Tidak Langsung';
  String _distanceFromWindow = 'Dekat Jendela (1-1.5 meter)';
  String _specificArea = 'Ruang Tamu';
  bool _enableTimeCapsule = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _plantRepository = widget.plantRepository ?? PlantRepositoryImpl();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _timeCapsuleMessageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 4) {
      if (_currentStep == 3) {
        if (_formKey.currentState?.validate() ?? false) {
          setState(() => _currentStep++);
        }
      } else {
        setState(() => _currentStep++);
      }
    } else {
      _saveCustomPlant();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      context.pop();
    }
  }

  Future<void> _saveCustomPlant() async {
    setState(() => _isLoading = true);

    final name = _nameController.text.trim();
    final customPlant = PlantEntity(
      id: 'cust_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      scientificName: 'Tanaman Kustom',
      location: _environment,
      containerDetail: _drainage,
      lightIntensity: _lightIntensity,
      distanceFromWindow: _distanceFromWindow,
      specificArea: _specificArea,
      imageAsset: 'assets/images/custom_plant.png',
      careLevel: 'EASY CARE',
      waterSchedule: _drainage.contains('Ada') ? 'Setiap 7 Hari' : 'Setiap 10-14 Hari',
      lightSchedule: '$_lightIntensity ($_distanceFromWindow)',
      toxicity: '',
      description: 'Tanaman hias kustom buatan sendiri di area $_specificArea.',
      maxHeight: 'Disesuaikan',
      growthRate: 'Sedang',
      growthCycle: 'Perenial',
      pruningSeason: 'Kondisional',
      flowerStatus: 'Disesuaikan',
      pests: 'Kutu putih, tungau',
      isCustom: true,
      hasTimeCapsule: _enableTimeCapsule,
      timeCapsuleMessage: _enableTimeCapsule ? _timeCapsuleMessageController.text : '',
      nextWaterDate: 'Siram sekarang',
      lastCleanedDate: 'Bersihkan sekarang',
    );

    final addResult = await _plantRepository.addUserPlant(customPlant);
    await _plantRepository.incrementStreak();

    if (!mounted) return;
    setState(() => _isLoading = false);

    addResult.when(
      success: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Tanaman kustom '$name' berhasil ditambahkan!"),
            backgroundColor: AppColors.emerald,
          ),
        );
        context.pop();
      },
      error: (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failure.message),
            backgroundColor: AppColors.pastelRedText,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvasDefault,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: _previousStep,
        ),
        title: Text(
          'Tambah Tanaman',
          style: AppTypography.title2Bold.copyWith(
            color: AppColors.ink,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                WizardStepProgress(currentStep: _currentStep),
                const SizedBox(height: 32),
                _buildHeader(),
                const SizedBox(height: 24),
                Expanded(
                  child: SingleChildScrollView(child: _buildStepContent()),
                ),
                const SizedBox(height: 24),
                CustomButton(
                  text: _currentStep == 4 ? 'Selesaikan & Tambahkan Tanaman' : 'Lanjut',
                  isLoading: _isLoading,
                  onPressed: _nextStep,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final (title, desc) = switch (_currentStep) {
      0 => (
        'Di mana tanaman ini akan diletakkan?',
        'Pilih lokasi dan jenis wadah/pot yang dipakai.'
      ),
      1 => (
        'Bagaimana kondisi cahayanya?',
        'Tentukan intensitas sinar matahari dan jarak tanaman ke jendela.'
      ),
      2 => (
        'Pilih lokasi spesifik',
        'Kelompokkan koleksimu berdasarkan ruangan atau area.'
      ),
      3 => (
        'Berikan nama untuk tanamanmu',
        'Tambahkan foto dan nama unik untuk tanamanmu.'
      ),
      4 => (
        'Buat Time Capsule',
        'Pesan rahasia untuk dirimu saat tanaman ini tumbuh nanti.'
      ),
      _ => ('', ''),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.title2Bold.copyWith(
            color: AppColors.ink,
            fontSize: 24,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          desc,
          style: AppTypography.bodyRegular.copyWith(
            color: AppColors.muted,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildStepContent() {
    return switch (_currentStep) {
      0 => WizardEnvironmentStep(
          environment: _environment,
          drainage: _drainage,
          onEnvironmentChanged: (env) {
            setState(() {
              _environment = env;
              _specificArea = env == 'Indoor' ? 'Ruang Tamu' : 'Balkon';
            });
          },
          onDrainageChanged: (drain) => setState(() => _drainage = drain),
        ),
      1 => WizardLightStep(
          lightIntensity: _lightIntensity,
          distanceFromWindow: _distanceFromWindow,
          onLightIntensityChanged: (light) => setState(() => _lightIntensity = light),
          onDistanceChanged: (dist) => setState(() => _distanceFromWindow = dist),
        ),
      2 => WizardAreaStep(
          environment: _environment,
          specificArea: _specificArea,
          onAreaChanged: (area) => setState(() => _specificArea = area),
        ),
      3 => WizardNamePhotoStep(nameController: _nameController),
      4 => WizardTimeCapsuleStep(
          enableTimeCapsule: _enableTimeCapsule,
          messageController: _timeCapsuleMessageController,
          onToggle: (val) => setState(() => _enableTimeCapsule = val),
        ),
      _ => const SizedBox.shrink(),
    };
  }
}
