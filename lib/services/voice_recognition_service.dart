import 'dart:async';
import 'package:flutter/foundation.dart';

/// 语音识别服务（离线方案）
///
/// 使用平台原生API进行语音识别，不依赖云端服务
class VoiceRecognitionService {
  static final VoiceRecognitionService instance = VoiceRecognitionService._internal();

  bool _isInitialized = false;
  bool _isListening = false;
  bool _isAvailable = false;
  String _lastRecognizedText = '';
  String? _error;

  // 语音识别状态流
  final _resultController = StreamController<String>.broadcast();
  final _statusController = StreamController<VoiceStatus>.broadcast();
  final _errorController = StreamController<String>.broadcast();

  Stream<String> get resultStream => _resultController.stream;
  Stream<VoiceStatus> get statusStream => _statusController.stream;
  Stream<String> get errorStream => _errorController.stream;

  bool get isInitialized => _isInitialized;
  bool get isListening => _isListening;
  bool get isAvailable => _isAvailable;
  String get lastRecognizedText => _lastRecognizedText;

  VoiceRecognitionService._internal();

  /// 初始化语音识别服务
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 检查设备是否支持语音识别
      // 这里需要调用平台原生API来检查
      // 暂时设置为true，实际使用时需要实现

      await Future.delayed(const Duration(milliseconds: 500));
      _isAvailable = true;
      _isInitialized = true;
      _statusController.add(VoiceStatus.initialized);
    } catch (e) {
      _error = e.toString();
      _errorController.add(e.toString());
      _statusController.add(VoiceStatus.error);
    }
  }

  /// 开始语音识别
  Future<void> startListening({
    Function(String)? onResult,
    Function(String)? onError,
    Function()? onDone,
  }) async {
    if (!_isAvailable) {
      _error = '语音识别服务不可用';
      _errorController.add(_error!);
      return;
    }

    if (_isListening) {
      return; // 已在录音中
    }

    _isListening = true;
    _statusController.add(VoiceStatus.listening);
    _lastRecognizedText = '';

    try {
      // 这里需要调用平台原生API开始录音
      // iOS: SFSpeechRecognizer
      // Android: SpeechRecognizer

      // 模拟语音识别过程
      await Future.delayed(const Duration(seconds: 1));

      // 模拟实时识别结果
      final mockResults = [
        '买',
        '买菜',
        '买菜，',
        '买菜，还有',
        '买菜，还有买',
        '买菜，还有买牛奶',
      ];

      for (final result in mockResults) {
        await Future.delayed(const Duration(milliseconds: 500));
        _lastRecognizedText = result;
        _resultController.add(result);
        onResult?.call(result);
      }

      _isListening = false;
      _statusController.add(VoiceStatus.done);
      onDone?.call();
    } catch (e) {
      _error = e.toString();
      _errorController.add(e.toString());
      _isListening = false;
      _statusController.add(VoiceStatus.error);
      onError?.call(e.toString());
    }
  }

  /// 停止语音识别
  Future<void> stopListening() async {
    if (!_isListening) return;

    _isListening = false;
    _statusController.add(VoiceStatus.stopped);

    try {
      // 这里需要调用平台原生API停止录音
    } catch (e) {
      _error = e.toString();
      _errorController.add(e.toString());
    }
  }

  /// 取消语音识别
  Future<void> cancelListening() async {
    if (!_isListening) return;

    _isListening = false;
    _lastRecognizedText = '';
    _statusController.add(VoiceStatus.cancelled);

    try {
      // 这里需要调用平台原生API取消录音
    } catch (e) {
      _error = e.toString();
      _errorController.add(e.toString());
    }
  }

  /// 释放资源
  void dispose() {
    _resultController.close();
    _statusController.close();
    _errorController.close();
  }
}

/// 语音识别状态枚举
enum VoiceStatus {
  /// 未初始化
  uninitialized,

  /// 已初始化
  initialized,

  /// 录音中
  listening,

  /// 已停止
  stopped,

  /// 已完成
  done,

  /// 已取消
  cancelled,

  /// 发生错误
  error,
}
