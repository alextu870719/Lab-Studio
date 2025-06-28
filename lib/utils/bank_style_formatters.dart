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
        currentDigits = '0' + currentDigits.substring(0, currentDigits.length - 1);
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
      digits = '0' + digits;
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
