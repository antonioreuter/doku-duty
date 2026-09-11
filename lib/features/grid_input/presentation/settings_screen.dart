import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design_system/presentation/doku_type.dart';
import '../../design_system/presentation/paper_grain.dart';
import '../../persistence/domain/app_setting.dart';
import '../application/grid_providers.dart';

/// Every stored setting, and nothing that is not stored.
///
/// A row here is a promise that the switch does something. Auto-check and
/// strict mode are stored and read by nothing yet — `add-mistake-model` is what
/// makes them work — so they are shown as not yet implemented rather than as
/// working switches. A row that lies is worse than a row that is absent.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  /// What each setting is called, and whether anything acts on it today.
  static const Map<AppSetting, ({String title, String detail, bool live})>
  rows = <AppSetting, ({String title, String detail, bool live})>{
    AppSetting.numberFirstInput: (
      title: 'Number-first input',
      detail: 'Choose a digit, then tap cells to place it.',
      live: true,
    ),
    AppSetting.reduceEffects: (
      title: 'Reduce effects',
      detail: 'Silences animation. Independent of the system setting.',
      live: true,
    ),
    AppSetting.autoCheck: (
      title: 'Auto-check',
      detail: 'Flags a wrong digit as it is placed. Arrives with mistakes.',
      live: false,
    ),
    AppSetting.strictMode: (
      title: 'Strict mode',
      detail:
          'Immediate flagging and a three-mistake limit. Arrives with '
          'mistakes.',
      live: false,
    ),
  };

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  Future<Map<AppSetting, bool>>? _values;

  @override
  Widget build(BuildContext context) {
    final repository = ref.watch(settingsRepositoryProvider);
    _values ??= repository.readAll();

    return Scaffold(
      appBar: AppBar(
        title: Text('Settings', style: TypeRole.screenTitle.style),
      ),
      body: PaperGrain(
        child: FutureBuilder<Map<AppSetting, bool>>(
          future: _values,
          builder: (context, snapshot) {
            final values = snapshot.data;
            return ListView(
              children: <Widget>[
                for (final entry in SettingsScreen.rows.entries)
                  SwitchListTile(
                    key: ValueKey<String>('setting-${entry.key.name}'),
                    title: Text(entry.value.title, style: TypeRole.body.style),
                    subtitle: Text(
                      entry.value.live
                          ? entry.value.detail
                          : '${entry.value.detail} Not in effect yet.',
                      style: TypeRole.label.style,
                    ),
                    value: values?[entry.key] ?? entry.key.defaultValue,
                    onChanged: values == null
                        ? null
                        : (value) async {
                            await repository.write(entry.key, value: value);
                            // The input mode is read from this setting, so the
                            // next puzzle opens in the mode just chosen.
                            ref.invalidate(inputModeProvider);
                            // Re-read rather than assume: the row shows what is
                            // stored, not what was tapped.
                            if (!mounted) return;
                            final reread = repository.readAll();
                            setState(() {
                              _values = reread;
                            });
                          },
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
