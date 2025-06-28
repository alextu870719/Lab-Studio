import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';
import 'package:pcr_reagent_calculator/utils/format_utils.dart';
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
  final String name;
  final double proportion;
  final bool isOptional;
  final bool isVariable;

  Reagent({
    required this.name,
    required this.proportion,
    this.isOptional = false,
    this.isVariable = false,
  });

  Reagent copyWith({
    String? name,
    double? proportion,
    bool? isOptional,
    bool? isVariable,
  }) {
    return Reagent(
      name: name ?? this.name,
      proportion: proportion ?? this.proportion,
      isOptional: isOptional ?? this.isOptional,
      isVariable: isVariable ?? this.isVariable,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'proportion': proportion,
      'isOptional': isOptional,
      'isVariable': isVariable,
    };
  }

  factory Reagent.fromJson(Map<String, dynamic> json) {
    return Reagent(
      name: json['name'] ?? '',
      proportion: (json['proportion'] ?? 0.0).toDouble(),
      isOptional: json['isOptional'] ?? false,
      isVariable: json['isVariable'] ?? false,
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
      reactionVolume: (json['reactionVolume'] ?? 25.0).toDouble(),
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
  final TextEditingController _numReactionsController = TextEditingController(text: '1');
  final TextEditingController _customReactionVolumeController = TextEditingController(text: '25.0');
  final TextEditingController _templateDnaVolumeController = TextEditingController();

  Map<String, double> _calculatedTotalVolumes = {};
  final Map<String, bool> _reagentInclusionStatus = {};
  bool _isEditMode = false;
  String _currentConfigurationName = 'Default Configuration';

  final List<Reagent> _reagents = [
    Reagent(name: '5X Q5 Reaction Buffer', proportion: 5.0 / 25.0),
    Reagent(name: '10 mM dNTPs', proportion: 2.0 / 25.0),
    Reagent(name: '10 µM Forward Primer', proportion: 2.5 / 25.0),
    Reagent(name: '10 µM Reverse Primer', proportion: 2.5 / 25.0),
    Reagent(name: 'Template DNA', proportion: 0.0, isVariable: true),
    Reagent(name: 'Q5 High-Fidelity DNA Polymerase', proportion: 0.5 / 25.0),
    Reagent(name: '5X Q5 High GC Enhancer (optional)', proportion: 5.0 / 25.0, isOptional: true),
    Reagent(name: 'Nuclease-Free Water', proportion: 0.0),
  ];

  @override
  void initState() {
    super.initState();
    for (var reagent in _reagents) {
      if (reagent.isOptional) {
        _reagentInclusionStatus[reagent.name] = false;
      }
    }
    _calculateVolumes();
  }

  @override
  void dispose() {
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

      double totalVolumePerReaction = double.tryParse(_customReactionVolumeController.text) ?? 25.0;
      if (totalVolumePerReaction <= 0) totalVolumePerReaction = 25.0;

      double totalCalculatedVolumeExcludingWater = 0.0;

      for (var reagent in _reagents) {
        if (reagent.name == 'Nuclease-Free Water') continue;
        if (reagent.isOptional && !(_reagentInclusionStatus[reagent.name] ?? false)) continue;

        double singleReactionVolume;
        if (reagent.isVariable) {
          // For Template DNA, use 0 if empty or invalid, no error dialog
          double parsedVolume = double.tryParse(_templateDnaVolumeController.text) ?? 0.0;
          singleReactionVolume = parsedVolume;
        } else {
          singleReactionVolume = reagent.proportion * totalVolumePerReaction;
        }

        double totalReagentVolume = singleReactionVolume * numReactions;
        _calculatedTotalVolumes[reagent.name] = totalReagentVolume;
        totalCalculatedVolumeExcludingWater += totalReagentVolume;
      }

      double totalDesiredVolume = totalVolumePerReaction * numReactions;
      double waterVolume = totalDesiredVolume - totalCalculatedVolumeExcludingWater;

      if (waterVolume < 0) {
        _showErrorDialog('Calculated reagent volumes exceed total desired volume. Please check your inputs.');
        _calculatedTotalVolumes.clear();
      } else {
        _calculatedTotalVolumes['Nuclease-Free Water'] = waterVolume;
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

  void _clearAllInputs() {
    _numReactionsController.text = '1';
    _customReactionVolumeController.text = '25.0';
    _templateDnaVolumeController.clear();
    setState(() {
      _calculatedTotalVolumes.clear();
      for (var reagent in _reagents) {
        if (reagent.isOptional) {
          _reagentInclusionStatus[reagent.name] = false;
        }
      }
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
        reactionVolume: double.tryParse(_customReactionVolumeController.text) ?? 25.0,
        templateDnaVolume: double.tryParse(_templateDnaVolumeController.text) ?? 0.0,
        reagents: _reagents,
        reagentInclusionStatus: _reagentInclusionStatus,
      );
      
      List<String> existingConfigs = prefs.getStringList('saved_configurations') ?? [];
      existingConfigs.add(jsonEncode(config.toJson()));
      await prefs.setStringList('saved_configurations', existingConfigs);
      
      setState(() {
        _currentConfigurationName = name;
      });
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
      
      List<PcrConfiguration> configs = configStrings
          .map((configString) => PcrConfiguration.fromJson(jsonDecode(configString)))
          .toList();
      
      await showCupertinoModalPopup(
        context: context,
        builder: (BuildContext context) {
          return CupertinoActionSheet(
            title: const Text('Load Configuration'),
            actions: configs.map((config) {
              return CupertinoActionSheetAction(
                onPressed: () {
                  _applyConfiguration(config);
                  Navigator.of(context).pop();
                },
                child: Text(config.name),
              );
            }).toList(),
            cancelButton: CupertinoActionSheetAction(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          );
        },
      );
    } catch (e) {
      _showErrorDialog('Failed to load configurations: $e');
    }
  }

  void _applyConfiguration(PcrConfiguration config) {
    setState(() {
      _numReactionsController.text = config.numReactions.toString();
      _customReactionVolumeController.text = config.reactionVolume.toString();
      _templateDnaVolumeController.text = config.templateDnaVolume.toString();
      
      _reagents.clear();
      _reagents.addAll(config.reagents);
      
      _reagentInclusionStatus.clear();
      _reagentInclusionStatus.addAll(config.reagentInclusionStatus);
      
      _currentConfigurationName = config.name;
      
      _calculateVolumes();
    });
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
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Text(
            reagent.name,
            style: CupertinoTheme.of(context).textTheme.textStyle,
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            formatVolume(_calculatedTotalVolumes[reagent.name]! / 
                (int.tryParse(_numReactionsController.text) ?? 1)),
            textAlign: TextAlign.center,
            style: CupertinoTheme.of(context).textTheme.textStyle,
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            formatVolume(_calculatedTotalVolumes[reagent.name]!),
            textAlign: TextAlign.end,
            style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
              fontWeight: FontWeight.w600,
              color: CupertinoColors.systemBlue,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEditableReagentRow(Reagent reagent, int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              flex: 3,
              child: CupertinoTextField(
                placeholder: 'Reagent Name',
                controller: TextEditingController(text: reagent.name),
                onChanged: (value) {
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
            if (!reagent.isVariable) ...[
              Expanded(
                flex: 2,
                child: CupertinoTextField(
                  placeholder: 'Volume',
                  controller: TextEditingController(text: (reagent.proportion * 25.0).toString()),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    double? newVolume = double.tryParse(value);
                    if (newVolume != null) {
                      setState(() {
                        _reagents[index] = reagent.copyWith(proportion: newVolume / 25.0);
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
            ] else ...[
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
                  decoration: BoxDecoration(
                    color: CupertinoColors.secondarySystemBackground,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Text(
                    'Variable',
                    style: TextStyle(color: CupertinoColors.secondaryLabel),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            if (reagent.isOptional) ...[
              CupertinoSwitch(
                value: _reagentInclusionStatus[reagent.name] ?? false,
                onChanged: (value) {
                  setState(() {
                    _reagentInclusionStatus[reagent.name] = value;
                    _calculateVolumes();
                  });
                },
              ),
              const SizedBox(width: 8),
              const Text('Include in calculation'),
            ] else ...[
              const Text('Required reagent'),
            ],
            const Spacer(),
            Text(
              'Swipe left to delete',
              style: TextStyle(
                color: CupertinoColors.secondaryLabel,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _addNewReagent() {
    setState(() {
      _reagents.add(Reagent(
        name: 'New Reagent',
        proportion: 1.0 / 25.0,
        isOptional: true,
      ));
      _calculateVolumes();
    });
  }

  void _deleteReagent(int index) {
    if (_reagents.length > 1) {
      setState(() {
        String reagentName = _reagents[index].name;
        _reagents.removeAt(index);
        _reagentInclusionStatus.remove(reagentName);
        _calculateVolumes();
      });
    }
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

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('PCR Calculator'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.floppy_disk),
              onPressed: _saveConfiguration,
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.folder_open),
              onPressed: _loadConfiguration,
            ),
          ],
        ),
      ),
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

            // Configuration Name and Edit Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                CupertinoButton(
                  onPressed: () {
                    setState(() {
                      _isEditMode = !_isEditMode;
                    });
                  },
                  child: Text(_isEditMode ? 'Done' : 'Edit'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Reagents List
            if (_calculatedTotalVolumes.isNotEmpty) ...[
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
                          '25 µl rxn',
                          textAlign: TextAlign.center,
                          style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                            fontWeight: FontWeight.w600,
                            color: CupertinoColors.secondaryLabel,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              
              for (var i = 0; i < _reagents.length; i++)
                if (_calculatedTotalVolumes.containsKey(_reagents[i].name))
                  _isEditMode 
                    ? Dismissible(
                        key: Key('reagent_$i'),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (direction) async {
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
            ] else
              Container(
                padding: const EdgeInsets.all(32.0),
                child: const Center(
                  child: Text(
                    'Enter parameters above to calculate volumes',
                    style: TextStyle(
                      color: CupertinoColors.secondaryLabel,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
