import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart'; // Import for Clipboard
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
    return MaterialApp(
      title: 'PCR Reagent Calculator',
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blueGrey,
          foregroundColor: Colors.white,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueGrey,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
        ),
      ),
      home: const PcrCalculatorPage(),
    );
  }
}

class Reagent {
  final String name;
  final double proportion; // Changed from fixedVolume to proportion
  final bool isOptional;
  final bool isVariable; // For Template DNA

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
  
  
  final Map<String, bool> _reagentInclusionStatus = {}; // New map to manage inclusion status
  bool _isEditMode = false;

  final List<Reagent> _reagents = [
    Reagent(name: '5X Q5 Reaction Buffer', proportion: 5.0 / 25.0),
    Reagent(name: '10 mM dNTPs', proportion: 2.0 / 25.0),
    Reagent(name: '10 µM Forward Primer', proportion: 2.5 / 25.0),
    Reagent(name: '10 µM Reverse Primer', proportion: 2.5 / 25.0),
    Reagent(name: 'Template DNA', proportion: 0.0, isVariable: true), // Volume will be from user input
    Reagent(name: 'Q5 High-Fidelity DNA Polymerase', proportion: 0.5 / 25.0),
    Reagent(name: '5X Q5 High GC Enhancer (optional)', proportion: 5.0 / 25.0, isOptional: true),
    Reagent(name: 'Nuclease-Free Water', proportion: 0.0),
  ];

  @override
  void initState() {
    super.initState();
    // Initialize inclusion status for optional reagents
    for (var reagent in _reagents) {
      if (reagent.isOptional) {
        _reagentInclusionStatus[reagent.name] = false; // Default to not included
      }
    }
    _calculateVolumes(); // Initial calculation
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
      int numReactions = int.tryParse(_numReactionsController.text) ?? 1;
      if (numReactions <= 0) numReactions = 1; // Ensure at least 1 reaction

      double totalVolumePerReaction = double.tryParse(_customReactionVolumeController.text) ?? 0.0;

      if (totalVolumePerReaction <= 0) {
        _showErrorDialog('Please enter a valid total reaction volume.');
        return;
      }

      double totalCalculatedVolumeExcludingWater = 0.0;

      for (var reagent in _reagents) {
        if (reagent.name == 'Nuclease-Free Water') continue;
        // Check inclusion status from the new map
        if (reagent.isOptional && !(_reagentInclusionStatus[reagent.name] ?? false)) continue;

        double singleReactionVolume;
        if (reagent.isVariable) {
          double? parsedVolume = double.tryParse(_templateDnaVolumeController.text);
          if (parsedVolume == null && _templateDnaVolumeController.text.isNotEmpty) {
             _showErrorDialog('Please enter a valid number for Template DNA volume.');
             return;
          }
          singleReactionVolume = parsedVolume ?? 0.0; // Default to 0 if not entered
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
        _showErrorDialog('Calculated reagent volumes exceed total desired volume. Please check your inputs, especially Template DNA.');
        _calculatedTotalVolumes.clear(); // Clear results on error
      } else {
        _calculatedTotalVolumes['Nuclease-Free Water'] = waterVolume;
      }
    });
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Input Error'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
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
      // Reset inclusion status for optional reagents
      for (var reagent in _reagents) {
        if (reagent.isOptional) {
          _reagentInclusionStatus[reagent.name] = false; // Default to not included
        }
      }
    });
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
    buffer.writeln('Component\tTotal Volume (µl)');
    _calculatedTotalVolumes.forEach((key, value) {
      buffer.writeln('$key\t${formatVolume(value)}');
    });

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Results copied to clipboard!')),
    );
  }

  Future<void> _saveConfiguration() async {
    final TextEditingController nameController = TextEditingController();
    
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Save Configuration'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Configuration Name',
              hintText: 'Enter a name for this configuration',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a configuration name')),
                  );
                  return;
                }
                
                Navigator.of(context).pop();
                await _saveConfigurationWithName(nameController.text.trim());
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
      
      // Get existing configurations
      List<String> existingConfigs = prefs.getStringList('saved_configurations') ?? [];
      
      // Add new configuration
      existingConfigs.add(jsonEncode(config.toJson()));
      
      // Save back to preferences
      await prefs.setStringList('saved_configurations', existingConfigs);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Configuration "$name" saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Failed to save configuration: $e');
      }
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
      
      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Load Configuration'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: configs.length,
                itemBuilder: (context, index) {
                  final config = configs[index];
                  return ListTile(
                    title: Text(config.name),
                    subtitle: Text('${config.numReactions} reactions, ${config.reactionVolume}µl each'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () async {
                        await _deleteConfiguration(index);
                        Navigator.of(context).pop();
                        _loadConfiguration(); // Refresh the dialog
                      },
                    ),
                    onTap: () {
                      _applyConfiguration(config);
                      Navigator.of(context).pop();
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      _showErrorDialog('Failed to load configurations: $e');
    }
  }

  Future<void> _deleteConfiguration(int index) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> configStrings = prefs.getStringList('saved_configurations') ?? [];
      
      if (index >= 0 && index < configStrings.length) {
        configStrings.removeAt(index);
        await prefs.setStringList('saved_configurations', configStrings);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Configuration deleted')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Failed to delete configuration: $e');
      }
    }
  }

  void _applyConfiguration(PcrConfiguration config) {
    setState(() {
      _numReactionsController.text = config.numReactions.toString();
      _customReactionVolumeController.text = config.reactionVolume.toString();
      _templateDnaVolumeController.text = config.templateDnaVolume.toString();
      
      // Apply reagents
      _reagents.clear();
      _reagents.addAll(config.reagents);
      
      // Apply inclusion status
      _reagentInclusionStatus.clear();
      _reagentInclusionStatus.addAll(config.reagentInclusionStatus);
      
      _calculateVolumes();
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Configuration "${config.name}" loaded')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PCR Reagent Calculator'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveConfiguration,
            tooltip: 'Save Configuration',
          ),
          IconButton(
            icon: const Icon(Icons.folder_open),
            onPressed: _loadConfiguration,
            tooltip: 'Load Configuration',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PCR Parameters',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _numReactionsController,
                            decoration: const InputDecoration(
                              labelText: 'Number of Reactions',
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (value) => _calculateVolumes(),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: _customReactionVolumeController,
                            decoration: const InputDecoration(
                              labelText: 'Reaction Volume (µl)',
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (value) => _calculateVolumes(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _templateDnaVolumeController,
                      decoration: const InputDecoration(
                        labelText: 'Template DNA Volume (µl)',
                        hintText: 'Enter volume per reaction',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) => _calculateVolumes(),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _clearAllInputs,
                            child: const Text('Clear'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _printResults,
                            child: const Text('Print'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _copyResults,
                            child: const Text('Copy'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Reagent Components',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                ElevatedButton(
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
            // Header Row for the table
            if (!_isEditMode)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: Row(
                  children: [
                    Expanded(flex: 3, child: Text('Component', style: Theme.of(context).textTheme.titleSmall)),
                    Expanded(flex: 2, child: Text('Volume/Rxn (µl)', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleSmall)),
                    Expanded(flex: 2, child: Text('Total (µl)', textAlign: TextAlign.end, style: Theme.of(context).textTheme.titleSmall)),
                  ],
                ),
              ),
            Expanded(
              child: ListView.builder(
                itemCount: _reagents.length,
                itemBuilder: (context, index) {
                  final reagent = _reagents[index];
                  final double? totalNeededVolume = _calculatedTotalVolumes[reagent.name];
                  
                  if (totalNeededVolume == null) {
                    return Container(); // Don't display reagents not in calculations
                  }

                  final int numReactions = int.tryParse(_numReactionsController.text) ?? 1;
                  final double singleReactionVolume = numReactions > 0 ? totalNeededVolume / numReactions : 0.0;

                  Widget componentNameWidget;
                  Widget singleRxnVolumeWidget;

                  if (_isEditMode && !reagent.isVariable) {
                    componentNameWidget = TextField(
                      controller: TextEditingController(text: reagent.name),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _reagents[index] = reagent.copyWith(name: value);
                          _calculateVolumes();
                        });
                      },
                    );

                    final double totalReactionVolume = double.tryParse(_customReactionVolumeController.text) ?? 25.0;
                    singleRxnVolumeWidget = Expanded(
                      flex: 2,
                      child: TextField(
                        controller: TextEditingController(text: (reagent.proportion * totalReactionVolume).toStringAsFixed(2)),
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                        ),
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        onChanged: (value) {
                          final double? newVolume = double.tryParse(value);
                          if (newVolume != null && totalReactionVolume > 0) {
                            setState(() {
                              _reagents[index] = reagent.copyWith(proportion: newVolume / totalReactionVolume);
                              _calculateVolumes();
                            });
                          }
                        },
                      ),
                    );
                  } else {
                    componentNameWidget = Text(
                      reagent.name,
                      style: Theme.of(context).textTheme.bodyMedium,
                    );

                    singleRxnVolumeWidget = Expanded(
                      flex: 2,
                      child: reagent.isVariable
                          ? TextField(
                              controller: _templateDnaVolumeController,
                              decoration: const InputDecoration(
                                hintText: 'Enter volume',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                              ),
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              onChanged: (value) => _calculateVolumes(),
                            )
                          : Text(
                              formatVolume(singleReactionVolume),
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                    );
                  }

                  return GestureDetector(
                    onTap: () {
                      if (_isEditMode && reagent.isOptional) {
                        setState(() {
                          _reagentInclusionStatus[reagent.name] = !(_reagentInclusionStatus[reagent.name] ?? false);
                          _calculateVolumes();
                        });
                      }
                    },
                    child: Card(
                      margin: const EdgeInsets.symmetric(vertical: 4.0),
                      elevation: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(flex: 3, child: componentNameWidget),
                                singleRxnVolumeWidget,
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    formatVolume(totalNeededVolume),
                                    textAlign: TextAlign.end,
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.blueGrey[700]),
                                  ),
                                ),
                              ],
                            ),
                            if (_isEditMode && reagent.isOptional)
                              Row(
                                children: [
                                  Checkbox(
                                    value: _reagentInclusionStatus[reagent.name] ?? false,
                                    onChanged: (bool? value) {
                                      setState(() {
                                        _reagentInclusionStatus[reagent.name] = value ?? false;
                                        _calculateVolumes();
                                      });
                                    },
                                  ),
                                  const Text('Include in calculation'),
                                ],
                              ),
                            if (_isEditMode && !reagent.isVariable && index < _reagents.length - 1)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () {
                                      setState(() {
                                        _reagents.removeAt(index);
                                        _calculateVolumes();
                                      });
                                    },
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_isEditMode)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _reagents.insert(_reagents.length - 1, // Insert before water
                        Reagent(
                          name: 'New Reagent',
                          proportion: 0.0,
                        ),
                      );
                    });
                  },
                  child: const Text('Add New Reagent'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}