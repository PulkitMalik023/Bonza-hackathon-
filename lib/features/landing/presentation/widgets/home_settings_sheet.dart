import 'package:flutter/material.dart';

import '../../../../core/audio/ui_button_sound.dart';
import '../../../../core/audio/audio_settings_service.dart';
import '../../../../core/theme/puzzle_theme.dart';
import '../../../puzzle/presentation/how_to_play/how_to_play_popup.dart';

Future<void> showHomeSettingsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return const HomeSettingsSheet();
    },
  );
}

class HomeSettingsSheet extends StatelessWidget {
  const HomeSettingsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: PuzzleTheme.boardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: PuzzleTheme.boardShadow,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: PuzzleTheme.mediumGreen.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'SETTINGS',
                style: TextStyle(
                  color: PuzzleTheme.darkGreen,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              ListenableBuilder(
                listenable: AudioSettingsService.instance,
                builder: (context, _) {
                  final settings = AudioSettingsService.instance;
                  return Column(
                    children: [
                      _SettingsToggleTile(
                        label: 'Sound',
                        enabled: settings.sfxEnabled,
                        enabledIcon: Icons.volume_up_rounded,
                        disabledIcon: Icons.volume_off_rounded,
                        onTap: settings.toggleSfx,
                      ),
                      const SizedBox(height: 8),
                      _SettingsToggleTile(
                        label: 'Music',
                        enabled: settings.musicEnabled,
                        enabledIcon: Icons.music_note_rounded,
                        disabledIcon: Icons.music_off_rounded,
                        onTap: settings.toggleMusic,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 8),
              _SettingsActionTile(
                label: 'How to Play',
                icon: Icons.help_outline_rounded,
                onTap: () {
                  Navigator.of(context).pop();
                  showHowToPlayPopup(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsToggleTile extends StatelessWidget {
  const _SettingsToggleTile({
    required this.label,
    required this.enabled,
    required this.enabledIcon,
    required this.disabledIcon,
    required this.onTap,
  });

  final String label;
  final bool enabled;
  final IconData enabledIcon;
  final IconData disabledIcon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: withButtonTap(onTap),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(
                enabled ? enabledIcon : disabledIcon,
                color: enabled ? PuzzleTheme.mediumGreen : PuzzleTheme.darkGreen.withValues(alpha: 0.45),
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: PuzzleTheme.darkGreen,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
              Text(
                enabled ? 'On' : 'Off',
                style: TextStyle(
                  color: enabled
                      ? PuzzleTheme.mediumGreen
                      : PuzzleTheme.darkGreen.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsActionTile extends StatelessWidget {
  const _SettingsActionTile({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: withButtonTap(onTap),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(
                icon,
                color: PuzzleTheme.mediumGreen,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: PuzzleTheme.darkGreen,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: PuzzleTheme.darkGreen.withValues(alpha: 0.45),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
