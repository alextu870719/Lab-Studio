import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';
import 'package:lab_studio/utils/format_utils.dart';
import 'package:lab_studio/utils/bank_style_formatters.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = false;
  bool _isExperimentTrackingMode = false;
  int _trackingDisplayMode = 0; // 0: checkbox, 1: strikethrough

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('isDarkMode') ?? false;
      _isExperimentTrackingMode = prefs.getBool('isExperimentTrackingMode') ?? false;
      _trackingDisplayMode = prefs.getInt('trackingDisplayMode') ?? 0;
    });
  }

  Future<void> _toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
    await prefs.setBool('isDarkMode', _isDarkMode);
  }

  Future<void> _toggleExperimentTracking() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isExperimentTrackingMode = !_isExperimentTrackingMode;
    });
    await prefs.setBool('isExperimentTrackingMode', _isExperimentTrackingMode);
  }

  Future<void> _setTrackingDisplayMode(int mode) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _trackingDisplayMode = mode;
    });
    await prefs.setInt('trackingDisplayMode', _trackingDisplayMode);
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      title: 'Lab Studio',
      theme: CupertinoThemeData(
        brightness: _isDarkMode ? Brightness.dark : Brightness.light,
        primaryColor: CupertinoColors.systemBlue,
        scaffoldBackgroundColor: _isDarkMode 
            ? CupertinoColors.black
            : CupertinoColors.systemGroupedBackground,
      ),
      home: CupertinoTabScaffold(
        tabBar: CupertinoTabBar(
          backgroundColor: _isDarkMode 
              ? CupertinoColors.systemGrey6.darkColor
              : CupertinoColors.systemBackground,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.lab_flask),
              label: 'Calculator',
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.gear_alt),
              label: 'Reaction',
            ),
          ],
        ),
        tabBuilder: (BuildContext context, int index) {
          switch (index) {
            case 0:
              return PcrCalculatorPage(
                onToggleTheme: _toggleTheme,
                isDarkMode: _isDarkMode,
                onToggleExperimentTracking: _toggleExperimentTracking,
                isExperimentTrackingMode: _isExperimentTrackingMode,
                trackingDisplayMode: _trackingDisplayMode,
                onSetTrackingDisplayMode: _setTrackingDisplayMode,
              );
            case 1:
              return PcrReactionPage(
                isDarkMode: _isDarkMode,
                onToggleTheme: _toggleTheme,
              );
            default:
              return Container();
          }
        },
      ),
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
      id: id,  // 保持相同的 ID
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
  final VoidCallback onToggleTheme;
  final bool isDarkMode;
  final VoidCallback onToggleExperimentTracking;
  final bool isExperimentTrackingMode;
  final int trackingDisplayMode;
  final Function(int) onSetTrackingDisplayMode;

  const PcrCalculatorPage({
    super.key,
    required this.onToggleTheme,
    required this.isDarkMode,
    required this.onToggleExperimentTracking,
    required this.isExperimentTrackingMode,
    required this.trackingDisplayMode,
    required this.onSetTrackingDisplayMode,
  });

  @override
  State<PcrCalculatorPage> createState() => _PcrCalculatorPageState();
}

class _PcrCalculatorPageState extends State<PcrCalculatorPage> {
  final TextEditingController _numReactionsController = TextEditingController();
  final TextEditingController _customReactionVolumeController = TextEditingController(text: '50.0');
  final TextEditingController _templateDnaVolumeController = TextEditingController(text: '0.0');
  final TextEditingController _experimentNameController = TextEditingController();

  final Map<String, double> _calculatedTotalVolumes = {};
  final Map<String, bool> _reagentInclusionStatus = {};
  final Map<String, bool> _reagentAddedStatus = {}; // 追蹤哪些試劑已加入實驗
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
  final List<TextEditingController> _reagentNameControllers = [];
  final List<TextEditingController> _reagentVolumeControllers = [];
  
  // Timer for debouncing input updates
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _initializeEditControllers();
    _initializeReagentInclusionStatus();
    _initializeReagentAddedStatus();
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

  void _initializeReagentAddedStatus() {
    // 初始化實驗追蹤狀態，預設所有試劑都未加入
    for (var reagent in _reagents) {
      _reagentAddedStatus[reagent.name] ??= false;
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
    _experimentNameController.dispose();
    super.dispose();
  }

  String _getTodayDate() {
    final now = DateTime.now();
    return '${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')}/${(now.year % 100).toString().padLeft(2, '0')}';
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
          title: Text(
            'Input Error',
            style: TextStyle(color: widget.isDarkMode ? CupertinoColors.white : CupertinoColors.black),
          ),
          content: Text(
            message,
            style: TextStyle(color: widget.isDarkMode ? CupertinoColors.white : CupertinoColors.black),
          ),
          actions: <Widget>[
            CupertinoDialogAction(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'OK',
                style: TextStyle(color: CupertinoColors.systemBlue),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showSettingsPage() {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return SettingsPage(
          isDarkMode: widget.isDarkMode,
          onToggleTheme: widget.onToggleTheme,
          isExperimentTrackingMode: widget.isExperimentTrackingMode,
          onToggleExperimentTracking: widget.onToggleExperimentTracking,
          trackingDisplayMode: widget.trackingDisplayMode,
          onSetTrackingDisplayMode: widget.onSetTrackingDisplayMode,
        );
      },
    );
  }

  void _showSuccessDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: Text(
            'Success',
            style: TextStyle(color: widget.isDarkMode ? CupertinoColors.white : CupertinoColors.black),
          ),
          content: Text(
            message,
            style: TextStyle(color: widget.isDarkMode ? CupertinoColors.white : CupertinoColors.black),
          ),
          actions: <Widget>[
            CupertinoDialogAction(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'OK',
                style: TextStyle(color: CupertinoColors.systemBlue),
              ),
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
    _experimentNameController.clear();
    
    // Reset edit controllers to match reagent values
    for (int i = 0; i < _reagents.length && i < _reagentNameControllers.length; i++) {
      _reagentNameControllers[i].text = _reagents[i].name;
      double volume = _reagents[i].proportion * 50.0;
      _reagentVolumeControllers[i].text = volume.toStringAsFixed(1);
    }
    
    setState(() {
      _calculatedTotalVolumes.clear();
      _reagentInclusionStatus.clear();
      _reagentAddedStatus.clear();
      _initializeReagentInclusionStatus();
      _initializeReagentAddedStatus();
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
          title: Text(
            'Save Configuration',
            style: TextStyle(color: widget.isDarkMode ? CupertinoColors.white : CupertinoColors.black),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              CupertinoTextField(
                controller: nameController,
                placeholder: 'Configuration Name',
                style: TextStyle(color: widget.isDarkMode ? CupertinoColors.white : CupertinoColors.black),
                placeholderStyle: TextStyle(color: CupertinoColors.placeholderText),
                decoration: BoxDecoration(
                  color: CupertinoColors.tertiarySystemBackground,
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ],
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: CupertinoColors.systemBlue),
              ),
            ),
            CupertinoDialogAction(
              onPressed: () async {
                if (nameController.text.trim().isNotEmpty) {
                  Navigator.of(context).pop();
                  await _saveConfigurationWithName(nameController.text.trim());
                }
              },
              child: Text(
                'Save',
                style: TextStyle(color: CupertinoColors.systemBlue),
              ),
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
            isDarkMode: widget.isDarkMode,
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
    buffer.writeln('Lab Studio - PCR Reagent Calculation');
    
    // 試驗名稱和日期
    if (_experimentNameController.text.isNotEmpty) {
      buffer.writeln('Experiment Name: ${_experimentNameController.text}');
    }
    buffer.writeln('Date: ${_getTodayDate()}');
    buffer.writeln('');
    
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
              pw.Text('Lab Studio - PCR Reagent Calculation', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              // 試驗名稱和日期
              if (_experimentNameController.text.isNotEmpty) ...[
                pw.Text('Experiment Name: ${_experimentNameController.text}', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 5),
              ],
              pw.Text('Date: ${_getTodayDate()}', style: pw.TextStyle(fontSize: 16)),
              pw.SizedBox(height: 15),
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

    await Printing.sharePdf(bytes: await doc.save(), filename: 'lab_studio_pcr_calculation.pdf');
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
        // 實驗追蹤模式的 checkbox（當模式開啟且顯示模式為 checkbox 時顯示）
        if (widget.isExperimentTrackingMode && widget.trackingDisplayMode == 0) ...[
          Transform.scale(
            scale: 0.8,
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                setState(() {
                  _reagentAddedStatus[reagent.name] = !(_reagentAddedStatus[reagent.name] ?? false);
                });
              },
              child: Icon(
                (_reagentAddedStatus[reagent.name] ?? false) 
                    ? CupertinoIcons.checkmark_square_fill 
                    : CupertinoIcons.square,
                color: (_reagentAddedStatus[reagent.name] ?? false) 
                    ? CupertinoColors.systemGreen 
                    : (widget.isDarkMode ? CupertinoColors.white : CupertinoColors.black),
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
        // Optional 開關（只對 optional 試劑顯示，使用小型圖標）
        if (reagent.isOptional) ...[
          GestureDetector(
            onTap: () {
              setState(() {
                _reagentInclusionStatus[reagent.name] = !isIncluded;
                _calculateVolumes();
              });
            },
            child: Container(
              padding: const EdgeInsets.all(4),
              child: Icon(
                isIncluded 
                    ? CupertinoIcons.eye_fill 
                    : CupertinoIcons.eye_slash_fill,
                color: isIncluded 
                    ? CupertinoColors.systemGreen 
                    : CupertinoColors.systemGrey,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
        Expanded(
          flex: 3,
          child: GestureDetector(
            onTap: widget.isExperimentTrackingMode && widget.trackingDisplayMode == 1 
                ? () {
                    setState(() {
                      _reagentAddedStatus[reagent.name] = !(_reagentAddedStatus[reagent.name] ?? false);
                    });
                  }
                : null,
            child: Text(
              reagent.name + (reagent.isOptional ? ' (Optional)' : ''),
              style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                color: reagent.isOptional && !isIncluded 
                    ? (widget.isDarkMode ? CupertinoColors.systemGrey2 : CupertinoColors.secondaryLabel)
                    : (widget.isDarkMode ? CupertinoColors.white : CupertinoColors.black),
                decoration: (widget.isExperimentTrackingMode && 
                           widget.trackingDisplayMode == 1 && 
                           (_reagentAddedStatus[reagent.name] ?? false))
                    ? TextDecoration.lineThrough 
                    : null,
                decorationColor: widget.isDarkMode 
                    ? CupertinoColors.white 
                    : CupertinoColors.black,
                decorationThickness: 2.0,
              ),
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
                  ? (widget.isDarkMode ? CupertinoColors.systemGrey2 : CupertinoColors.secondaryLabel)
                  : (widget.isDarkMode ? CupertinoColors.white : CupertinoColors.black),
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
                  ? (widget.isDarkMode ? CupertinoColors.systemGrey2 : CupertinoColors.secondaryLabel)
                  : (widget.isDarkMode ? CupertinoColors.white : CupertinoColors.black),
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
                textInputAction: TextInputAction.next,
                onEditingComplete: () {
                  // 安全的焦點跳轉
                  FocusScope.of(context).nextFocus();
                },
                style: TextStyle(color: widget.isDarkMode ? CupertinoColors.white : CupertinoColors.black),
                placeholderStyle: TextStyle(color: CupertinoColors.placeholderText),
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
                  color: widget.isDarkMode 
                      ? CupertinoColors.systemGrey5.darkColor
                      : CupertinoColors.tertiarySystemBackground,
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
                textInputAction: TextInputAction.done,
                onEditingComplete: () {
                  final currentFocus = FocusScope.of(context);
                  if (currentFocus.hasFocus) {
                    currentFocus.unfocus();
                  }
                },
                inputFormatters: [BankStyleDecimalFormatter(decimalPlaces: 1, maxDigits: 5)],
                style: TextStyle(color: widget.isDarkMode ? CupertinoColors.white : CupertinoColors.black),
                placeholderStyle: TextStyle(color: CupertinoColors.placeholderText),
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
                  color: widget.isDarkMode 
                      ? CupertinoColors.systemGrey5.darkColor
                      : CupertinoColors.tertiarySystemBackground,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
              ),
            ),
            const SizedBox(width: 8),
            // Optional checkbox
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                setState(() {
                  _reagents[index] = reagent.copyWith(isOptional: !reagent.isOptional);
                  _calculateVolumes();
                });
              },
              child: Container(
                padding: const EdgeInsets.all(8.0),
                child: Icon(
                  reagent.isOptional 
                      ? CupertinoIcons.checkmark_square_fill 
                      : CupertinoIcons.square,
                  color: reagent.isOptional 
                      ? CupertinoColors.systemBlue 
                      : (widget.isDarkMode ? CupertinoColors.white : CupertinoColors.black),
                  size: 22,
                ),
              ),
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
      
      // 初始化新試劑的追蹤狀態
      _reagentAddedStatus[newReagentName] = false;
      
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
          title: Text(
            'Delete Reagent',
            style: TextStyle(color: widget.isDarkMode ? CupertinoColors.white : CupertinoColors.black),
          ),
          content: Text(
            'Are you sure you want to delete "$reagentName"?',
            style: TextStyle(color: widget.isDarkMode ? CupertinoColors.white : CupertinoColors.black),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(color: CupertinoColors.systemBlue),
              ),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                'Delete',
                style: TextStyle(color: CupertinoColors.destructiveRed),
              ),
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
      // 移除這裡的成功訊息顯示，讓調用方來處理
    } catch (e) {
      // 拋出異常讓調用方處理錯誤訊息
      throw Exception('Failed to delete configuration: $e');
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

  // 拖拽排序相關方法
  List<Widget> _buildDraggableReagentsList() {
    // 過濾掉 Water 試劑，因為它不需要在編輯模式中顯示
    List<Reagent> editableReagents = _reagents.where((r) => r.name != 'Water').toList();
    
    List<Widget> widgets = [];
    for (int index = 0; index < editableReagents.length; index++) {
      final reagent = editableReagents[index];
      final originalIndex = _reagents.indexOf(reagent);
      
      widgets.add(
        _buildDraggableReagentItem(reagent, originalIndex, index),
      );
    }
    
    return widgets;
  }

  Widget _buildDraggableReagentItem(Reagent reagent, int originalIndex, int listIndex) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: DragTarget<int>(
        onWillAcceptWithDetails: (details) {
          return details.data != listIndex;
        },
        onAcceptWithDetails: (details) {
          if (details.data != listIndex) {
            _onReorderReagents(details.data, listIndex);
          }
        },
        builder: (context, candidateData, rejectedData) {
          bool isHighlighted = candidateData.isNotEmpty;
          
          return AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: isHighlighted
                  ? CupertinoColors.systemBlue.withOpacity(0.1)
                  : (widget.isDarkMode 
                      ? CupertinoColors.systemGrey6.darkColor
                      : CupertinoColors.systemBackground),
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(
                color: isHighlighted 
                    ? CupertinoColors.systemBlue
                    : CupertinoColors.separator,
                width: isHighlighted ? 2.0 : 0.5,
              ),
            ),
            child: Dismissible(
              key: ValueKey(reagent.id),
              direction: DismissDirection.endToStart,
              dismissThresholds: const {
                DismissDirection.endToStart: 0.6,
              },
              confirmDismiss: (direction) async {
                return await _showDeleteConfirmation(reagent.name);
              },
              onDismissed: (direction) {
                _deleteReagent(originalIndex);
              },
              background: Container(
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
              child: Row(
                children: [
                  // 拖拽手柄 - 只有這個區域可以觸發拖拽
                  Draggable<int>(
                    data: listIndex,
                    feedback: Material(
                      color: Colors.transparent,
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: widget.isDarkMode 
                              ? CupertinoColors.systemGrey6.darkColor
                              : CupertinoColors.systemBackground,
                          borderRadius: BorderRadius.circular(12.0),
                          border: Border.all(
                            color: CupertinoColors.systemBlue,
                            width: 2.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: CupertinoColors.systemBlue.withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          CupertinoIcons.bars,
                          color: CupertinoColors.systemBlue,
                          size: 24,
                        ),
                      ),
                    ),
                    childWhenDragging: Container(
                      padding: const EdgeInsets.all(16.0),
                      child: Icon(
                        CupertinoIcons.bars,
                        color: CupertinoColors.secondaryLabel,
                        size: 20,
                      ),
                    ),
                    onDragStarted: () {
                      HapticFeedback.mediumImpact();
                    },
                    onDragEnd: (details) {
                      // 拖拽結束，可以在這裡處理
                    },
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Icon(
                          CupertinoIcons.bars,
                          color: isHighlighted 
                              ? CupertinoColors.systemBlue
                              : (widget.isDarkMode 
                                  ? CupertinoColors.white.withOpacity(0.7)
                                  : CupertinoColors.systemGrey),
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  // 試劑內容 - 這個區域不會觸發拖拽
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(0, 16.0, 16.0, 16.0),
                      child: _buildEditableReagentRow(reagent, originalIndex),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _onReorderReagents(int oldIndex, int newIndex) {
    // 取得可編輯的試劑清單（不包含 Water）
    List<Reagent> editableReagents = _reagents.where((r) => r.name != 'Water').toList();
    
    if (oldIndex >= 0 && oldIndex < editableReagents.length && 
        newIndex >= 0 && newIndex < editableReagents.length &&
        oldIndex != newIndex) {
      
      setState(() {
        // 在可編輯清單中重新排序
        final Reagent item = editableReagents.removeAt(oldIndex);
        editableReagents.insert(newIndex, item);
        
        // 更新主要的試劑清單，保持 Water 在最後
        List<Reagent> newReagents = List<Reagent>.from(editableReagents);
        Reagent? waterReagent = _reagents.firstWhere((r) => r.name == 'Water');
        newReagents.add(waterReagent);
        
        _reagents.clear();
        _reagents.addAll(newReagents);
        
        // 重新初始化控制器以確保順序正確
        _initializeEditControllers();
        
        // 重新計算體積
        _calculateVolumes();
      });
      
      // 提供觸覺反饋
      HapticFeedback.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          'PCR Calculator',
          style: TextStyle(color: widget.isDarkMode ? CupertinoColors.white : CupertinoColors.black),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            _showSettingsPage();
          },
          child: Icon(
            CupertinoIcons.settings,
            size: 24,
            color: widget.isDarkMode ? CupertinoColors.white : CupertinoColors.black,
          ),
        ),
      ),
      child: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            // 強制隱藏鍵盤 - 使用更強力的方法
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification notification) {
          // 移除滾動時自動關閉鍵盤，避免影響輸入體驗
          return false;
        },
          child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Parameters Section
            Container(
              decoration: BoxDecoration(
                color: widget.isDarkMode 
                    ? CupertinoColors.systemGrey6.darkColor
                    : CupertinoColors.systemBackground,
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
                      color: widget.isDarkMode ? CupertinoColors.white : CupertinoColors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 試驗名稱和日期行
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: CupertinoTextField(
                          controller: _experimentNameController,
                          placeholder: 'Experiment Name',
                          textInputAction: TextInputAction.done,
                          onEditingComplete: () {
                            final currentFocus = FocusScope.of(context);
                            if (currentFocus.hasFocus) {
                              currentFocus.unfocus();
                            }
                          },
                          style: TextStyle(color: widget.isDarkMode ? CupertinoColors.white : CupertinoColors.black),
                          placeholderStyle: TextStyle(color: CupertinoColors.placeholderText),
                          decoration: BoxDecoration(
                            color: widget.isDarkMode 
                                ? CupertinoColors.systemGrey5.darkColor
                                : CupertinoColors.tertiarySystemBackground,
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
                          decoration: BoxDecoration(
                            color: widget.isDarkMode 
                                ? CupertinoColors.systemGrey6.darkColor
                                : CupertinoColors.systemGrey6,
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Text(
                            _getTodayDate(),
                            style: TextStyle(
                              color: widget.isDarkMode ? CupertinoColors.white : CupertinoColors.black,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Number of Reactions',
                              style: TextStyle(
                                color: widget.isDarkMode ? CupertinoColors.white : CupertinoColors.black,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 6),
                            CupertinoTextField(
                              controller: _numReactionsController,
                              placeholder: '# RXN',
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.next,
                              onEditingComplete: () {
                                // 安全的焦點跳轉
                                FocusScope.of(context).nextFocus();
                              },
                              inputFormatters: [BankStyleIntegerFormatter(maxDigits: 3)],
                              style: TextStyle(color: widget.isDarkMode ? CupertinoColors.white : CupertinoColors.black),
                              placeholderStyle: TextStyle(color: CupertinoColors.placeholderText),
                              decoration: BoxDecoration(
                                color: widget.isDarkMode 
                                    ? CupertinoColors.systemGrey5.darkColor
                                    : CupertinoColors.tertiarySystemBackground,
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
                              onChanged: (value) => _calculateVolumes(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'RXN Vol (µl)',
                              style: TextStyle(
                                color: widget.isDarkMode ? CupertinoColors.white : CupertinoColors.black,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 6),
                            CupertinoTextField(
                              controller: _customReactionVolumeController,
                              placeholder: 'Volume',
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.next,
                              onEditingComplete: () {
                                // 安全的焦點跳轉
                                FocusScope.of(context).nextFocus();
                              },
                              inputFormatters: [BankStyleDecimalFormatter(decimalPlaces: 1, maxDigits: 5)],
                              style: TextStyle(color: widget.isDarkMode ? CupertinoColors.white : CupertinoColors.black),
                              placeholderStyle: TextStyle(color: CupertinoColors.placeholderText),
                              decoration: BoxDecoration(
                                color: widget.isDarkMode 
                                    ? CupertinoColors.systemGrey5.darkColor
                                    : CupertinoColors.tertiarySystemBackground,
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
                              onChanged: (value) => _calculateVolumes(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Template DNA Vol (µl)',
                        style: TextStyle(
                          color: widget.isDarkMode ? CupertinoColors.white : CupertinoColors.black,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      CupertinoTextField(
                        controller: _templateDnaVolumeController,
                        placeholder: 'Template Volume',
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        onEditingComplete: () {
                          final currentFocus = FocusScope.of(context);
                          if (currentFocus.hasFocus) {
                            currentFocus.unfocus();
                          }
                        },
                        inputFormatters: [BankStyleDecimalFormatter(decimalPlaces: 1, maxDigits: 5)],
                        style: TextStyle(color: widget.isDarkMode ? CupertinoColors.white : CupertinoColors.black),
                        placeholderStyle: TextStyle(color: CupertinoColors.placeholderText),
                        decoration: BoxDecoration(
                          color: widget.isDarkMode 
                              ? CupertinoColors.systemGrey5.darkColor
                              : CupertinoColors.tertiarySystemBackground,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
                        onChanged: (value) => _calculateVolumes(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: CupertinoButton.filled(
                          onPressed: _clearAllInputs,
                          child: Text(
                            'Clear',
                            style: TextStyle(color: CupertinoColors.white),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: CupertinoButton.filled(
                          onPressed: _printResults,
                          child: Text(
                            'Print',
                            style: TextStyle(color: CupertinoColors.white),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: CupertinoButton.filled(
                          onPressed: _copyResults,
                          child: Text(
                            'Copy',
                            style: TextStyle(color: CupertinoColors.white),
                          ),
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
                                color: widget.isDarkMode ? CupertinoColors.white : CupertinoColors.black,
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
            const SizedBox(height: 8),            // Reagents List
            // Always show reagents list, even if calculations are empty
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
                          color: widget.isDarkMode ? CupertinoColors.systemGrey : CupertinoColors.secondaryLabel,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'µl/rxn',
                        textAlign: TextAlign.center,
                        style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                          fontWeight: FontWeight.w600,
                          color: widget.isDarkMode ? CupertinoColors.systemGrey : CupertinoColors.secondaryLabel,
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
                          color: widget.isDarkMode ? CupertinoColors.systemGrey : CupertinoColors.secondaryLabel,
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
                          color: widget.isDarkMode ? CupertinoColors.systemGrey : CupertinoColors.secondaryLabel,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: Text(
                        '50 µl/rxn',
                        textAlign: TextAlign.center,
                        style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                          fontWeight: FontWeight.w600,
                          color: widget.isDarkMode ? CupertinoColors.systemGrey : CupertinoColors.secondaryLabel,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Optional',
                      style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                        fontWeight: FontWeight.w600,
                        color: widget.isDarkMode ? CupertinoColors.systemGrey : CupertinoColors.secondaryLabel,
                      ),
                    ),
                  ],
                ),
              ),
            
            // 編輯模式：支援拖拽排序的試劑清單
            if (_isEditMode) ...[
              ..._buildDraggableReagentsList(),
              // Add new reagent button in edit mode
              Container(
                margin: const EdgeInsets.symmetric(vertical: 4.0),
                child: CupertinoButton(
                  onPressed: _addNewReagent,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(CupertinoIcons.add),
                      const SizedBox(width: 8),
                      Text(
                        'Add New Reagent',
                        style: TextStyle(
                          color: CupertinoColors.systemBlue,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            // 正常顯示模式
            if (!_isEditMode)
              for (var i = 0; i < _reagents.length; i++)
                if (_calculatedTotalVolumes.containsKey(_reagents[i].name))
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 4.0),
                    decoration: BoxDecoration(
                      color: widget.isDarkMode 
                          ? CupertinoColors.systemGrey6.darkColor
                          : CupertinoColors.systemBackground,
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(
                        color: CupertinoColors.separator,
                        width: 0.5,
                      ),
                    ),
                    padding: const EdgeInsets.all(16.0),
                    child: _buildDisplayReagentRow(_reagents[i]),
                  ),
          ],
        ),
        ), // NotificationListener
        ), // GestureDetector
      ), // SafeArea
    );
  }
}

// PCR Step 資料結構
class PcrStep {
  final String id;
  final String name;
  final double temperature;
  final int duration; // 秒
  final bool isEnabled;
  
  PcrStep({
    String? id,
    required this.name,
    required this.temperature,
    required this.duration,
    this.isEnabled = true,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString() + name.hashCode.toString();
  
  PcrStep copyWith({
    String? name,
    double? temperature,
    int? duration,
    bool? isEnabled,
  }) {
    return PcrStep(
      id: id,
      name: name ?? this.name,
      temperature: temperature ?? this.temperature,
      duration: duration ?? this.duration,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'temperature': temperature,
      'duration': duration,
      'isEnabled': isEnabled,
    };
  }
  
  factory PcrStep.fromJson(Map<String, dynamic> json) {
    return PcrStep(
      id: json['id'],
      name: json['name'] ?? '',
      temperature: (json['temperature'] ?? 0.0).toDouble(),
      duration: json['duration'] ?? 0,
      isEnabled: json['isEnabled'] ?? true,
    );
  }
}

// PCR Stage 資料結構
class PcrStage {
  final String id;
  final String name;
  final int cycles;
  final List<PcrStep> steps;
  final bool isEnabled;
  
  PcrStage({
    String? id,
    required this.name,
    required this.cycles,
    required this.steps,
    this.isEnabled = true,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString() + name.hashCode.toString();
  
  PcrStage copyWith({
    String? name,
    int? cycles,
    List<PcrStep>? steps,
    bool? isEnabled,
  }) {
    return PcrStage(
      id: id,
      name: name ?? this.name,
      cycles: cycles ?? this.cycles,
      steps: steps ?? this.steps,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'cycles': cycles,
      'steps': steps.map((s) => s.toJson()).toList(),
      'isEnabled': isEnabled,
    };
  }
  
  factory PcrStage.fromJson(Map<String, dynamic> json) {
    return PcrStage(
      id: json['id'],
      name: json['name'] ?? '',
      cycles: json['cycles'] ?? 1,
      steps: (json['steps'] as List? ?? [])
          .map((s) => PcrStep.fromJson(s as Map<String, dynamic>))
          .toList(),
      isEnabled: json['isEnabled'] ?? true,
    );
  }
  
  // 計算這個 Stage 的總時間（秒）
  double getTotalTime() {
    double stepTime = 0;
    for (var step in steps) {
      if (step.isEnabled) {
        stepTime += step.duration;
      }
    }
    return stepTime * cycles;
  }
}

// 可編輯的 PCR 步驟，包含控制器和 UI 資訊
class EditablePcrStep {
  final String id;
  String name;
  final String subtitle;
  final IconData icon;
  final TextEditingController nameController;
  final TextEditingController tempController;
  final TextEditingController timeController;
  bool isEnabled;
  
  EditablePcrStep({
    String? id,
    required this.name,
    required this.subtitle,
    required this.icon,
    required double temperature,
    required int duration,
    this.isEnabled = true,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString() + name.hashCode.toString(),
       nameController = TextEditingController(text: name),
       tempController = TextEditingController(text: temperature.toStringAsFixed(1)),
       timeController = TextEditingController(text: TimeInputFormatter.formatSecondsToTime(duration));
  
  // 獲取溫度值
  double get temperature => double.tryParse(tempController.text) ?? 0.0;
  
  // 獲取時間值
  int get duration => TimeInputFormatter.parseTimeToSeconds(timeController.text);
  
  // 獲取 PcrStep 對象
  PcrStep toPcrStep() {
    return PcrStep(
      id: id,
      name: name,
      temperature: temperature,
      duration: duration,
      isEnabled: isEnabled,
    );
  }
  
  // 從 PcrStep 創建 EditablePcrStep
  factory EditablePcrStep.fromPcrStep(PcrStep step, {
    required String subtitle,
    required IconData icon,
  }) {
    return EditablePcrStep(
      id: step.id,
      name: step.name,
      subtitle: subtitle,
      icon: icon,
      temperature: step.temperature,
      duration: step.duration,
      isEnabled: step.isEnabled,
    );
  }
  
  void dispose() {
    nameController.dispose();
    tempController.dispose();
    timeController.dispose();
  }
}

// 可編輯的 PCR Stage
class EditablePcrStage {
  final String id;
  String name;
  final TextEditingController nameController;
  final TextEditingController cyclesController;
  List<EditablePcrStep> steps;
  bool isEnabled;
  
  EditablePcrStage({
    String? id,
    required this.name,
    required int cycles,
    required this.steps,
    this.isEnabled = true,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString() + name.hashCode.toString(),
       nameController = TextEditingController(text: name),
       cyclesController = TextEditingController(text: cycles.toString());
  
  // 獲取循環次數
  int get cycles => int.tryParse(cyclesController.text) ?? 1;
  
  // 獲取 PcrStage 對象
  PcrStage toPcrStage() {
    return PcrStage(
      id: id,
      name: name,
      cycles: cycles,
      steps: steps.map((s) => s.toPcrStep()).toList(),
      isEnabled: isEnabled,
    );
  }
  
  // 從 PcrStage 創建 EditablePcrStage
  factory EditablePcrStage.fromPcrStage(PcrStage stage) {
    return EditablePcrStage(
      id: stage.id,
      name: stage.name,
      cycles: stage.cycles,
      steps: stage.steps.map((step) => EditablePcrStep.fromPcrStep(
        step,
        subtitle: _getStepSubtitle(step.name),
        icon: _getStepIcon(step.name),
      )).toList(),
      isEnabled: stage.isEnabled,
    );
  }
  
  void dispose() {
    nameController.dispose();
    cyclesController.dispose();
    for (var step in steps) {
      step.dispose();
    }
  }
  
  static String _getStepSubtitle(String stepName) {
    switch (stepName.toLowerCase()) {
      case 'initial denaturation':
        return 'One-time step at the beginning';
      case 'denaturation':
        return 'Separate DNA strands';
      case 'annealing':
        return 'Primer binding';
      case 'extension':
        return 'DNA synthesis';
      case 'final extension':
        return 'Complete incomplete products';
      case 'hold':
        return 'Hold temperature';
      default:
        return 'PCR step';
    }
  }
  
  static IconData _getStepIcon(String stepName) {
    switch (stepName.toLowerCase()) {
      case 'initial denaturation':
        return CupertinoIcons.flame;
      case 'denaturation':
        return CupertinoIcons.flame_fill;
      case 'annealing':
        return CupertinoIcons.link;
      case 'extension':
        return CupertinoIcons.arrow_right_circle_fill;
      case 'final extension':
        return CupertinoIcons.checkmark_circle_fill;
      case 'hold':
        return CupertinoIcons.pause_circle;
      default:
        return CupertinoIcons.circle;
    }
  }
}

// PCR Protocol 資料結構
class PcrProtocol {
  final String name;
  final List<PcrStage> stages;
  
  PcrProtocol({
    required this.name,
    required this.stages,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'stages': stages.map((s) => s.toJson()).toList(),
    };
  }
  
  factory PcrProtocol.fromJson(Map<String, dynamic> json) {
    return PcrProtocol(
      name: json['name'] ?? '',
      stages: (json['stages'] as List? ?? [])
          .map((s) => PcrStage.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }
  
  // 計算總時間（分鐘）
  double getTotalTime() {
    double totalSeconds = 0;
    
    for (var stage in stages) {
      if (stage.isEnabled) {
        totalSeconds += stage.getTotalTime();
      }
    }
    
    return totalSeconds / 60.0; // 轉換為分鐘
  }
}

// PCR Reaction 頁面
class PcrReactionPage extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onToggleTheme;
  
  const PcrReactionPage({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
  });
  
  @override
  State<PcrReactionPage> createState() => _PcrReactionPageState();
}

class _PcrReactionPageState extends State<PcrReactionPage> {
  final TextEditingController _protocolNameController = TextEditingController();
  
  final String _currentProtocolName = 'Standard PCR Protocol';
  bool _isEditMode = false;
  
  // 可編輯的 Stage 列表
  final List<EditablePcrStage> _stages = [];
  
  // 拖拽相關的狀態 (預留給未來的拖拽功能)
  // int? _draggedStageIndex;
  // int? _draggedStepIndex;  
  // String? _draggedStepStageId;
  
  @override
  void initState() {
    super.initState();
    _protocolNameController.text = _currentProtocolName;
    _initializeDefaultStages();
  }
  
  @override
  void dispose() {
    _protocolNameController.dispose();
    for (var stage in _stages) {
      stage.dispose();
    }
    super.dispose();
  }
  
  void _initializeDefaultStages() {
    _stages.clear();
    
    // Stage 1: Initial Denaturation
    _stages.add(EditablePcrStage(
      name: 'Initial Denaturation',
      cycles: 1,
      steps: [
        EditablePcrStep(
          name: 'Initial Denaturation',
          subtitle: 'One-time step at the beginning',
          icon: CupertinoIcons.flame,
          temperature: 95.0,
          duration: 300,
        ),
      ],
    ));
    
    // Stage 2: PCR Cycling
    _stages.add(EditablePcrStage(
      name: 'PCR Cycling',
      cycles: 35,
      steps: [
        EditablePcrStep(
          name: 'Denaturation',
          subtitle: 'Separate DNA strands',
          icon: CupertinoIcons.flame_fill,
          temperature: 95.0,
          duration: 30,
        ),
        EditablePcrStep(
          name: 'Annealing',
          subtitle: 'Primer binding',
          icon: CupertinoIcons.link,
          temperature: 55.0,
          duration: 30,
        ),
        EditablePcrStep(
          name: 'Extension',
          subtitle: 'DNA synthesis',
          icon: CupertinoIcons.arrow_right_circle_fill,
          temperature: 72.0,
          duration: 60,
        ),
      ],
    ));
    
    // Stage 3: Final Steps
    _stages.add(EditablePcrStage(
      name: 'Final Steps',
      cycles: 1,
      steps: [
        EditablePcrStep(
          name: 'Final Extension',
          subtitle: 'Complete incomplete products',
          icon: CupertinoIcons.checkmark_circle_fill,
          temperature: 72.0,
          duration: 600,
        ),
        EditablePcrStep(
          name: 'Hold',
          subtitle: 'Hold temperature',
          icon: CupertinoIcons.pause_circle,
          temperature: 4.0,
          duration: 0, // Infinite hold - 顯示為 ∞
        ),
      ],
    ));
  }
  
  PcrProtocol _getCurrentProtocol() {
    return PcrProtocol(
      name: _protocolNameController.text.isNotEmpty ? _protocolNameController.text : 'Unnamed Protocol',
      stages: _stages.map((stage) => stage.toPcrStage()).toList(),
    );
  }
  
  // Stage 操作方法
  void _addNewStage() {
    setState(() {
      _stages.add(EditablePcrStage(
        name: 'Custom Stage ${_stages.length + 1}',
        cycles: 1,
        steps: [
          EditablePcrStep(
            name: 'Custom Step',
            subtitle: 'Custom PCR step',
            icon: CupertinoIcons.gear_alt,
            temperature: 72.0,
            duration: 30,
          ),
        ],
      ));
    });
  }
  
  void _deleteStage(int stageIndex) {
    if (stageIndex >= 0 && stageIndex < _stages.length) {
      setState(() {
        _stages[stageIndex].dispose();
        _stages.removeAt(stageIndex);
      });
    }
  }
  
  // 移動 Stage 的方法 (待實現拖拽功能時使用)
  // void _moveStage(int oldIndex, int newIndex) { ... }
  
  void _toggleStageEnabled(int stageIndex) {
    if (stageIndex >= 0 && stageIndex < _stages.length) {
      setState(() {
        _stages[stageIndex].isEnabled = !_stages[stageIndex].isEnabled;
      });
    }
  }
  
  // Stage 拖拽排序方法
  void _onReorderStages(int oldIndex, int newIndex) {
    if (oldIndex >= 0 && oldIndex < _stages.length && 
        newIndex >= 0 && newIndex < _stages.length &&
        oldIndex != newIndex) {
      
      setState(() {
        final stage = _stages.removeAt(oldIndex);
        _stages.insert(newIndex, stage);
      });
      
      // 提供觸覺反饋
      HapticFeedback.lightImpact();
    }
  }
  
  // 建構可拖拽的 Stage 列表
  List<Widget> _buildDraggableStagesList() {
    List<Widget> widgets = [];
    for (int index = 0; index < _stages.length; index++) {
      widgets.add(
        _buildDraggableStageItem(_stages[index], index),
      );
    }
    return widgets;
  }
  
  Widget _buildDraggableStageItem(EditablePcrStage stage, int stageIndex) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: DragTarget<int>(
        onWillAcceptWithDetails: (details) {
          return details.data != stageIndex;
        },
        onAcceptWithDetails: (details) {
          if (details.data != stageIndex) {
            _onReorderStages(details.data, stageIndex);
          }
        },
        builder: (context, candidateData, rejectedData) {
          bool isHighlighted = candidateData.isNotEmpty;
          
          return AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: isHighlighted
                  ? CupertinoColors.systemBlue.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12.0),
              border: isHighlighted ? Border.all(
                color: CupertinoColors.systemBlue,
                width: 2.0,
              ) : null,
            ),
            child: Row(
              children: [
                // 拖拽手柄 - 只有這個區域可以觸發拖拽
                if (_isEditMode)
                  Draggable<int>(
                    data: stageIndex,
                    feedback: Material(
                      color: Colors.transparent,
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: widget.isDarkMode 
                              ? CupertinoColors.systemGrey6.darkColor
                              : CupertinoColors.systemBackground,
                          borderRadius: BorderRadius.circular(12.0),
                          border: Border.all(
                            color: CupertinoColors.systemBlue,
                            width: 2.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: CupertinoColors.systemBlue.withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          CupertinoIcons.bars,
                          color: CupertinoColors.systemBlue,
                          size: 24,
                        ),
                      ),
                    ),
                    childWhenDragging: Container(
                      padding: const EdgeInsets.all(8.0),
                      child: Icon(
                        CupertinoIcons.bars,
                        color: CupertinoColors.secondaryLabel,
                        size: 20,
                      ),
                    ),
                    onDragStarted: () {
                      HapticFeedback.mediumImpact();
                    },
                    onDragEnd: (details) {
                      // 拖拽結束
                    },
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Icon(
                          CupertinoIcons.bars,
                          color: CupertinoColors.systemGrey,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                // Stage 內容
                Expanded(
                  child: _buildStageCard(stage, stageIndex),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  
  // Step 操作方法
  void _addNewStep(int stageIndex) {
    if (stageIndex >= 0 && stageIndex < _stages.length) {
      setState(() {
        _stages[stageIndex].steps.add(EditablePcrStep(
          name: 'New Step',
          subtitle: 'Custom PCR step',
          icon: CupertinoIcons.gear_alt,
          temperature: 72.0,
          duration: 30,
        ));
      });
    }
  }
  
  void _deleteStep(int stageIndex, int stepIndex) {
    if (stageIndex >= 0 && stageIndex < _stages.length &&
        stepIndex >= 0 && stepIndex < _stages[stageIndex].steps.length) {
      setState(() {
        _stages[stageIndex].steps[stepIndex].dispose();
        _stages[stageIndex].steps.removeAt(stepIndex);
      });
    }
  }
  
  // 移動 Step 的方法 (待實現拖拽功能時使用)
  // void _moveStep(int fromStageIndex, int fromStepIndex, int toStageIndex, int toStepIndex) { ... }
  
  void _toggleStepEnabled(int stageIndex, int stepIndex) {
    if (stageIndex >= 0 && stageIndex < _stages.length &&
        stepIndex >= 0 && stepIndex < _stages[stageIndex].steps.length) {
      setState(() {
        _stages[stageIndex].steps[stepIndex].isEnabled = 
            !_stages[stageIndex].steps[stepIndex].isEnabled;
      });
    }
  }
  
  // Step 拖拽排序方法
  void _onReorderSteps(int stageIndex, int oldIndex, int newIndex) {
    if (stageIndex >= 0 && stageIndex < _stages.length &&
        oldIndex >= 0 && oldIndex < _stages[stageIndex].steps.length && 
        newIndex >= 0 && newIndex < _stages[stageIndex].steps.length &&
        oldIndex != newIndex) {
      
      setState(() {
        final step = _stages[stageIndex].steps.removeAt(oldIndex);
        _stages[stageIndex].steps.insert(newIndex, step);
      });
      
      // 提供觸覺反饋
      HapticFeedback.lightImpact();
    }
  }
  
  // 建構可拖拽的 Step 列表
  List<Widget> _buildDraggableStepsList(int stageIndex) {
    if (stageIndex < 0 || stageIndex >= _stages.length) return [];
    
    List<Widget> widgets = [];
    for (int index = 0; index < _stages[stageIndex].steps.length; index++) {
      widgets.add(
        _buildDraggableStepItem(_stages[stageIndex].steps[index], stageIndex, index),
      );
    }
    return widgets;
  }
  
  Widget _buildDraggableStepItem(EditablePcrStep step, int stageIndex, int stepIndex) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2.0),
      child: DragTarget<Map<String, int>>(
        onWillAcceptWithDetails: (details) {
          return details.data['stageIndex'] == stageIndex && details.data['stepIndex'] != stepIndex;
        },
        onAcceptWithDetails: (details) {
          if (details.data['stageIndex'] == stageIndex && details.data['stepIndex'] != stepIndex) {
            _onReorderSteps(stageIndex, details.data['stepIndex']!, stepIndex);
          }
        },
        builder: (context, candidateData, rejectedData) {
          bool isHighlighted = candidateData.isNotEmpty;
          
          return AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: isHighlighted
                  ? CupertinoColors.systemBlue.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8.0),
              border: isHighlighted ? Border.all(
                color: CupertinoColors.systemBlue,
                width: 1.0,
              ) : null,
            ),
            child: Row(
              children: [
                // 拖拽手柄 - 只有這個區域可以觸發拖拽
                if (_isEditMode)
                  Draggable<Map<String, int>>(
                    data: {'stageIndex': stageIndex, 'stepIndex': stepIndex},
                    feedback: Material(
                      color: Colors.transparent,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: widget.isDarkMode 
                              ? CupertinoColors.systemGrey6.darkColor
                              : CupertinoColors.systemBackground,
                          borderRadius: BorderRadius.circular(8.0),
                          border: Border.all(
                            color: CupertinoColors.systemBlue,
                            width: 2.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: CupertinoColors.systemBlue.withOpacity(0.4),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          CupertinoIcons.bars,
                          color: CupertinoColors.systemBlue,
                          size: 16,
                        ),
                      ),
                    ),
                    childWhenDragging: Container(
                      padding: const EdgeInsets.all(4.0),
                      child: Icon(
                        CupertinoIcons.bars,
                        color: CupertinoColors.secondaryLabel,
                        size: 16,
                      ),
                    ),
                    onDragStarted: () {
                      HapticFeedback.lightImpact();
                    },
                    onDragEnd: (details) {
                      // 拖拽結束
                    },
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4.0),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        child: Icon(
                          CupertinoIcons.bars,
                          color: CupertinoColors.systemGrey,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                // Step 內容
                Expanded(
                  child: _buildStepCard(step, stageIndex, stepIndex),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  
  // 格式化時間
  String _formatTime(int seconds) {
    // 使用新的 mm:ss 格式
    return TimeInputFormatter.formatSecondsToTime(seconds);
  }
  
  // 複製協議
  void _copyProtocol() {
    final protocol = _getCurrentProtocol();
    final StringBuffer buffer = StringBuffer();
    
    buffer.writeln('Lab Studio - PCR Protocol');
    buffer.writeln('Protocol Name: ${protocol.name}');
    buffer.writeln('Date: ${DateTime.now().toString().split(' ')[0]}');
    buffer.writeln('');
    buffer.writeln('Total Stages: ${protocol.stages.length}');
    buffer.writeln('Estimated Total Time: ${protocol.getTotalTime().toStringAsFixed(1)} minutes');
    buffer.writeln('');
    
    for (int i = 0; i < protocol.stages.length; i++) {
      final stage = protocol.stages[i];
      if (stage.isEnabled) {
        buffer.writeln('Stage ${i + 1}: ${stage.name} (${stage.cycles} cycles)');
        for (int j = 0; j < stage.steps.length; j++) {
          final step = stage.steps[j];
          if (step.isEnabled) {
            buffer.writeln('  Step ${j + 1}: ${step.name} - ${step.temperature}°C for ${_formatTime(step.duration)}');
          }
        }
        buffer.writeln('');
      }
    }
    
    Clipboard.setData(ClipboardData(text: buffer.toString()));
  }
  
  // 清除所有輸入
  void _clearAllInputs() {
    setState(() {
      _protocolNameController.text = 'Standard PCR Protocol';
      // 清理舊的 stages
      for (var stage in _stages) {
        stage.dispose();
      }
      _initializeDefaultStages();
    });
  }
  
  // 創建標準 3-step 協議
  void _createStandardProtocol() {
    setState(() {
      for (var stage in _stages) {
        stage.dispose();
      }
      _initializeDefaultStages();
    });
  }
  
  // 創建 2-step 協議
  void _create2StepProtocol() {
    setState(() {
      for (var stage in _stages) {
        stage.dispose();
      }
      _stages.clear();
      
      // Stage 1: Initial Denaturation
      _stages.add(EditablePcrStage(
        name: 'Initial Denaturation',
        cycles: 1,
        steps: [
          EditablePcrStep(
            name: 'Initial Denaturation',
            subtitle: 'One-time step at the beginning',
            icon: CupertinoIcons.flame,
            temperature: 95.0,
            duration: 300,
          ),
        ],
      ));
      
      // Stage 2: PCR Cycling (2-step)
      _stages.add(EditablePcrStage(
        name: 'PCR Cycling',
        cycles: 35,
        steps: [
          EditablePcrStep(
            name: 'Denaturation',
            subtitle: 'Separate DNA strands',
            icon: CupertinoIcons.flame_fill,
            temperature: 95.0,
            duration: 30,
          ),
          EditablePcrStep(
            name: 'Annealing/Extension',
            subtitle: 'Primer binding and DNA synthesis',
            icon: CupertinoIcons.arrow_right_circle_fill,
            temperature: 60.0,
            duration: 90,
          ),
        ],
      ));
      
      // Stage 3: Final Steps
      _stages.add(EditablePcrStage(
        name: 'Final Steps',
        cycles: 1,
        steps: [
          EditablePcrStep(
            name: 'Final Extension',
            subtitle: 'Complete incomplete products',
            icon: CupertinoIcons.checkmark_circle_fill,
            temperature: 72.0,
            duration: 600,
          ),
          EditablePcrStep(
            name: 'Hold',
            subtitle: 'Hold temperature',
            icon: CupertinoIcons.pause_circle,
            temperature: 4.0,
            duration: 0, // Infinite hold - 顯示為 ∞
          ),
        ],
      ));
    });
  }
  
  // UI 建構方法
  Widget _buildStageCard(EditablePcrStage stage, int stageIndex) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: widget.isDarkMode 
            ? CupertinoColors.systemGrey6.darkColor
            : CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: stage.isEnabled 
              ? CupertinoColors.separator
              : CupertinoColors.systemGrey4,
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stage 標題行
          Container(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_isEditMode)
                        CupertinoTextField(
                          controller: stage.nameController,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: widget.isDarkMode ? CupertinoColors.white : CupertinoColors.black,
                          ),
                          decoration: BoxDecoration(
                            color: widget.isDarkMode 
                                ? CupertinoColors.systemGrey5.darkColor
                                : CupertinoColors.tertiarySystemBackground,
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          // 移除 onChanged 中的 setState，避免輸入時重建導致失焦
                          // onChanged: (value) {
                          //   setState(() {
                          //     stage.name = value;
                          //   });
                          // },
                        )
                      else
                        Text(
                          stage.nameController.text,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: stage.isEnabled
                                ? (widget.isDarkMode ? CupertinoColors.white : CupertinoColors.black)
                                : CupertinoColors.systemGrey,
                          ),
                        ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            'Cycles: ',
                            style: TextStyle(
                              fontSize: 14,
                              color: widget.isDarkMode ? CupertinoColors.systemGrey2 : CupertinoColors.secondaryLabel,
                            ),
                          ),
                          if (_isEditMode)
                            SizedBox(
                              width: 80,
                              child: CupertinoTextField(
                                controller: stage.cyclesController,
                                keyboardType: TextInputType.number,
                                textInputAction: TextInputAction.done,
                                onEditingComplete: () {
                                  FocusScope.of(context).unfocus();
                                },
                                style: TextStyle(
                                  fontSize: 14,
                                  color: widget.isDarkMode ? CupertinoColors.white : CupertinoColors.black,
                                ),
                                decoration: BoxDecoration(
                                  color: widget.isDarkMode 
                                      ? CupertinoColors.systemGrey5.darkColor
                                      : CupertinoColors.tertiarySystemBackground,
                                  borderRadius: BorderRadius.circular(6.0),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                                // 移除 onChanged 中的 setState，避免輸入時重建導致失焦
                                // onChanged: (value) => setState(() {}),
                              ),
                            )
                          else
                            Text(
                              stage.cyclesController.text,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: stage.isEnabled
                                    ? (widget.isDarkMode ? CupertinoColors.white : CupertinoColors.black)
                                    : CupertinoColors.systemGrey,
                              ),
                            ),
                          const Spacer(),
                          if (_isEditMode) ...[
                            // 新增 Step 按鈕
                            CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: () => _addNewStep(stageIndex),
                              child: const Icon(
                                CupertinoIcons.add_circled,
                                color: CupertinoColors.systemBlue,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 8),
                            // 刪除 Stage 按鈕
                            CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: () => _deleteStage(stageIndex),
                              child: const Icon(
                                CupertinoIcons.delete,
                                color: CupertinoColors.destructiveRed,
                                size: 20,
                              ),
                            ),
                          ],
                          // 啟用/停用開關
                          Transform.scale(
                            scale: 0.8,
                            child: CupertinoSwitch(
                              value: stage.isEnabled,
                              onChanged: (value) => _toggleStageEnabled(stageIndex),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Steps
          if (stage.isEnabled)
            if (_isEditMode)
              ..._buildDraggableStepsList(stageIndex)
            else
              ...List.generate(stage.steps.length, (stepIndex) {
                return _buildStepCard(stage.steps[stepIndex], stageIndex, stepIndex);
              }),
        ],
      ),
    );
  }
  
  Widget _buildStepCard(EditablePcrStep step, int stageIndex, int stepIndex) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 8.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: widget.isDarkMode 
            ? CupertinoColors.systemGrey5.darkColor
            : CupertinoColors.tertiarySystemBackground,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        children: [
          // Step 圖示
          Icon(
            step.icon,
            color: step.isEnabled 
                ? CupertinoColors.systemBlue 
                : CupertinoColors.systemGrey,
            size: 18,
          ),
          const SizedBox(width: 8),
          // Step 內容
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isEditMode)
                  CupertinoTextField(
                    controller: step.nameController,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: widget.isDarkMode ? CupertinoColors.white : CupertinoColors.black,
                    ),
                    decoration: BoxDecoration(
                      color: widget.isDarkMode 
                          ? CupertinoColors.systemGrey6.darkColor
                          : CupertinoColors.systemBackground,
                      borderRadius: BorderRadius.circular(6.0),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                    // 移除 onChanged 中的 setState，避免輸入時重建導致失焦
                    // onChanged: (value) {
                    //   step.name = value;
                    // },
                  )
                else
                  Text(
                    step.nameController.text,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: step.isEnabled
                          ? (widget.isDarkMode ? CupertinoColors.white : CupertinoColors.black)
                          : CupertinoColors.systemGrey,
                    ),
                  ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    // 溫度
                    if (_isEditMode)
                      Flexible(
                        flex: 1,
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 70),
                          child: CupertinoTextField(
                            controller: step.tempController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [BankStyleDecimalFormatter(decimalPlaces: 1, maxDigits: 5)],
                            textInputAction: TextInputAction.next,
                            onEditingComplete: () {
                              // 安全的焦點跳轉
                              FocusScope.of(context).nextFocus();
                            },
                            style: TextStyle(
                              fontSize: 12,
                              color: widget.isDarkMode ? CupertinoColors.white : CupertinoColors.black,
                            ),
                            decoration: BoxDecoration(
                              color: widget.isDarkMode 
                                  ? CupertinoColors.systemGrey6.darkColor
                                  : CupertinoColors.systemBackground,
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 6.0),
                            suffix: Text('°C', style: TextStyle(fontSize: 10, color: widget.isDarkMode ? CupertinoColors.systemGrey2 : CupertinoColors.secondaryLabel)),
                            // 移除 onChanged 中的 setState，避免輸入時重建導致失焦
                            // onChanged: (value) => setState(() {}),
                          ),
                        ),
                      )
                    else
                      Text(
                        '${step.tempController.text}°C',
                        style: TextStyle(
                          fontSize: 12,
                          color: widget.isDarkMode ? CupertinoColors.systemGrey2 : CupertinoColors.secondaryLabel,
                        ),
                      ),
                    const SizedBox(width: 12),
                    // 時間
                    if (_isEditMode)
                      Flexible(
                        flex: 1,
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 90),
                          child: CupertinoTextField(
                            controller: step.timeController,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.done,
                            onEditingComplete: () {
                              FocusScope.of(context).unfocus();
                            },
                            inputFormatters: [TimeInputFormatter()],
                            // 禁止長按選取和游標移動
                            enableInteractiveSelection: false,
                            // 禁止點選移動游標
                            onTap: () {
                              // 強制游標在最後
                              step.timeController.selection = TextSelection.collapsed(
                                offset: step.timeController.text.length,
                              );
                            },
                            style: TextStyle(
                              fontSize: 12,
                              color: widget.isDarkMode ? CupertinoColors.white : CupertinoColors.black,
                            ),
                            decoration: BoxDecoration(
                              color: widget.isDarkMode 
                                  ? CupertinoColors.systemGrey6.darkColor
                                  : CupertinoColors.systemBackground,
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 6.0),
                            // 移除 onChanged 中的 setState，避免輸入時重建導致失焦
                            // onChanged: (value) => setState(() {}),
                          ),
                        ),
                      )
                    else
                      Text(
                        _formatTime(TimeInputFormatter.parseTimeToSeconds(step.timeController.text)),
                        style: TextStyle(
                          fontSize: 12,
                          color: widget.isDarkMode ? CupertinoColors.systemGrey2 : CupertinoColors.secondaryLabel,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          // 控制按鈕
          if (_isEditMode) ...[
            const SizedBox(width: 8),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => _deleteStep(stageIndex, stepIndex),
              child: const Icon(
                CupertinoIcons.delete,
                color: CupertinoColors.destructiveRed,
                size: 16,
              ),
            ),
          ],
          // 啟用/停用開關
          Transform.scale(
            scale: 0.7,
            child: CupertinoSwitch(
              value: step.isEnabled,
              onChanged: (value) => _toggleStepEnabled(stageIndex, stepIndex),
            ),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final protocol = _getCurrentProtocol();
    
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          'PCR Reaction',
          style: TextStyle(color: widget.isDarkMode ? CupertinoColors.white : CupertinoColors.black),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 快速協議按鈕
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                _showProtocolTemplates();
              },
              child: Icon(
                CupertinoIcons.lab_flask,
                size: 24,
                color: widget.isDarkMode ? CupertinoColors.white : CupertinoColors.black,
              ),
            ),
            // 編輯按鈕
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                setState(() {
                  _isEditMode = !_isEditMode;
                });
              },
              child: Text(
                _isEditMode ? 'Done' : 'Edit',
                style: TextStyle(color: CupertinoColors.systemBlue),
              ),
            ),
          ],
        ),
      ),
      child: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            // 強制隱藏鍵盤 - 使用更強力的方法
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: NotificationListener<ScrollNotification>(
          onNotification: (ScrollNotification notification) {
            // 移除滾動時自動關閉鍵盤，避免影響輸入體驗
            return false;
          },
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
              // 協議名稱和總覽
              Container(
                decoration: BoxDecoration(
                  color: widget.isDarkMode 
                      ? CupertinoColors.systemGrey6.darkColor
                      : CupertinoColors.systemBackground,
                  borderRadius: BorderRadius.circular(12.0),
                ),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Protocol Configuration',
                      style: CupertinoTheme.of(context).textTheme.navLargeTitleTextStyle.copyWith(
                        fontSize: 20,
                        color: widget.isDarkMode ? CupertinoColors.white : CupertinoColors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    CupertinoTextField(
                      controller: _protocolNameController,
                      placeholder: 'Protocol Name',
                      textInputAction: TextInputAction.done,
                      onEditingComplete: () {
                        FocusScope.of(context).unfocus();
                      },
                      style: TextStyle(color: widget.isDarkMode ? CupertinoColors.white : CupertinoColors.black),
                      placeholderStyle: TextStyle(color: CupertinoColors.placeholderText),
                      decoration: BoxDecoration(
                        color: widget.isDarkMode 
                            ? CupertinoColors.systemGrey5.darkColor
                            : CupertinoColors.tertiarySystemBackground,
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total Stages',
                                style: TextStyle(
                                  color: widget.isDarkMode ? CupertinoColors.white : CupertinoColors.black,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
                                decoration: BoxDecoration(
                                  color: widget.isDarkMode 
                                      ? CupertinoColors.systemGrey5.darkColor
                                      : CupertinoColors.systemGrey6,
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                child: Text(
                                  '${protocol.stages.length}',
                                  style: TextStyle(
                                    color: widget.isDarkMode ? CupertinoColors.white : CupertinoColors.black,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total Time',
                                style: TextStyle(
                                  color: widget.isDarkMode ? CupertinoColors.white : CupertinoColors.black,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
                                decoration: BoxDecoration(
                                  color: widget.isDarkMode 
                                      ? CupertinoColors.systemGrey5.darkColor
                                      : CupertinoColors.systemGrey6,
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                child: Text(
                                  '${protocol.getTotalTime().toStringAsFixed(1)} min',
                                  style: TextStyle(
                                    color: widget.isDarkMode ? CupertinoColors.white : CupertinoColors.black,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: CupertinoButton.filled(
                            onPressed: _clearAllInputs,
                            child: Text(
                              'Clear',
                              style: TextStyle(color: CupertinoColors.white),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: CupertinoButton.filled(
                            onPressed: _copyProtocol,
                            child: Text(
                              'Copy',
                              style: TextStyle(color: CupertinoColors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // PCR Stages 設定標題和編輯模式按鈕
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'PCR Stages',
                    style: CupertinoTheme.of(context).textTheme.navLargeTitleTextStyle.copyWith(
                      fontSize: 18,
                      color: widget.isDarkMode ? CupertinoColors.white : CupertinoColors.black,
                    ),
                  ),
                  if (_isEditMode)
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: _addNewStage,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            CupertinoIcons.add_circled,
                            color: CupertinoColors.systemBlue,
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Add Stage',
                            style: TextStyle(
                              color: CupertinoColors.systemBlue,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Stages 列表
              if (_isEditMode)
                ..._buildDraggableStagesList()
              else
                ...List.generate(_stages.length, (index) {
                  return _buildStageCard(_stages[index], index);
                }),
              
              const SizedBox(height: 32),
            ],
          ),
        ), // NotificationListener
        ), // GestureDetector  
      ), // SafeArea
    );
  }
  
  void _showProtocolTemplates() {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.4,
          decoration: BoxDecoration(
            color: widget.isDarkMode 
                ? CupertinoColors.systemGrey6.darkColor
                : CupertinoColors.systemBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
                    Text(
                      'Protocol Templates',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: widget.isDarkMode ? CupertinoColors.white : CupertinoColors.black,
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: CupertinoColors.systemBlue),
                      ),
                    ),
                  ],
                ),
              ),
              // 模板選項
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _buildTemplateCard(
                      title: 'Standard 3-Step PCR',
                      subtitle: 'Denaturation → Annealing → Extension',
                      icon: CupertinoIcons.lab_flask,
                      onTap: () {
                        Navigator.of(context).pop();
                        _createStandardProtocol();
                      },
                    ),
                    _buildTemplateCard(
                      title: '2-Step PCR',
                      subtitle: 'Denaturation → Annealing/Extension',
                      icon: CupertinoIcons.arrow_2_circlepath,
                      onTap: () {
                        Navigator.of(context).pop();
                        _create2StepProtocol();
                      },
                    ),
                    _buildTemplateCard(
                      title: 'Custom Protocol',
                      subtitle: 'Start with empty protocol',
                      icon: CupertinoIcons.gear_alt,
                      onTap: () {
                        Navigator.of(context).pop();
                        setState(() {
                          for (var stage in _stages) {
                            stage.dispose();
                          }
                          _stages.clear();
                          _isEditMode = true;
                        });
                      },
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
  
  Widget _buildTemplateCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: CupertinoListTile(
        leading: Icon(
          icon,
          color: CupertinoColors.systemBlue,
          size: 24,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: widget.isDarkMode ? CupertinoColors.white : CupertinoColors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: widget.isDarkMode ? CupertinoColors.systemGrey2 : CupertinoColors.secondaryLabel,
          ),
        ),
        trailing: Icon(
          CupertinoIcons.forward,
          color: CupertinoColors.systemGrey,
          size: 16,
        ),
        onTap: onTap,
      ),
    );
  }
}

// Settings Page
class SettingsPage extends StatelessWidget {
  final bool isDarkMode;
  final VoidCallback onToggleTheme;
  final bool isExperimentTrackingMode;
  final VoidCallback onToggleExperimentTracking;
  final int trackingDisplayMode;
  final Function(int) onSetTrackingDisplayMode;

  const SettingsPage({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
    required this.isExperimentTrackingMode,
    required this.onToggleExperimentTracking,
    required this.trackingDisplayMode,
    required this.onSetTrackingDisplayMode,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.translucent,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          color: isDarkMode 
              ? CupertinoColors.systemGrey6.darkColor
              : CupertinoColors.systemBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
                Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? CupertinoColors.white : CupertinoColors.black,
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Done',
                    style: TextStyle(color: CupertinoColors.systemBlue),
                  ),
                ),
              ],
            ),
          ),
          // 設定選項
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                // 深色模式
                CupertinoListTile(
                  title: Text(
                    'Dark Mode',
                    style: TextStyle(
                      color: isDarkMode ? CupertinoColors.white : CupertinoColors.black,
                    ),
                  ),
                  trailing: CupertinoSwitch(
                    value: isDarkMode,
                    onChanged: (value) => onToggleTheme(),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // 實驗追蹤模式
                CupertinoListTile(
                  title: Text(
                    'Experiment Tracking',
                    style: TextStyle(
                      color: isDarkMode ? CupertinoColors.white : CupertinoColors.black,
                    ),
                  ),
                  subtitle: Text(
                    'Track which reagents have been added',
                    style: TextStyle(
                      color: isDarkMode ? CupertinoColors.systemGrey2 : CupertinoColors.secondaryLabel,
                    ),
                  ),
                  trailing: CupertinoSwitch(
                    value: isExperimentTrackingMode,
                    onChanged: (value) => onToggleExperimentTracking(),
                  ),
                ),
                
                if (isExperimentTrackingMode) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Tracking Display Mode',
                    style: TextStyle(
                      color: isDarkMode ? CupertinoColors.white : CupertinoColors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  CupertinoSlidingSegmentedControl<int>(
                    groupValue: trackingDisplayMode,
                    children: const {
                      0: Text('Checkbox'),
                      1: Text('Strikethrough'),
                    },
                    onValueChanged: (int? value) {
                      if (value != null) {
                        onSetTrackingDisplayMode(value);
                      }
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
      ), // Container (wrapped by GestureDetector)
    ); // GestureDetector
  }
}

// Configuration Selector
class ConfigurationSelector extends StatefulWidget {
  final List<PcrConfiguration> initialConfigs;
  final Function(PcrConfiguration) onConfigurationSelected;
  final Function(PcrConfiguration) onDeleteConfiguration;
  final Function(String) onShowError;
  final Function(String) onShowSuccess;
  final bool isDarkMode;

  const ConfigurationSelector({
    super.key,
    required this.initialConfigs,
    required this.onConfigurationSelected,
    required this.onDeleteConfiguration,
    required this.onShowError,
    required this.onShowSuccess,
    required this.isDarkMode,
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
          title: Text(
            'Delete Configuration',
            style: TextStyle(color: widget.isDarkMode ? CupertinoColors.white : CupertinoColors.black),
          ),
          content: Text(
            'Are you sure you want to delete "${config.name}"? This action cannot be undone.',
            style: TextStyle(color: widget.isDarkMode ? CupertinoColors.white : CupertinoColors.black),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(color: CupertinoColors.systemBlue),
              ),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                'Delete',
                style: TextStyle(color: CupertinoColors.destructiveRed),
              ),
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
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.translucent,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: widget.isDarkMode 
              ? CupertinoColors.systemGrey6.darkColor
              : CupertinoColors.systemBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
                Text(
                  'Load Configuration',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: widget.isDarkMode ? CupertinoColors.white : CupertinoColors.black,
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: CupertinoColors.systemBlue),
                  ),
                ),
              ],
            ),
          ),
          // 配置列表
          Expanded(
            child: configs.isEmpty
                ? Center(
                    child: Text(
                      'No saved configurations',
                      style: TextStyle(
                        color: widget.isDarkMode ? CupertinoColors.systemGrey2 : CupertinoColors.secondaryLabel,
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
                        margin: const EdgeInsets.only(bottom: 8),
                        child: CupertinoListTile(
                          title: Text(
                            config.name,
                            style: TextStyle(
                              color: widget.isDarkMode ? CupertinoColors.white : CupertinoColors.black,
                            ),
                          ),
                          subtitle: Text(
                            '${config.numReactions} reactions, ${config.reactionVolume}µl',
                            style: TextStyle(
                              color: widget.isDarkMode ? CupertinoColors.systemGrey2 : CupertinoColors.secondaryLabel,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CupertinoButton(
                                padding: EdgeInsets.zero,
                                onPressed: () => _handleDeleteConfiguration(config),
                                child: Icon(
                                  CupertinoIcons.delete,
                                  color: CupertinoColors.destructiveRed,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                CupertinoIcons.forward,
                                color: CupertinoColors.systemGrey,
                                size: 16,
                              ),
                            ],
                          ),
                          onTap: () => widget.onConfigurationSelected(config),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      ), // Container (wrapped by GestureDetector)
    ); // GestureDetector
  }
}
