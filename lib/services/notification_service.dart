import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

/// 本地通知服务
/// 管理待办事项的提醒通知
class NotificationService {
  // 单例模式
  static final NotificationService instance = NotificationService._internal();
  
  factory NotificationService() => instance;
  
  NotificationService._internal();

  // flutter_local_notifications 插件实例
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  // 初始化状态
  bool _isInitialized = false;

  /// 初始化通知服务
  Future<void> initialize() async {
    if (_isInitialized) return;

    // 初始化时区数据
    tz.initializeTimeZones();

    // Android 初始化设置
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS 初始化设置
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // 组合初始化设置
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // 初始化插件
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _isInitialized = true;
  }

  /// 通知点击回调
  void _onNotificationTapped(NotificationResponse response) {
    // TODO: 处理通知点击事件，例如导航到待办详情页
    // 可以通过 response.payload 传递待办事项 ID
  }

  /// 调度单次提醒
  /// 
  /// [id] 通知 ID（唯一标识）
  /// [title] 通知标题
  /// [body] 通知内容
  /// [scheduledDate] 调度时间
  Future<void> scheduleReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    if (!_isInitialized) {
      throw StateError('NotificationService not initialized. Call initialize() first.');
    }

    // 转换为时区感知的日期时间
    final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);

    // Android 通知详情
    const androidDetails = AndroidNotificationDetails(
      'todo_reminders', // 渠道 ID
      'Todo Reminders', // 渠道名称
      channelDescription: '待办事项提醒通知',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    // iOS 通知详情
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    // 组合通知详情
    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // 调度通知
    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tzScheduledDate,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// 调度多次提醒
  /// 
  /// [todoId] 待办事项 ID（用于生成唯一的通知 ID）
  /// [title] 通知标题
  /// [deadline] 待办截止日期
  /// [count] 提醒次数
  /// [interval] 提醒间隔
  /// 
  /// 返回已调度的提醒时间列表
  Future<List<DateTime>> scheduleMultipleReminders({
    required int todoId,
    required String title,
    required DateTime deadline,
    required int count,
    required Duration interval,
  }) async {
    if (!_isInitialized) {
      throw StateError('NotificationService not initialized. Call initialize() first.');
    }

    final scheduledTimes = <DateTime>[];

    // 从截止日期往前推算提醒时间
    for (int i = 0; i < count; i++) {
      // 计算提醒时间：deadline - (interval * (count - i))
      final reminderTime = deadline.subtract(interval * (count - i));

      // 只调度未来的提醒
      if (reminderTime.isAfter(DateTime.now())) {
        // 生成唯一的通知 ID：todoId * 1000 + i
        final notificationId = todoId * 1000 + i;

        await scheduleReminder(
          id: notificationId,
          title: '待办提醒',
          body: title,
          scheduledDate: reminderTime,
        );

        scheduledTimes.add(reminderTime);
      }
    }

    return scheduledTimes;
  }

  /// 取消单个提醒
  /// 
  /// [id] 通知 ID
  Future<void> cancelReminder(int id) async {
    if (!_isInitialized) {
      throw StateError('NotificationService not initialized. Call initialize() first.');
    }

    await _notifications.cancel(id);
  }

  /// 取消待办事项的所有提醒
  /// 
  /// [todoId] 待办事项 ID
  /// [count] 提醒次数（用于计算所有通知 ID）
  Future<void> cancelAllRemindersForTodo(int todoId, {int count = 10}) async {
    if (!_isInitialized) {
      throw StateError('NotificationService not initialized. Call initialize() first.');
    }

    // 取消该待办事项的所有可能的通知
    for (int i = 0; i < count; i++) {
      final notificationId = todoId * 1000 + i;
      await _notifications.cancel(notificationId);
    }
  }

  /// 取消所有提醒
  Future<void> cancelAllReminders() async {
    if (!_isInitialized) {
      throw StateError('NotificationService not initialized. Call initialize() first.');
    }

    await _notifications.cancelAll();
  }

  /// 获取待处理的通知列表
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    if (!_isInitialized) {
      throw StateError('NotificationService not initialized. Call initialize() first.');
    }

    return await _notifications.pendingNotificationRequests();
  }

  /// 检查是否已初始化
  bool get isInitialized => _isInitialized;
}
