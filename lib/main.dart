import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';
import 'package:pcr_reagent_calculator/utils/format_utils.dart';
import 'package:pcr_reagent_calculator/utils/bank_style_formatters.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      title: 'PCR Reagent Calculator',
      theme: const CupertinoThemeData(
        primaryColor: CupertinoColors.systemBlue,
        scaffoldBackgroundColor: CupertinoColors.systemGroupedBackground,
      ),
      home: const PcrCalculatorPage(),
    );
  }
}

class Reagent {
  final String id;  // 添加唯一 ID
  final String name;
  final double proportion;
  final bool isOptional;

  Reagent({
    String? id,  // 可選 ID，如果未提供則自動生成
    required this.name,
    required this.proportion,
    this.isOptional = false,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString() + name.hashCode.toString();

  Reagent copyWith({
    String? name,
    double? proportion,
    bool? isOptional,
  }) {
    return Reagent(
      id: this.id,  // 保持相同的 ID
      name: name ?? this.name,
      proportion: proportion ?? this.proportion,
      isOptional: isOptional ?? this.isOptional,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'proportion': proportion,
      'isOptional': isOptional,
    };
  }

  factory Reagent.fromJson(Map<String, dynamic> json) {
    return Reagent(
      id: json['id'],  // 從 JSON 載入時保持 ID
      name: json['name'] ?? '',
      proportion: (json['proportion'] ?? 0.0).toDouble(),
      isOptional: json['isOptional'] ?? false,
    );
  }
}

class PcrConfiguration {
  final String name;
  final int numReactions;
  final double reactionVolume;
  final double templateDnaVolume;
  final List<Reagent> reagents;
  final Map<String, bool> reagentInclusionStatus;

  PcrConfiguration({
    required this.name,
    required this.numReactions,
    required this.reactionVolume,
    required this.templateDnaVolume,
    required this.reagents,
    required this.reagentInclusionStatus,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'numReactions': numReactions,
      'reactionVolume': reactionVolume,
      'templateDnaVolume': templateDnaVolume,
      'reagents': reagents.map((r) => r.toJson()).toList(),
      'reagentInclusionStatus': reagentInclusionStatus,
    };
  }

  factory PcrConfiguration.fromJson(Map<String, dynamic> json) {
    return PcrConfiguration(
      name: json['name'] ?? '',
      numReactions: json['numReactions'] ?? 1,
      reactionVolume: (json['reactionVolume'] ?? 50.0).toDouble(),
      templateDnaVolume: (json['templateDnaVolume'] ?? 0.0).toDouble(),
      reagents: (json['reagents'] as List? ?? [])
          .map((r) => Reagent.fromJson(r as Map<String, dynamic>))
          .toList(),
      reagentInclusionStatus: Map<String, bool>.from(json['reagentInclusionStatus'] ?? {}),
    );
  }
}

class PcrCalculatorPage extends StatefulWidget {
  const PcrCalculatorPage({super.key});

  @override
  State<PcrCalculatorPage> createState() => _PcrCalculatorPageState();
}

class _PcrCalculatorPageState extends State<PcrCalculatorPage> {
  final TextEditingController _numReactionsController = TextEditingController();
  final TextEditingController _customReactionVolumeController = TextEditingController(text: '50.0');
  final TextEditingController _templateDnaVolumeController = TextEditingController(text: '0.0');

  Map<String, double> _calculatedTotalVolumes = {};
  final Map<String, bool> _reagentInclusionStatus = {};
  bool _isEditMode = false;
  bool _hasVolumeError = false;
  String _currentConfigurationName = 'Default Configuration';

  final List<Reagent> _reagents = [
    Reagent(id: 'buffer', name: '5X Q5 Reaction Buffer', proportion: 10.0 / 50.0),
    Reagent(id: 'dntps', name: '10 mM dNTPs', proportion: 4.0 / 50.0),
    Reagent(id: 'forward_primer', name: '10 µM Forward Primer', proportion: 5.0 / 50.0),
    Reagent(id: 'reverse_primer', name: '10 µM Reverse Primer', proportion: 5.0 / 50.0),
    Reagent(id: 'polymerase', name: 'Q5 High-Fidelity DNA Polymerase', proportion: 1.0 / 50.0),
    Reagent(id: 'gc_enhancer', name: '5X Q5 High GC Enhancer (optional)', proportion: 10.0 / 50.0, isOptional: true),
    Reagent(id: 'water', name: 'Water', proportion: 0.0),
  ];

  // Controllers for edit mode to prevent focus loss
  List<TextEditingController> _reagentNameControllers = [];
  List<TextEditingController> _reagentVolumeControllers = [];
  
  // Timer for debouncing input updates
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _initializeEditControllers();
    _initializeReagentInclusionStatus();
    _calculateVolumes();
  }

  void _initializeReagentInclusionStatus() {
    // 初始化 optional 試劑的包含狀態，預設為 true
    for (var reagent in _reagents) {
      if (reagent.isOptional) {
        _reagentInclusionStatus[reagent.name] ??= true;
      }
    }
  }

  void _initializeEditControllers() {
    _reagentNameControllers.clear();
    _reagentVolumeControllers.clear();
    
    for (int i = 0; i < _reagents.length; i++) {
      if (_reagents[i].name == 'Water') {
        // Water 試劑不需要編輯控制器，因為它是自動計算的
        _reagentNameControllers.add(TextEditingController());
        _reagentVolumeControllers.add(TextEditingController());
      } else {
        _reagentNameControllers.add(TextEditingController(text: _reagents[i].name));
        double volume = _reagents[i].proportion * 50.0;
        String formattedVolume = volume.toStringAsFixed(1);
        _reagentVolumeControllers.add(TextEditingController(text: formattedVolume));
      }
    }
  }

  @override
  void dispose() {
    // Dispose all controllers
    for (var controller in _reagentNameControllers) {
      controller.dispose();
    }
    for (var controller in _reagentVolumeControllers) {
      controller.dispose();
    }
    _debounceTimer?.cancel();
    _numReactionsController.dispose();
    _customReactionVolumeController.dispose();
    _templateDnaVolumeController.dispose();
    super.dispose();
  }

  void _calculateVolumes() {
    setState(() {
      _calculatedTotalVolumes.clear();
      
      // Use default values if fields are empty or invalid
      int numReactions = int.tryParse(_numReactionsController.text) ?? 1;
      if (numReactions <= 0) numReactions = 1;

      double totalVolumePerReaction = double.tryParse(_customReactionVolumeController.text) ?? 50.0;
      if (totalVolumePerReaction <= 0) totalVolumePerReaction = 50.0;

      double totalCalculatedVolumeExcludingWater = 0.0;

      // 先計算 Template DNA（從上方輸入欄位）
      double templateDnaVolume = double.tryParse(_templateDnaVolumeController.text) ?? 0.0;
      if (templateDnaVolume > 0) {
        double totalTemplateDna = templateDnaVolume * numReactions;
        _calculatedTotalVolumes['Template DNA'] = totalTemplateDna;
        totalCalculatedVolumeExcludingWater += totalTemplateDna;
      }

      // 計算其他試劑
      for (var reagent in _reagents) {
        if (reagent.name == 'Water') continue;

        // 檢查 optional 試劑是否被包含
        bool isIncluded = true;
        if (reagent.isOptional) {
          isIncluded = _reagentInclusionStatus[reagent.name] ?? true;
        }

        if (isIncluded) {
          double singleReactionVolume = reagent.proportion * totalVolumePerReaction;
          double totalReagentVolume = singleReactionVolume * numReactions;
          _calculatedTotalVolumes[reagent.name] = totalReagentVolume;
          totalCalculatedVolumeExcludingWater += totalReagentVolume;
        } else {
          // Optional 試劑未被包含時，設為 0
          _calculatedTotalVolumes[reagent.name] = 0.0;
        }
      }

      double totalDesiredVolume = totalVolumePerReaction * numReactions;
      double waterVolume = totalDesiredVolume - totalCalculatedVolumeExcludingWater;

      if (waterVolume < 0) {
        _hasVolumeError = true;
        // Set water to 0 to show the problem, but keep reagents visible
        _calculatedTotalVolumes['Water'] = 0.0;
      } else {
        _hasVolumeError = false;
        _calculatedTotalVolumes['Water'] = waterVolume;
      }
    });
  }

  void _showErrorDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text('Input Error'),
          content: Text(message),
          actions: <Widget>[
            CupertinoDialogAction(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text('Success'),
          content: Text(message),
          actions: <Widget>[
            CupertinoDialogAction(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _clearAllInputs() {
    _numReactionsController.clear();
    _customReactionVolumeController.text = '50.0';
    _templateDnaVolumeController.clear();
    
    // Reset edit controllers to match reagent values
    for (int i = 0; i < _reagents.length && i < _reagentNameControllers.length; i++) {
      _reagentNameControllers[i].text = _reagents[i].name;
      double volume = _reagents[i].proportion * 50.0;
      _reagentVolumeControllers[i].text = volume.toStringAsFixed(1);
    }
    
    setState(() {
      _calculatedTotalVolumes.clear();
      _reagentInclusionStatus.clear();
      _initializeReagentInclusionStatus();
      // Recalculate volumes to show the cleared results
      _calculateVolumes();
    });
  }

  Future<void> _saveConfiguration() async {
    final TextEditingController nameController = TextEditingController(text: _currentConfigurationName);
    
    await showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text('Save Configuration'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              CupertinoTextField(
                controller: nameController,
                placeholder: 'Configuration Name',
              ),
            ],
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              onPressed: () async {
                if (nameController.text.trim().isNotEmpty) {
                  Navigator.of(context).pop();
                  await _saveConfigurationWithName(nameController.text.trim());
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveConfigurationWithName(String name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final config = PcrConfiguration(
        name: name,
        numReactions: int.tryParse(_numReactionsController.text) ?? 1,
        reactionVolume: double.tryParse(_customReactionVolumeController.text) ?? 50.0,
        templateDnaVolume: double.tryParse(_templateDnaVolumeController.text) ?? 0.0,
        reagents: _reagents,
        reagentInclusionStatus: _reagentInclusionStatus,
      );
      
      List<String> existingConfigs = prefs.getStringList('saved_configurations') ?? [];
      
      // 檢查是否已經存在同名配置，如果存在則替換
      String newConfigJson = jsonEncode(config.toJson());
      int existingIndex = -1;
      
      for (int i = 0; i < existingConfigs.length; i++) {
        try {
          Map<String, dynamic> existingJson = jsonDecode(existingConfigs[i]);
          if (existingJson['name'] == name) {
            existingIndex = i;
            break;
          }
        } catch (e) {
          // 如果解析現有配置失敗，標記為需要移除
          print('Found invalid existing configuration at index $i: $e');
        }
      }
      
      if (existingIndex >= 0) {
        // 替換現有配置
        existingConfigs[existingIndex] = newConfigJson;
      } else {
        // 新增配置
        existingConfigs.add(newConfigJson);
      }
      
      await prefs.setStringList('saved_configurations', existingConfigs);
      
      setState(() {
        _currentConfigurationName = name;
      });
      
      _showSuccessDialog('Configuration "$name" saved successfully!');
    } catch (e) {
      _showErrorDialog('Failed to save configuration: $e');
    }
  }

  Future<void> _loadConfiguration() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> configStrings = prefs.getStringList('saved_configurations') ?? [];
      
      if (configStrings.isEmpty) {
        _showErrorDialog('No saved configurations found.');
        return;
      }

      List<PcrConfiguration> configs = [];
      List<String> validConfigStrings = [];
      
      // 逐一解析配置，過濾掉損壞的配置
      for (int i = 0; i < configStrings.length; i++) {
        try {
          String configString = configStrings[i].trim();
          if (configString.isEmpty) continue;
          
          // 嘗試解析 JSON
          Map<String, dynamic> jsonData = jsonDecode(configString);
          PcrConfiguration config = PcrConfiguration.fromJson(jsonData);
          configs.add(config);
          validConfigStrings.add(configString);
        } catch (e) {
          print('Skipping invalid configuration at index $i: $e');
          print('Invalid config string: "${configStrings[i]}"');
          // 跳過損壞的配置，繼續處理其他配置
        }
      }
      
      // 如果有有效的配置被清理掉，更新儲存的列表
      if (validConfigStrings.length != configStrings.length) {
        await prefs.setStringList('saved_configurations', validConfigStrings);
        print('Cleaned ${configStrings.length - validConfigStrings.length} invalid configurations');
      }
      
      if (configs.isEmpty) {
        _showErrorDialog('No valid configurations found. Invalid configurations have been cleaned.');
        return;
      }

      await showCupertinoModalPopup(
        context: context,
        builder: (BuildContext context) {
          return ConfigurationSelector(
            initialConfigs: configs,
            onConfigurationSelected: (config) {
              _applyConfiguration(config);
              Navigator.of(context).pop();
            },
            onDeleteConfiguration: _deleteConfiguration,
            onShowError: _showErrorDialog,
            onShowSuccess: _showSuccessDialog,
          );
        },
      );
    } catch (e) {
      _showErrorDialog('Failed to load configurations: $e');
    }
  }

  void _applyConfiguration(PcrConfiguration config) {
    try {
      setState(() {
        // 使用正確的格式化來設定控制器文字，符合銀行式格式化器的期望
        _numReactionsController.text = config.numReactions.toString();
        _customReactionVolumeController.text = config.reactionVolume.toStringAsFixed(1);
        _templateDnaVolumeController.text = config.templateDnaVolume.toStringAsFixed(1);
        
        _reagents.clear();
        _reagents.addAll(config.reagents);
        
        // 重新初始化控制器以確保與新的試劑列表同步
        _initializeEditControllers();
        
        _reagentInclusionStatus.clear();
        _reagentInclusionStatus.addAll(config.reagentInclusionStatus);
        
        _currentConfigurationName = config.name;
        
        _calculateVolumes();
      });
    } catch (e) {
      _showErrorDialog('Failed to apply configuration: $e');
    }
  }

  void _copyResults() {
    if (_calculatedTotalVolumes.isEmpty) {
      _showErrorDialog('Please calculate the reagent volumes first.');
      return;
    }

    final StringBuffer buffer = StringBuffer();
    buffer.writeln('PCR Reagent Calculation');
    buffer.writeln('Number of Reactions: ${_numReactionsController.text}');
    buffer.writeln('Custom Reaction Volume: ${_customReactionVolumeController.text} µl');
    buffer.writeln('');
    buffer.writeln('Calculated Total Volumes (µl):');
    _calculatedTotalVolumes.forEach((key, value) {
      buffer.writeln('$key: ${formatVolume(value)}');
    });

    Clipboard.setData(ClipboardData(text: buffer.toString()));
  }

  Future<void> _printResults() async {
    if (_calculatedTotalVolumes.isEmpty) {
      _showErrorDialog('Please calculate the reagent volumes first.');
      return;
    }

    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('PCR Reagent Calculation', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              pw.Text('Number of Reactions: ${_numReactionsController.text}'),
              pw.Text('Custom Reaction Volume: ${_customReactionVolumeController.text} µl'),
              pw.SizedBox(height: 20),
              pw.Text('Calculated Total Volumes (µl):', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Table.fromTextArray(
                headers: ['Component', 'Total Volume (µl)'],
                data: _calculatedTotalVolumes.entries.map((entry) {
                  return [entry.key, formatVolume(entry.value)];
                }).toList(),
              ),
            ],
          );
        },
      ),
    );

    await Printing.sharePdf(bytes: await doc.save(), filename: 'pcr_reagent_calculation.pdf');
  }

  Widget _buildDisplayReagentRow(Reagent reagent) {
    // Get the calculated volume, default to 0.0 if not found
    double totalVolume = _calculatedTotalVolumes[reagent.name] ?? 0.0;
    int numReactions = int.tryParse(_numReactionsController.text) ?? 1;
    double volumePerReaction = numReactions > 0 ? totalVolume / numReactions : 0.0;
    
    // Check if this reagent is included (for optional reagents)
    bool isIncluded = _reagentInclusionStatus[reagent.name] ?? true;
    
    return Row(
      children: [
        // Optional 開關（只對 optional 試劑顯示，使用較小的尺寸）
        if (reagent.isOptional) ...[
          Transform.scale(
            scale: 0.8,
            child: CupertinoSwitch(
              value: isIncluded,
              onChanged: (bool value) {
                setState(() {
                  _reagentInclusionStatus[reagent.name] = value;
                  _calculateVolumes();
                });
              },
            ),
          ),
          const SizedBox(width: 4),
        ],
        Expanded(
          flex: 3,
          child: Text(
            reagent.name + (reagent.isOptional ? ' (Optional)' : ''),
            style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
              color: reagent.isOptional && !isIncluded 
                  ? CupertinoColors.secondaryLabel 
                  : null,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            reagent.isOptional && !isIncluded 
                ? '-' 
                : formatVolume(volumePerReaction),
            textAlign: TextAlign.center,
            style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
              color: reagent.isOptional && !isIncluded 
                  ? CupertinoColors.secondaryLabel 
                  : null,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            reagent.isOptional && !isIncluded 
                ? '-' 
                : formatVolume(totalVolume),
            textAlign: TextAlign.end,
            style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
              fontWeight: FontWeight.w600,
              color: reagent.isOptional && !isIncluded 
                  ? CupertinoColors.secondaryLabel 
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEditableReagentRow(Reagent reagent, int index) {
    // Ensure controllers exist for this index
    while (_reagentNameControllers.length <= index) {
      _reagentNameControllers.add(TextEditingController(text: _reagents[_reagentNameControllers.length].name));
      double volume = _reagents[_reagentVolumeControllers.length].proportion * 50.0;
      String formattedVolume = volume.toStringAsFixed(1);
      _reagentVolumeControllers.add(TextEditingController(text: formattedVolume));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              flex: 3,
              child: CupertinoTextField(
                key: ValueKey('name_$index'),
                placeholder: 'Reagent Name',
                controller: _reagentNameControllers[index],
                onChanged: (value) {
                  _debouncedUpdate(() {
                    setState(() {
                      _reagents[index] = reagent.copyWith(name: value);
                      _calculateVolumes();
                    });
                  });
                },
                onSubmitted: (value) {
                  setState(() {
                    _reagents[index] = reagent.copyWith(name: value);
                    _calculateVolumes();
                  });
                },
                decoration: BoxDecoration(
                  color: CupertinoColors.tertiarySystemBackground,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: CupertinoTextField(
                key: ValueKey('volume_$index'),
                placeholder: 'Volume',
                controller: _reagentVolumeControllers[index],
                keyboardType: TextInputType.number,
                inputFormatters: [BankStyleDecimalFormatter(decimalPlaces: 1, maxDigits: 5)],
                onChanged: (value) {
                  _debouncedUpdate(() {
                    double? newVolume = double.tryParse(value);
                    if (newVolume != null) {
                      setState(() {
                        _reagents[index] = reagent.copyWith(proportion: newVolume / 50.0);
                        _calculateVolumes();
                      });
                    }
                  });
                },
                onSubmitted: (value) {
                  double? newVolume = double.tryParse(value);
                  if (newVolume != null) {
                    setState(() {
                      _reagents[index] = reagent.copyWith(proportion: newVolume / 50.0);
                      _calculateVolumes();
                    });
                  }
                },
                decoration: BoxDecoration(
                  color: CupertinoColors.tertiarySystemBackground,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
              ),
            ),
            const SizedBox(width: 8),
            // Optional 開關（移除標籤，只保留開關）
            CupertinoSwitch(
              value: reagent.isOptional,
              onChanged: (bool value) {
                setState(() {
                  _reagents[index] = reagent.copyWith(isOptional: value);
                  _calculateVolumes();
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  void _addNewReagent() {
    setState(() {
      String newReagentName = 'New Reagent ${_reagents.length + 1}';
      Reagent newReagent = Reagent(
        name: newReagentName,
        proportion: 1.0 / 50.0,
        isOptional: false, // Make all new reagents required for simplicity
      );
      _reagents.add(newReagent);
      
      // Add new controllers for the added reagent
      _reagentNameControllers.add(TextEditingController(text: newReagentName));
      _reagentVolumeControllers.add(TextEditingController(text: '1.0'));
      
      _calculateVolumes();
    });
  }

  void _deleteReagent(int index) {
    // 防止刪除 Water 試劑
    if (index < _reagents.length && _reagents[index].name == 'Water') {
      return;
    }
    
    setState(() {
      _reagents.removeAt(index);
      // Also remove corresponding controllers
      if (index < _reagentNameControllers.length) {
        _reagentNameControllers[index].dispose();
        _reagentNameControllers.removeAt(index);
      }
      if (index < _reagentVolumeControllers.length) {
        _reagentVolumeControllers[index].dispose();
        _reagentVolumeControllers.removeAt(index);
      }
      _calculateVolumes();
    });
  }

  Future<bool?> _showDeleteConfirmation(String reagentName) async {
    return await showCupertinoDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text('Delete Reagent'),
          content: Text('Are you sure you want to delete "$reagentName"?'),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteConfiguration(PcrConfiguration configToDelete) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> configStrings = prefs.getStringList('saved_configurations') ?? [];
      
      // 解析所有配置並移除指定的配置
      List<String> updatedConfigStrings = [];
      for (String configString in configStrings) {
        try {
          Map<String, dynamic> jsonData = jsonDecode(configString);
          PcrConfiguration config = PcrConfiguration.fromJson(jsonData);
          if (config.name != configToDelete.name) {
            updatedConfigStrings.add(configString);
          }
        } catch (e) {
          // 保留無法解析的配置（雖然這種情況應該很少發生）
          updatedConfigStrings.add(configString);
        }
      }
      
      await prefs.setStringList('saved_configurations', updatedConfigStrings);
      _showSuccessDialog('Configuration "${configToDelete.name}" deleted successfully.');
    } catch (e) {
      _showErrorDialog('Failed to delete configuration: $e');
    }
  }

  // 帶防抖的更新方法，避免編輯模式快速輸入時的性能問題
  void _debouncedUpdate(VoidCallback updateCallback) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      updateCallback();
    });
  }

  // 將編輯控制器的值同步到試劑列表（退出編輯模式時使用）
  void _syncEditControllersToReagents() {
    for (int i = 0; i < _reagents.length && i < _reagentNameControllers.length; i++) {
      // 跳過 Water 試劑，因為它是自動計算的
      if (_reagents[i].name == 'Water') continue;
      
      String name = _reagentNameControllers[i].text;
      double? volume = double.tryParse(_reagentVolumeControllers[i].text);
      
      if (name.isNotEmpty && volume != null && volume > 0) {
        _reagents[i] = _reagents[i].copyWith(
          name: name,
          proportion: volume / 50.0,
        );
      }
    }
    _calculateVolumes();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('PCR Calculator'),
      ),
      child: GestureDetector(
        onTap: () {
          // 點擊空白處時關閉鍵盤
          FocusScope.of(context).unfocus();
        },
        child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Parameters Section
            Container(
              decoration: BoxDecoration(
                color: CupertinoColors.systemBackground,
                borderRadius: BorderRadius.circular(12.0),
              ),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PCR Parameters',
                    style: CupertinoTheme.of(context).textTheme.navLargeTitleTextStyle.copyWith(
                      fontSize: 20,
                      color: CupertinoColors.label,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: CupertinoTextField(
                          controller: _numReactionsController,
                          placeholder: 'Number of Reactions',
                          keyboardType: TextInputType.number,
                          inputFormatters: [BankStyleIntegerFormatter(maxDigits: 3)],
                          decoration: BoxDecoration(
                            color: CupertinoColors.tertiarySystemBackground,
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
                          onChanged: (value) => _calculateVolumes(),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: CupertinoTextField(
                          controller: _customReactionVolumeController,
                          placeholder: 'Reaction Volume (µl)',
                          keyboardType: TextInputType.number,
                          inputFormatters: [BankStyleDecimalFormatter(decimalPlaces: 1, maxDigits: 5)],
                          decoration: BoxDecoration(
                            color: CupertinoColors.tertiarySystemBackground,
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
                          onChanged: (value) => _calculateVolumes(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  CupertinoTextField(
                    controller: _templateDnaVolumeController,
                    placeholder: 'Template DNA Volume (µl)',
                    keyboardType: TextInputType.number,
                    inputFormatters: [BankStyleDecimalFormatter(decimalPlaces: 1, maxDigits: 5)],
                    decoration: BoxDecoration(
                      color: CupertinoColors.tertiarySystemBackground,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
                    onChanged: (value) => _calculateVolumes(),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: CupertinoButton.filled(
                          onPressed: _clearAllInputs,
                          child: const Text('Clear'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: CupertinoButton.filled(
                          onPressed: _printResults,
                          child: const Text('Print'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: CupertinoButton.filled(
                          onPressed: _copyResults,
                          child: const Text('Copy'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Configuration Name and Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      _loadConfiguration();
                    },
                    child: Container(
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _currentConfigurationName,
                              style: CupertinoTheme.of(context).textTheme.navLargeTitleTextStyle.copyWith(
                                fontSize: 20,
                                color: CupertinoColors.label,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            CupertinoIcons.chevron_down,
                            color: CupertinoColors.systemBlue,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Row(
                  children: [
                    CupertinoButton(
                      onPressed: () {
                        _saveConfiguration();
                      },
                      child: const Text(
                        'Save',
                        style: TextStyle(
                          color: CupertinoColors.systemBlue,
                        ),
                      ),
                    ),
                    CupertinoButton(
                      onPressed: _isEditMode && _hasVolumeError ? null : () {
                        setState(() {
                          if (_isEditMode) {
                            // 退出編輯模式時，確保所有變更都已同步
                            _syncEditControllersToReagents();
                          } else {
                            // 進入編輯模式時，重新初始化控制器
                            _initializeEditControllers();
                          }
                          _isEditMode = !_isEditMode;
                        });
                      },
                      child: Text(
                        _isEditMode ? 'Done' : 'Edit',
                        style: TextStyle(
                          color: _isEditMode && _hasVolumeError 
                              ? CupertinoColors.destructiveRed
                              : CupertinoColors.systemBlue,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Reagents List
            // Always show reagents list, even if calculations are empty
            ...[
              // Header row for normal display mode
              if (!_isEditMode)
                Container(
                  margin: const EdgeInsets.only(bottom: 2.0),
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          'Components',
                          style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                            fontWeight: FontWeight.w600,
                            color: CupertinoColors.secondaryLabel,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Vol/rxn',
                          textAlign: TextAlign.center,
                          style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                            fontWeight: FontWeight.w600,
                            color: CupertinoColors.secondaryLabel,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Total',
                          textAlign: TextAlign.end,
                          style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                            fontWeight: FontWeight.w600,
                            color: CupertinoColors.secondaryLabel,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Header row for edit mode
              if (_isEditMode)
                Container(
                  margin: const EdgeInsets.only(bottom: 2.0),
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          'Components',
                          style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                            fontWeight: FontWeight.w600,
                            color: CupertinoColors.secondaryLabel,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: Text(
                          '50 µl rxn',
                          textAlign: TextAlign.center,
                          style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                            fontWeight: FontWeight.w600,
                            color: CupertinoColors.secondaryLabel,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Optional',
                        style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                          fontWeight: FontWeight.w600,
                          color: CupertinoColors.secondaryLabel,
                        ),
                      ),
                    ],
                  ),
                ),
              
              for (var i = 0; i < _reagents.length; i++)
                if ((_isEditMode && _reagents[i].name != 'Water') || (!_isEditMode && _calculatedTotalVolumes.containsKey(_reagents[i].name)))
                  _isEditMode 
                    ? Dismissible(
                        key: ValueKey(_reagents[i].id),  // 使用唯一 ID 作為 key
                        direction: DismissDirection.endToStart,
                        dismissThresholds: const {
                          DismissDirection.endToStart: 0.6, // Require 60% swipe to trigger
                        },
                        confirmDismiss: (direction) async {
                          // 防止刪除 Water 試劑
                          if (_reagents[i].name == 'Water') {
                            return false;
                          }
                          return await _showDeleteConfirmation(_reagents[i].name);
                        },
                        onDismissed: (direction) {
                          _deleteReagent(i);
                        },
                        background: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4.0),
                          decoration: BoxDecoration(
                            color: CupertinoColors.destructiveRed,
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20.0),
                          child: const Icon(
                            CupertinoIcons.delete,
                            color: CupertinoColors.white,
                            size: 24,
                          ),
                        ),
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4.0),
                          decoration: BoxDecoration(
                            color: CupertinoColors.systemBackground,
                            borderRadius: BorderRadius.circular(12.0),
                            border: Border.all(
                              color: CupertinoColors.separator,
                              width: 0.5,
                            ),
                          ),
                          padding: const EdgeInsets.all(16.0),
                          child: _buildEditableReagentRow(_reagents[i], i),
                        ),
                      )
                    : Container(
                        margin: const EdgeInsets.symmetric(vertical: 4.0),
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemBackground,
                          borderRadius: BorderRadius.circular(12.0),
                          border: Border.all(
                            color: CupertinoColors.separator,
                            width: 0.5,
                          ),
                        ),
                        padding: const EdgeInsets.all(16.0),
                        child: _buildDisplayReagentRow(_reagents[i]),
                      ),
              
              // Add new reagent button in edit mode
              if (_isEditMode)
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 4.0),
                  child: CupertinoButton(
                    onPressed: _addNewReagent,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(CupertinoIcons.add),
                        SizedBox(width: 8),
                        Text('Add New Reagent'),
                      ],
                    ),
                  ),
                ),
            ],
          ],
        ),
      ), // SafeArea
      ), // GestureDetector
    );
  }
}

class ConfigurationSelector extends StatefulWidget {
  final List<PcrConfiguration> initialConfigs;
  final Function(PcrConfiguration) onConfigurationSelected;
  final Function(PcrConfiguration) onDeleteConfiguration;
  final Function(String) onShowError;
  final Function(String) onShowSuccess;

  const ConfigurationSelector({
    super.key,
    required this.initialConfigs,
    required this.onConfigurationSelected,
    required this.onDeleteConfiguration,
    required this.onShowError,
    required this.onShowSuccess,
  });

  @override
  State<ConfigurationSelector> createState() => _ConfigurationSelectorState();
}

class _ConfigurationSelectorState extends State<ConfigurationSelector> {
  late List<PcrConfiguration> configs;

  @override
  void initState() {
    super.initState();
    configs = List.from(widget.initialConfigs);
  }

  Future<void> _handleDeleteConfiguration(PcrConfiguration config) async {
    // 顯示確認對話框
    final bool? shouldDelete = await showCupertinoDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text('Delete Configuration'),
          content: Text('Are you sure you want to delete "${config.name}"? This action cannot be undone.'),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      try {
        // 執行刪除操作
        await widget.onDeleteConfiguration(config);
        
        // 更新本地列表
        setState(() {
          configs.removeWhere((c) => c.name == config.name);
        });
        
        widget.onShowSuccess('Configuration "${config.name}" deleted successfully.');
        
        // 如果沒有配置了，關閉選擇器
        if (configs.isEmpty) {
          if (mounted) {
            Navigator.of(context).pop();
            widget.onShowError('No configurations available.');
          }
        }
      } catch (e) {
        widget.onShowError('Failed to delete configuration: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // 頂部拖動條
          Container(
            width: 36,
            height: 5,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: CupertinoColors.quaternaryLabel,
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),
          // 標題
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Load Configuration',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
          // 垂直轉盤列表
          Expanded(
            child: configs.isEmpty
                ? const Center(
                    child: Text(
                      'No configurations available',
                      style: TextStyle(
                        color: CupertinoColors.secondaryLabel,
                        fontSize: 16,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: configs.length,
                    itemBuilder: (context, index) {
                      final config = configs[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              CupertinoColors.systemBlue.withOpacity(0.1),
                              CupertinoColors.systemPurple.withOpacity(0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: CupertinoColors.separator,
                            width: 0.5,
                          ),
                        ),
                        child: CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () {
                            widget.onConfigurationSelected(config);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              children: [
                                // 配置圖標
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        CupertinoColors.systemBlue,
                                        CupertinoColors.systemPurple,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    CupertinoIcons.lab_flask,
                                    color: CupertinoColors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // 配置資訊
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        config.name,
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${config.numReactions} reactions • ${config.reactionVolume.toStringAsFixed(1)} µl',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: CupertinoColors.secondaryLabel,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // 刪除按鈕
                                CupertinoButton(
                                  padding: const EdgeInsets.all(8),
                                  onPressed: () {
                                    _handleDeleteConfiguration(config);
                                  },
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: CupertinoColors.destructiveRed.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      CupertinoIcons.delete,
                                      color: CupertinoColors.destructiveRed,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
