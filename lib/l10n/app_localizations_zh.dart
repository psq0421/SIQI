// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appName => '司器';

  @override
  String get navChat => '对话';

  @override
  String get navLab => '实验室';

  @override
  String get navSettings => '设置';

  @override
  String get onboardingWelcomeTitle => '欢迎使用司器';

  @override
  String get welcomeBody => '完全端侧优先的 AI 智能工作站。除模型下载和你主动发起的 API 请求外，数据不会离开设备。';

  @override
  String get licenseTitle => '开源许可';

  @override
  String get licenseBody => '本项目源代码采用 MIT License。你导入或下载的模型仍受各自许可证约束。';

  @override
  String get privacyTitle => '隐私说明';

  @override
  String get privacyBody => '配置、密钥、模型、会话和文件均从本地存储。API 密钥使用系统加密存储保存，导出时自动脱敏。';

  @override
  String get noAffiliation =>
      '本应用为个人独立开源项目，与 OpenAI、Anthropic、阿里云等公司无任何商业关联。项目代码按 MIT License 授权，第三方模型与服务遵循各自许可条款。';

  @override
  String get continueLabel => '继续';

  @override
  String get nicknameTitle => '怎么称呼你？';

  @override
  String get nicknameSubtitle => '昵称仅保存在当前设备，可用于系统提示词变量。';

  @override
  String get nicknameHint => '输入昵称';

  @override
  String get personalizationTitle => '个性化';

  @override
  String get colorMode => '颜色模式';

  @override
  String get finish => '开始使用';

  @override
  String get themeSystem => '跟随系统';

  @override
  String get themeLight => '浅色';

  @override
  String get themeDark => '深色';

  @override
  String get defaultSystemPrompt => '你是一位有帮助、注重隐私且表达清晰的 AI 助手。';

  @override
  String get conversations => '会话历史';

  @override
  String get newConversation => '新建会话';

  @override
  String get newChatTitle => '新会话';

  @override
  String get searchHistory => '搜索标题或消息内容';

  @override
  String get delete => '删除';

  @override
  String get model => '模型';

  @override
  String get chooseModel => '选择模型';

  @override
  String get customApi => '自定义 API Key';

  @override
  String get localOffline => '端侧离线';

  @override
  String license(String license) {
    return '许可证：$license';
  }

  @override
  String get notInstalled => '未安装';

  @override
  String get installed => '已安装';

  @override
  String get modeChat => 'Chat';

  @override
  String get modeAgent => 'Agent';

  @override
  String get modeHarness => 'Harness';

  @override
  String get modeMcp => 'MCP';

  @override
  String get attach => '添加附件';

  @override
  String get pureTextNotice => '该模型为纯文本模型，无法处理多模态数据';

  @override
  String get messageHint => '输入消息…';

  @override
  String get send => '发送';

  @override
  String get stop => '停止';

  @override
  String get thinking => '正在推理…';

  @override
  String get slowTitle => '任务仍在运行';

  @override
  String get slowBody => '推理已超过 3 秒。你可以继续等待，或立即终止本次任务。';

  @override
  String get forceStop => '强行终止';

  @override
  String get errorApiNotTested => '此 API 配置尚未通过连接测试，请先在设置中测试。';

  @override
  String get errorLocalNotDownloaded => '本地模型不存在或文件已损坏，请在模型市场下载。';

  @override
  String get errorEngineUnavailable => '端侧推理引擎不可用。请确认原生引擎组件已安装。';

  @override
  String get errorLocalModelLoad =>
      '模型已下载并通过校验，但加载失败。应用已自动降低上下文并尝试 CPU 回退，请在“工作日志”中查看详情。';

  @override
  String get errorLocalPrompt =>
      '模型已加载，但当前会话无法套用模型模板。应用已自动裁剪旧消息，请在“工作日志”中查看详情。';

  @override
  String get errorLocalGeneration => '模型已加载，但生成过程中断。请释放部分内存后重试，详情已写入“工作日志”。';

  @override
  String get errorLocalEmptyOutput => '模型完成运行但没有返回有效文本。请新建会话后重试，详情已写入“工作日志”。';

  @override
  String get errorMemory => '可用内存不足以安全加载此模型。';

  @override
  String get errorNetwork => '网络不可用。你可以切换到已安装的端侧模型。';

  @override
  String get errorRequest => '请求失败，请检查配置后重试。';

  @override
  String get agentWarningTitle => '允许修改本地文件';

  @override
  String get agentWarningBody =>
      '自主编码代理可按你的指令修改本地文件并运行命令。启用前请备份重要数据，并核对每项高风险操作。';

  @override
  String get enable => '确认启用';

  @override
  String get cancel => '取消';

  @override
  String get noMessages => '从一条消息开始，或切换模型与工作模式。';

  @override
  String get labSubtitle => '端侧模型、工具协议与开发工作流';

  @override
  String get modelMarket => '模型市场';

  @override
  String get modelMarketDescription => '下载、续传并管理许可清晰的端侧模型';

  @override
  String get mcpConfiguration => 'MCP 配置';

  @override
  String get mcpDescription => '挂载本地文件、数据库或 Webhook 工具';

  @override
  String get harnessDashboard => 'Harness 仪表盘';

  @override
  String get harnessDescription => '语言检测、静态扫描和测试用例建议';

  @override
  String get agentToolbox => 'Agent 工具箱';

  @override
  String get agentToolboxDescription => '在二次确认保护下运行完整 Shell 指令';

  @override
  String get codeReview => '代码审查';

  @override
  String get codeReviewDescription => '从本地文件生成结构化审查报告';

  @override
  String get githubImport => 'GitHub 仓库导入';

  @override
  String get githubImportDescription => '使用令牌导入仓库压缩包到本地目录';

  @override
  String get download => '下载';

  @override
  String get pause => '暂停';

  @override
  String get resume => '继续';

  @override
  String get unavailable => '暂无已验证下载源';

  @override
  String modelSize(String size) {
    return '约 $size';
  }

  @override
  String memoryRequirement(int memory) {
    return '建议内存 $memory GB';
  }

  @override
  String get downloadStarted => '模型下载已开始';

  @override
  String downloadProgress(int percent) {
    return '已下载 $percent%';
  }

  @override
  String get modelLicenseNotice => '下载即表示你同意模型卡片所列许可证；模型文件仅保存在本机。';

  @override
  String get mcpTitle => 'MCP 服务器';

  @override
  String get addServer => '添加服务器';

  @override
  String get serverName => '名称';

  @override
  String get transport => '传输方式';

  @override
  String get commandOrUrl => '命令或 URL';

  @override
  String get configurationJson => '配置 JSON';

  @override
  String get enabledStatus => '启用';

  @override
  String get save => '保存';

  @override
  String get localFilesTemplate => '本地文件模板';

  @override
  String get databaseTemplate => '数据库模板';

  @override
  String get webhookTemplate => 'Webhook 模板';

  @override
  String get noServers => '尚未配置 MCP 服务器';

  @override
  String get selectFile => '选择文件';

  @override
  String get analyze => '开始分析';

  @override
  String languageDetected(String language) {
    return '检测语言：$language';
  }

  @override
  String get reviewResult => '审查结果';

  @override
  String get noIssues => '未发现明显的结构性问题。仍建议运行项目自带的分析器与测试。';

  @override
  String get selectCodeFirst => '请先选择一个代码文件';

  @override
  String get shellTitle => '全指令 Shell';

  @override
  String get commandHint => '输入 Shell 命令';

  @override
  String get run => '运行';

  @override
  String get output => '输出';

  @override
  String exitCode(int code) {
    return '退出码：$code';
  }

  @override
  String get dangerousTitle => '检测到高危命令';

  @override
  String get dangerousBody => '此命令可能删除数据、格式化存储或重启设备。请逐字确认后再运行。';

  @override
  String get confirmRun => '仍然运行';

  @override
  String get history => '历史记录';

  @override
  String get repoOwner => '仓库所有者';

  @override
  String get repoName => '仓库名称';

  @override
  String get destination => '本地目标目录';

  @override
  String get tokenOptional => '访问令牌（私有仓库必填）';

  @override
  String get importAction => '导入';

  @override
  String get importSuccess => '导入完成';

  @override
  String get chooseFolder => '选择目录';

  @override
  String get settingsSubtitle => '本地偏好、API 投射与数据管理';

  @override
  String get conversationReasoning => '对话与推理参数';

  @override
  String get contextWindow => '上下文窗口';

  @override
  String get temperature => 'Temperature';

  @override
  String get topP => 'Top-P';

  @override
  String get maxTokens => '最大输出 Tokens';

  @override
  String get systemPrompt => 'System Prompt';

  @override
  String get variablesHint => '支持 {user_name} 与 {current_time} 变量';

  @override
  String get appearance => '界面与外观';

  @override
  String get fontScale => '全局字体缩放';

  @override
  String get messageSpacing => '消息间距';

  @override
  String get timestampFormat => '时间戳格式';

  @override
  String get timeRelative => '相对时间';

  @override
  String get time24 => '24 小时制';

  @override
  String get time12 => '12 小时制';

  @override
  String get language => '语言';

  @override
  String get dataStorage => '数据与存储';

  @override
  String get saveInterval => '自动保存间隔';

  @override
  String get saveRealtime => '实时';

  @override
  String get saveFiveMinutes => '5 分钟';

  @override
  String get saveManual => '手动';

  @override
  String get modelStorage => '模型存储路径';

  @override
  String get defaultPath => '应用默认目录';

  @override
  String get exportData => '导出全部数据';

  @override
  String get importData => '导入恢复';

  @override
  String get exportConfig => '导出脱敏配置';

  @override
  String get share => '分享';

  @override
  String get exportReady => '导出文件已生成';

  @override
  String importFailed(String reason) {
    return '导入失败：$reason';
  }

  @override
  String get apiProjection => '自定义 API 投射';

  @override
  String get manageProviders => '管理厂商、兼容格式与自定义 Headers';

  @override
  String get quotaStatistics => '额度统计';

  @override
  String get inputTokens => '输入 Tokens';

  @override
  String get outputTokens => '输出 Tokens';

  @override
  String get estimatedCost => '估算费用';

  @override
  String get shellSettings => 'Shell 设置';

  @override
  String get historyLength => '命令历史长度';

  @override
  String get defaultShell => '默认 Shell 环境';

  @override
  String get dangerousConfirmation => '高危命令二次确认';

  @override
  String get aboutLegal => '关于与合规';

  @override
  String get versionLabel => '版本 1.0.0';

  @override
  String get apiProfiles => 'API 配置';

  @override
  String get addProfile => '添加配置';

  @override
  String get noProfiles => '尚未添加自定义 API 配置';

  @override
  String get providerTemplate => '厂商模板';

  @override
  String get customName => '自定义名称';

  @override
  String get baseUrl => 'Base URL';

  @override
  String get modelId => '模型 ID';

  @override
  String get apiKey => 'API Key';

  @override
  String get apiFormat => '接口格式';

  @override
  String get multimodal => '支持多模态';

  @override
  String get customHeaders => '自定义 Headers';

  @override
  String get headersHint => '例如：{\"X-Custom\":\"value\"}';

  @override
  String get testConnection => '测试连接';

  @override
  String get testing => '测试中…';

  @override
  String get testSuccess => '连接测试成功';

  @override
  String testFailed(String reason) {
    return '连接测试失败：$reason';
  }

  @override
  String get neverTested => '尚未测试';

  @override
  String lastTested(String time) {
    return '上次测试：$time';
  }

  @override
  String get deleteProfile => '删除此配置';

  @override
  String get invalidJson => 'Headers 必须是字符串键值组成的 JSON 对象';

  @override
  String get requiredField => '请填写所有必填项';

  @override
  String get done => '完成';

  @override
  String get close => '关闭';

  @override
  String get loading => '加载中…';

  @override
  String get error => '出现错误';

  @override
  String notificationDownloadTitle(String model) {
    return '正在下载 $model';
  }

  @override
  String get notificationDownloadBody => '下载任务在后台继续运行';

  @override
  String fileReadFailed(String reason) {
    return '无法读取文件：$reason';
  }

  @override
  String get justNow => '刚刚';

  @override
  String minutesAgo(int count) {
    return '$count 分钟前';
  }

  @override
  String hoursAgo(int count) {
    return '$count 小时前';
  }

  @override
  String daysAgo(int count) {
    return '$count 天前';
  }

  @override
  String reviewTodos(int count) {
    return '发现 $count 个 TODO/FIXME 待办标记。';
  }

  @override
  String reviewLongLines(int count) {
    return '发现 $count 行超过 120 个字符，建议拆分。';
  }

  @override
  String reviewSecrets(int count) {
    return '发现 $count 处疑似明文密钥，请立即核查。';
  }

  @override
  String reviewShellCalls(int count) {
    return '发现 $count 处进程或 Shell 调用，请校验输入边界。';
  }

  @override
  String get generatedTestIdeas => '单元测试建议';

  @override
  String get testIdeasBody => '覆盖正常输入、空输入、边界值、异常路径与资源释放；对文件和进程操作使用临时目录或替身实现。';

  @override
  String get languageZhHans => '简体中文';

  @override
  String get languageZhHant => '繁體中文';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageJapanese => '日本語';

  @override
  String get protocolOpenAi => 'OpenAI 兼容';

  @override
  String get protocolAnthropic => 'Anthropic 兼容';

  @override
  String get transportStdio => '标准输入输出';

  @override
  String get transportHttp => 'HTTP';

  @override
  String get transportSse => 'SSE';

  @override
  String get shellSystemName => '系统 sh';

  @override
  String get shellTermuxName => 'Termux';

  @override
  String get shellShizukuName => 'Shizuku';

  @override
  String get notificationChannelDownloads => '模型下载';

  @override
  String get notificationChannelDownloadsDescription => '端侧模型后台下载进度';

  @override
  String get githubOAuth => 'GitHub OAuth 登录';

  @override
  String get oauthClientId => 'OAuth App Client ID';

  @override
  String get oauthClientIdRequired => '请先填写 GitHub OAuth App Client ID';

  @override
  String get oauthInstruction => '浏览器已打开。请输入下方设备代码并授权仓库访问：';

  @override
  String get oauthCodeCopied => '设备代码已复制到剪贴板';

  @override
  String get authorizationComplete => '我已完成授权';

  @override
  String get oauthPendingOrExpired => '授权尚未完成或设备代码已过期';

  @override
  String get oauthSuccess => 'GitHub 授权成功';

  @override
  String get oauthOpenFailed => '无法打开系统浏览器';

  @override
  String get chatWorkspaceSubtitle => '对话、模型与本地工具工作台';

  @override
  String get chatWelcomeTitle => '今天想完成什么？';

  @override
  String get noWorkspace => '未选择工作区';

  @override
  String get noWorkspaceSelected => '尚未选择本地工作区';

  @override
  String contextValue(int value) {
    return '上下文 ${value}K';
  }

  @override
  String get streamingOn => '流式开启';

  @override
  String get streamingOff => '流式关闭';

  @override
  String get multimodalReady => '多模态可用';

  @override
  String get textOnly => '仅文本';

  @override
  String get noConversations => '暂无会话';

  @override
  String get noConversationsBody => '新建会话后，所有历史记录都只保存在本机。';

  @override
  String get suggestionExplain => '解释代码';

  @override
  String get suggestionExplainPrompt => '请解释这段代码的逻辑、边界条件与潜在风险。';

  @override
  String get suggestionReview => '审查项目';

  @override
  String get suggestionReviewPrompt => '请审查当前工作区，优先检查正确性、安全性和可维护性。';

  @override
  String get suggestionBuild => '构建功能';

  @override
  String get suggestionBuildPrompt => '请先分析当前工作区并制定计划，然后实现我接下来描述的功能。';

  @override
  String get roleYou => '你';

  @override
  String get streamingResponse => '正在流式生成';

  @override
  String get errorWorkspaceRequired => 'Agent 模式需要本地工作区，请先在设置中选择目录。';

  @override
  String get agentActionPlan => 'Agent 动作计划';

  @override
  String actionCount(int count) {
    return '$count 项动作';
  }

  @override
  String get rejectActions => '拒绝';

  @override
  String get approveReadOnly => '批准只读';

  @override
  String get approveAll => '批准全部';

  @override
  String get confirmAgentActionsTitle => '确认执行工作区变更';

  @override
  String get confirmAgentActionsBody => '下列动作可能写入本地文件或运行命令。请逐项核对，确认已备份重要数据。';

  @override
  String get confirmExecute => '确认执行';

  @override
  String get executionOutput => '执行输出';

  @override
  String get actionListFiles => '列出文件';

  @override
  String get actionReadFile => '读取文件';

  @override
  String get actionWriteFile => '写入文件';

  @override
  String get actionCreateDirectory => '创建目录';

  @override
  String get actionRunCommand => '运行命令';

  @override
  String get labOverview => '工作站概览';

  @override
  String get notConfigured => '未配置';

  @override
  String get localReady => '本地就绪';

  @override
  String tokensUsed(int count) {
    return '已用 $count Tokens';
  }

  @override
  String get mcpServersMetric => 'MCP 服务器';

  @override
  String get localModelsMetric => '端侧模型';

  @override
  String get availableToDownload => '可下载型号';

  @override
  String get workbenchTools => '工作台工具';

  @override
  String get workbenchToolsDescription => '模型、协议、审查、Shell 与仓库导入';

  @override
  String get workspaceScan => '工作区静态扫描';

  @override
  String get selectWorkspaceFirst => '请先选择一个本地工作区';

  @override
  String get scanning => '扫描中…';

  @override
  String get analyzeWorkspace => '分析工作区';

  @override
  String scanFailed(String reason) {
    return '扫描失败：$reason';
  }

  @override
  String get scannedFiles => '已扫描文件';

  @override
  String get errorSeverity => '错误';

  @override
  String get warningSeverity => '警告';

  @override
  String get infoSeverity => '提示';

  @override
  String get testDrafts => '测试草稿';

  @override
  String issueCount(int count) {
    return '共 $count 项结果';
  }

  @override
  String get allSeverities => '全部';

  @override
  String get noIssuesTitle => '未发现规则问题';

  @override
  String get testDraftDescription => '根据源文件语言生成的最小测试骨架，请核对后再加入项目。';

  @override
  String get copy => '复制';

  @override
  String get copied => '已复制到剪贴板';

  @override
  String get issueLongLine => '代码行过长，建议拆分以提高可读性';

  @override
  String get issueTodo => '存在待办或临时标记';

  @override
  String get issueHardcodedSecret => '疑似硬编码密钥或凭据';

  @override
  String get issueDynamicExecution => '动态执行可能运行不可信输入';

  @override
  String get issueShellInjection => 'Shell 调用存在输入注入风险';

  @override
  String get issueSqlInterpolation => 'SQL 字符串插值可能导致注入';

  @override
  String get issueEmptyCatch => '空异常处理会掩盖错误';

  @override
  String get issueDebugOutput => '生产代码中存在调试输出';

  @override
  String get issueCleartextUrl => '非本机地址使用了明文 HTTP';

  @override
  String get issueDestructiveCommand => '发现潜在破坏性命令';

  @override
  String get issueMissingDispose => '控制器可能未在生命周期结束时释放';

  @override
  String get issueInnerHtml => '直接写入 innerHTML 可能导致脚本注入';

  @override
  String get noServersBody => '添加本地或 HTTP 服务器后，可测试握手并查看可用工具。';

  @override
  String get disabledStatus => '已停用';

  @override
  String get connectionSuccess => '连接成功';

  @override
  String get connectionFailed => '连接失败';

  @override
  String latencyMs(int value) {
    return '$value ms';
  }

  @override
  String toolsDiscovered(int count) {
    return '发现 $count 个工具';
  }

  @override
  String get noTools => '服务器未返回工具。';

  @override
  String get testServer => '测试服务器';

  @override
  String get edit => '编辑';

  @override
  String get editServer => '编辑服务器';

  @override
  String get deleteServer => '删除服务器';

  @override
  String deleteServerBody(String name) {
    return '确定删除“$name”吗？此操作不会删除服务器端数据。';
  }

  @override
  String get configurationJsonInvalid => '配置必须是有效的 JSON 对象';

  @override
  String get commandQueue => 'Shell 命令队列';

  @override
  String get shellAppDirectory => '应用默认执行目录';

  @override
  String activeTasks(int count) {
    return '$count 个活动任务';
  }

  @override
  String get addToQueue => '加入队列';

  @override
  String get taskQueue => '任务队列';

  @override
  String get clearCompleted => '清理已完成';

  @override
  String get queueEmpty => '队列为空';

  @override
  String get queueEmptyBody => '命令将按加入顺序串行执行，输出会保留在本机。';

  @override
  String get refresh => '刷新';

  @override
  String get noCommandHistory => '暂无本地命令历史';

  @override
  String get noOutput => '此任务没有输出';

  @override
  String get statusQueued => '等待中';

  @override
  String get statusRunning => '运行中';

  @override
  String get statusCompleted => '已完成';

  @override
  String get statusFailed => '失败';

  @override
  String get statusCancelled => '已取消';

  @override
  String get streamResponses => '流式显示响应';

  @override
  String get streamResponsesDescription => '远程模型返回内容时逐字显示';

  @override
  String get showTokenCounter => '显示 Token 计数';

  @override
  String get autoTitleSessions => '自动生成会话标题';

  @override
  String get confirmAgentWrites => 'Agent 写入前确认';

  @override
  String get confirmAgentWritesDescription => '写文件和运行命令前显示动作清单';

  @override
  String get activeWorkspace => '活动工作区';

  @override
  String get downloadWifiOnly => '仅使用 Wi-Fi 下载模型';

  @override
  String get downloadWifiOnlyDescription => '避免端侧模型消耗移动数据';

  @override
  String get downloadWifiRequired => '已开启仅 Wi-Fi 下载，请连接 Wi-Fi 后重试。';

  @override
  String get downloadChecksumMismatch => '模型校验失败，已删除损坏文件，请重新下载。';

  @override
  String downloadFailedReason(String reason) {
    return '下载失败：$reason';
  }

  @override
  String get workspaceOnboardingTitle => '选择工作区';

  @override
  String get workspaceOnboardingBody =>
      'Agent 与 Harness 工具将使用这个本地目录。你也可以暂时跳过，稍后在设置中选择。';

  @override
  String preferredProjectsPath(String path) {
    return '推荐项目目录：$path';
  }

  @override
  String get settingsConversationDescription => '上下文、输出长度、采样参数、提示词与 Agent 防护';

  @override
  String get settingsAppearanceDescription => '主题、语言、动效、字体、间距与时间戳';

  @override
  String get settingsDataDescription => '工作区、模型存储、备份恢复与下载策略';

  @override
  String get settingsShellDescription => 'Shell 环境、历史记录与高危命令确认';

  @override
  String get aboutDescription => '版本、源码仓库、许可证与法律声明';

  @override
  String get projectRepository => '项目仓库';

  @override
  String get savedLocally => '已保存到本地';

  @override
  String get serverOnlyModel => '仅服务器';

  @override
  String get officialSource => '官方来源';

  @override
  String get noCompatibleLocalModels => '当前最新一代模型暂无经过验证且兼容本项目 Android 引擎的移动端包。';

  @override
  String get deepSeekHarnessTitle => 'DeepSeek Harness';

  @override
  String deepSeekHarnessVersion(String version) {
    return '官方运行包 $version';
  }

  @override
  String get developerPreview => '开发者预览';

  @override
  String get harnessRuntimeNotice =>
      '官方运行时要求 Node.js 22.19+ 或 24+，无法直接在普通 Android APK 内执行。司器可校验并下载官方包、管理插件源码归档，并连接由 Termux 或同一局域网电脑启动的运行时。下载的插件绝不会被静默执行。';

  @override
  String get addDeepSeekProfile => '添加 DeepSeek API 配置';

  @override
  String get harnessDeepSeekProfile => 'Harness 使用的 DeepSeek API 配置';

  @override
  String get runtimeDownloaded => '运行包已下载';

  @override
  String get downloadOfficialRuntime => '下载官方运行包';

  @override
  String get harnessPluginCatalog => 'Harness 插件目录';

  @override
  String get developmentDocs => '开发文档';

  @override
  String get repository => '仓库';

  @override
  String get openLocalHarness => '打开本地运行时';

  @override
  String get localPreflight => '本地预检';

  @override
  String get syncAllPlugins => '同步全部插件';

  @override
  String get pluginCatalogNotice =>
      '该目录自动聚合公开 GitHub 仓库，未审查安全性或兼容性。司器只在本地保存元数据与源码归档；安装或执行始终需要你明确操作。';

  @override
  String get searchPlugins => '搜索名称、作者、描述或分类';

  @override
  String pluginSyncProgress(int completed, int total, int count) {
    return '页面 $completed/$total · 已保存 $count 个插件';
  }

  @override
  String get noPluginsSynced => '本地尚未保存插件目录。';

  @override
  String get pluginSecurityTitle => '核对第三方源码';

  @override
  String pluginSecurityBody(String repository) {
    return '下载 $repository 的源码归档吗？司器未审查该仓库。下载不会安装或运行代码；在外部运行时启用前，请检查许可证、提交版本和构建脚本。';
  }

  @override
  String get downloadSourceArchive => '下载源码';

  @override
  String get removePluginArchive => '移除本地归档';

  @override
  String removePluginArchiveBody(String name) {
    return '删除 $name 的已下载归档吗？已同步的目录元数据会保留。';
  }

  @override
  String get downloaded => '已下载';

  @override
  String get copyInstallCommand => '复制安装命令';

  @override
  String get errorHarnessDeepSeekRequired =>
      'Harness 模式仅支持已测试且已保存密钥的 DeepSeek API 配置。请先在实验室的 Harness 页面完成选择。';

  @override
  String get modeTeam => 'AI 团队';

  @override
  String get startupFailureTitle => '司器暂时无法启动';

  @override
  String get startupFailureBody =>
      '本地初始化遇到问题。你的数据没有被删除，请重新打开应用；若问题持续，可在日志与缓存中导出运行日志。';

  @override
  String get permissionPrivacy => '权限与隐私';

  @override
  String get permissionPrivacyMenuDescription => '查看每项权限的用途、当前状态与调用记录';

  @override
  String get permissionPrivacyBody =>
      '司器仅在你使用对应功能时申请权限。拒绝不会阻止应用启动，你可以在系统设置中重新授权，也可以删除本页保存的权限调用记录。';

  @override
  String get openSystemSettings => '系统设置';

  @override
  String get currentPermissions => '当前权限';

  @override
  String get permissionHistory => '调用记录';

  @override
  String get clearHistory => '清空记录';

  @override
  String get noPermissionHistory => '尚无权限调用记录';

  @override
  String get deleteRecord => '删除此记录';

  @override
  String get systemPickerManaged => '由系统选择器管理';

  @override
  String get permissionNotifications => '通知';

  @override
  String get permissionMicrophone => '麦克风';

  @override
  String get permissionCamera => '相机';

  @override
  String get permissionPhotos => '照片与视频';

  @override
  String get permissionWorkspace => '工作区目录';

  @override
  String get permissionNotificationsDescription => '仅在模型下载或长任务开始时，用于显示进度与完成状态。';

  @override
  String get permissionMicrophoneDescription => '仅在你主动录音进行语音转文字时调用。';

  @override
  String get permissionCameraDescription => '仅在你主动拍摄多模态附件时调用。';

  @override
  String get permissionPhotosDescription => '仅在你主动选择图片或视频附件时调用。';

  @override
  String get permissionWorkspaceDescription =>
      '通过 Android 系统目录选择器授权；不申请所有文件访问或 Root。';

  @override
  String get purposeModelDownload => '显示模型下载与后台任务进度';

  @override
  String get purposeSpeechToText => '录制需要转写的语音';

  @override
  String get purposeCameraAttachment => '拍摄对话附件';

  @override
  String get purposeImageAttachment => '选择多模态附件';

  @override
  String get purposeWorkspace => '读取或修改已选择的工作区';

  @override
  String get purposeModelStorage => '选择模型存储目录';

  @override
  String get permissionGranted => '已允许';

  @override
  String get permissionDenied => '已拒绝';

  @override
  String get permissionPermanentlyDenied => '已永久拒绝';

  @override
  String get permissionRestricted => '受系统限制';

  @override
  String get permissionLimited => '部分允许';

  @override
  String get permissionUnknown => '检查中';

  @override
  String get logsAndCache => '日志与缓存';

  @override
  String get logsAndCacheDescription => '导出工作日志、诊断启动问题并清理临时缓存';

  @override
  String get cache => '临时缓存';

  @override
  String get calculating => '正在计算…';

  @override
  String get clearCache => '清理缓存';

  @override
  String get runtimeLogs => '运行日志';

  @override
  String get runtimeLogsDescription => '本地异常与启动诊断，不包含已保存的 API 密钥';

  @override
  String get shareLogs => '导出日志';

  @override
  String get clearLogs => '清空日志';

  @override
  String get workLogs => '工作日志';

  @override
  String get noWorkLogs => '尚无工作日志';

  @override
  String get developerMode => '开发者模式';

  @override
  String get developerModeDescription =>
      '开启后才显示本地 Shell。命令仅在应用沙箱或已授权工作区中运行，不提供 Root、提权或系统分区写入。';

  @override
  String get developerModeRequired => '需要开启开发者模式';

  @override
  String get developerModeRequiredDescription =>
      '请前往设置 > Shell 设置阅读安全边界并手动开启。普通用户无需输入任何命令。';

  @override
  String get aiTeamMode => 'AI 团队';

  @override
  String get aiTeamDescription => '让最多 8 个已配置的云端 AI 共享上下文、分轮协作并汇总结果';

  @override
  String get aiTeamNotice =>
      '每一轮都会按顺序调用所有成员，成员能看到之前成员的输出。调用会消耗各 API 的额度；任务、成员输出与工作日志仅保存在本机。';

  @override
  String get aiTeamNeedsProfiles => '需要已测试的 API 配置';

  @override
  String get aiTeamNeedsProfilesDescription =>
      '先在设置的自定义 API 投射中添加并测试至少一个云端模型，然后即可创建团队，全程无需输入命令。';

  @override
  String get noAiTeams => '尚未创建 AI 团队';

  @override
  String get noAiTeamsDescription => '选择 1–8 个已测试模型，并设置协作轮数。';

  @override
  String get newAiTeam => '新建团队';

  @override
  String get activeAiTeam => '当前团队';

  @override
  String get editAiTeam => '编辑团队';

  @override
  String get deleteAiTeam => '删除团队';

  @override
  String deleteAiTeamBody(String name) {
    return '删除“$name”及其本地协作记录吗？';
  }

  @override
  String get aiTeamTask => '团队任务';

  @override
  String get aiTeamTaskHint => '描述目标、约束和期望交付物';

  @override
  String get startCollaboration => '开始协作';

  @override
  String get teamTranscript => '团队工作记录';

  @override
  String get noTeamMessages => '尚无团队协作记录';

  @override
  String get teamFinalAnswer => '团队最终汇总';

  @override
  String teamMemberRound(String name, int round) {
    return '$name · 第 $round 轮';
  }

  @override
  String get aiTeamName => '团队名称';

  @override
  String aiTeamMembers(int count) {
    return '团队成员 $count/8';
  }

  @override
  String collaborationRounds(int count) {
    return '协作轮数：$count';
  }

  @override
  String get mcpStore => 'MCP 商店';

  @override
  String get mcpStoreDescription => '浏览、缓存并管理 ModelScope MCP 服务';

  @override
  String get syncCatalog => '同步目录';

  @override
  String get openOfficialCatalog => '打开官方目录';

  @override
  String get searchMcpStore => '搜索名称、作者或说明';

  @override
  String mcpStoreSynced(int count) {
    return '已同步 $count 个 MCP 服务';
  }

  @override
  String get mcpStoreProtected => 'ModelScope 暂时要求浏览器安全验证，自动同步未完成。';

  @override
  String get mcpStoreCacheNotice => '现有本地缓存仍可使用，也可以打开官方目录查看最新内容。';

  @override
  String get mcpStoreEmpty => '本地还没有 MCP 商店缓存。同步只读取公开目录，不会上传本地配置。';

  @override
  String get mcpImported => '已导入 MCP 管理器，请先测试连接再启用。';

  @override
  String get mcpImportManualRequired => '该服务没有公开的托管端点，请查看官方详情完成授权或部署。';

  @override
  String get importToMcp => '导入管理器';

  @override
  String get details => '详情';

  @override
  String get serverUrl => '服务器 URL';

  @override
  String get multimodalZone => '多模态专区';

  @override
  String get multimodalZoneDescription => '语音模型、内存评估与音频时长建议';

  @override
  String get audioMemoryGuard => '60% 内存保护';

  @override
  String audioMemorySummary(String total, String budget, String available) {
    return '设备总内存 $total；模型与任务最多使用 $budget；当前可用 $available。';
  }

  @override
  String get audioMemoryPolicy =>
      '只有具备可验证来源、Android 端侧运行时且峰值占用不超过总内存 60% 的模型才会开放下载。';

  @override
  String get speechToText => '语音转文字';

  @override
  String get textToSpeech => '文字转语音';

  @override
  String officialWeightSize(String size) {
    return '官方权重大小：$size';
  }

  @override
  String get audioRuntimeUnavailable =>
      '权重大小符合预算，但目前没有经过验证的 Android 量化运行时，因此暂不开放下载。';

  @override
  String get audioModelExceedsLimit => '该官方模型超过本设备的 60% 内存上限，已阻止下载和加载。';

  @override
  String get audioDurationUnavailable => '当前没有安全的端侧内存余量，建议最大音频时长：0 分钟。';

  @override
  String audioDurationSuggestion(String duration) {
    return '按剩余内存估算，建议单次音频不超过 $duration。';
  }

  @override
  String get notCompatible => '当前设备不兼容';
}

/// The translations for Chinese, as used in Taiwan (`zh_TW`).
class AppLocalizationsZhTw extends AppLocalizationsZh {
  AppLocalizationsZhTw() : super('zh_TW');

  @override
  String get appName => '司器';

  @override
  String get navChat => '對話';

  @override
  String get navLab => '實驗室';

  @override
  String get navSettings => '設定';

  @override
  String get onboardingWelcomeTitle => '歡迎使用司器';

  @override
  String get welcomeBody => '完全端側優先的 AI 智慧工作站。除模型下載和你主動發起的 API 請求外，資料不會離開裝置。';

  @override
  String get licenseTitle => '開源授權';

  @override
  String get licenseBody => '本專案原始碼採用 MIT License。你匯入或下載的模型仍受各自授權條款約束。';

  @override
  String get privacyTitle => '隱私說明';

  @override
  String get privacyBody => '設定、金鑰、模型、會話和檔案均從本機儲存。API 金鑰使用系統加密儲存，匯出時自動遮蔽。';

  @override
  String get noAffiliation =>
      '本應用為個人獨立開源專案，與 OpenAI、Anthropic、阿里雲等公司無任何商業關聯。專案程式碼依 MIT License 授權，第三方模型與服務遵循各自授權條款。';

  @override
  String get continueLabel => '繼續';

  @override
  String get nicknameTitle => '怎麼稱呼你？';

  @override
  String get nicknameSubtitle => '暱稱僅儲存在目前裝置，可用於系統提示詞變數。';

  @override
  String get nicknameHint => '輸入暱稱';

  @override
  String get personalizationTitle => '個人化';

  @override
  String get colorMode => '顏色模式';

  @override
  String get finish => '開始使用';

  @override
  String get themeSystem => '跟隨系統';

  @override
  String get themeLight => '淺色';

  @override
  String get themeDark => '深色';

  @override
  String get defaultSystemPrompt => '你是一位有幫助、注重隱私且表達清晰的 AI 助手。';

  @override
  String get conversations => '會話歷史';

  @override
  String get newConversation => '新增會話';

  @override
  String get newChatTitle => '新會話';

  @override
  String get searchHistory => '搜尋標題或訊息內容';

  @override
  String get delete => '刪除';

  @override
  String get model => '模型';

  @override
  String get chooseModel => '選擇模型';

  @override
  String get customApi => '自訂 API Key';

  @override
  String get localOffline => '端側離線';

  @override
  String license(String license) {
    return '授權：$license';
  }

  @override
  String get notInstalled => '未安裝';

  @override
  String get installed => '已安裝';

  @override
  String get modeChat => 'Chat';

  @override
  String get modeAgent => 'Agent';

  @override
  String get modeHarness => 'Harness';

  @override
  String get modeMcp => 'MCP';

  @override
  String get attach => '加入附件';

  @override
  String get pureTextNotice => '該模型為純文字模型，無法處理多模態資料';

  @override
  String get messageHint => '輸入訊息…';

  @override
  String get send => '傳送';

  @override
  String get stop => '停止';

  @override
  String get thinking => '正在推理…';

  @override
  String get slowTitle => '任務仍在執行';

  @override
  String get slowBody => '推理已超過 3 秒。你可以繼續等待，或立即終止本次任務。';

  @override
  String get forceStop => '強制終止';

  @override
  String get errorApiNotTested => '此 API 設定尚未通過連線測試，請先在設定中測試。';

  @override
  String get errorLocalNotDownloaded => '本機模型不存在或檔案已損壞，請在模型市場下載。';

  @override
  String get errorEngineUnavailable => '端側推理引擎不可用。請確認原生引擎元件已安裝。';

  @override
  String get errorLocalModelLoad =>
      '模型已下載並通過驗證，但載入失敗。應用程式已自動降低上下文並嘗試 CPU 回退，請在「工作記錄」查看詳情。';

  @override
  String get errorLocalPrompt =>
      '模型已載入，但目前對話無法套用模型範本。應用程式已自動裁剪舊訊息，請在「工作記錄」查看詳情。';

  @override
  String get errorLocalGeneration => '模型已載入，但生成過程中斷。請釋放部分記憶體後重試，詳情已寫入「工作記錄」。';

  @override
  String get errorLocalEmptyOutput => '模型完成執行但未返回有效文字。請建立新對話後重試，詳情已寫入「工作記錄」。';

  @override
  String get errorMemory => '可用記憶體不足以安全載入此模型。';

  @override
  String get errorNetwork => '網路不可用。你可以切換到已安裝的端側模型。';

  @override
  String get errorRequest => '請求失敗，請檢查設定後重試。';

  @override
  String get agentWarningTitle => '允許修改本機檔案';

  @override
  String get agentWarningBody =>
      '自主程式設計代理可依你的指令修改本機檔案並執行命令。啟用前請備份重要資料，並核對每項高風險操作。';

  @override
  String get enable => '確認啟用';

  @override
  String get cancel => '取消';

  @override
  String get noMessages => '從一條訊息開始，或切換模型與工作模式。';

  @override
  String get labSubtitle => '端側模型、工具協定與開發工作流程';

  @override
  String get modelMarket => '模型市場';

  @override
  String get modelMarketDescription => '下載、續傳並管理授權清晰的端側模型';

  @override
  String get mcpConfiguration => 'MCP 設定';

  @override
  String get mcpDescription => '掛載本機檔案、資料庫或 Webhook 工具';

  @override
  String get harnessDashboard => 'Harness 儀表板';

  @override
  String get harnessDescription => '語言偵測、靜態掃描和測試案例建議';

  @override
  String get agentToolbox => 'Agent 工具箱';

  @override
  String get agentToolboxDescription => '在二次確認保護下執行完整 Shell 指令';

  @override
  String get codeReview => '程式碼審查';

  @override
  String get codeReviewDescription => '從本機檔案產生結構化審查報告';

  @override
  String get githubImport => 'GitHub 儲存庫匯入';

  @override
  String get githubImportDescription => '使用權杖匯入儲存庫壓縮包到本機目錄';

  @override
  String get download => '下載';

  @override
  String get pause => '暫停';

  @override
  String get resume => '繼續';

  @override
  String get unavailable => '暫無已驗證下載來源';

  @override
  String modelSize(String size) {
    return '約 $size';
  }

  @override
  String memoryRequirement(int memory) {
    return '建議記憶體 $memory GB';
  }

  @override
  String get downloadStarted => '模型下載已開始';

  @override
  String downloadProgress(int percent) {
    return '已下載 $percent%';
  }

  @override
  String get modelLicenseNotice => '下載即表示你同意模型卡片所列授權；模型檔案僅保存在本機。';

  @override
  String get mcpTitle => 'MCP 伺服器';

  @override
  String get addServer => '新增伺服器';

  @override
  String get serverName => '名稱';

  @override
  String get transport => '傳輸方式';

  @override
  String get commandOrUrl => '命令或 URL';

  @override
  String get configurationJson => '設定 JSON';

  @override
  String get enabledStatus => '啟用';

  @override
  String get save => '儲存';

  @override
  String get localFilesTemplate => '本機檔案範本';

  @override
  String get databaseTemplate => '資料庫範本';

  @override
  String get webhookTemplate => 'Webhook 範本';

  @override
  String get noServers => '尚未設定 MCP 伺服器';

  @override
  String get selectFile => '選擇檔案';

  @override
  String get analyze => '開始分析';

  @override
  String languageDetected(String language) {
    return '偵測語言：$language';
  }

  @override
  String get reviewResult => '審查結果';

  @override
  String get noIssues => '未發現明顯的結構性問題。仍建議執行專案自帶的分析器與測試。';

  @override
  String get selectCodeFirst => '請先選擇一個程式碼檔案';

  @override
  String get shellTitle => '全指令 Shell';

  @override
  String get commandHint => '輸入 Shell 命令';

  @override
  String get run => '執行';

  @override
  String get output => '輸出';

  @override
  String exitCode(int code) {
    return '退出碼：$code';
  }

  @override
  String get dangerousTitle => '偵測到高危命令';

  @override
  String get dangerousBody => '此命令可能刪除資料、格式化儲存或重新啟動裝置。請逐字確認後再執行。';

  @override
  String get confirmRun => '仍然執行';

  @override
  String get history => '歷史記錄';

  @override
  String get repoOwner => '儲存庫擁有者';

  @override
  String get repoName => '儲存庫名稱';

  @override
  String get destination => '本機目標目錄';

  @override
  String get tokenOptional => '存取權杖（私有儲存庫必填）';

  @override
  String get importAction => '匯入';

  @override
  String get importSuccess => '匯入完成';

  @override
  String get chooseFolder => '選擇目錄';

  @override
  String get settingsSubtitle => '本機偏好、API 投射與資料管理';

  @override
  String get conversationReasoning => '對話與推理參數';

  @override
  String get contextWindow => '上下文視窗';

  @override
  String get temperature => 'Temperature';

  @override
  String get topP => 'Top-P';

  @override
  String get maxTokens => '最大輸出 Tokens';

  @override
  String get systemPrompt => 'System Prompt';

  @override
  String get variablesHint => '支援 {user_name} 與 {current_time} 變數';

  @override
  String get appearance => '介面與外觀';

  @override
  String get fontScale => '全域字型縮放';

  @override
  String get messageSpacing => '訊息間距';

  @override
  String get timestampFormat => '時間戳格式';

  @override
  String get timeRelative => '相對時間';

  @override
  String get time24 => '24 小時制';

  @override
  String get time12 => '12 小時制';

  @override
  String get language => '語言';

  @override
  String get dataStorage => '資料與儲存';

  @override
  String get saveInterval => '自動儲存間隔';

  @override
  String get saveRealtime => '即時';

  @override
  String get saveFiveMinutes => '5 分鐘';

  @override
  String get saveManual => '手動';

  @override
  String get modelStorage => '模型儲存路徑';

  @override
  String get defaultPath => '應用程式預設目錄';

  @override
  String get exportData => '匯出全部資料';

  @override
  String get importData => '匯入恢復';

  @override
  String get exportConfig => '匯出遮蔽設定';

  @override
  String get share => '分享';

  @override
  String get exportReady => '匯出檔案已產生';

  @override
  String importFailed(String reason) {
    return '匯入失敗：$reason';
  }

  @override
  String get apiProjection => '自訂 API 投射';

  @override
  String get manageProviders => '管理廠商、相容格式與自訂 Headers';

  @override
  String get quotaStatistics => '額度統計';

  @override
  String get inputTokens => '輸入 Tokens';

  @override
  String get outputTokens => '輸出 Tokens';

  @override
  String get estimatedCost => '估算費用';

  @override
  String get shellSettings => 'Shell 設定';

  @override
  String get historyLength => '命令歷史長度';

  @override
  String get defaultShell => '預設 Shell 環境';

  @override
  String get dangerousConfirmation => '高危命令二次確認';

  @override
  String get aboutLegal => '關於與合規';

  @override
  String get versionLabel => '版本 1.0.0';

  @override
  String get apiProfiles => 'API 設定';

  @override
  String get addProfile => '新增設定';

  @override
  String get noProfiles => '尚未新增自訂 API 設定';

  @override
  String get providerTemplate => '廠商範本';

  @override
  String get customName => '自訂名稱';

  @override
  String get baseUrl => 'Base URL';

  @override
  String get modelId => '模型 ID';

  @override
  String get apiKey => 'API Key';

  @override
  String get apiFormat => '介面格式';

  @override
  String get multimodal => '支援多模態';

  @override
  String get customHeaders => '自訂 Headers';

  @override
  String get headersHint => '例如：{\"X-Custom\":\"value\"}';

  @override
  String get testConnection => '測試連線';

  @override
  String get testing => '測試中…';

  @override
  String get testSuccess => '連線測試成功';

  @override
  String testFailed(String reason) {
    return '連線測試失敗：$reason';
  }

  @override
  String get neverTested => '尚未測試';

  @override
  String lastTested(String time) {
    return '上次測試：$time';
  }

  @override
  String get deleteProfile => '刪除此設定';

  @override
  String get invalidJson => 'Headers 必須是由字串鍵值組成的 JSON 物件';

  @override
  String get requiredField => '請填寫所有必填欄位';

  @override
  String get done => '完成';

  @override
  String get close => '關閉';

  @override
  String get loading => '載入中…';

  @override
  String get error => '發生錯誤';

  @override
  String notificationDownloadTitle(String model) {
    return '正在下載 $model';
  }

  @override
  String get notificationDownloadBody => '下載任務在背景繼續執行';

  @override
  String fileReadFailed(String reason) {
    return '無法讀取檔案：$reason';
  }

  @override
  String get justNow => '剛剛';

  @override
  String minutesAgo(int count) {
    return '$count 分鐘前';
  }

  @override
  String hoursAgo(int count) {
    return '$count 小時前';
  }

  @override
  String daysAgo(int count) {
    return '$count 天前';
  }

  @override
  String reviewTodos(int count) {
    return '發現 $count 個 TODO/FIXME 待辦標記。';
  }

  @override
  String reviewLongLines(int count) {
    return '發現 $count 行超過 120 個字元，建議拆分。';
  }

  @override
  String reviewSecrets(int count) {
    return '發現 $count 處疑似明文金鑰，請立即核查。';
  }

  @override
  String reviewShellCalls(int count) {
    return '發現 $count 處程序或 Shell 呼叫，請驗證輸入邊界。';
  }

  @override
  String get generatedTestIdeas => '單元測試建議';

  @override
  String get testIdeasBody => '涵蓋正常輸入、空輸入、邊界值、例外路徑與資源釋放；檔案和程序操作請使用暫存目錄或替身實作。';

  @override
  String get languageZhHans => '简体中文';

  @override
  String get languageZhHant => '繁體中文';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageJapanese => '日本語';

  @override
  String get protocolOpenAi => 'OpenAI 相容';

  @override
  String get protocolAnthropic => 'Anthropic 相容';

  @override
  String get transportStdio => '標準輸入輸出';

  @override
  String get transportHttp => 'HTTP';

  @override
  String get transportSse => 'SSE';

  @override
  String get shellSystemName => '系統 sh';

  @override
  String get shellTermuxName => 'Termux';

  @override
  String get shellShizukuName => 'Shizuku';

  @override
  String get notificationChannelDownloads => '模型下載';

  @override
  String get notificationChannelDownloadsDescription => '端側模型背景下載進度';

  @override
  String get githubOAuth => 'GitHub OAuth 登入';

  @override
  String get oauthClientId => 'OAuth App Client ID';

  @override
  String get oauthClientIdRequired => '請先填寫 GitHub OAuth App Client ID';

  @override
  String get oauthInstruction => '瀏覽器已開啟。請輸入下方裝置代碼並授權儲存庫存取：';

  @override
  String get oauthCodeCopied => '裝置代碼已複製到剪貼簿';

  @override
  String get authorizationComplete => '我已完成授權';

  @override
  String get oauthPendingOrExpired => '授權尚未完成或裝置代碼已過期';

  @override
  String get oauthSuccess => 'GitHub 授權成功';

  @override
  String get oauthOpenFailed => '無法開啟系統瀏覽器';

  @override
  String get chatWorkspaceSubtitle => '對話、模型與本機工具工作臺';

  @override
  String get chatWelcomeTitle => '今天想完成什麼？';

  @override
  String get noWorkspace => '未選擇工作區';

  @override
  String get noWorkspaceSelected => '尚未選擇本機工作區';

  @override
  String contextValue(int value) {
    return '上下文 ${value}K';
  }

  @override
  String get streamingOn => '串流開啟';

  @override
  String get streamingOff => '串流關閉';

  @override
  String get multimodalReady => '多模態可用';

  @override
  String get textOnly => '僅文字';

  @override
  String get noConversations => '暫無對話';

  @override
  String get noConversationsBody => '建立對話後，所有歷史記錄都只保存在本機。';

  @override
  String get suggestionExplain => '解釋程式碼';

  @override
  String get suggestionExplainPrompt => '請解釋這段程式碼的邏輯、邊界條件與潛在風險。';

  @override
  String get suggestionReview => '審查專案';

  @override
  String get suggestionReviewPrompt => '請審查目前工作區，優先檢查正確性、安全性與可維護性。';

  @override
  String get suggestionBuild => '建置功能';

  @override
  String get suggestionBuildPrompt => '請先分析目前工作區並制定計畫，然後實作我接下來描述的功能。';

  @override
  String get roleYou => '你';

  @override
  String get streamingResponse => '正在串流產生';

  @override
  String get errorWorkspaceRequired => 'Agent 模式需要本機工作區，請先在設定中選擇目錄。';

  @override
  String get agentActionPlan => 'Agent 動作計畫';

  @override
  String actionCount(int count) {
    return '$count 項動作';
  }

  @override
  String get rejectActions => '拒絕';

  @override
  String get approveReadOnly => '核准唯讀';

  @override
  String get approveAll => '全部核准';

  @override
  String get confirmAgentActionsTitle => '確認執行工作區變更';

  @override
  String get confirmAgentActionsBody => '下列動作可能寫入本機檔案或執行命令。請逐項核對並備份重要資料。';

  @override
  String get confirmExecute => '確認執行';

  @override
  String get executionOutput => '執行輸出';

  @override
  String get actionListFiles => '列出檔案';

  @override
  String get actionReadFile => '讀取檔案';

  @override
  String get actionWriteFile => '寫入檔案';

  @override
  String get actionCreateDirectory => '建立目錄';

  @override
  String get actionRunCommand => '執行命令';

  @override
  String get labOverview => '工作站概覽';

  @override
  String get notConfigured => '未設定';

  @override
  String get localReady => '本機就緒';

  @override
  String tokensUsed(int count) {
    return '已用 $count Tokens';
  }

  @override
  String get mcpServersMetric => 'MCP 伺服器';

  @override
  String get localModelsMetric => '端側模型';

  @override
  String get availableToDownload => '可下載型號';

  @override
  String get workbenchTools => '工作臺工具';

  @override
  String get workbenchToolsDescription => '模型、協定、審查、Shell 與儲存庫匯入';

  @override
  String get workspaceScan => '工作區靜態掃描';

  @override
  String get selectWorkspaceFirst => '請先選擇一個本機工作區';

  @override
  String get scanning => '掃描中…';

  @override
  String get analyzeWorkspace => '分析工作區';

  @override
  String scanFailed(String reason) {
    return '掃描失敗：$reason';
  }

  @override
  String get scannedFiles => '已掃描檔案';

  @override
  String get errorSeverity => '錯誤';

  @override
  String get warningSeverity => '警告';

  @override
  String get infoSeverity => '提示';

  @override
  String get testDrafts => '測試草稿';

  @override
  String issueCount(int count) {
    return '共 $count 項結果';
  }

  @override
  String get allSeverities => '全部';

  @override
  String get noIssuesTitle => '未發現規則問題';

  @override
  String get testDraftDescription => '依來源檔語言產生的最小測試骨架，請核對後再加入專案。';

  @override
  String get copy => '複製';

  @override
  String get copied => '已複製到剪貼簿';

  @override
  String get issueLongLine => '程式碼行過長，建議拆分以提高可讀性';

  @override
  String get issueTodo => '存在待辦或暫時標記';

  @override
  String get issueHardcodedSecret => '疑似硬編碼金鑰或憑證';

  @override
  String get issueDynamicExecution => '動態執行可能執行不受信任輸入';

  @override
  String get issueShellInjection => 'Shell 呼叫存在輸入注入風險';

  @override
  String get issueSqlInterpolation => 'SQL 字串插值可能導致注入';

  @override
  String get issueEmptyCatch => '空白例外處理會掩蓋錯誤';

  @override
  String get issueDebugOutput => '正式程式碼中存在除錯輸出';

  @override
  String get issueCleartextUrl => '非本機位址使用明文 HTTP';

  @override
  String get issueDestructiveCommand => '發現潛在破壞性命令';

  @override
  String get issueMissingDispose => '控制器可能未在生命週期結束時釋放';

  @override
  String get issueInnerHtml => '直接寫入 innerHTML 可能導致指令碼注入';

  @override
  String get noServersBody => '新增本機或 HTTP 伺服器後，可測試握手並查看可用工具。';

  @override
  String get disabledStatus => '已停用';

  @override
  String get connectionSuccess => '連線成功';

  @override
  String get connectionFailed => '連線失敗';

  @override
  String latencyMs(int value) {
    return '$value ms';
  }

  @override
  String toolsDiscovered(int count) {
    return '發現 $count 個工具';
  }

  @override
  String get noTools => '伺服器未回傳工具。';

  @override
  String get testServer => '測試伺服器';

  @override
  String get edit => '編輯';

  @override
  String get editServer => '編輯伺服器';

  @override
  String get deleteServer => '刪除伺服器';

  @override
  String deleteServerBody(String name) {
    return '確定刪除「$name」嗎？此操作不會刪除伺服器端資料。';
  }

  @override
  String get configurationJsonInvalid => '設定必須是有效的 JSON 物件';

  @override
  String get commandQueue => 'Shell 命令佇列';

  @override
  String get shellAppDirectory => '應用程式預設執行目錄';

  @override
  String activeTasks(int count) {
    return '$count 個活動工作';
  }

  @override
  String get addToQueue => '加入佇列';

  @override
  String get taskQueue => '工作佇列';

  @override
  String get clearCompleted => '清理已完成';

  @override
  String get queueEmpty => '佇列為空';

  @override
  String get queueEmptyBody => '命令將依加入順序逐一執行，輸出會保留在本機。';

  @override
  String get refresh => '重新整理';

  @override
  String get noCommandHistory => '暫無本機命令歷史';

  @override
  String get noOutput => '此工作沒有輸出';

  @override
  String get statusQueued => '等待中';

  @override
  String get statusRunning => '執行中';

  @override
  String get statusCompleted => '已完成';

  @override
  String get statusFailed => '失敗';

  @override
  String get statusCancelled => '已取消';

  @override
  String get streamResponses => '串流顯示回應';

  @override
  String get streamResponsesDescription => '遠端模型回傳內容時逐字顯示';

  @override
  String get showTokenCounter => '顯示 Token 計數';

  @override
  String get autoTitleSessions => '自動產生對話標題';

  @override
  String get confirmAgentWrites => 'Agent 寫入前確認';

  @override
  String get confirmAgentWritesDescription => '寫入檔案和執行命令前顯示動作清單';

  @override
  String get activeWorkspace => '活動工作區';

  @override
  String get downloadWifiOnly => '僅使用 Wi-Fi 下載模型';

  @override
  String get downloadWifiOnlyDescription => '避免端側模型消耗行動數據';

  @override
  String get downloadWifiRequired => '已啟用僅 Wi-Fi 下載，請連接 Wi-Fi 後再試。';

  @override
  String get downloadChecksumMismatch => '模型校驗失敗，已刪除損壞檔案，請重新下載。';

  @override
  String downloadFailedReason(String reason) {
    return '下載失敗：$reason';
  }

  @override
  String get workspaceOnboardingTitle => '選擇工作區';

  @override
  String get workspaceOnboardingBody =>
      'Agent 與 Harness 工具將使用這個本機目錄。你也可以暫時略過，稍後在設定中選擇。';

  @override
  String preferredProjectsPath(String path) {
    return '建議專案目錄：$path';
  }

  @override
  String get settingsConversationDescription => '上下文、輸出長度、取樣參數、提示詞與 Agent 防護';

  @override
  String get settingsAppearanceDescription => '主題、語言、動效、字體、間距與時間戳記';

  @override
  String get settingsDataDescription => '工作區、模型儲存、備份還原與下載策略';

  @override
  String get settingsShellDescription => 'Shell 環境、歷史記錄與高風險命令確認';

  @override
  String get aboutDescription => '版本、原始碼倉庫、授權條款與法律聲明';

  @override
  String get projectRepository => '專案倉庫';

  @override
  String get savedLocally => '已儲存到本機';

  @override
  String get serverOnlyModel => '僅伺服器';

  @override
  String get officialSource => '官方來源';

  @override
  String get noCompatibleLocalModels =>
      '目前最新一代模型尚無經過驗證且相容本專案 Android 引擎的行動端套件。';

  @override
  String get deepSeekHarnessTitle => 'DeepSeek Harness';

  @override
  String deepSeekHarnessVersion(String version) {
    return '官方執行套件 $version';
  }

  @override
  String get developerPreview => '開發者預覽';

  @override
  String get harnessRuntimeNotice =>
      '官方執行環境要求 Node.js 22.19+ 或 24+，無法直接在一般 Android APK 內執行。司器可驗證並下載官方套件、管理外掛原始碼封存，並連線到由 Termux 或同一區域網路電腦啟動的執行環境。下載的外掛絕不會被靜默執行。';

  @override
  String get addDeepSeekProfile => '新增 DeepSeek API 設定';

  @override
  String get harnessDeepSeekProfile => 'Harness 使用的 DeepSeek API 設定';

  @override
  String get runtimeDownloaded => '執行套件已下載';

  @override
  String get downloadOfficialRuntime => '下載官方執行套件';

  @override
  String get harnessPluginCatalog => 'Harness 外掛目錄';

  @override
  String get developmentDocs => '開發文件';

  @override
  String get repository => '倉庫';

  @override
  String get openLocalHarness => '開啟本機執行環境';

  @override
  String get localPreflight => '本機預檢';

  @override
  String get syncAllPlugins => '同步全部外掛';

  @override
  String get pluginCatalogNotice =>
      '此目錄自動彙整公開 GitHub 倉庫，未審查安全性或相容性。司器只在本機儲存中繼資料與原始碼封存；安裝或執行一律需要你明確操作。';

  @override
  String get searchPlugins => '搜尋名稱、作者、描述或分類';

  @override
  String pluginSyncProgress(int completed, int total, int count) {
    return '頁面 $completed/$total · 已儲存 $count 個外掛';
  }

  @override
  String get noPluginsSynced => '本機尚未儲存外掛目錄。';

  @override
  String get pluginSecurityTitle => '核對第三方原始碼';

  @override
  String pluginSecurityBody(String repository) {
    return '下載 $repository 的原始碼封存嗎？司器未審查該倉庫。下載不會安裝或執行程式碼；在外部執行環境啟用前，請檢查授權條款、提交版本與建置指令碼。';
  }

  @override
  String get downloadSourceArchive => '下載原始碼';

  @override
  String get removePluginArchive => '移除本機封存';

  @override
  String removePluginArchiveBody(String name) {
    return '刪除 $name 的已下載封存嗎？已同步的目錄中繼資料會保留。';
  }

  @override
  String get downloaded => '已下載';

  @override
  String get copyInstallCommand => '複製安裝命令';

  @override
  String get errorHarnessDeepSeekRequired =>
      'Harness 模式僅支援已測試且已儲存金鑰的 DeepSeek API 設定。請先在實驗室的 Harness 頁面完成選擇。';

  @override
  String get modeTeam => 'AI 團隊';

  @override
  String get startupFailureTitle => '司器暫時無法啟動';

  @override
  String get startupFailureBody =>
      '本機初始化遇到問題。你的資料沒有被刪除，請重新開啟應用程式；若問題持續，可在日誌與快取中匯出執行日誌。';

  @override
  String get permissionPrivacy => '權限與隱私';

  @override
  String get permissionPrivacyMenuDescription => '查看每項權限的用途、目前狀態與呼叫記錄';

  @override
  String get permissionPrivacyBody =>
      '司器僅在你使用對應功能時申請權限。拒絕不會阻止應用程式啟動，你可在系統設定重新授權，也可刪除本頁保存的權限呼叫記錄。';

  @override
  String get openSystemSettings => '系統設定';

  @override
  String get currentPermissions => '目前權限';

  @override
  String get permissionHistory => '呼叫記錄';

  @override
  String get clearHistory => '清除記錄';

  @override
  String get noPermissionHistory => '尚無權限呼叫記錄';

  @override
  String get deleteRecord => '刪除此記錄';

  @override
  String get systemPickerManaged => '由系統選擇器管理';

  @override
  String get permissionNotifications => '通知';

  @override
  String get permissionMicrophone => '麥克風';

  @override
  String get permissionCamera => '相機';

  @override
  String get permissionPhotos => '相片與影片';

  @override
  String get permissionWorkspace => '工作區目錄';

  @override
  String get permissionNotificationsDescription => '僅在模型下載或長任務開始時，用於顯示進度與完成狀態。';

  @override
  String get permissionMicrophoneDescription => '僅在你主動錄音進行語音轉文字時呼叫。';

  @override
  String get permissionCameraDescription => '僅在你主動拍攝多模態附件時呼叫。';

  @override
  String get permissionPhotosDescription => '僅在你主動選擇圖片或影片附件時呼叫。';

  @override
  String get permissionWorkspaceDescription =>
      '透過 Android 系統目錄選擇器授權；不申請所有檔案存取或 Root。';

  @override
  String get purposeModelDownload => '顯示模型下載與背景任務進度';

  @override
  String get purposeSpeechToText => '錄製需要轉寫的語音';

  @override
  String get purposeCameraAttachment => '拍攝對話附件';

  @override
  String get purposeImageAttachment => '選擇多模態附件';

  @override
  String get purposeWorkspace => '讀取或修改已選擇的工作區';

  @override
  String get purposeModelStorage => '選擇模型儲存目錄';

  @override
  String get permissionGranted => '已允許';

  @override
  String get permissionDenied => '已拒絕';

  @override
  String get permissionPermanentlyDenied => '已永久拒絕';

  @override
  String get permissionRestricted => '受系統限制';

  @override
  String get permissionLimited => '部分允許';

  @override
  String get permissionUnknown => '檢查中';

  @override
  String get logsAndCache => '日誌與快取';

  @override
  String get logsAndCacheDescription => '匯出工作日誌、診斷啟動問題並清理暫存快取';

  @override
  String get cache => '暫存快取';

  @override
  String get calculating => '正在計算…';

  @override
  String get clearCache => '清理快取';

  @override
  String get runtimeLogs => '執行日誌';

  @override
  String get runtimeLogsDescription => '本機異常與啟動診斷，不包含已儲存的 API 金鑰';

  @override
  String get shareLogs => '匯出日誌';

  @override
  String get clearLogs => '清除日誌';

  @override
  String get workLogs => '工作日誌';

  @override
  String get noWorkLogs => '尚無工作日誌';

  @override
  String get developerMode => '開發者模式';

  @override
  String get developerModeDescription =>
      '開啟後才顯示本機 Shell。指令僅在應用程式沙箱或已授權工作區執行，不提供 Root、提權或系統分割區寫入。';

  @override
  String get developerModeRequired => '需要開啟開發者模式';

  @override
  String get developerModeRequiredDescription =>
      '請前往設定 > Shell 設定閱讀安全邊界並手動開啟。一般使用者不需要輸入任何指令。';

  @override
  String get aiTeamMode => 'AI 團隊';

  @override
  String get aiTeamDescription => '讓最多 8 個已設定的雲端 AI 共用內容、分輪協作並彙整結果';

  @override
  String get aiTeamNotice =>
      '每一輪都會依序呼叫所有成員，成員可看到之前成員的輸出。呼叫會消耗各 API 額度；任務、成員輸出與工作日誌僅儲存在本機。';

  @override
  String get aiTeamNeedsProfiles => '需要已測試的 API 設定';

  @override
  String get aiTeamNeedsProfilesDescription =>
      '先在設定的自訂 API 投射中新增並測試至少一個雲端模型，即可建立團隊，全程不需輸入指令。';

  @override
  String get noAiTeams => '尚未建立 AI 團隊';

  @override
  String get noAiTeamsDescription => '選擇 1–8 個已測試模型，並設定協作輪數。';

  @override
  String get newAiTeam => '新增團隊';

  @override
  String get activeAiTeam => '目前團隊';

  @override
  String get editAiTeam => '編輯團隊';

  @override
  String get deleteAiTeam => '刪除團隊';

  @override
  String deleteAiTeamBody(String name) {
    return '刪除「$name」及其本機協作記錄嗎？';
  }

  @override
  String get aiTeamTask => '團隊任務';

  @override
  String get aiTeamTaskHint => '描述目標、限制與預期交付物';

  @override
  String get startCollaboration => '開始協作';

  @override
  String get teamTranscript => '團隊工作記錄';

  @override
  String get noTeamMessages => '尚無團隊協作記錄';

  @override
  String get teamFinalAnswer => '團隊最終彙整';

  @override
  String teamMemberRound(String name, int round) {
    return '$name · 第 $round 輪';
  }

  @override
  String get aiTeamName => '團隊名稱';

  @override
  String aiTeamMembers(int count) {
    return '團隊成員 $count/8';
  }

  @override
  String collaborationRounds(int count) {
    return '協作輪數：$count';
  }

  @override
  String get mcpStore => 'MCP 商店';

  @override
  String get mcpStoreDescription => '瀏覽、快取並管理 ModelScope MCP 服務';

  @override
  String get syncCatalog => '同步目錄';

  @override
  String get openOfficialCatalog => '開啟官方目錄';

  @override
  String get searchMcpStore => '搜尋名稱、作者或說明';

  @override
  String mcpStoreSynced(int count) {
    return '已同步 $count 個 MCP 服務';
  }

  @override
  String get mcpStoreProtected => 'ModelScope 暫時要求瀏覽器安全驗證，自動同步未完成。';

  @override
  String get mcpStoreCacheNotice => '現有本機快取仍可使用，也可以開啟官方目錄查看最新內容。';

  @override
  String get mcpStoreEmpty => '本機還沒有 MCP 商店快取。同步只讀取公開目錄，不會上傳本機設定。';

  @override
  String get mcpImported => '已匯入 MCP 管理器，請先測試連線再啟用。';

  @override
  String get mcpImportManualRequired => '該服務沒有公開的託管端點，請查看官方詳情完成授權或部署。';

  @override
  String get importToMcp => '匯入管理器';

  @override
  String get details => '詳情';

  @override
  String get serverUrl => '伺服器 URL';

  @override
  String get multimodalZone => '多模態專區';

  @override
  String get multimodalZoneDescription => '語音模型、記憶體評估與音訊時長建議';

  @override
  String get audioMemoryGuard => '60% 記憶體保護';

  @override
  String audioMemorySummary(String total, String budget, String available) {
    return '裝置總記憶體 $total；模型與任務最多使用 $budget；目前可用 $available。';
  }

  @override
  String get audioMemoryPolicy =>
      '只有來源可驗證、具備 Android 端側執行環境且峰值占用不超過總記憶體 60% 的模型才會開放下載。';

  @override
  String get speechToText => '語音轉文字';

  @override
  String get textToSpeech => '文字轉語音';

  @override
  String officialWeightSize(String size) {
    return '官方權重大小：$size';
  }

  @override
  String get audioRuntimeUnavailable =>
      '權重大小符合預算，但目前沒有經過驗證的 Android 量化執行環境，因此暫不開放下載。';

  @override
  String get audioModelExceedsLimit => '此官方模型超過本裝置的 60% 記憶體上限，已阻止下載與載入。';

  @override
  String get audioDurationUnavailable => '目前沒有安全的端側記憶體餘量，建議最大音訊時長：0 分鐘。';

  @override
  String audioDurationSuggestion(String duration) {
    return '依剩餘記憶體估算，建議單次音訊不超過 $duration。';
  }

  @override
  String get notCompatible => '目前裝置不相容';
}
