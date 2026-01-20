# Requirements Document

## Introduction

本文档定义了语音识别待办事项系统的需求，该系统将接入系统原生 ASR（Automatic Speech Recognition）服务，实现真正可用的语音识别功能，并能够智能解析语音内容，自动创建包含标题、分类、截止日期等信息的待办事项。

## Glossary

- **ASR (Automatic Speech Recognition)**: 自动语音识别，将语音转换为文本的技术
- **Native_ASR**: 系统原生的语音识别服务（iOS 的 SFSpeechRecognizer 和 Android 的 SpeechRecognizer）
- **Voice_Recognition_Service**: 语音识别服务，封装平台原生 ASR API
- **Parser_Service**: 解析服务，从识别的文本中提取待办事项信息
- **Todo_Item**: 待办事项对象，包含标题、描述、分类、优先级、截止日期、提醒配置等属性
- **Real_Time_Recognition**: 实时识别，在用户说话过程中持续返回识别结果
- **Final_Result**: 最终识别结果，用户停止说话后的完整识别文本
- **List_Mode**: 列表模式，识别包含多个品类或项目的列表式描述
- **Reminder_Config**: 提醒配置，包含提醒次数、提醒间隔等参数

## Requirements

### Requirement 1: 系统原生 ASR 集成

**User Story:** 作为用户，我希望使用系统原生的语音识别服务，以便获得准确、快速、离线可用的语音识别体验。

#### Acceptance Criteria

1. WHEN 应用启动时，THE Voice_Recognition_Service SHALL 检查设备是否支持语音识别
2. WHEN 设备支持语音识别时，THE Voice_Recognition_Service SHALL 请求必要的权限（麦克风权限、语音识别权限）
3. WHEN 用户授予权限后，THE Voice_Recognition_Service SHALL 初始化平台原生 ASR 服务
4. WHERE iOS 平台，THE Voice_Recognition_Service SHALL 使用 SFSpeechRecognizer API
5. WHERE Android 平台，THE Voice_Recognition_Service SHALL 使用 SpeechRecognizer API
6. WHEN 设备不支持语音识别或用户拒绝权限时，THE Voice_Recognition_Service SHALL 返回明确的错误信息

### Requirement 2: 实时语音识别

**User Story:** 作为用户，我希望在说话时能够实时看到识别结果，以便确认系统正确理解了我的语音。

#### Acceptance Criteria

1. WHEN 用户开始语音输入时，THE Voice_Recognition_Service SHALL 开始录音并实时识别
2. WHILE 用户说话时，THE Voice_Recognition_Service SHALL 持续返回 Real_Time_Recognition 结果
3. WHEN 识别结果更新时，THE Voice_Recognition_Service SHALL 通过 Stream 发送新的识别文本
4. WHEN 用户停止说话时，THE Voice_Recognition_Service SHALL 返回 Final_Result
5. WHEN 识别过程中发生错误时，THE Voice_Recognition_Service SHALL 通过错误流发送错误信息

### Requirement 3: 智能待办事项解析

**User Story:** 作为用户，我希望系统能够智能解析我的语音内容，自动提取标题、分类、截止日期等信息，以便快速创建待办事项。

#### Acceptance Criteria

1. WHEN Parser_Service 接收到识别文本时，THE Parser_Service SHALL 提取待办事项标题
2. WHEN 文本包含时间表达式时，THE Parser_Service SHALL 解析并提取截止日期
3. WHEN 文本包含分类关键词时，THE Parser_Service SHALL 识别并设置待办事项分类
4. WHEN 文本包含优先级关键词时，THE Parser_Service SHALL 识别并设置优先级
5. WHEN 文本包含多个待办事项时，THE Parser_Service SHALL 分割并分别解析每个待办事项
6. WHEN 文本描述列表式内容（如"苹果两箱，茼蒿10把，草莓"）时，THE Parser_Service SHALL 按品类分割为多个独立待办事项
7. WHEN 解析完成后，THE Parser_Service SHALL 返回结构化的 Todo_Item 对象列表

### Requirement 4: 时间表达式解析

**User Story:** 作为用户，我希望能够用自然语言描述截止日期（如"明天上午"、"下周五"、"三天后"），系统能够自动转换为具体的日期时间。

#### Acceptance Criteria

1. WHEN 文本包含"今天"时，THE Parser_Service SHALL 设置截止日期为当天
2. WHEN 文本包含"明天"时，THE Parser_Service SHALL 设置截止日期为次日
3. WHEN 文本包含"后天"时，THE Parser_Service SHALL 设置截止日期为两天后
4. WHEN 文本包含"下周X"（X为星期几）时，THE Parser_Service SHALL 计算并设置对应日期
5. WHEN 文本包含"X天后"时，THE Parser_Service SHALL 计算并设置对应日期
6. WHEN 文本包含时间段（上午、下午、晚上、中午）时，THE Parser_Service SHALL 设置对应的时间范围
7. WHEN 文本包含具体时间（如"10点"、"下午3点"）时，THE Parser_Service SHALL 设置精确时间
8. WHEN 文本不包含时间表达式时，THE Parser_Service SHALL 将截止日期设置为 null

### Requirement 5: 分类和优先级识别

**User Story:** 作为用户，我希望系统能够根据待办内容自动识别分类和优先级，以便更好地组织我的待办事项。

#### Acceptance Criteria

1. WHEN 文本包含工作相关关键词（如"会议"、"报告"、"项目"、"巡检"、"进货"）时，THE Parser_Service SHALL 设置分类为"工作"
2. WHEN 文本包含购物相关关键词（如"买"、"购买"、"超市"）时，THE Parser_Service SHALL 设置分类为"购物"
3. WHEN 文本包含学习相关关键词（如"学习"、"阅读"、"课程"）时，THE Parser_Service SHALL 设置分类为"学习"
4. WHEN 文本包含生活相关关键词（如"打扫"、"做饭"、"洗衣"、"生日"、"提醒"）时，THE Parser_Service SHALL 设置分类为"生活"
5. WHEN 文本包含健康相关关键词（如"运动"、"锻炼"、"健身"）时，THE Parser_Service SHALL 设置分类为"健康"
6. WHEN 文本包含紧急关键词（如"紧急"、"马上"、"立即"）时，THE Parser_Service SHALL 设置优先级为"高"
7. WHEN 文本包含低优先级关键词（如"不急"、"有空"、"以后"）时，THE Parser_Service SHALL 设置优先级为"低"
8. WHEN 文本不包含明确的分类或优先级关键词时，THE Parser_Service SHALL 使用默认值

### Requirement 6: 自动创建待办事项

**User Story:** 作为用户，我希望语音识别完成后，系统能够自动创建待办事项并保存到数据库，无需手动确认。

#### Acceptance Criteria

1. WHEN Parser_Service 返回 Todo_Item 列表时，THE System SHALL 验证每个待办事项的必填字段
2. WHEN 待办事项验证通过时，THE System SHALL 将其保存到 SQLite 数据库
3. WHEN 待办事项保存成功时，THE System SHALL 更新 UI 显示新创建的待办事项
4. WHEN 待办事项保存失败时，THE System SHALL 显示错误提示并保留识别文本
5. WHEN 创建多个待办事项时，THE System SHALL 按顺序逐个保存

### Requirement 7: 错误处理和用户反馈

**User Story:** 作为用户，我希望在语音识别或解析过程中遇到问题时，能够收到清晰的错误提示，以便了解问题并采取相应措施。

#### Acceptance Criteria

1. WHEN 麦克风权限被拒绝时，THE System SHALL 显示权限请求说明并引导用户到设置页面
2. WHEN 语音识别权限被拒绝时，THE System SHALL 显示权限请求说明并引导用户到设置页面
3. WHEN 设备不支持语音识别时，THE System SHALL 显示明确的不支持提示
4. WHEN 网络连接失败（如果需要在线识别）时，THE System SHALL 提示网络错误
5. WHEN 识别超时时，THE System SHALL 提示用户重新尝试
6. WHEN 识别结果为空时，THE System SHALL 提示用户未识别到有效内容
7. WHEN 解析失败时，THE System SHALL 显示原始识别文本并允许用户手动编辑

### Requirement 8: 语音识别状态管理

**User Story:** 作为用户，我希望能够清楚地看到语音识别的当前状态（准备中、录音中、处理中、完成），以便了解系统的工作状态。

#### Acceptance Criteria

1. WHEN 语音识别服务初始化时，THE System SHALL 显示"准备中"状态
2. WHEN 用户开始录音时，THE System SHALL 显示"录音中"状态和音频波形动画
3. WHEN 用户停止录音后，THE System SHALL 显示"处理中"状态
4. WHEN 识别和解析完成时，THE System SHALL 显示"完成"状态
5. WHEN 发生错误时，THE System SHALL 显示"错误"状态和错误信息
6. WHEN 用户取消录音时，THE System SHALL 恢复到初始状态

### Requirement 9: 语音识别控制

**User Story:** 作为用户，我希望能够控制语音识别的开始、停止和取消，以便灵活地使用语音输入功能。

#### Acceptance Criteria

1. WHEN 用户点击麦克风按钮时，THE System SHALL 开始语音识别
2. WHEN 用户再次点击麦克风按钮时，THE System SHALL 停止语音识别并处理结果
3. WHEN 用户点击取消按钮时，THE System SHALL 取消语音识别并清空识别结果
4. WHEN 语音识别超过最大时长（60秒）时，THE System SHALL 自动停止并处理结果
5. WHEN 用户在录音过程中切换到其他应用时，THE System SHALL 暂停或停止录音

### Requirement 10: 列表式待办事项解析

**User Story:** 作为用户，我希望能够一次性说出多个相关的待办事项（如购物清单），系统能够自动按品类分割为多个独立的待办事项。

#### Acceptance Criteria

1. WHEN 文本包含列表式描述（如"苹果两箱，茼蒿10把，草莓，土豆一箱"）时，THE Parser_Service SHALL 识别列表模式
2. WHEN 识别为列表模式时，THE Parser_Service SHALL 按逗号、顿号等分隔符分割品类
3. WHEN 分割品类后，THE Parser_Service SHALL 为每个品类创建独立的 Todo_Item
4. WHEN 品类包含数量信息时，THE Parser_Service SHALL 将数量信息包含在标题或描述中
5. WHEN 所有品类共享同一时间和分类时，THE Parser_Service SHALL 为所有生成的待办事项设置相同的时间和分类
6. WHEN 列表中某个品类没有明确数量时，THE Parser_Service SHALL 仍然创建该待办事项

### Requirement 11: 提醒功能

**User Story:** 作为用户，我希望能够为待办事项设置提醒，并能够选择提醒次数和间隔，以便不会错过重要事项。

#### Acceptance Criteria

1. WHEN 文本包含提醒关键词（如"提醒我"、"记得"、"别忘了"）时，THE Parser_Service SHALL 标记该待办事项需要提醒
2. WHEN 待办事项需要提醒时，THE System SHALL 在创建后提示用户设置提醒参数
3. WHEN 用户设置提醒时，THE System SHALL 允许选择提醒次数（1次、2次、3次、自定义）
4. WHEN 用户设置提醒时，THE System SHALL 允许选择提醒间隔（提前1小时、提前1天、提前1周、自定义）
5. WHEN 提醒参数设置完成时，THE System SHALL 保存提醒配置到数据库
6. WHEN 到达提醒时间时，THE System SHALL 发送本地通知
7. WHEN 设置多次提醒时，THE System SHALL 按照间隔依次发送通知

### Requirement 12: 数据持久化

**User Story:** 作为用户，我希望通过语音创建的待办事项能够被正确保存，并在应用重启后仍然可用。

#### Acceptance Criteria

1. WHEN 待办事项通过语音创建时，THE System SHALL 标记 isVoiceCreated 字段为 true
2. WHEN 待办事项保存到数据库时，THE System SHALL 保存所有字段（标题、描述、分类、优先级、截止日期、提醒配置等）
3. WHEN 应用重启后，THE System SHALL 能够从数据库加载所有待办事项
4. WHEN 待办事项包含截止日期时，THE System SHALL 正确序列化和反序列化日期时间
5. WHEN 待办事项包含提醒配置时，THE System SHALL 正确保存和恢复提醒设置
6. WHEN 数据库操作失败时，THE System SHALL 记录错误日志并通知用户
