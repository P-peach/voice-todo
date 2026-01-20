import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

/// 语音识别服务（原生ASR集成）
///
/// 使用平台原生API进行语音识别：
/// - iOS: SFSpeechRecognizer
/// - Android: SpeechRecognizer
/// - Web: Web Speech API (浏览器自动处理权限)
class VoiceRecognitionService {
  static final VoiceRecognitionService instance =
      VoiceRecognitionService._internal();

  // speech_to_text 实例
  late stt.SpeechToText _speech;

  bool _isInitialized = false;
  bool _isListening = false;
  bool _isAvailable = false;
  String _lastRecognizedText = '';
  String? _error;
  Timer? _timeoutTimer;
  bool _hasFinalResult = false;

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

  VoiceRecognitionService._internal() {
    _speech = stt.SpeechToText();
  }

  /// 检查权限状态
  Future<PermissionStatus> checkPermissions() async {
    // Web 平台权限由浏览器自动处理，直接返回已授权
    if (kIsWeb) {
      return PermissionStatus.granted;
    }

    final micStatus = await Permission.microphone.status;
    final speechStatus = await Permission.speech.status;

    // 如果任一权限被拒绝，返回拒绝状态
    if (micStatus.isDenied || speechStatus.isDenied) {
      return PermissionStatus.denied;
    }

    if (micStatus.isPermanentlyDenied || speechStatus.isPermanentlyDenied) {
      return PermissionStatus.permanentlyDenied;
    }

    if (micStatus.isGranted && speechStatus.isGranted) {
      return PermissionStatus.granted;
    }

    return PermissionStatus.notDetermined;
  }

  /// 请求权限
  Future<bool> requestPermissions() async {
    // Web 平台权限由浏览器在首次使用时自动请求
    if (kIsWeb) {
      return true;
    }

    try {
      final micStatus = await Permission.microphone.request();
      final speechStatus = await Permission.speech.request();

      final granted = micStatus.isGranted && speechStatus.isGranted;

      if (!granted) {
        _error = '需要麦克风和语音识别权限才能使用语音输入功能';
        _errorController.add(_error!);
      }

      return granted;
    } catch (e) {
      _error = '请求权限时发生错误: ${e.toString()}';
      _errorController.add(_error!);
      return false;
    }
  }

  /// 初始化语音识别服务
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 检查权限
      final permissionStatus = await checkPermissions();

      if (permissionStatus == PermissionStatus.permanentlyDenied) {
        _error = '语音识别权限已被永久拒绝，请在设置中开启';
        _errorController.add(_error!);
        _statusController.add(VoiceStatus.error);
        return;
      }

      if (permissionStatus != PermissionStatus.granted) {
        final granted = await requestPermissions();
        if (!granted) {
          _error = '未获得必要的权限';
          _errorController.add(_error!);
          _statusController.add(VoiceStatus.error);
          return;
        }
      }

      // 初始化 speech_to_text
      _isAvailable = await _speech.initialize(
        onError: (error) {
          _error = error.errorMsg;
          _errorController.add(error.errorMsg);
          _statusController.add(VoiceStatus.error);
        },
        onStatus: (status) {
          if (kDebugMode) {
            print('Speech recognition status: $status');
          }
        },
      );

      if (!_isAvailable) {
        _error = '设备不支持语音识别功能';
        _errorController.add(_error!);
        _statusController.add(VoiceStatus.error);
        return;
      }

      _isInitialized = true;
      _statusController.add(VoiceStatus.ready);
    } catch (e) {
      _error = '初始化语音识别服务失败: ${e.toString()}';
      _errorController.add(_error!);
      _statusController.add(VoiceStatus.error);
    }
  }

  /// 开始语音识别
  Future<void> startListening({
    String locale = 'zh_CN',
    Function(String)? onResult,
    Function(String)? onError,
  }) async {
    if (!_isAvailable) {
      _error = '语音识别服务不可用';
      _errorController.add(_error!);
      onError?.call(_error!);
      return;
    }

    if (_isListening) {
      return; // 已在录音中
    }

    _isListening = true;
    _lastRecognizedText = '';
    _statusController.add(VoiceStatus.listening);

    try {
      // 设置60秒超时
      _timeoutTimer?.cancel();
      _timeoutTimer = Timer(const Duration(seconds: 60), () async {
        if (_isListening) {
          await stopListening();
          _error = '语音识别超时，已自动停止';
          _errorController.add(_error!);
        }
      });

      // 开始语音识别
      _hasFinalResult = false;
      await _speech.listen(
        onResult: (result) {
          // 如果已经收到 finalResult，不再处理后续结果
          if (_hasFinalResult) return;

          _lastRecognizedText = result.recognizedWords;

          // 只有 finalResult 才发送到 Stream
          if (result.finalResult) {
            _hasFinalResult = true;
            _resultController.add(_lastRecognizedText);
            onResult?.call(_lastRecognizedText);
            stopListening();
          } else {
            // partialResults 不发送到 Stream，避免状态不一致
          }
        },
        localeId: locale,
        listenMode: stt.ListenMode.confirmation,
        cancelOnError: true,
        partialResults: true,
      );
    } catch (e) {
      _error = '开始语音识别失败: ${e.toString()}';
      _errorController.add(_error!);
      _isListening = false;
      _statusController.add(VoiceStatus.error);
      _timeoutTimer?.cancel();
      onError?.call(_error!);
    }
  }

  /// 停止语音识别
  Future<String> stopListening() async {
    if (!_isListening) return _lastRecognizedText;

    _timeoutTimer?.cancel();
    _isListening = false;
    _statusController.add(VoiceStatus.processing);

    try {
      await _speech.stop();
      _statusController.add(VoiceStatus.done);
      return _lastRecognizedText;
    } catch (e) {
      _error = '停止语音识别失败: ${e.toString()}';
      _errorController.add(_error!);
      _statusController.add(VoiceStatus.error);
      return _lastRecognizedText;
    }
  }

  /// 取消语音识别
  Future<void> cancelListening() async {
    if (!_isListening) return;

    _timeoutTimer?.cancel();
    _isListening = false;
    _lastRecognizedText = '';
    _statusController.add(VoiceStatus.ready);

    try {
      await _speech.cancel();
    } catch (e) {
      _error = '取消语音识别失败: ${e.toString()}';
      _errorController.add(_error!);
      _statusController.add(VoiceStatus.error);
    }
  }

  /// 释放资源
  void dispose() {
    _timeoutTimer?.cancel();
    _resultController.close();
    _statusController.close();
    _errorController.close();
  }
}

/// 语音识别状态枚举
enum VoiceStatus {
  /// 未初始化
  uninitialized,

  /// 准备就绪
  ready,

  /// 录音中
  listening,

  /// 处理中
  processing,

  /// 已完成
  done,

  /// 发生错误
  error,
}

/// 权限状态枚举
enum PermissionStatus {
  /// 已授权
  granted,

  /// 已拒绝
  denied,

  /// 永久拒绝
  permanentlyDenied,

  /// 未确定
  notDetermined,
}
