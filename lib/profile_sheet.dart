import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'models.dart';

class ProfileSelectionSheet extends StatefulWidget {
  final StorageService storage;
  final ValueChanged<String> onProfileSelected;
  final VoidCallback onProfileAdded;
  final VoidCallback onProfileEdited;

  const ProfileSelectionSheet({
    super.key,
    required this.storage,
    required this.onProfileSelected,
    required this.onProfileAdded,
    required this.onProfileEdited,
  });

  @override
  State<ProfileSelectionSheet> createState() => _ProfileSelectionSheetState();
}

class _ProfileSelectionSheetState extends State<ProfileSelectionSheet> {
  @override
  Widget build(BuildContext context) {
    final profiles = widget.storage.profiles;
    final activeId = widget.storage.activeProfileId;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '프로필 선택',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: profiles.length + 1,
              separatorBuilder: (context, index) => const SizedBox(width: 16),
              itemBuilder: (context, index) {
                if (index == profiles.length) {
                  return GestureDetector(
                    onTap: widget.onProfileAdded,
                    child: Column(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey[800] : Colors.grey[200],
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.add, size: 30),
                        ),
                        const SizedBox(height: 8),
                        const Text('추가', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  );
                }

                final profile = profiles[index];
                final isActive = profile.id == activeId;
                final avatarAbsPath = widget.storage.getAvatarAbsolutePath(profile.avatarPath);
                final hasAvatar = avatarAbsPath != null && File(avatarAbsPath).existsSync();

                return GestureDetector(
                  onTap: () => widget.onProfileSelected(profile.id),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: isActive ? Theme.of(context).colorScheme.primary : (isDark ? Colors.grey[800] : Colors.grey[300]),
                              shape: BoxShape.circle,
                              border: isActive ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2) : null,
                              image: hasAvatar
                                  ? DecorationImage(
                                      image: FileImage(File(avatarAbsPath)),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: !hasAvatar
                                ? Icon(
                                    Icons.person,
                                    color: isActive ? Colors.white : (isDark ? Colors.white70 : Colors.black54),
                                    size: 30,
                                  )
                                : null,
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: GestureDetector(
                              onTap: () async {
                                final edited = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => EditProfileDialog(
                                    profile: profile,
                                    storage: widget.storage,
                                  ),
                                );
                                if (edited == true && mounted) {
                                  setState(() {});
                                  widget.onProfileEdited();
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.secondary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.edit, size: 12, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        profile.name,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                          color: isActive ? Theme.of(context).colorScheme.primary : null,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class EditProfileDialog extends StatefulWidget {
  final Profile profile;
  final StorageService storage;

  const EditProfileDialog({super.key, required this.profile, required this.storage});

  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  late TextEditingController _nameController;
  String? _avatarPath;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.name);
    _avatarPath = widget.profile.avatarPath;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${pickedFile.name}';
      final savedImage = await File(pickedFile.path).copy('${appDir.path}/$fileName');
      
      setState(() {
        _avatarPath = fileName;
      });
    }
  }

  void _saveProfile() {
    final name = _nameController.text.trim();
    if (name.isNotEmpty) {
      final profiles = widget.storage.profiles;
      final index = profiles.indexWhere((p) => p.id == widget.profile.id);
      if (index != -1) {
        profiles[index].name = name;
        profiles[index].avatarPath = _avatarPath;
        widget.storage.saveProfiles(profiles);
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final avatarAbsPath = widget.storage.getAvatarAbsolutePath(_avatarPath);
    final hasAvatar = avatarAbsPath != null && File(avatarAbsPath).existsSync();

    return AlertDialog(
      title: const Text('프로필 편집'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                shape: BoxShape.circle,
                image: hasAvatar
                    ? DecorationImage(
                        image: FileImage(File(avatarAbsPath)),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: !hasAvatar
                  ? const Icon(Icons.camera_alt, size: 40, color: Colors.grey)
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: '프로필 이름',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: _saveProfile,
          child: const Text('저장'),
        ),
      ],
    );
  }
}

class AddProfileDialog extends StatefulWidget {
  final StorageService storage;

  const AddProfileDialog({super.key, required this.storage});

  @override
  State<AddProfileDialog> createState() => _AddProfileDialogState();
}

class _AddProfileDialogState extends State<AddProfileDialog> {
  late TextEditingController _nameController;
  String? _avatarPath;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${pickedFile.name}';
      final savedImage = await File(pickedFile.path).copy('${appDir.path}/$fileName');
      
      setState(() {
        _avatarPath = fileName;
      });
    }
  }

  void _addProfile() {
    final name = _nameController.text.trim();
    if (name.isNotEmpty) {
      final profiles = widget.storage.profiles;
      final newId = DateTime.now().millisecondsSinceEpoch.toString();
      final newProfile = Profile(id: newId, name: name, avatarPath: _avatarPath);
      profiles.add(newProfile);
      widget.storage.saveProfiles(profiles);
      Navigator.pop(context, newId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final avatarAbsPath = widget.storage.getAvatarAbsolutePath(_avatarPath);
    final hasAvatar = avatarAbsPath != null && File(avatarAbsPath).existsSync();
    
    return AlertDialog(
      title: const Text('새 프로필 추가'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                shape: BoxShape.circle,
                image: hasAvatar
                    ? DecorationImage(
                        image: FileImage(File(avatarAbsPath)),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: !hasAvatar
                  ? const Icon(Icons.camera_alt, size: 40, color: Colors.grey)
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: '프로필 이름',
              hintText: '예: 가족, 비상금',
            ),
            autofocus: true,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: _addProfile,
          child: const Text('추가'),
        ),
      ],
    );
  }
}

