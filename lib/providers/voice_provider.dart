import 'package:flutter/material.dart';

/// 语音识别状态管理 Provider
class VoiceProvider extends ChangeNotifier {
  bool _isListening = false;
  bool _isAvailable = false;
  String _recognizedText = '';
  String _lastRecognizedText = '';
  String? _error;

  bool get isListening => _isListening;
  bool get isAvailable => _isAvailable;
  String get recognizedText => _recognizedText;
  String get lastRecognizedText => _lastRecognizedText;
  String? get error => _error;

  VoiceProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    // 初始化语音识别服务
    // 这里需要在后续实现语音识别服务
    _isAvailable = true;
    notifyListeners();
  }

  /// 开始录音
  Future<void> startListening() async {
    if (!_isAvailable) {
      _error = '语音识别服务不可用';
      notifyListeners();
      return;
    }

    _isListening = true;
    _recognizedText = '';
    _error = null;
    notifyListeners();

    // 这里需要调用实际的语音识别服务
    // 暂时使用模拟数据
    await Future.delayed(const Duration(seconds: 2));
    _recognizedText = '待办事项内容示例';
    _isListening = false;
    notifyListeners();
  }

  /// 停止录音
  Future<void> stopListening() async {
    if (!_isListening) return;

    _isListening = false;
    _lastRecognizedText = _recognizedText;
    notifyListeners();
  }

  /// 取消录音
  Future<void> cancelListening() async {
    if (!_isListening) return;

    _isListening = false;
    _recognizedText = '';
    notifyListeners();
  }

  /// 清空识别结果
  void clearRecognizedText() {
    _recognizedText = '';
    _lastRecognizedText = '';
    notifyListeners();
  }
}
