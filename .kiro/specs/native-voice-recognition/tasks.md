# Implementation Plan: Native Voice Recognition

## Overview

本实现计划将原生语音识别功能分解为离散的编码任务。实现将按照以下顺序进行：首先搭建基础服务层（语音识别、解析、通知），然后实现核心业务逻辑，最后集成到 UI 层。每个任务都包含相应的测试子任务，确保代码质量和正确性。

## Tasks

- [x] 1. 项目依赖和配置
  - 添加必要的依赖包到 pubspec.yaml
  - 配置 iOS 和 Android 平台权限
  - 初始化通知服务配置
  - _Requirements: 1.1, 1.2_

- [x] 2. 实现日期时间解析器 (DateTimeParser)
  - [x] 2.1 创建 DateTimeParser 类和基础结构
    - 实现相对日期解析（今天、明天、后天）
    - 实现星期表达式解析（下周一、下周五）
    - 实现天数偏移解析（三天后、一周后）
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5_

  - [x] 2.2 编写 DateTimeParser 的属性测试
    - **Property 8: 时间表达式解析正确性**
    - **Validates: Requirements 3.2, 4.2, 4.4, 4.5, 4.6, 4.7**

  - [x] 2.3 实现时间段和具体时间解析
    - 实现时间段解析（上午、下午、晚上、中午）
    - 实现具体时间解析（10点、下午3点）
    - _Requirements: 4.6, 4.7_

  - [x] 2.4 编写时间解析的单元测试
    - 测试边界情况（午夜、正午）
    - 测试无效输入处理
    - _Requirements: 4.6, 4.7_

- [x] 3. 实现分类和优先级识别器
  - [x] 3.1 创建 CategoryClassifier 类
    - 定义分类关键词映射表
    - 定义优先级关键词映射表
    - 实现分类识别方法
    - 实现优先级识别方法
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6, 5.7, 5.8_

  - [x] 3.2 编写分类识别的属性测试
    - **Property 9: 分类识别正确性**
    - **Validates: Requirements 3.3, 5.1, 5.2, 5.3, 5.4, 5.5**

  - [x] 3.3 编写优先级识别的属性测试
    - **Property 10: 优先级识别正确性**
    - **Validates: Requirements 3.4, 5.6, 5.7**

- [-] 4. 实现列表模式检测器 (ListModeDetector)
  - [x] 4.1 创建 ListModeDetector 类
    - 实现列表模式检测逻辑
    - 实现列表项分割方法
    - 实现共享属性提取
    - 实现数量信息提取
    - _Requirements: 10.1, 10.2, 10.4, 10.5, 10.6_

  - [x] 4.2 编写列表模式检测的属性测试
    - **Property 12: 列表模式分割正确性**
    - **Validates: Requirements 3.6, 10.1, 10.2, 10.3**

  - [x] 4.3 编写数量信息保留的属性测试
    - **Property 21: 数量信息保留**
    - **Validates: Requirements 10.4**

  - [x] 4.4 编写列表属性继承的属性测试
    - **Property 22: 列表属性继承**
    - **Validates: Requirements 10.5**

- [x] 5. 实现待办事项解析服务 (TodoParserService)
  - [x] 5.1 重构 TodoParserService 类
    - 集成 DateTimeParser
    - 集成 CategoryClassifier
    - 集成 ListModeDetector
    - 实现完整的解析流程
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7_

  - [x] 5.2 编写标题提取的属性测试
    - **Property 7: 标题提取完整性**
    - **Validates: Requirements 3.1**

  - [x] 5.3 编写多待办分割的属性测试
    - **Property 11: 多待办分割正确性**
    - **Validates: Requirements 3.5**

  - [x] 5.4 编写返回类型的属性测试
    - **Property 13: 返回类型正确性**
    - **Validates: Requirements 3.7**

  - [x] 5.5 编写默认行为的属性测试
    - **Property 14: 无时间表达式默认行为**
    - **Property 15: 无关键词默认值**
    - **Validates: Requirements 4.8, 5.8**

  - [x] 5.6 编写提醒标记的属性测试
    - **Property 24: 提醒标记正确性**
    - **Validates: Requirements 11.1**

- [x] 6. Checkpoint - 解析服务测试
  - 确保所有解析相关的测试通过
  - 验证解析器能正确处理示例场景
  - 如有问题，请向用户反馈

- [x] 7. 更新数据模型
  - [x] 7.1 扩展 TodoItem 模型
    - 添加 reminderConfig 字段
    - 更新 toJson 和 fromJson 方法
    - _Requirements: 12.1, 12.2, 12.4, 12.5_

  - [x] 7.2 创建 ReminderConfig 模型
    - 定义 ReminderConfig 类
    - 实现序列化和反序列化方法
    - _Requirements: 11.3, 11.4, 11.5_

  - [x] 7.3 编写 TodoItem 序列化的属性测试
    - **Property 30: TodoItem 序列化 Round-Trip**
    - **Validates: Requirements 12.4, 12.5**

- [x] 8. 实现本地通知服务 (NotificationService)
  - [x] 8.1 创建 NotificationService 类
    - 初始化 flutter_local_notifications
    - 实现单次提醒调度
    - 实现多次提醒调度
    - 实现提醒取消
    - _Requirements: 11.6, 11.7_

  - [x] 8.2 编写通知调度的属性测试
    - **Property 25: 通知调度正确性**
    - **Property 26: 多次提醒调度**
    - **Validates: Requirements 11.6, 11.7**

  - [x] 8.3 编写通知服务的单元测试
    - 测试通知初始化
    - 测试提醒取消
    - _Requirements: 11.6, 11.7_

- [x] 9. 更新 SQLite 服务
  - [x] 9.1 扩展数据库表结构
    - 添加 reminderConfig 字段到 todos 表
    - 创建数据库迁移脚本
    - _Requirements: 12.2, 12.5_

  - [x] 9.2 更新 CRUD 操作
    - 更新 insert 方法以保存提醒配置
    - 更新 query 方法以加载提醒配置
    - 添加批量插入方法
    - _Requirements: 6.2, 6.5, 12.2, 12.3_

  - [x] 9.3 编写数据持久化的属性测试
    - **Property 17: 数据持久化成功性**
    - **Property 28: 数据完整性保存**
    - **Property 29: 持久化加载正确性**
    - **Validates: Requirements 6.2, 12.2, 12.3**

- [x] 10. 实现原生语音识别服务 (VoiceRecognitionService)
  - [x] 10.1 重构 VoiceRecognitionService 类
    - 集成 speech_to_text 包
    - 实现权限检查和请求
    - 实现初始化逻辑
    - _Requirements: 1.1, 1.2, 1.3, 1.6_

  - [x] 10.2 实现语音识别控制方法
    - 实现 startListening 方法
    - 实现 stopListening 方法
    - 实现 cancelListening 方法
    - 实现超时自动停止
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 9.1, 9.2, 9.3, 9.4_

  - [x] 10.3 编写语音识别服务的属性测试
    - **Property 1: 服务初始化状态一致性**
    - **Property 2: 权限请求正确性**
    - **Property 3: 错误信息明确性**
    - **Property 4: 实时识别流连续性**
    - **Property 5: 停止识别返回最终结果**
    - **Property 6: 错误流正确传递**
    - **Property 20: 超时自动停止**
    - **Validates: Requirements 1.1, 1.2, 1.6, 2.2, 2.3, 2.4, 2.5, 9.4**

  - [x] 10.4 编写语音识别服务的单元测试
    - 测试权限拒绝场景
    - 测试设备不支持场景
    - _Requirements: 1.6_

- [x] 11. Checkpoint - 服务层测试
  - 确保所有服务层的测试通过
  - 验证语音识别、解析、通知服务正常工作
  - 如有问题，请向用户反馈

- [x] 12. 更新 VoiceProvider
  - [x] 12.1 重构 VoiceProvider 类
    - 集成新的 VoiceRecognitionService
    - 集成 TodoParserService
    - 实现完整的语音识别流程
    - 实现错误处理
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 6.4, 7.1, 7.2, 7.3, 7.4, 7.5, 7.6, 7.7_

  - [x] 12.2 编写 VoiceProvider 的集成测试
    - 测试完整的语音识别到解析流程
    - 测试错误处理流程
    - _Requirements: 6.4, 7.1, 7.2, 7.3, 7.4, 7.5, 7.6, 7.7_

- [x] 13. 更新 TodoProvider
  - [x] 13.1 扩展 TodoProvider 功能
    - 添加批量添加待办方法
    - 添加提醒设置方法
    - 集成 NotificationService
    - _Requirements: 6.1, 6.2, 6.3, 6.5, 11.2, 11.3, 11.4, 11.5_

  - [x] 13.2 编写 TodoProvider 的属性测试
    - **Property 16: 数据验证完整性**
    - **Property 18: 保存失败错误处理**
    - **Property 19: 批量保存顺序性**
    - **Property 27: 语音创建标记**
    - **Validates: Requirements 6.1, 6.4, 6.5, 12.1**

- [x] 14. 更新 UI 组件
  - [x] 14.1 更新 MicrophoneButton 组件
    - 添加录音状态动画
    - 添加实时识别文本显示
    - 添加错误提示显示
    - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5, 8.6_

  - [x] 14.2 更新 VoiceInputSection 组件
    - 集成新的 VoiceProvider
    - 显示实时识别结果
    - 处理识别完成后的待办创建
    - _Requirements: 6.3, 9.1, 9.2, 9.3_

  - [x] 14.3 创建提醒设置对话框
    - 创建 ReminderDialog 组件
    - 实现提醒次数选择
    - 实现提醒间隔选择
    - _Requirements: 11.2, 11.3, 11.4, 11.5_

  - [x] 14.4 更新 TodoCard 组件
    - 显示提醒图标
    - 显示语音创建标记
    - _Requirements: 11.2, 12.1_

- [x] 15. 实现权限管理 UI
  - [x] 15.1 创建权限请求对话框
    - 显示权限说明
    - 提供跳转到设置的按钮
    - _Requirements: 7.1, 7.2_

  - [x] 15.2 创建设备不支持提示
    - 显示明确的不支持提示
    - 提供替代方案建议
    - _Requirements: 7.3_

- [-] 16. 集成和端到端测试
  - [x] 16.1 编写端到端集成测试
    - 测试完整的语音识别到待办创建流程
    - 测试列表模式的完整流程
    - 测试提醒设置的完整流程
    - _Requirements: 所有需求_

  - [ ] 16.2 手动测试和调优
    - 在 iOS 设备上测试
    - 在 Android 设备上测试
    - 测试各种语音输入场景
    - 调优识别准确率

- [ ] 17. Final Checkpoint - 完整功能验证
  - 确保所有测试通过
  - 验证所有需求场景正常工作
  - 性能和用户体验优化
  - 如有问题，请向用户反馈

## Notes

- 所有测试任务都是必需的，确保从一开始就有全面的测试覆盖
- 每个任务都引用了具体的需求编号，确保可追溯性
- Checkpoint 任务确保增量验证
- 属性测试验证通用正确性属性
- 单元测试验证特定示例和边界情况
- 集成测试验证端到端流程
