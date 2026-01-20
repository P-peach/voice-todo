import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/voice_recognition_service.dart';
import '../services/todo_parser_service.dart';
import '../models/todo_item.dart';
import '../components/voice/permission_dialog.dart';
import '../components/voice/device_unsupported_dialog.dart';
import 'todo_provider.dart';

/// 语音识别状态管理 Provider
class VoiceProvider extends ChangeNotifier {
  final VoiceRecognitionService _voiceService = VoiceRecognitionService.instance;
  final TodoParserService _parserService = TodoParserService.instance;

  VoiceStatus _status = VoiceStatus.uninitialized;
  String _recognizedText = '';
  String? _error;
  StreamSubscription<String>? _resultSubscription;
  StreamSubscription<VoiceStatus>? _statusSubscription;
  StreamSubscription<String>? _errorSubscription;
  BuildContext? _context;

  VoiceStatus get status => _status;
  String get recognizedText => _recognizedText;
  String? get error => _error;
  bool get isListening => _status == VoiceStatus.listening;
  bool get isAvailable => _voiceService.isAvailable;

  VoiceProvider() {
    _initialize();
  }

  /// 设置 BuildContext 用于显示对话框
  void setContext(BuildContext context) {
    _context = context;
  }

  /// 初始化语音识别服务
  Future<void> _initialize() async {
    try {
      // 检查权限状态
      final permissionStatus = await _voiceService.checkPermissions();
      
      // 如果权限被永久拒绝，显示对话框
      if (permissionStatus == PermissionStatus.permanentlyDenied) {
        _status = VoiceStatus.error;
        _error = '语音识别权限已被永久拒绝';
        notifyListeners();
        
        // 延迟显示对话框，等待 UI 构建完成
        if (_context != null && _context!.mounted) {
          Future.delayed(const Duration(milliseconds: 500), () {
            if (_context != null && _context!.mounted) {
              PermissionDialog.showPermanentlyDenied(
                _context!,
                permissionName: '麦克风和语音识别',
              );
            }
          });
        }
        return;
      }

      // 初始化语音识别服务
      await _voiceService.initialize();

      // 订阅状态流
      _statusSubscription = _voiceService.statusStream.listen((status) {
        _status = status;
        notifyListeners();
        
        // 如果初始化后发现设备不支持，显示对话框
        if (status == VoiceStatus.error && 
            _error?.contains('不支持') == true &&
            _context != null && 
            _context!.mounted) {
          DeviceUnsupportedDialog.show(_context!);
        }
      });

      // 订阅实时识别结果流
      _resultSubscription = _voiceService.resultStream.listen((text) {
        _recognizedText = text;
        notifyListeners();
      });

      // 订阅错误流
      _errorSubscription = _voiceService.errorStream.listen((errorMsg) {
        _error = errorMsg;
        _status = VoiceStatus.error;
        notifyListeners();
      });

      // 如果服务可用，设置为就绪状态
      if (_voiceService.isAvailable) {
        _status = VoiceStatus.ready;
      } else {
        _status = VoiceStatus.error;
        _error = '语音识别服务不可用';
      }
      notifyListeners();
    } catch (e) {
      _error = '初始化语音识别服务失败: ${e.toString()}';
      _status = VoiceStatus.error;
      notifyListeners();
    }
  }

  /// 请求权限（带对话框）
  Future<bool> requestPermissionsWithDialog() async {
    if (_context == null || !_context!.mounted) {
      return false;
    }

    // 检查当前权限状态
    final permissionStatus = await _voiceService.checkPermissions();
    
    // 如果已授权，直接返回
    if (permissionStatus == PermissionStatus.granted) {
      return true;
    }
    
    // 如果永久拒绝，显示前往设置对话框
    if (permissionStatus == PermissionStatus.permanentlyDenied) {
      final result = await PermissionDialog.showPermanentlyDenied(
        _context!,
        permissionName: '麦克风和语音识别',
      );
      return result ?? false;
    }
    
    // 显示权限说明对话框
    final showDialog = await PermissionDialog.showMicrophonePermission(_context!);
    if (showDialog != true) {
      return false;
    }
    
    // 请求权限
    return await _voiceService.requestPermissions();
  }

  /// 开始语音识别
  Future<void> startListening() async {
    // 检查设备是否支持
    if (!_voiceService.isAvailable && _voiceService.isInitialized) {
      _error = '设备不支持语音识别';
      _status = VoiceStatus.error;
      notifyListeners();
      
      if (_context != null && _context!.mounted) {
        await DeviceUnsupportedDialog.show(_context!);
      }
      return;
    }

    // 检查权限
    final permissionStatus = await _voiceService.checkPermissions();
    if (permissionStatus != PermissionStatus.granted) {
      final granted = await requestPermissionsWithDialog();
      if (!granted) {
        _error = '未获得必要的权限';
        _status = VoiceStatus.error;
        notifyListeners();
        return;
      }
      
      // 权限获取后重新初始化
      await _voiceService.initialize();
    }

    if (!_voiceService.isAvailable) {
      _error = '语音识别服务不可用';
      _status = VoiceStatus.error;
      notifyListeners();
      return;
    }

    if (_status == VoiceStatus.listening) {
      return; // 已在录音中
    }

    try {
      // 清空之前的状态
      _recognizedText = '';
      _error = null;
      notifyListeners();

      // 开始语音识别
      await _voiceService.startListening(
        locale: 'zh_CN',
        onResult: (text) {
          // 实时结果已通过 resultStream 处理
        },
        onError: (errorMsg) {
          // 错误已通过 errorStream 处理
        },
      );
    } catch (e) {
      _error = '开始语音识别失败: ${e.toString()}';
      _status = VoiceStatus.error;
      notifyListeners();
    }
  }

  /// 停止语音识别并解析待办事项
  Future<List<TodoItem>> stopListening() async {
    if (_status != VoiceStatus.listening) {
      return [];
    }

    try {
      // 停止语音识别
      final finalText = await _voiceService.stopListening();

      // 如果没有识别到内容
      if (finalText.trim().isEmpty) {
        _error = '未识别到有效内容，请重试';
        _status = VoiceStatus.error;
        notifyListeners();
        return [];
      }

      // 解析待办事项
      _status = VoiceStatus.processing;
      notifyListeners();

      final todos = _parserService.parse(finalText);

      // 如果解析失败
      if (todos.isEmpty) {
        _error = '无法从语音中提取待办事项，请重试';
        _status = VoiceStatus.error;
        notifyListeners();
        return [];
      }

      // 解析成功
      _status = VoiceStatus.done;
      notifyListeners();

      return todos;
    } catch (e) {
      _error = '处理语音识别结果失败: ${e.toString()}';
      _status = VoiceStatus.error;
      notifyListeners();
      return [];
    }
  }

  /// 取消语音识别
  Future<void> cancelListening() async {
    if (_status != VoiceStatus.listening) {
      return;
    }

    try {
      await _voiceService.cancelListening();
      _recognizedText = '';
      _error = null;
      _status = VoiceStatus.ready;
      notifyListeners();
    } catch (e) {
      _error = '取消语音识别失败: ${e.toString()}';
      _status = VoiceStatus.error;
      notifyListeners();
    }
  }

  /// 清除错误信息
  void clearError() {
    _error = null;
    if (_status == VoiceStatus.error) {
      _status = VoiceStatus.ready;
    }
    notifyListeners();
  }

  /// 解析并添加待办事项（供 UI 手动调用）
  Future<void> parseAndAddTodos() async {
    await _parseAndAddTodos();
  }

  /// 解析并添加待办事项（内部方法）
  Future<void> _parseAndAddTodos() async {
    if (_recognizedText.trim().isEmpty) {
      return;
    }

    try {
      // 解析待办事项
      final todos = _parserService.parse(_recognizedText);

      // 如果解析失败
      if (todos.isEmpty) {
        _error = '无法从语音中提取待办事项';
        _status = VoiceStatus.error;
        notifyListeners();
        return;
      }

      // 批量添加待办事项到 TodoProvider
      if (_context != null && _context!.mounted) {
        final todoProvider = Provider.of<TodoProvider>(_context!, listen: false);
        try {
          // 使用批量添加方法，避免多次调用 loadTodos
          await todoProvider.addTodos(todos);
        } catch (e) {
          rethrow;
        }

        // 显示成功提示
        if (_context!.mounted) {
          ScaffoldMessenger.of(_context!).showSnackBar(
            SnackBar(
              content: Text('已添加 ${todos.length} 个待办事项'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }

      // 清空识别文本，准备下次录音
      _recognizedText = '';
      _status = VoiceStatus.ready;
      notifyListeners();
    } catch (e) {
      _error = '添加待办事项失败: ${e.toString()}';
      _status = VoiceStatus.error;
      notifyListeners();
    }
  }

  /// 重置状态
  void reset() {
    _recognizedText = '';
    _error = null;
    _status = VoiceStatus.ready;
    notifyListeners();
  }

  @override
  void dispose() {
    _resultSubscription?.cancel();
    _statusSubscription?.cancel();
    _errorSubscription?.cancel();
    super.dispose();
  }
}
