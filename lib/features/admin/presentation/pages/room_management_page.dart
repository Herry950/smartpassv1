import 'package:myprojectflut/shared/widgets/home_button.dart';

import 'package:flutter/material.dart';

import '../../../../core/feedback/smartpass_feedback.dart';
import '../../../../core/feedback/smartpass_messages.dart';
import '../../../../core/services/room_management_service.dart';
import '../../../../app/theme/app_colors.dart';

class RoomManagementPage extends StatefulWidget {
  const RoomManagementPage({super.key});

  @override
  State<RoomManagementPage> createState() =>
      _RoomManagementPageState();
}

class _RoomManagementPageState extends State<RoomManagementPage> {
  final RoomManagementService _roomService = RoomManagementService();

  List<Map<String, dynamic>> _rooms = [];
  bool _isLoading = true;
  bool _isSaving = false;
  String _searchQuery = '';
  String _filter = 'Toutes';

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  int get _totalRooms => _rooms.length;

  int get _activeRooms =>
      _rooms.where((room) => room['is_active'] == true).length;

  int get _inactiveRooms => _totalRooms - _activeRooms;

  List<Map<String, dynamic>> get _filteredRooms {
    return _rooms.where((room) {
      final code = (room['code'] ?? '').toString().toLowerCase();
      final name = (room['name'] ?? '').toString().toLowerCase();
      final building =
          (room['building'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();

      final matchesSearch = code.contains(query) ||
          name.contains(query) ||
          building.contains(query);

      final isActive = room['is_active'] == true;

      final matchesFilter = switch (_filter) {
        'Actives' => isActive,
        'Désactivées' => !isActive,
        _ => true,
      };

      return matchesSearch && matchesFilter;
    }).toList();
  }

  // Affichage centralisé des messages SmartPass.
  void _showMessage(
    SmartPassMessageCode code, {
    String? details,
  }) {
    SmartPassFeedback.showSnackBar(
      context,
      code: code,
      role: SmartPassRole.admin,
      details: details,
    );
  }

  // Chargement des salles.
  Future<void> _loadRooms() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      debugPrint('[ROOMS][LOAD] Début du chargement.');

      final rooms = await _roomService.getRooms();

      debugPrint(
        '[ROOMS][LOAD] Succès : ${rooms.length} salle(s).',
      );

      if (!mounted) return;

      setState(() {
        _rooms = rooms;
        _isLoading = false;
      });
    } catch (error, stackTrace) {
      debugPrint('========== ROOMS LOAD ERROR ==========');
      debugPrint('Erreur : $error');
      debugPrint('Type : ${error.runtimeType}');
      debugPrint('StackTrace : $stackTrace');
      debugPrint('======================================');

      if (!mounted) return;

      setState(() => _isLoading = false);

      _showMessage(
        SmartPassMessageCode.roomOperationFailed,
        details: error.toString(),
      );
    }
  }

  // Ouvre le formulaire de création ou de modification.
  Future<void> _openRoomForm({
    Map<String, dynamic>? room,
  }) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _RoomFormDialog(room: room),
    );

    if (result == null || !mounted) return;

    await _saveRoom(result, room);
  }

  // Création ou modification d'une salle.
  Future<void> _saveRoom(
    Map<String, dynamic> data,
    Map<String, dynamic>? existingRoom,
  ) async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    final isCreating = existingRoom == null;

    try {
      if (isCreating) {
        debugPrint('[ROOMS][CREATE] Début de création.');
        debugPrint('[ROOMS][CREATE] Code : ${data['code']}');
        debugPrint('[ROOMS][CREATE] Nom : ${data['name']}');
        debugPrint('[ROOMS][CREATE] Capacité : ${data['capacity']}');

        final createdRoom = await _roomService.createRoom(
          code: data['code'] as String,
          name: data['name'] as String,
          building: data['building'] as String,
          capacity: data['capacity'] as int,
        );

        debugPrint(
          '[ROOMS][CREATE] Succès. ID : ${createdRoom['id']}',
        );

        if (!mounted) return;

        _showMessage(SmartPassMessageCode.roomCreated);
      } else {
        final roomId = existingRoom['id'].toString();

        debugPrint('[ROOMS][UPDATE] Début de modification.');
        debugPrint('[ROOMS][UPDATE] ID : $roomId');
        debugPrint('[ROOMS][UPDATE] Code : ${data['code']}');

        final updatedRoom = await _roomService.updateRoom(
          roomId: roomId,
          code: data['code'] as String,
          name: data['name'] as String,
          building: data['building'] as String,
          capacity: data['capacity'] as int,
        );

        debugPrint(
          '[ROOMS][UPDATE] Succès. ID : ${updatedRoom['id']}',
        );

        if (!mounted) return;

        _showMessage(SmartPassMessageCode.roomUpdated);
      }

      await _loadRooms();
    } catch (error, stackTrace) {
      debugPrint('========== ROOM SAVE ERROR ==========');
      debugPrint(
        'Opération : ${isCreating ? 'CREATE' : 'UPDATE'}',
      );
      debugPrint('Erreur : $error');
      debugPrint('Type : ${error.runtimeType}');
      debugPrint('StackTrace : $stackTrace');
      debugPrint('=====================================');

      if (!mounted) return;

      final errorMessage = error.toString().toLowerCase();

      final isDuplicate = errorMessage.contains('23505') ||
          errorMessage.contains('existe déjà');

      _showMessage(
        isDuplicate
            ? SmartPassMessageCode.roomCodeAlreadyExists
            : SmartPassMessageCode.roomOperationFailed,
        details: error.toString(),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  // Activation ou désactivation d'une salle.
  Future<void> _toggleRoom(Map<String, dynamic> room) async {
    final currentStatus = room['is_active'] == true;
    final newStatus = !currentStatus;
    final roomId = room['id'].toString();

    try {
      debugPrint('[ROOMS][STATUS] Début de modification.');
      debugPrint('[ROOMS][STATUS] ID : $roomId');
      debugPrint('[ROOMS][STATUS] Nouveau statut : $newStatus');

      await _roomService.setRoomStatus(
        roomId: roomId,
        isActive: newStatus,
      );

      debugPrint('[ROOMS][STATUS] Modification réussie.');

      if (!mounted) return;

      _showMessage(
        newStatus
            ? SmartPassMessageCode.roomActivated
            : SmartPassMessageCode.roomDeactivated,
      );

      await _loadRooms();
    } catch (error, stackTrace) {
      debugPrint('========== ROOM STATUS ERROR ==========');
      debugPrint('ID : $roomId');
      debugPrint('Erreur : $error');
      debugPrint('Type : ${error.runtimeType}');
      debugPrint('StackTrace : $stackTrace');
      debugPrint('========================================');

      if (!mounted) return;

      _showMessage(
        SmartPassMessageCode.roomOperationFailed,
        details: error.toString(),
      );
    }
  }

  // Suppression d'une salle.
  Future<void> _deleteRoom(Map<String, dynamic> room) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text('Supprimer cette salle ?'),
          content: Text(
            'Voulez-vous vraiment supprimer la salle '
            '${room['code']} – ${room['name']} ?\n\n'
            'Cette opération est définitive.',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.error,
              ),
              onPressed: () =>
                  Navigator.pop(dialogContext, true),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    final roomId = room['id'].toString();

    try {
      debugPrint('[ROOMS][DELETE] Début de suppression.');
      debugPrint('[ROOMS][DELETE] ID : $roomId');

      await _roomService.deleteRoom(roomId);

      debugPrint('[ROOMS][DELETE] Suppression réussie.');

      if (!mounted) return;

      _showMessage(SmartPassMessageCode.roomDeleted);

      await _loadRooms();
    } catch (error, stackTrace) {
      debugPrint('========== ROOM DELETE ERROR ==========');
      debugPrint('ID : $roomId');
      debugPrint('Erreur : $error');
      debugPrint('Type : ${error.runtimeType}');
      debugPrint('StackTrace : $stackTrace');
      debugPrint('========================================');

      if (!mounted) return;

      SmartPassFeedback.showDialogMessage(
        context,
        code: SmartPassMessageCode.roomOperationFailed,
        role: SmartPassRole.admin,
        details: error.toString(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.primaryDark,
        elevation: 0,
        title: const Text(
          'Gestion des salles',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          const HomeButton(),
          IconButton(
            tooltip: 'Actualiser',
            onPressed: _loadRooms,
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              )
            : RefreshIndicator(
                color: AppColors.primary,
                onRefresh: _loadRooms,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 850;

                    return SingleChildScrollView(
                      physics:
                          const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.all(isWide ? 28 : 16),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          _buildIntroduction(isWide),
                          const SizedBox(height: 24),
                          _buildStatistics(isWide),
                          const SizedBox(height: 28),
                          _buildToolbar(isWide),
                          const SizedBox(height: 18),
                          _buildRoomList(isWide),
                        ],
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }

  Widget _buildIntroduction(bool isWide) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isWide ? 28 : 20),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(20),
      ),
      child: isWide
          ? Row(
              children: [
                const Expanded(child: _IntroductionText()),
                const SizedBox(width: 20),
                FilledButton.icon(
                  onPressed: () => _openRoomForm(),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primaryDark,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter une salle'),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _IntroductionText(),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _openRoomForm(),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primaryDark,
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                      ),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Ajouter une salle'),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatistics(bool isWide) {
    final cards = [
      _StatData(
        label: 'Total des salles',
        value: _totalRooms.toString(),
        icon: Icons.meeting_room_outlined,
      ),
      _StatData(
        label: 'Salles actives',
        value: _activeRooms.toString(),
        icon: Icons.check_circle_outline,
      ),
      _StatData(
        label: 'Salles désactivées',
        value: _inactiveRooms.toString(),
        icon: Icons.pause_circle_outline,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cards.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isWide ? 3 : 1,
        crossAxisSpacing: 14,
        mainAxisSpacing: 12,
        mainAxisExtent: 105,
      ),
      itemBuilder: (context, index) {
        final item = cards[index];

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.border,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color:
                      AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  item.icon,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.label,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      item.value,
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildToolbar(bool isWide) {
    return isWide
        ? Row(
            children: [
              Expanded(child: _buildSearchField()),
              const SizedBox(width: 14),
              _buildFilter(),
            ],
          )
        : Column(
            children: [
              _buildSearchField(),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: _buildFilter(),
              ),
            ],
          );
  }

  Widget _buildSearchField() {
    return TextField(
      onChanged: (value) =>
          setState(() => _searchQuery = value.trim()),
      decoration: InputDecoration(
        hintText: 'Rechercher une salle...',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.border,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.border,
          ),
        ),
      ),
    );
  }

  Widget _buildFilter() {
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(
          value: 'Toutes',
          label: Text('Toutes'),
        ),
        ButtonSegment(
          value: 'Actives',
          label: Text('Actives'),
        ),
        ButtonSegment(
          value: 'Désactivées',
          label: Text('Désactivées'),
        ),
      ],
      selected: {_filter},
      onSelectionChanged: (selection) {
        setState(() => _filter = selection.first);
      },
      style: SegmentedButton.styleFrom(
        foregroundColor: AppColors.primaryDark,
        selectedForegroundColor: Colors.white,
        selectedBackgroundColor: AppColors.primary,
      ),
    );
  }

  Widget _buildRoomList(bool isWide) {
    final rooms = _filteredRooms;

    if (rooms.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(35),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppColors.border,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.meeting_room_outlined,
              size: 48,
              color: AppColors.textDisabled,
            ),
            const SizedBox(height: 12),
            const Text(
              'Aucune salle trouvée',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _rooms.isEmpty
                  ? 'Commencez par enregistrer votre première salle.'
                  : 'Essayez une autre recherche ou un autre filtre.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return Column(
      children: rooms.map((room) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildRoomCard(room, isWide),
        );
      }).toList(),
    );
  }

  Widget _buildRoomCard(
    Map<String, dynamic> room,
    bool isWide,
  ) {
    final isActive = room['is_active'] == true;
    final capacity = room['capacity']?.toString() ?? '—';
    final building = room['building']?.toString();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: isWide
          ? Row(
              children: [
                _roomIcon(),
                const SizedBox(width: 16),
                Expanded(
                  child: _roomInformation(
                    room,
                    building,
                    capacity,
                  ),
                ),
                const SizedBox(width: 16),
                _statusChip(isActive),
                const SizedBox(width: 12),
                _roomActions(room, isActive),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _roomIcon(),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _roomInformation(
                        room,
                        building,
                        capacity,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _statusChip(isActive),
                    const Spacer(),
                    _roomActions(room, isActive),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _roomIcon() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        Icons.meeting_room_outlined,
        color: AppColors.primary,
        size: 25,
      ),
    );
  }

  Widget _roomInformation(
    Map<String, dynamic> room,
    String? building,
    String capacity,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${room['code']} · ${room['name']}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: AppColors.primaryDark,
          ),
        ),
        const SizedBox(height: 7),
        Wrap(
          spacing: 14,
          runSpacing: 6,
          children: [
            _detail(Icons.groups_outlined, '$capacity places'),
            if (building != null && building.isNotEmpty)
              _detail(Icons.apartment_outlined, building),
          ],
        ),
      ],
    );
  }

  Widget _detail(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 15,
          color: Colors.black45,
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _statusChip(bool isActive) {
    final color = isActive ? AppColors.primary : AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        isActive ? 'Active' : 'Désactivée',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _roomActions(
    Map<String, dynamic> room,
    bool isActive,
  ) {
    return Wrap(
      spacing: 2,
      children: [
        IconButton(
          tooltip: 'Modifier',
          onPressed: () => _openRoomForm(room: room),
          icon: const Icon(Icons.edit_outlined),
          color: AppColors.primary,
        ),
        IconButton(
          tooltip: isActive ? 'Désactiver' : 'Activer',
          onPressed: () => _toggleRoom(room),
          icon: Icon(
            isActive
                ? Icons.pause_circle_outline
                : Icons.play_circle_outline,
          ),
          color: AppColors.primary,
        ),
        IconButton(
          tooltip: 'Supprimer',
          onPressed: () => _deleteRoom(room),
          icon: const Icon(Icons.delete_outline),
          color: AppColors.error,
        ),
      ],
    );
  }
}

class _IntroductionText extends StatelessWidget {
  const _IntroductionText();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Infrastructure des examens',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Gérez vos salles en toute simplicité',
          style: TextStyle(
            color: Colors.white,
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 7),
        Text(
          'Enregistrez les salles et définissez leur capacité d’accueil.',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _StatData {
  const _StatData({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;
}

// Formulaire indépendant : les contrôleurs appartiennent
// au dialogue et sont libérés lorsque celui-ci est détruit.
class _RoomFormDialog extends StatefulWidget {
  final Map<String, dynamic>? room;

  const _RoomFormDialog({this.room});

  @override
  State<_RoomFormDialog> createState() =>
      _RoomFormDialogState();
}

class _RoomFormDialogState extends State<_RoomFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _codeController;
  late final TextEditingController _nameController;
  late final TextEditingController _buildingController;
  late final TextEditingController _capacityController;

  @override
  void initState() {
    super.initState();

    final room = widget.room;

    _codeController = TextEditingController(
      text: room?['code']?.toString() ?? '',
    );

    _nameController = TextEditingController(
      text: room?['name']?.toString() ?? '',
    );

    _buildingController = TextEditingController(
      text: room?['building']?.toString() ?? '',
    );

    _capacityController = TextEditingController(
      text: room?['capacity']?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _buildingController.dispose();
    _capacityController.dispose();

    super.dispose();
  }

  Widget _formField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(
          icon,
          color: AppColors.primary,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.primary,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.of(context).pop({
      'code': _codeController.text.trim(),
      'name': _nameController.text.trim(),
      'building': _buildingController.text.trim(),
      'capacity': int.parse(
        _capacityController.text.trim(),
      ),
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.room != null;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Text(
        isEditing ? 'Modifier la salle' : 'Nouvelle salle',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: AppColors.primaryDark,
        ),
      ),
      content: SizedBox(
        width: 430,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _formField(
                  controller: _codeController,
                  label: 'Code de la salle',
                  hint: 'Ex. : A101',
                  icon: Icons.tag,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Le code est obligatoire.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _formField(
                  controller: _nameController,
                  label: 'Nom de la salle',
                  hint: 'Ex. : Grand auditoire',
                  icon: Icons.meeting_room_outlined,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Le nom est obligatoire.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _formField(
                  controller: _buildingController,
                  label: 'Bâtiment (facultatif)',
                  hint: 'Ex. : Bâtiment A',
                  icon: Icons.apartment_outlined,
                ),
                const SizedBox(height: 16),
                _formField(
                  controller: _capacityController,
                  label: 'Capacité maximale',
                  hint: 'Ex. : 120',
                  icon: Icons.groups_outlined,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    final capacity = int.tryParse(value ?? '');

                    if (capacity == null || capacity <= 0) {
                      return 'Saisissez une capacité valide.';
                    }

                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
          ),
          onPressed: _submit,
          child: Text(
            isEditing ? 'Enregistrer' : 'Créer la salle',
          ),
        ),
      ],
    );
  }
}
