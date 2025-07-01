# Lab Studio - 統一玻璃效果配色指南

## 主要配色規範

### 1. TabBar 和 NavigationBar
- **背景透明度**: 0.4 (統一)
- **邊框透明度**: 0.2 (統一)
- **暗色模式**: 黑色背景 + 白色邊框
- **亮色模式**: 白色背景 + 黑色邊框

```dart
backgroundColor: isDarkMode 
    ? CupertinoColors.black.withOpacity(0.4)
    : CupertinoColors.white.withOpacity(0.4),
border: Border(
  top: BorderSide(
    color: isDarkMode 
        ? CupertinoColors.white.withOpacity(0.2)
        : CupertinoColors.black.withOpacity(0.2),
    width: 0.5,
  ),
),
```

### 2. 主要玻璃容器 (Calculator & Reaction Page)
- **漸變背景**:
  - 暗色模式: 白色 0.15 → 0.05 透明度
  - 亮色模式: 白色 0.4 → 0.1 透明度
- **邊框**:
  - 暗色模式: 白色 0.2 透明度
  - 亮色模式: 白色 0.3 透明度
- **陰影**:
  - 暗色模式: 黑色 0.3 透明度
  - 亮色模式: 黑色 0.1 透明度
- **模糊效果**: sigmaX: 15, sigmaY: 15
- **圓角**: 20px
- **邊框寬度**: 1.5px

```dart
decoration: BoxDecoration(
  gradient: LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: isDarkMode 
        ? [
            const Color(0xFFFFFFFF).withOpacity(0.15),
            const Color(0xFFFFFFFF).withOpacity(0.05),
          ]
        : [
            const Color(0xFFFFFFFF).withOpacity(0.4),
            const Color(0xFFFFFFFF).withOpacity(0.1),
          ],
  ),
  borderRadius: BorderRadius.circular(20),
  border: Border.all(
    color: isDarkMode 
        ? const Color(0xFFFFFFFF).withOpacity(0.2)
        : const Color(0xFFFFFFFF).withOpacity(0.3),
    width: 1.5,
  ),
  boxShadow: [
    BoxShadow(
      color: isDarkMode 
          ? const Color(0xFF000000).withOpacity(0.3)
          : const Color(0xFF000000).withOpacity(0.1),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ],
),
child: ClipRRect(
  borderRadius: BorderRadius.circular(20),
  child: BackdropFilter(
    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
    child: // ... 內容
  ),
),
```

### 3. 背景漸變
- **暗色模式**: 深藍色系 (1A1A2E → 16213E → 0F3460)
- **亮色模式**: 淺藍綠色系 (E8F4FD → D1E7DD → B8E6B8)

```dart
decoration: BoxDecoration(
  gradient: isDarkMode 
      ? const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A1A2E),
            Color(0xFF16213E), 
            Color(0xFF0F3460),
          ],
        )
      : const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFE8F4FD),
            Color(0xFFD1E7DD),
            Color(0xFFB8E6B8),
          ],
        ),
),
```

## 統一原則

1. **透明度一致性**: 所有同類型元素使用相同的透明度值
2. **顏色漸變統一**: 所有玻璃容器使用相同的漸變配色
3. **邊框和陰影一致**: 所有容器使用相同的邊框寬度和陰影設定
4. **模糊效果統一**: 所有 BackdropFilter 使用相同的模糊參數
5. **圓角統一**: 主要容器使用 20px，次要元素使用 12px 或 8px

## 實施狀態

✅ TabBar 透明度統一 (0.4)
✅ NavigationBar 透明度統一 (0.4)  
✅ Calculator Page 玻璃容器配色統一
✅ Reaction Page 玻璃容器配色統一
✅ 邊框透明度統一 (0.2/0.3)
✅ 陰影透明度統一 (0.3/0.1)
✅ 背景漸變保持一致

## 注意事項

- 所有 `withOpacity()` 呼叫將來可能需要更新為 `withValues()` 以配合 Flutter 新版本
- 維持暗色/亮色模式的對比度平衡
- 確保所有玻璃效果在不同平台上的一致性
