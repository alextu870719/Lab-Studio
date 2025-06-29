// 備份 - 完整的 Stage/Step 拖拽排序實現

import 'package:flutter/cupertino.dart';

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

// 可編輯的 PCR Step
class EditablePcrStep {
  final String id;
  String name;
  final String subtitle;
  final IconData icon;
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
       tempController = TextEditingController(text: temperature.toStringAsFixed(1)),
       timeController = TextEditingController(text: duration.toString());
  
  // 獲取 PcrStep 對象
  PcrStep toPcrStep() {
    return PcrStep(
      id: id,
      name: name,
      temperature: double.tryParse(tempController.text) ?? 0.0,
      duration: int.tryParse(timeController.text) ?? 0,
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
    tempController.dispose();
    timeController.dispose();
  }
}

// 可編輯的 PCR Stage
class EditablePcrStage {
  final String id;
  String name;
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
       cyclesController = TextEditingController(text: cycles.toString());
  
  // 獲取 PcrStage 對象
  PcrStage toPcrStage() {
    return PcrStage(
      id: id,
      name: name,
      cycles: int.tryParse(cyclesController.text) ?? 1,
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
