import 'package:flutter/services.dart';

/// 真正的銀行式數字輸入格式化器
/// 固定小數點位置，新數字從右邊（小數位）開始輸入，向左移動
class BankStyleDecimalFormatter extends TextInputFormatter {
  final int decimalPlaces;
  final int maxDigits;
  
  BankStyleDecimalFormatter({this.decimalPlaces = 1, this.maxDigits = 5});
  
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // 初始化預設值
    if (oldValue.text.isEmpty) {
      String initial = '0.${List.filled(decimalPlaces, '0').join()}';
      return TextEditingValue(
        text: initial,
        selection: TextSelection.collapsed(offset: initial.length),
      );
    }
    
    String newText = newValue.text;
    String oldText = oldValue.text;
    
    // 如果是刪除操作（Backspace）
    if (newText.length < oldText.length) {
      String currentDigits = oldText.replaceAll(RegExp(r'[^\d]'), '');
      if (currentDigits.length > decimalPlaces + 1) {
        // 在最左邊加0，然後移除最右邊一位
        currentDigits = '0${currentDigits.substring(0, currentDigits.length - 1)}';
      } else {
        // 最小值
        currentDigits = List.filled(decimalPlaces + 1, '0').join();
      }
      
      String formatted = _formatDigits(currentDigits);
      return TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
    
    // 找出新輸入的字符
    String newChar = '';
    if (newText.length > oldText.length) {
      String newDigits = newText.replaceAll(RegExp(r'[^\d]'), '');
      String oldDigits = oldText.replaceAll(RegExp(r'[^\d]'), '');
      if (newDigits.length > oldDigits.length) {
        newChar = newDigits[newDigits.length - 1];
      }
    }
    
    // 只接受數字
    if (newChar.isEmpty || !RegExp(r'^\d$').hasMatch(newChar)) {
      return oldValue;
    }
    
    // 獲取當前的數字字符串
    String currentDigits = oldText.replaceAll(RegExp(r'[^\d]'), '');
    
    // 檢查是否超過最大位數
    if (currentDigits.length >= maxDigits) {
      return oldValue;
    }
    
    // 移除最左邊的0（如果不是最後一位），然後在右邊加入新數字
    if (currentDigits.length > decimalPlaces && currentDigits.startsWith('0')) {
      currentDigits = currentDigits.substring(1);
    }
    currentDigits = currentDigits + newChar;
    
    String formatted = _formatDigits(currentDigits);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
  
  String _formatDigits(String digits) {
    // 確保至少有 decimalPlaces + 1 位數字
    while (digits.length < decimalPlaces + 1) {
      digits = '0$digits';
    }
    
    // 分割整數部分和小數部分
    String integerPart = digits.substring(0, digits.length - decimalPlaces);
    String decimalPart = digits.substring(digits.length - decimalPlaces);
    
    // 移除整數部分前面的0（但保留至少一個0）
    integerPart = integerPart.replaceFirst(RegExp(r'^0+'), '');
    if (integerPart.isEmpty) {
      integerPart = '0';
    }
    
    return '$integerPart.$decimalPart';
  }
}

/// 銀行式整數輸入格式化器
class BankStyleIntegerFormatter extends TextInputFormatter {
  final int maxDigits;
  final bool allowEmpty;
  
  BankStyleIntegerFormatter({this.maxDigits = 4, this.allowEmpty = true});
  
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String newText = newValue.text;
    String oldText = oldValue.text;
    
    // 如果是刪除操作
    if (newText.length < oldText.length) {
      String currentDigits = oldText.replaceAll(RegExp(r'[^\d]'), '');
      if (currentDigits.length > 1) {
        currentDigits = currentDigits.substring(0, currentDigits.length - 1);
        int value = int.tryParse(currentDigits) ?? 0;
        return TextEditingValue(
          text: value.toString(),
          selection: TextSelection.collapsed(offset: value.toString().length),
        );
      } else {
        // 如果只剩一個數字，允許刪除到空字串或0
        if (allowEmpty) {
          return const TextEditingValue(
            text: '',
            selection: TextSelection.collapsed(offset: 0),
          );
        } else {
          return const TextEditingValue(
            text: '0',
            selection: TextSelection.collapsed(offset: 1),
          );
        }
      }
    }
    
    // 處理完全清空的情況
    if (newText.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }
    
    // 找出新輸入的字符
    String newChar = '';
    if (newText.length > oldText.length) {
      String newDigits = newText.replaceAll(RegExp(r'[^\d]'), '');
      String oldDigits = oldText.replaceAll(RegExp(r'[^\d]'), '');
      if (newDigits.length > oldDigits.length) {
        newChar = newDigits[newDigits.length - 1];
      }
    }
    
    // 只接受數字
    if (newChar.isEmpty || !RegExp(r'^\d$').hasMatch(newChar)) {
      return oldValue;
    }
    
    // 獲取當前的數字字符串
    String currentDigits = oldText.replaceAll(RegExp(r'[^\d]'), '');
    
    // 如果當前是空字串，直接使用新字符
    if (currentDigits.isEmpty) {
      return TextEditingValue(
        text: newChar,
        selection: TextSelection.collapsed(offset: newChar.length),
      );
    }
    
    // 檢查是否超過最大位數
    if (currentDigits.length >= maxDigits) {
      return oldValue;
    }
    
    // 新數字從右邊加入
    currentDigits = currentDigits + newChar;
    
    int value = int.tryParse(currentDigits) ?? 0;
    
    return TextEditingValue(
      text: value.toString(),
      selection: TextSelection.collapsed(offset: value.toString().length),
    );
  }
}

/// 時間格式化器，支持 hh:mm:ss 格式的銀行式輸入
/// 時間以秒為單位存儲，但顯示為 hh:mm:ss 格式
class TimeInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String newText = newValue.text;
    
    // 只允許數字和冒號
    newText = newText.replaceAll(RegExp(r'[^0-9:]'), '');
    
    // 如果輸入 '00' 或 '0:00:00' 或 '00:00:00'，顯示為 ∞
    if (newText == '00' || newText == '0:00:00' || newText == '00:00:00') {
      return TextEditingValue(
        text: '∞',
        selection: TextSelection.collapsed(offset: 1),
      );
    }
    
    // 處理 ∞ 符號
    if (newText.contains('∞')) {
      return TextEditingValue(
        text: '∞',
        selection: TextSelection.collapsed(offset: 1),
      );
    }
    
    // 處理數字輸入，自動格式化為 hh:mm:ss
    if (newText.isNotEmpty) {
      // 移除所有冒號
      String digitsOnly = newText.replaceAll(':', '');
      
      if (digitsOnly.length > 6) {
        digitsOnly = digitsOnly.substring(0, 6); // 限制為 6 位數字 (hhmmss)
      }
      
      if (digitsOnly.isEmpty) {
        return TextEditingValue(
          text: '0:00:00',
          selection: TextSelection.collapsed(offset: 7),
        );
      }
      
      // 根據長度自動添加冒號，從右邊開始填充
      digitsOnly = digitsOnly.padLeft(6, '0');
      
      String hours = digitsOnly.substring(0, 2);
      String minutes = digitsOnly.substring(2, 4);
      String seconds = digitsOnly.substring(4, 6);
      
      // 確保分鐘和秒數不超過 59
      int min = int.tryParse(minutes) ?? 0;
      int sec = int.tryParse(seconds) ?? 0;
      if (min > 59) minutes = '59';
      if (sec > 59) seconds = '59';
      
      // 移除小時前導零（除非小時為 0）
      int hr = int.tryParse(hours) ?? 0;
      String hoursFormatted = hr.toString();
      
      newText = '$hoursFormatted:$minutes:$seconds';
    } else {
      newText = '0:00:00';
    }
    
    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
  
  /// 將 hh:mm:ss 格式轉換為總秒數
  static int parseTimeToSeconds(String timeText) {
    if (timeText.isEmpty || timeText == '0:00:00') {
      return 0;
    }
    
    // 處理特殊情況：∞ 符號
    if (timeText.contains('∞')) {
      return 0;
    }
    
    List<String> parts = timeText.split(':');
    
    if (parts.length == 3) {
      // hh:mm:ss 格式
      int hours = int.tryParse(parts[0]) ?? 0;
      int minutes = int.tryParse(parts[1]) ?? 0;
      int seconds = int.tryParse(parts[2]) ?? 0;
      return hours * 3600 + minutes * 60 + seconds;
    } else if (parts.length == 2) {
      // 向後兼容 mm:ss 格式
      int minutes = int.tryParse(parts[0]) ?? 0;
      int seconds = int.tryParse(parts[1]) ?? 0;
      return minutes * 60 + seconds;
    }
    
    return 0;
  }
  
  /// 將總秒數轉換為 hh:mm:ss 格式
  static String formatSecondsToTime(int totalSeconds) {
    if (totalSeconds == 0) {
      return '∞';
    }
    
    int hours = totalSeconds ~/ 3600;
    int minutes = (totalSeconds % 3600) ~/ 60;
    int seconds = totalSeconds % 60;
    
    return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
