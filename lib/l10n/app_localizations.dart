import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
    Locale('zh'),
    Locale('zh', 'TW'),
  ];

  /// No description provided for @appName.
  ///
  /// In zh, this message translates to:
  /// **'司器'**
  String get appName;

  /// No description provided for @navChat.
  ///
  /// In zh, this message translates to:
  /// **'对话'**
  String get navChat;

  /// No description provided for @navLab.
  ///
  /// In zh, this message translates to:
  /// **'实验室'**
  String get navLab;

  /// No description provided for @navSettings.
  ///
  /// In zh, this message translates to:
  /// **'设置'**
  String get navSettings;

  /// No description provided for @onboardingWelcomeTitle.
  ///
  /// In zh, this message translates to:
  /// **'欢迎使用司器'**
  String get onboardingWelcomeTitle;

  /// No description provided for @welcomeBody.
  ///
  /// In zh, this message translates to:
  /// **'完全端侧优先的 AI 智能工作站。除模型下载和你主动发起的 API 请求外，数据不会离开设备。'**
  String get welcomeBody;

  /// No description provided for @licenseTitle.
  ///
  /// In zh, this message translates to:
  /// **'开源许可'**
  String get licenseTitle;

  /// No description provided for @licenseBody.
  ///
  /// In zh, this message translates to:
  /// **'本项目源代码采用 MIT License。你导入或下载的模型仍受各自许可证约束。'**
  String get licenseBody;

  /// No description provided for @privacyTitle.
  ///
  /// In zh, this message translates to:
  /// **'隐私说明'**
  String get privacyTitle;

  /// No description provided for @privacyBody.
  ///
  /// In zh, this message translates to:
  /// **'配置、密钥、模型、会话和文件均从本地存储。API 密钥使用系统加密存储保存，导出时自动脱敏。'**
  String get privacyBody;

  /// No description provided for @noAffiliation.
  ///
  /// In zh, this message translates to:
  /// **'本应用为个人独立开源项目，与 OpenAI、Anthropic、阿里云等公司无任何商业关联。项目代码按 MIT License 授权，第三方模型与服务遵循各自许可条款。'**
  String get noAffiliation;

  /// No description provided for @continueLabel.
  ///
  /// In zh, this message translates to:
  /// **'继续'**
  String get continueLabel;

  /// No description provided for @nicknameTitle.
  ///
  /// In zh, this message translates to:
  /// **'怎么称呼你？'**
  String get nicknameTitle;

  /// No description provided for @nicknameSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'昵称仅保存在当前设备，可用于系统提示词变量。'**
  String get nicknameSubtitle;

  /// No description provided for @nicknameHint.
  ///
  /// In zh, this message translates to:
  /// **'输入昵称'**
  String get nicknameHint;

  /// No description provided for @personalizationTitle.
  ///
  /// In zh, this message translates to:
  /// **'个性化'**
  String get personalizationTitle;

  /// No description provided for @colorMode.
  ///
  /// In zh, this message translates to:
  /// **'颜色模式'**
  String get colorMode;

  /// No description provided for @finish.
  ///
  /// In zh, this message translates to:
  /// **'开始使用'**
  String get finish;

  /// No description provided for @themeSystem.
  ///
  /// In zh, this message translates to:
  /// **'跟随系统'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In zh, this message translates to:
  /// **'浅色'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In zh, this message translates to:
  /// **'深色'**
  String get themeDark;

  /// No description provided for @defaultSystemPrompt.
  ///
  /// In zh, this message translates to:
  /// **'你是一位有帮助、注重隐私且表达清晰的 AI 助手。'**
  String get defaultSystemPrompt;

  /// No description provided for @conversations.
  ///
  /// In zh, this message translates to:
  /// **'会话历史'**
  String get conversations;

  /// No description provided for @newConversation.
  ///
  /// In zh, this message translates to:
  /// **'新建会话'**
  String get newConversation;

  /// No description provided for @newChatTitle.
  ///
  /// In zh, this message translates to:
  /// **'新会话'**
  String get newChatTitle;

  /// No description provided for @searchHistory.
  ///
  /// In zh, this message translates to:
  /// **'搜索标题或消息内容'**
  String get searchHistory;

  /// No description provided for @delete.
  ///
  /// In zh, this message translates to:
  /// **'删除'**
  String get delete;

  /// No description provided for @model.
  ///
  /// In zh, this message translates to:
  /// **'模型'**
  String get model;

  /// No description provided for @chooseModel.
  ///
  /// In zh, this message translates to:
  /// **'选择模型'**
  String get chooseModel;

  /// No description provided for @customApi.
  ///
  /// In zh, this message translates to:
  /// **'自定义 API Key'**
  String get customApi;

  /// No description provided for @localOffline.
  ///
  /// In zh, this message translates to:
  /// **'端侧离线'**
  String get localOffline;

  /// No description provided for @license.
  ///
  /// In zh, this message translates to:
  /// **'许可证：{license}'**
  String license(String license);

  /// No description provided for @notInstalled.
  ///
  /// In zh, this message translates to:
  /// **'未安装'**
  String get notInstalled;

  /// No description provided for @installed.
  ///
  /// In zh, this message translates to:
  /// **'已安装'**
  String get installed;

  /// No description provided for @modeChat.
  ///
  /// In zh, this message translates to:
  /// **'Chat'**
  String get modeChat;

  /// No description provided for @modeAgent.
  ///
  /// In zh, this message translates to:
  /// **'Agent'**
  String get modeAgent;

  /// No description provided for @modeHarness.
  ///
  /// In zh, this message translates to:
  /// **'Harness'**
  String get modeHarness;

  /// No description provided for @modeMcp.
  ///
  /// In zh, this message translates to:
  /// **'MCP'**
  String get modeMcp;

  /// No description provided for @attach.
  ///
  /// In zh, this message translates to:
  /// **'添加附件'**
  String get attach;

  /// No description provided for @pureTextNotice.
  ///
  /// In zh, this message translates to:
  /// **'该模型为纯文本模型，无法处理多模态数据'**
  String get pureTextNotice;

  /// No description provided for @messageHint.
  ///
  /// In zh, this message translates to:
  /// **'输入消息…'**
  String get messageHint;

  /// No description provided for @send.
  ///
  /// In zh, this message translates to:
  /// **'发送'**
  String get send;

  /// No description provided for @stop.
  ///
  /// In zh, this message translates to:
  /// **'停止'**
  String get stop;

  /// No description provided for @thinking.
  ///
  /// In zh, this message translates to:
  /// **'正在推理…'**
  String get thinking;

  /// No description provided for @slowTitle.
  ///
  /// In zh, this message translates to:
  /// **'任务仍在运行'**
  String get slowTitle;

  /// No description provided for @slowBody.
  ///
  /// In zh, this message translates to:
  /// **'推理已超过 3 秒。你可以继续等待，或立即终止本次任务。'**
  String get slowBody;

  /// No description provided for @forceStop.
  ///
  /// In zh, this message translates to:
  /// **'强行终止'**
  String get forceStop;

  /// No description provided for @errorApiNotTested.
  ///
  /// In zh, this message translates to:
  /// **'此 API 配置尚未通过连接测试，请先在设置中测试。'**
  String get errorApiNotTested;

  /// No description provided for @errorLocalNotDownloaded.
  ///
  /// In zh, this message translates to:
  /// **'本地模型不存在或文件已损坏，请在模型市场下载。'**
  String get errorLocalNotDownloaded;

  /// No description provided for @errorEngineUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'端侧推理引擎不可用。请确认原生引擎组件已安装。'**
  String get errorEngineUnavailable;

  /// No description provided for @errorLocalModelLoad.
  ///
  /// In zh, this message translates to:
  /// **'模型已下载并通过校验，但加载失败。应用已自动降低上下文并尝试 CPU 回退，请在“工作日志”中查看详情。'**
  String get errorLocalModelLoad;

  /// No description provided for @errorLocalPrompt.
  ///
  /// In zh, this message translates to:
  /// **'模型已加载，但当前会话无法套用模型模板。应用已自动裁剪旧消息，请在“工作日志”中查看详情。'**
  String get errorLocalPrompt;

  /// No description provided for @errorLocalGeneration.
  ///
  /// In zh, this message translates to:
  /// **'模型已加载，但生成过程中断。请释放部分内存后重试，详情已写入“工作日志”。'**
  String get errorLocalGeneration;

  /// No description provided for @errorLocalEmptyOutput.
  ///
  /// In zh, this message translates to:
  /// **'模型完成运行但没有返回有效文本。请新建会话后重试，详情已写入“工作日志”。'**
  String get errorLocalEmptyOutput;

  /// No description provided for @errorMemory.
  ///
  /// In zh, this message translates to:
  /// **'可用内存不足以安全加载此模型。'**
  String get errorMemory;

  /// No description provided for @errorNetwork.
  ///
  /// In zh, this message translates to:
  /// **'网络不可用。你可以切换到已安装的端侧模型。'**
  String get errorNetwork;

  /// No description provided for @errorRequest.
  ///
  /// In zh, this message translates to:
  /// **'请求失败，请检查配置后重试。'**
  String get errorRequest;

  /// No description provided for @agentWarningTitle.
  ///
  /// In zh, this message translates to:
  /// **'允许修改本地文件'**
  String get agentWarningTitle;

  /// No description provided for @agentWarningBody.
  ///
  /// In zh, this message translates to:
  /// **'自主编码代理可按你的指令修改本地文件并运行命令。启用前请备份重要数据，并核对每项高风险操作。'**
  String get agentWarningBody;

  /// No description provided for @enable.
  ///
  /// In zh, this message translates to:
  /// **'确认启用'**
  String get enable;

  /// No description provided for @cancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get cancel;

  /// No description provided for @noMessages.
  ///
  /// In zh, this message translates to:
  /// **'从一条消息开始，或切换模型与工作模式。'**
  String get noMessages;

  /// No description provided for @labSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'端侧模型、工具协议与开发工作流'**
  String get labSubtitle;

  /// No description provided for @modelMarket.
  ///
  /// In zh, this message translates to:
  /// **'模型市场'**
  String get modelMarket;

  /// No description provided for @modelMarketDescription.
  ///
  /// In zh, this message translates to:
  /// **'下载、续传并管理许可清晰的端侧模型'**
  String get modelMarketDescription;

  /// No description provided for @mcpConfiguration.
  ///
  /// In zh, this message translates to:
  /// **'MCP 配置'**
  String get mcpConfiguration;

  /// No description provided for @mcpDescription.
  ///
  /// In zh, this message translates to:
  /// **'挂载本地文件、数据库或 Webhook 工具'**
  String get mcpDescription;

  /// No description provided for @harnessDashboard.
  ///
  /// In zh, this message translates to:
  /// **'Harness 仪表盘'**
  String get harnessDashboard;

  /// No description provided for @harnessDescription.
  ///
  /// In zh, this message translates to:
  /// **'语言检测、静态扫描和测试用例建议'**
  String get harnessDescription;

  /// No description provided for @agentToolbox.
  ///
  /// In zh, this message translates to:
  /// **'Agent 工具箱'**
  String get agentToolbox;

  /// No description provided for @agentToolboxDescription.
  ///
  /// In zh, this message translates to:
  /// **'在二次确认保护下运行完整 Shell 指令'**
  String get agentToolboxDescription;

  /// No description provided for @codeReview.
  ///
  /// In zh, this message translates to:
  /// **'代码审查'**
  String get codeReview;

  /// No description provided for @codeReviewDescription.
  ///
  /// In zh, this message translates to:
  /// **'从本地文件生成结构化审查报告'**
  String get codeReviewDescription;

  /// No description provided for @githubImport.
  ///
  /// In zh, this message translates to:
  /// **'GitHub 仓库导入'**
  String get githubImport;

  /// No description provided for @githubImportDescription.
  ///
  /// In zh, this message translates to:
  /// **'使用令牌导入仓库压缩包到本地目录'**
  String get githubImportDescription;

  /// No description provided for @download.
  ///
  /// In zh, this message translates to:
  /// **'下载'**
  String get download;

  /// No description provided for @pause.
  ///
  /// In zh, this message translates to:
  /// **'暂停'**
  String get pause;

  /// No description provided for @resume.
  ///
  /// In zh, this message translates to:
  /// **'继续'**
  String get resume;

  /// No description provided for @unavailable.
  ///
  /// In zh, this message translates to:
  /// **'暂无已验证下载源'**
  String get unavailable;

  /// No description provided for @modelSize.
  ///
  /// In zh, this message translates to:
  /// **'约 {size}'**
  String modelSize(String size);

  /// No description provided for @memoryRequirement.
  ///
  /// In zh, this message translates to:
  /// **'建议内存 {memory} GB'**
  String memoryRequirement(int memory);

  /// No description provided for @downloadStarted.
  ///
  /// In zh, this message translates to:
  /// **'模型下载已开始'**
  String get downloadStarted;

  /// No description provided for @downloadProgress.
  ///
  /// In zh, this message translates to:
  /// **'已下载 {percent}%'**
  String downloadProgress(int percent);

  /// No description provided for @modelLicenseNotice.
  ///
  /// In zh, this message translates to:
  /// **'下载即表示你同意模型卡片所列许可证；模型文件仅保存在本机。'**
  String get modelLicenseNotice;

  /// No description provided for @mcpTitle.
  ///
  /// In zh, this message translates to:
  /// **'MCP 服务器'**
  String get mcpTitle;

  /// No description provided for @addServer.
  ///
  /// In zh, this message translates to:
  /// **'添加服务器'**
  String get addServer;

  /// No description provided for @serverName.
  ///
  /// In zh, this message translates to:
  /// **'名称'**
  String get serverName;

  /// No description provided for @transport.
  ///
  /// In zh, this message translates to:
  /// **'传输方式'**
  String get transport;

  /// No description provided for @commandOrUrl.
  ///
  /// In zh, this message translates to:
  /// **'命令或 URL'**
  String get commandOrUrl;

  /// No description provided for @configurationJson.
  ///
  /// In zh, this message translates to:
  /// **'配置 JSON'**
  String get configurationJson;

  /// No description provided for @enabledStatus.
  ///
  /// In zh, this message translates to:
  /// **'启用'**
  String get enabledStatus;

  /// No description provided for @save.
  ///
  /// In zh, this message translates to:
  /// **'保存'**
  String get save;

  /// No description provided for @localFilesTemplate.
  ///
  /// In zh, this message translates to:
  /// **'本地文件模板'**
  String get localFilesTemplate;

  /// No description provided for @databaseTemplate.
  ///
  /// In zh, this message translates to:
  /// **'数据库模板'**
  String get databaseTemplate;

  /// No description provided for @webhookTemplate.
  ///
  /// In zh, this message translates to:
  /// **'Webhook 模板'**
  String get webhookTemplate;

  /// No description provided for @noServers.
  ///
  /// In zh, this message translates to:
  /// **'尚未配置 MCP 服务器'**
  String get noServers;

  /// No description provided for @selectFile.
  ///
  /// In zh, this message translates to:
  /// **'选择文件'**
  String get selectFile;

  /// No description provided for @analyze.
  ///
  /// In zh, this message translates to:
  /// **'开始分析'**
  String get analyze;

  /// No description provided for @languageDetected.
  ///
  /// In zh, this message translates to:
  /// **'检测语言：{language}'**
  String languageDetected(String language);

  /// No description provided for @reviewResult.
  ///
  /// In zh, this message translates to:
  /// **'审查结果'**
  String get reviewResult;

  /// No description provided for @noIssues.
  ///
  /// In zh, this message translates to:
  /// **'未发现明显的结构性问题。仍建议运行项目自带的分析器与测试。'**
  String get noIssues;

  /// No description provided for @selectCodeFirst.
  ///
  /// In zh, this message translates to:
  /// **'请先选择一个代码文件'**
  String get selectCodeFirst;

  /// No description provided for @shellTitle.
  ///
  /// In zh, this message translates to:
  /// **'全指令 Shell'**
  String get shellTitle;

  /// No description provided for @commandHint.
  ///
  /// In zh, this message translates to:
  /// **'输入 Shell 命令'**
  String get commandHint;

  /// No description provided for @run.
  ///
  /// In zh, this message translates to:
  /// **'运行'**
  String get run;

  /// No description provided for @output.
  ///
  /// In zh, this message translates to:
  /// **'输出'**
  String get output;

  /// No description provided for @exitCode.
  ///
  /// In zh, this message translates to:
  /// **'退出码：{code}'**
  String exitCode(int code);

  /// No description provided for @dangerousTitle.
  ///
  /// In zh, this message translates to:
  /// **'检测到高危命令'**
  String get dangerousTitle;

  /// No description provided for @dangerousBody.
  ///
  /// In zh, this message translates to:
  /// **'此命令可能删除数据、格式化存储或重启设备。请逐字确认后再运行。'**
  String get dangerousBody;

  /// No description provided for @confirmRun.
  ///
  /// In zh, this message translates to:
  /// **'仍然运行'**
  String get confirmRun;

  /// No description provided for @history.
  ///
  /// In zh, this message translates to:
  /// **'历史记录'**
  String get history;

  /// No description provided for @repoOwner.
  ///
  /// In zh, this message translates to:
  /// **'仓库所有者'**
  String get repoOwner;

  /// No description provided for @repoName.
  ///
  /// In zh, this message translates to:
  /// **'仓库名称'**
  String get repoName;

  /// No description provided for @destination.
  ///
  /// In zh, this message translates to:
  /// **'本地目标目录'**
  String get destination;

  /// No description provided for @tokenOptional.
  ///
  /// In zh, this message translates to:
  /// **'访问令牌（私有仓库必填）'**
  String get tokenOptional;

  /// No description provided for @importAction.
  ///
  /// In zh, this message translates to:
  /// **'导入'**
  String get importAction;

  /// No description provided for @importSuccess.
  ///
  /// In zh, this message translates to:
  /// **'导入完成'**
  String get importSuccess;

  /// No description provided for @chooseFolder.
  ///
  /// In zh, this message translates to:
  /// **'选择目录'**
  String get chooseFolder;

  /// No description provided for @settingsSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'本地偏好、API 投射与数据管理'**
  String get settingsSubtitle;

  /// No description provided for @conversationReasoning.
  ///
  /// In zh, this message translates to:
  /// **'对话与推理参数'**
  String get conversationReasoning;

  /// No description provided for @contextWindow.
  ///
  /// In zh, this message translates to:
  /// **'上下文窗口'**
  String get contextWindow;

  /// No description provided for @temperature.
  ///
  /// In zh, this message translates to:
  /// **'Temperature'**
  String get temperature;

  /// No description provided for @topP.
  ///
  /// In zh, this message translates to:
  /// **'Top-P'**
  String get topP;

  /// No description provided for @maxTokens.
  ///
  /// In zh, this message translates to:
  /// **'最大输出 Tokens'**
  String get maxTokens;

  /// No description provided for @systemPrompt.
  ///
  /// In zh, this message translates to:
  /// **'System Prompt'**
  String get systemPrompt;

  /// No description provided for @variablesHint.
  ///
  /// In zh, this message translates to:
  /// **'支持 \'{user_name}\' 与 \'{current_time}\' 变量'**
  String get variablesHint;

  /// No description provided for @appearance.
  ///
  /// In zh, this message translates to:
  /// **'界面与外观'**
  String get appearance;

  /// No description provided for @fontScale.
  ///
  /// In zh, this message translates to:
  /// **'全局字体缩放'**
  String get fontScale;

  /// No description provided for @messageSpacing.
  ///
  /// In zh, this message translates to:
  /// **'消息间距'**
  String get messageSpacing;

  /// No description provided for @timestampFormat.
  ///
  /// In zh, this message translates to:
  /// **'时间戳格式'**
  String get timestampFormat;

  /// No description provided for @timeRelative.
  ///
  /// In zh, this message translates to:
  /// **'相对时间'**
  String get timeRelative;

  /// No description provided for @time24.
  ///
  /// In zh, this message translates to:
  /// **'24 小时制'**
  String get time24;

  /// No description provided for @time12.
  ///
  /// In zh, this message translates to:
  /// **'12 小时制'**
  String get time12;

  /// No description provided for @language.
  ///
  /// In zh, this message translates to:
  /// **'语言'**
  String get language;

  /// No description provided for @dataStorage.
  ///
  /// In zh, this message translates to:
  /// **'数据与存储'**
  String get dataStorage;

  /// No description provided for @saveInterval.
  ///
  /// In zh, this message translates to:
  /// **'自动保存间隔'**
  String get saveInterval;

  /// No description provided for @saveRealtime.
  ///
  /// In zh, this message translates to:
  /// **'实时'**
  String get saveRealtime;

  /// No description provided for @saveFiveMinutes.
  ///
  /// In zh, this message translates to:
  /// **'5 分钟'**
  String get saveFiveMinutes;

  /// No description provided for @saveManual.
  ///
  /// In zh, this message translates to:
  /// **'手动'**
  String get saveManual;

  /// No description provided for @modelStorage.
  ///
  /// In zh, this message translates to:
  /// **'模型存储路径'**
  String get modelStorage;

  /// No description provided for @defaultPath.
  ///
  /// In zh, this message translates to:
  /// **'应用默认目录'**
  String get defaultPath;

  /// No description provided for @exportData.
  ///
  /// In zh, this message translates to:
  /// **'导出全部数据'**
  String get exportData;

  /// No description provided for @importData.
  ///
  /// In zh, this message translates to:
  /// **'导入恢复'**
  String get importData;

  /// No description provided for @exportConfig.
  ///
  /// In zh, this message translates to:
  /// **'导出脱敏配置'**
  String get exportConfig;

  /// No description provided for @share.
  ///
  /// In zh, this message translates to:
  /// **'分享'**
  String get share;

  /// No description provided for @exportReady.
  ///
  /// In zh, this message translates to:
  /// **'导出文件已生成'**
  String get exportReady;

  /// No description provided for @importFailed.
  ///
  /// In zh, this message translates to:
  /// **'导入失败：{reason}'**
  String importFailed(String reason);

  /// No description provided for @apiProjection.
  ///
  /// In zh, this message translates to:
  /// **'自定义 API 投射'**
  String get apiProjection;

  /// No description provided for @manageProviders.
  ///
  /// In zh, this message translates to:
  /// **'管理厂商、兼容格式与自定义 Headers'**
  String get manageProviders;

  /// No description provided for @quotaStatistics.
  ///
  /// In zh, this message translates to:
  /// **'额度统计'**
  String get quotaStatistics;

  /// No description provided for @inputTokens.
  ///
  /// In zh, this message translates to:
  /// **'输入 Tokens'**
  String get inputTokens;

  /// No description provided for @outputTokens.
  ///
  /// In zh, this message translates to:
  /// **'输出 Tokens'**
  String get outputTokens;

  /// No description provided for @estimatedCost.
  ///
  /// In zh, this message translates to:
  /// **'估算费用'**
  String get estimatedCost;

  /// No description provided for @shellSettings.
  ///
  /// In zh, this message translates to:
  /// **'Shell 设置'**
  String get shellSettings;

  /// No description provided for @historyLength.
  ///
  /// In zh, this message translates to:
  /// **'命令历史长度'**
  String get historyLength;

  /// No description provided for @defaultShell.
  ///
  /// In zh, this message translates to:
  /// **'默认 Shell 环境'**
  String get defaultShell;

  /// No description provided for @dangerousConfirmation.
  ///
  /// In zh, this message translates to:
  /// **'高危命令二次确认'**
  String get dangerousConfirmation;

  /// No description provided for @aboutLegal.
  ///
  /// In zh, this message translates to:
  /// **'关于与合规'**
  String get aboutLegal;

  /// No description provided for @versionLabel.
  ///
  /// In zh, this message translates to:
  /// **'版本 1.0.0'**
  String get versionLabel;

  /// No description provided for @apiProfiles.
  ///
  /// In zh, this message translates to:
  /// **'API 配置'**
  String get apiProfiles;

  /// No description provided for @addProfile.
  ///
  /// In zh, this message translates to:
  /// **'添加配置'**
  String get addProfile;

  /// No description provided for @noProfiles.
  ///
  /// In zh, this message translates to:
  /// **'尚未添加自定义 API 配置'**
  String get noProfiles;

  /// No description provided for @providerTemplate.
  ///
  /// In zh, this message translates to:
  /// **'厂商模板'**
  String get providerTemplate;

  /// No description provided for @customName.
  ///
  /// In zh, this message translates to:
  /// **'自定义名称'**
  String get customName;

  /// No description provided for @baseUrl.
  ///
  /// In zh, this message translates to:
  /// **'Base URL'**
  String get baseUrl;

  /// No description provided for @modelId.
  ///
  /// In zh, this message translates to:
  /// **'模型 ID'**
  String get modelId;

  /// No description provided for @apiKey.
  ///
  /// In zh, this message translates to:
  /// **'API Key'**
  String get apiKey;

  /// No description provided for @apiFormat.
  ///
  /// In zh, this message translates to:
  /// **'接口格式'**
  String get apiFormat;

  /// No description provided for @multimodal.
  ///
  /// In zh, this message translates to:
  /// **'支持多模态'**
  String get multimodal;

  /// No description provided for @customHeaders.
  ///
  /// In zh, this message translates to:
  /// **'自定义 Headers'**
  String get customHeaders;

  /// No description provided for @headersHint.
  ///
  /// In zh, this message translates to:
  /// **'例如：\'{\"X-Custom\":\"value\"}\''**
  String get headersHint;

  /// No description provided for @testConnection.
  ///
  /// In zh, this message translates to:
  /// **'测试连接'**
  String get testConnection;

  /// No description provided for @testing.
  ///
  /// In zh, this message translates to:
  /// **'测试中…'**
  String get testing;

  /// No description provided for @testSuccess.
  ///
  /// In zh, this message translates to:
  /// **'连接测试成功'**
  String get testSuccess;

  /// No description provided for @testFailed.
  ///
  /// In zh, this message translates to:
  /// **'连接测试失败：{reason}'**
  String testFailed(String reason);

  /// No description provided for @neverTested.
  ///
  /// In zh, this message translates to:
  /// **'尚未测试'**
  String get neverTested;

  /// No description provided for @lastTested.
  ///
  /// In zh, this message translates to:
  /// **'上次测试：{time}'**
  String lastTested(String time);

  /// No description provided for @deleteProfile.
  ///
  /// In zh, this message translates to:
  /// **'删除此配置'**
  String get deleteProfile;

  /// No description provided for @invalidJson.
  ///
  /// In zh, this message translates to:
  /// **'Headers 必须是字符串键值组成的 JSON 对象'**
  String get invalidJson;

  /// No description provided for @requiredField.
  ///
  /// In zh, this message translates to:
  /// **'请填写所有必填项'**
  String get requiredField;

  /// No description provided for @done.
  ///
  /// In zh, this message translates to:
  /// **'完成'**
  String get done;

  /// No description provided for @close.
  ///
  /// In zh, this message translates to:
  /// **'关闭'**
  String get close;

  /// No description provided for @loading.
  ///
  /// In zh, this message translates to:
  /// **'加载中…'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In zh, this message translates to:
  /// **'出现错误'**
  String get error;

  /// No description provided for @notificationDownloadTitle.
  ///
  /// In zh, this message translates to:
  /// **'正在下载 {model}'**
  String notificationDownloadTitle(String model);

  /// No description provided for @notificationDownloadBody.
  ///
  /// In zh, this message translates to:
  /// **'下载任务在后台继续运行'**
  String get notificationDownloadBody;

  /// No description provided for @fileReadFailed.
  ///
  /// In zh, this message translates to:
  /// **'无法读取文件：{reason}'**
  String fileReadFailed(String reason);

  /// No description provided for @justNow.
  ///
  /// In zh, this message translates to:
  /// **'刚刚'**
  String get justNow;

  /// No description provided for @minutesAgo.
  ///
  /// In zh, this message translates to:
  /// **'{count} 分钟前'**
  String minutesAgo(int count);

  /// No description provided for @hoursAgo.
  ///
  /// In zh, this message translates to:
  /// **'{count} 小时前'**
  String hoursAgo(int count);

  /// No description provided for @daysAgo.
  ///
  /// In zh, this message translates to:
  /// **'{count} 天前'**
  String daysAgo(int count);

  /// No description provided for @reviewTodos.
  ///
  /// In zh, this message translates to:
  /// **'发现 {count} 个 TODO/FIXME 待办标记。'**
  String reviewTodos(int count);

  /// No description provided for @reviewLongLines.
  ///
  /// In zh, this message translates to:
  /// **'发现 {count} 行超过 120 个字符，建议拆分。'**
  String reviewLongLines(int count);

  /// No description provided for @reviewSecrets.
  ///
  /// In zh, this message translates to:
  /// **'发现 {count} 处疑似明文密钥，请立即核查。'**
  String reviewSecrets(int count);

  /// No description provided for @reviewShellCalls.
  ///
  /// In zh, this message translates to:
  /// **'发现 {count} 处进程或 Shell 调用，请校验输入边界。'**
  String reviewShellCalls(int count);

  /// No description provided for @generatedTestIdeas.
  ///
  /// In zh, this message translates to:
  /// **'单元测试建议'**
  String get generatedTestIdeas;

  /// No description provided for @testIdeasBody.
  ///
  /// In zh, this message translates to:
  /// **'覆盖正常输入、空输入、边界值、异常路径与资源释放；对文件和进程操作使用临时目录或替身实现。'**
  String get testIdeasBody;

  /// No description provided for @languageZhHans.
  ///
  /// In zh, this message translates to:
  /// **'简体中文'**
  String get languageZhHans;

  /// No description provided for @languageZhHant.
  ///
  /// In zh, this message translates to:
  /// **'繁體中文'**
  String get languageZhHant;

  /// No description provided for @languageEnglish.
  ///
  /// In zh, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageJapanese.
  ///
  /// In zh, this message translates to:
  /// **'日本語'**
  String get languageJapanese;

  /// No description provided for @protocolOpenAi.
  ///
  /// In zh, this message translates to:
  /// **'OpenAI 兼容'**
  String get protocolOpenAi;

  /// No description provided for @protocolAnthropic.
  ///
  /// In zh, this message translates to:
  /// **'Anthropic 兼容'**
  String get protocolAnthropic;

  /// No description provided for @transportStdio.
  ///
  /// In zh, this message translates to:
  /// **'标准输入输出'**
  String get transportStdio;

  /// No description provided for @transportHttp.
  ///
  /// In zh, this message translates to:
  /// **'HTTP'**
  String get transportHttp;

  /// No description provided for @transportSse.
  ///
  /// In zh, this message translates to:
  /// **'SSE'**
  String get transportSse;

  /// No description provided for @shellSystemName.
  ///
  /// In zh, this message translates to:
  /// **'系统 sh'**
  String get shellSystemName;

  /// No description provided for @shellTermuxName.
  ///
  /// In zh, this message translates to:
  /// **'Termux'**
  String get shellTermuxName;

  /// No description provided for @shellShizukuName.
  ///
  /// In zh, this message translates to:
  /// **'Shizuku'**
  String get shellShizukuName;

  /// No description provided for @notificationChannelDownloads.
  ///
  /// In zh, this message translates to:
  /// **'模型下载'**
  String get notificationChannelDownloads;

  /// No description provided for @notificationChannelDownloadsDescription.
  ///
  /// In zh, this message translates to:
  /// **'端侧模型后台下载进度'**
  String get notificationChannelDownloadsDescription;

  /// No description provided for @githubOAuth.
  ///
  /// In zh, this message translates to:
  /// **'GitHub OAuth 登录'**
  String get githubOAuth;

  /// No description provided for @oauthClientId.
  ///
  /// In zh, this message translates to:
  /// **'OAuth App Client ID'**
  String get oauthClientId;

  /// No description provided for @oauthClientIdRequired.
  ///
  /// In zh, this message translates to:
  /// **'请先填写 GitHub OAuth App Client ID'**
  String get oauthClientIdRequired;

  /// No description provided for @oauthInstruction.
  ///
  /// In zh, this message translates to:
  /// **'浏览器已打开。请输入下方设备代码并授权仓库访问：'**
  String get oauthInstruction;

  /// No description provided for @oauthCodeCopied.
  ///
  /// In zh, this message translates to:
  /// **'设备代码已复制到剪贴板'**
  String get oauthCodeCopied;

  /// No description provided for @authorizationComplete.
  ///
  /// In zh, this message translates to:
  /// **'我已完成授权'**
  String get authorizationComplete;

  /// No description provided for @oauthPendingOrExpired.
  ///
  /// In zh, this message translates to:
  /// **'授权尚未完成或设备代码已过期'**
  String get oauthPendingOrExpired;

  /// No description provided for @oauthSuccess.
  ///
  /// In zh, this message translates to:
  /// **'GitHub 授权成功'**
  String get oauthSuccess;

  /// No description provided for @oauthOpenFailed.
  ///
  /// In zh, this message translates to:
  /// **'无法打开系统浏览器'**
  String get oauthOpenFailed;

  /// No description provided for @chatWorkspaceSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'对话、模型与本地工具工作台'**
  String get chatWorkspaceSubtitle;

  /// No description provided for @chatWelcomeTitle.
  ///
  /// In zh, this message translates to:
  /// **'今天想完成什么？'**
  String get chatWelcomeTitle;

  /// No description provided for @noWorkspace.
  ///
  /// In zh, this message translates to:
  /// **'未选择工作区'**
  String get noWorkspace;

  /// No description provided for @noWorkspaceSelected.
  ///
  /// In zh, this message translates to:
  /// **'尚未选择本地工作区'**
  String get noWorkspaceSelected;

  /// No description provided for @contextValue.
  ///
  /// In zh, this message translates to:
  /// **'上下文 {value}K'**
  String contextValue(int value);

  /// No description provided for @streamingOn.
  ///
  /// In zh, this message translates to:
  /// **'流式开启'**
  String get streamingOn;

  /// No description provided for @streamingOff.
  ///
  /// In zh, this message translates to:
  /// **'流式关闭'**
  String get streamingOff;

  /// No description provided for @multimodalReady.
  ///
  /// In zh, this message translates to:
  /// **'多模态可用'**
  String get multimodalReady;

  /// No description provided for @textOnly.
  ///
  /// In zh, this message translates to:
  /// **'仅文本'**
  String get textOnly;

  /// No description provided for @noConversations.
  ///
  /// In zh, this message translates to:
  /// **'暂无会话'**
  String get noConversations;

  /// No description provided for @noConversationsBody.
  ///
  /// In zh, this message translates to:
  /// **'新建会话后，所有历史记录都只保存在本机。'**
  String get noConversationsBody;

  /// No description provided for @suggestionExplain.
  ///
  /// In zh, this message translates to:
  /// **'解释代码'**
  String get suggestionExplain;

  /// No description provided for @suggestionExplainPrompt.
  ///
  /// In zh, this message translates to:
  /// **'请解释这段代码的逻辑、边界条件与潜在风险。'**
  String get suggestionExplainPrompt;

  /// No description provided for @suggestionReview.
  ///
  /// In zh, this message translates to:
  /// **'审查项目'**
  String get suggestionReview;

  /// No description provided for @suggestionReviewPrompt.
  ///
  /// In zh, this message translates to:
  /// **'请审查当前工作区，优先检查正确性、安全性和可维护性。'**
  String get suggestionReviewPrompt;

  /// No description provided for @suggestionBuild.
  ///
  /// In zh, this message translates to:
  /// **'构建功能'**
  String get suggestionBuild;

  /// No description provided for @suggestionBuildPrompt.
  ///
  /// In zh, this message translates to:
  /// **'请先分析当前工作区并制定计划，然后实现我接下来描述的功能。'**
  String get suggestionBuildPrompt;

  /// No description provided for @roleYou.
  ///
  /// In zh, this message translates to:
  /// **'你'**
  String get roleYou;

  /// No description provided for @streamingResponse.
  ///
  /// In zh, this message translates to:
  /// **'正在流式生成'**
  String get streamingResponse;

  /// No description provided for @errorWorkspaceRequired.
  ///
  /// In zh, this message translates to:
  /// **'Agent 模式需要本地工作区，请先在设置中选择目录。'**
  String get errorWorkspaceRequired;

  /// No description provided for @agentActionPlan.
  ///
  /// In zh, this message translates to:
  /// **'Agent 动作计划'**
  String get agentActionPlan;

  /// No description provided for @actionCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 项动作'**
  String actionCount(int count);

  /// No description provided for @rejectActions.
  ///
  /// In zh, this message translates to:
  /// **'拒绝'**
  String get rejectActions;

  /// No description provided for @approveReadOnly.
  ///
  /// In zh, this message translates to:
  /// **'批准只读'**
  String get approveReadOnly;

  /// No description provided for @approveAll.
  ///
  /// In zh, this message translates to:
  /// **'批准全部'**
  String get approveAll;

  /// No description provided for @confirmAgentActionsTitle.
  ///
  /// In zh, this message translates to:
  /// **'确认执行工作区变更'**
  String get confirmAgentActionsTitle;

  /// No description provided for @confirmAgentActionsBody.
  ///
  /// In zh, this message translates to:
  /// **'下列动作可能写入本地文件或运行命令。请逐项核对，确认已备份重要数据。'**
  String get confirmAgentActionsBody;

  /// No description provided for @confirmExecute.
  ///
  /// In zh, this message translates to:
  /// **'确认执行'**
  String get confirmExecute;

  /// No description provided for @executionOutput.
  ///
  /// In zh, this message translates to:
  /// **'执行输出'**
  String get executionOutput;

  /// No description provided for @actionListFiles.
  ///
  /// In zh, this message translates to:
  /// **'列出文件'**
  String get actionListFiles;

  /// No description provided for @actionReadFile.
  ///
  /// In zh, this message translates to:
  /// **'读取文件'**
  String get actionReadFile;

  /// No description provided for @actionWriteFile.
  ///
  /// In zh, this message translates to:
  /// **'写入文件'**
  String get actionWriteFile;

  /// No description provided for @actionCreateDirectory.
  ///
  /// In zh, this message translates to:
  /// **'创建目录'**
  String get actionCreateDirectory;

  /// No description provided for @actionRunCommand.
  ///
  /// In zh, this message translates to:
  /// **'运行命令'**
  String get actionRunCommand;

  /// No description provided for @labOverview.
  ///
  /// In zh, this message translates to:
  /// **'工作站概览'**
  String get labOverview;

  /// No description provided for @notConfigured.
  ///
  /// In zh, this message translates to:
  /// **'未配置'**
  String get notConfigured;

  /// No description provided for @localReady.
  ///
  /// In zh, this message translates to:
  /// **'本地就绪'**
  String get localReady;

  /// No description provided for @tokensUsed.
  ///
  /// In zh, this message translates to:
  /// **'已用 {count} Tokens'**
  String tokensUsed(int count);

  /// No description provided for @mcpServersMetric.
  ///
  /// In zh, this message translates to:
  /// **'MCP 服务器'**
  String get mcpServersMetric;

  /// No description provided for @localModelsMetric.
  ///
  /// In zh, this message translates to:
  /// **'端侧模型'**
  String get localModelsMetric;

  /// No description provided for @availableToDownload.
  ///
  /// In zh, this message translates to:
  /// **'可下载型号'**
  String get availableToDownload;

  /// No description provided for @workbenchTools.
  ///
  /// In zh, this message translates to:
  /// **'工作台工具'**
  String get workbenchTools;

  /// No description provided for @workbenchToolsDescription.
  ///
  /// In zh, this message translates to:
  /// **'模型、协议、审查、Shell 与仓库导入'**
  String get workbenchToolsDescription;

  /// No description provided for @workspaceScan.
  ///
  /// In zh, this message translates to:
  /// **'工作区静态扫描'**
  String get workspaceScan;

  /// No description provided for @selectWorkspaceFirst.
  ///
  /// In zh, this message translates to:
  /// **'请先选择一个本地工作区'**
  String get selectWorkspaceFirst;

  /// No description provided for @scanning.
  ///
  /// In zh, this message translates to:
  /// **'扫描中…'**
  String get scanning;

  /// No description provided for @analyzeWorkspace.
  ///
  /// In zh, this message translates to:
  /// **'分析工作区'**
  String get analyzeWorkspace;

  /// No description provided for @scanFailed.
  ///
  /// In zh, this message translates to:
  /// **'扫描失败：{reason}'**
  String scanFailed(String reason);

  /// No description provided for @scannedFiles.
  ///
  /// In zh, this message translates to:
  /// **'已扫描文件'**
  String get scannedFiles;

  /// No description provided for @errorSeverity.
  ///
  /// In zh, this message translates to:
  /// **'错误'**
  String get errorSeverity;

  /// No description provided for @warningSeverity.
  ///
  /// In zh, this message translates to:
  /// **'警告'**
  String get warningSeverity;

  /// No description provided for @infoSeverity.
  ///
  /// In zh, this message translates to:
  /// **'提示'**
  String get infoSeverity;

  /// No description provided for @testDrafts.
  ///
  /// In zh, this message translates to:
  /// **'测试草稿'**
  String get testDrafts;

  /// No description provided for @issueCount.
  ///
  /// In zh, this message translates to:
  /// **'共 {count} 项结果'**
  String issueCount(int count);

  /// No description provided for @allSeverities.
  ///
  /// In zh, this message translates to:
  /// **'全部'**
  String get allSeverities;

  /// No description provided for @noIssuesTitle.
  ///
  /// In zh, this message translates to:
  /// **'未发现规则问题'**
  String get noIssuesTitle;

  /// No description provided for @testDraftDescription.
  ///
  /// In zh, this message translates to:
  /// **'根据源文件语言生成的最小测试骨架，请核对后再加入项目。'**
  String get testDraftDescription;

  /// No description provided for @copy.
  ///
  /// In zh, this message translates to:
  /// **'复制'**
  String get copy;

  /// No description provided for @copied.
  ///
  /// In zh, this message translates to:
  /// **'已复制到剪贴板'**
  String get copied;

  /// No description provided for @issueLongLine.
  ///
  /// In zh, this message translates to:
  /// **'代码行过长，建议拆分以提高可读性'**
  String get issueLongLine;

  /// No description provided for @issueTodo.
  ///
  /// In zh, this message translates to:
  /// **'存在待办或临时标记'**
  String get issueTodo;

  /// No description provided for @issueHardcodedSecret.
  ///
  /// In zh, this message translates to:
  /// **'疑似硬编码密钥或凭据'**
  String get issueHardcodedSecret;

  /// No description provided for @issueDynamicExecution.
  ///
  /// In zh, this message translates to:
  /// **'动态执行可能运行不可信输入'**
  String get issueDynamicExecution;

  /// No description provided for @issueShellInjection.
  ///
  /// In zh, this message translates to:
  /// **'Shell 调用存在输入注入风险'**
  String get issueShellInjection;

  /// No description provided for @issueSqlInterpolation.
  ///
  /// In zh, this message translates to:
  /// **'SQL 字符串插值可能导致注入'**
  String get issueSqlInterpolation;

  /// No description provided for @issueEmptyCatch.
  ///
  /// In zh, this message translates to:
  /// **'空异常处理会掩盖错误'**
  String get issueEmptyCatch;

  /// No description provided for @issueDebugOutput.
  ///
  /// In zh, this message translates to:
  /// **'生产代码中存在调试输出'**
  String get issueDebugOutput;

  /// No description provided for @issueCleartextUrl.
  ///
  /// In zh, this message translates to:
  /// **'非本机地址使用了明文 HTTP'**
  String get issueCleartextUrl;

  /// No description provided for @issueDestructiveCommand.
  ///
  /// In zh, this message translates to:
  /// **'发现潜在破坏性命令'**
  String get issueDestructiveCommand;

  /// No description provided for @issueMissingDispose.
  ///
  /// In zh, this message translates to:
  /// **'控制器可能未在生命周期结束时释放'**
  String get issueMissingDispose;

  /// No description provided for @issueInnerHtml.
  ///
  /// In zh, this message translates to:
  /// **'直接写入 innerHTML 可能导致脚本注入'**
  String get issueInnerHtml;

  /// No description provided for @noServersBody.
  ///
  /// In zh, this message translates to:
  /// **'添加本地或 HTTP 服务器后，可测试握手并查看可用工具。'**
  String get noServersBody;

  /// No description provided for @disabledStatus.
  ///
  /// In zh, this message translates to:
  /// **'已停用'**
  String get disabledStatus;

  /// No description provided for @connectionSuccess.
  ///
  /// In zh, this message translates to:
  /// **'连接成功'**
  String get connectionSuccess;

  /// No description provided for @connectionFailed.
  ///
  /// In zh, this message translates to:
  /// **'连接失败'**
  String get connectionFailed;

  /// No description provided for @latencyMs.
  ///
  /// In zh, this message translates to:
  /// **'{value} ms'**
  String latencyMs(int value);

  /// No description provided for @toolsDiscovered.
  ///
  /// In zh, this message translates to:
  /// **'发现 {count} 个工具'**
  String toolsDiscovered(int count);

  /// No description provided for @noTools.
  ///
  /// In zh, this message translates to:
  /// **'服务器未返回工具。'**
  String get noTools;

  /// No description provided for @testServer.
  ///
  /// In zh, this message translates to:
  /// **'测试服务器'**
  String get testServer;

  /// No description provided for @edit.
  ///
  /// In zh, this message translates to:
  /// **'编辑'**
  String get edit;

  /// No description provided for @editServer.
  ///
  /// In zh, this message translates to:
  /// **'编辑服务器'**
  String get editServer;

  /// No description provided for @deleteServer.
  ///
  /// In zh, this message translates to:
  /// **'删除服务器'**
  String get deleteServer;

  /// No description provided for @deleteServerBody.
  ///
  /// In zh, this message translates to:
  /// **'确定删除“{name}”吗？此操作不会删除服务器端数据。'**
  String deleteServerBody(String name);

  /// No description provided for @configurationJsonInvalid.
  ///
  /// In zh, this message translates to:
  /// **'配置必须是有效的 JSON 对象'**
  String get configurationJsonInvalid;

  /// No description provided for @commandQueue.
  ///
  /// In zh, this message translates to:
  /// **'Shell 命令队列'**
  String get commandQueue;

  /// No description provided for @shellAppDirectory.
  ///
  /// In zh, this message translates to:
  /// **'应用默认执行目录'**
  String get shellAppDirectory;

  /// No description provided for @activeTasks.
  ///
  /// In zh, this message translates to:
  /// **'{count} 个活动任务'**
  String activeTasks(int count);

  /// No description provided for @addToQueue.
  ///
  /// In zh, this message translates to:
  /// **'加入队列'**
  String get addToQueue;

  /// No description provided for @taskQueue.
  ///
  /// In zh, this message translates to:
  /// **'任务队列'**
  String get taskQueue;

  /// No description provided for @clearCompleted.
  ///
  /// In zh, this message translates to:
  /// **'清理已完成'**
  String get clearCompleted;

  /// No description provided for @queueEmpty.
  ///
  /// In zh, this message translates to:
  /// **'队列为空'**
  String get queueEmpty;

  /// No description provided for @queueEmptyBody.
  ///
  /// In zh, this message translates to:
  /// **'命令将按加入顺序串行执行，输出会保留在本机。'**
  String get queueEmptyBody;

  /// No description provided for @refresh.
  ///
  /// In zh, this message translates to:
  /// **'刷新'**
  String get refresh;

  /// No description provided for @noCommandHistory.
  ///
  /// In zh, this message translates to:
  /// **'暂无本地命令历史'**
  String get noCommandHistory;

  /// No description provided for @noOutput.
  ///
  /// In zh, this message translates to:
  /// **'此任务没有输出'**
  String get noOutput;

  /// No description provided for @statusQueued.
  ///
  /// In zh, this message translates to:
  /// **'等待中'**
  String get statusQueued;

  /// No description provided for @statusRunning.
  ///
  /// In zh, this message translates to:
  /// **'运行中'**
  String get statusRunning;

  /// No description provided for @statusCompleted.
  ///
  /// In zh, this message translates to:
  /// **'已完成'**
  String get statusCompleted;

  /// No description provided for @statusFailed.
  ///
  /// In zh, this message translates to:
  /// **'失败'**
  String get statusFailed;

  /// No description provided for @statusCancelled.
  ///
  /// In zh, this message translates to:
  /// **'已取消'**
  String get statusCancelled;

  /// No description provided for @streamResponses.
  ///
  /// In zh, this message translates to:
  /// **'流式显示响应'**
  String get streamResponses;

  /// No description provided for @streamResponsesDescription.
  ///
  /// In zh, this message translates to:
  /// **'远程模型返回内容时逐字显示'**
  String get streamResponsesDescription;

  /// No description provided for @showTokenCounter.
  ///
  /// In zh, this message translates to:
  /// **'显示 Token 计数'**
  String get showTokenCounter;

  /// No description provided for @autoTitleSessions.
  ///
  /// In zh, this message translates to:
  /// **'自动生成会话标题'**
  String get autoTitleSessions;

  /// No description provided for @confirmAgentWrites.
  ///
  /// In zh, this message translates to:
  /// **'Agent 写入前确认'**
  String get confirmAgentWrites;

  /// No description provided for @confirmAgentWritesDescription.
  ///
  /// In zh, this message translates to:
  /// **'写文件和运行命令前显示动作清单'**
  String get confirmAgentWritesDescription;

  /// No description provided for @activeWorkspace.
  ///
  /// In zh, this message translates to:
  /// **'活动工作区'**
  String get activeWorkspace;

  /// No description provided for @downloadWifiOnly.
  ///
  /// In zh, this message translates to:
  /// **'仅使用 Wi-Fi 下载模型'**
  String get downloadWifiOnly;

  /// No description provided for @downloadWifiOnlyDescription.
  ///
  /// In zh, this message translates to:
  /// **'避免端侧模型消耗移动数据'**
  String get downloadWifiOnlyDescription;

  /// No description provided for @downloadWifiRequired.
  ///
  /// In zh, this message translates to:
  /// **'已开启仅 Wi-Fi 下载，请连接 Wi-Fi 后重试。'**
  String get downloadWifiRequired;

  /// No description provided for @downloadChecksumMismatch.
  ///
  /// In zh, this message translates to:
  /// **'模型校验失败，已删除损坏文件，请重新下载。'**
  String get downloadChecksumMismatch;

  /// No description provided for @downloadFailedReason.
  ///
  /// In zh, this message translates to:
  /// **'下载失败：{reason}'**
  String downloadFailedReason(String reason);

  /// No description provided for @workspaceOnboardingTitle.
  ///
  /// In zh, this message translates to:
  /// **'选择工作区'**
  String get workspaceOnboardingTitle;

  /// No description provided for @workspaceOnboardingBody.
  ///
  /// In zh, this message translates to:
  /// **'Agent 与 Harness 工具将使用这个本地目录。你也可以暂时跳过，稍后在设置中选择。'**
  String get workspaceOnboardingBody;

  /// No description provided for @preferredProjectsPath.
  ///
  /// In zh, this message translates to:
  /// **'推荐项目目录：{path}'**
  String preferredProjectsPath(String path);

  /// No description provided for @settingsConversationDescription.
  ///
  /// In zh, this message translates to:
  /// **'上下文、输出长度、采样参数、提示词与 Agent 防护'**
  String get settingsConversationDescription;

  /// No description provided for @settingsAppearanceDescription.
  ///
  /// In zh, this message translates to:
  /// **'主题、语言、动效、字体、间距与时间戳'**
  String get settingsAppearanceDescription;

  /// No description provided for @settingsDataDescription.
  ///
  /// In zh, this message translates to:
  /// **'工作区、模型存储、备份恢复与下载策略'**
  String get settingsDataDescription;

  /// No description provided for @settingsShellDescription.
  ///
  /// In zh, this message translates to:
  /// **'Shell 环境、历史记录与高危命令确认'**
  String get settingsShellDescription;

  /// No description provided for @aboutDescription.
  ///
  /// In zh, this message translates to:
  /// **'版本、源码仓库、许可证与法律声明'**
  String get aboutDescription;

  /// No description provided for @projectRepository.
  ///
  /// In zh, this message translates to:
  /// **'项目仓库'**
  String get projectRepository;

  /// No description provided for @savedLocally.
  ///
  /// In zh, this message translates to:
  /// **'已保存到本地'**
  String get savedLocally;

  /// No description provided for @serverOnlyModel.
  ///
  /// In zh, this message translates to:
  /// **'仅服务器'**
  String get serverOnlyModel;

  /// No description provided for @officialSource.
  ///
  /// In zh, this message translates to:
  /// **'官方来源'**
  String get officialSource;

  /// No description provided for @noCompatibleLocalModels.
  ///
  /// In zh, this message translates to:
  /// **'当前最新一代模型暂无经过验证且兼容本项目 Android 引擎的移动端包。'**
  String get noCompatibleLocalModels;

  /// No description provided for @deepSeekHarnessTitle.
  ///
  /// In zh, this message translates to:
  /// **'DeepSeek Harness'**
  String get deepSeekHarnessTitle;

  /// No description provided for @deepSeekHarnessVersion.
  ///
  /// In zh, this message translates to:
  /// **'官方运行包 {version}'**
  String deepSeekHarnessVersion(String version);

  /// No description provided for @developerPreview.
  ///
  /// In zh, this message translates to:
  /// **'开发者预览'**
  String get developerPreview;

  /// No description provided for @harnessRuntimeNotice.
  ///
  /// In zh, this message translates to:
  /// **'官方运行时要求 Node.js 22.19+ 或 24+，无法直接在普通 Android APK 内执行。司器可校验并下载官方包、管理插件源码归档，并连接由 Termux 或同一局域网电脑启动的运行时。下载的插件绝不会被静默执行。'**
  String get harnessRuntimeNotice;

  /// No description provided for @addDeepSeekProfile.
  ///
  /// In zh, this message translates to:
  /// **'添加 DeepSeek API 配置'**
  String get addDeepSeekProfile;

  /// No description provided for @harnessDeepSeekProfile.
  ///
  /// In zh, this message translates to:
  /// **'Harness 使用的 DeepSeek API 配置'**
  String get harnessDeepSeekProfile;

  /// No description provided for @runtimeDownloaded.
  ///
  /// In zh, this message translates to:
  /// **'运行包已下载'**
  String get runtimeDownloaded;

  /// No description provided for @downloadOfficialRuntime.
  ///
  /// In zh, this message translates to:
  /// **'下载官方运行包'**
  String get downloadOfficialRuntime;

  /// No description provided for @harnessPluginCatalog.
  ///
  /// In zh, this message translates to:
  /// **'Harness 插件目录'**
  String get harnessPluginCatalog;

  /// No description provided for @developmentDocs.
  ///
  /// In zh, this message translates to:
  /// **'开发文档'**
  String get developmentDocs;

  /// No description provided for @repository.
  ///
  /// In zh, this message translates to:
  /// **'仓库'**
  String get repository;

  /// No description provided for @openLocalHarness.
  ///
  /// In zh, this message translates to:
  /// **'打开本地运行时'**
  String get openLocalHarness;

  /// No description provided for @localPreflight.
  ///
  /// In zh, this message translates to:
  /// **'本地预检'**
  String get localPreflight;

  /// No description provided for @syncAllPlugins.
  ///
  /// In zh, this message translates to:
  /// **'同步全部插件'**
  String get syncAllPlugins;

  /// No description provided for @pluginCatalogNotice.
  ///
  /// In zh, this message translates to:
  /// **'该目录自动聚合公开 GitHub 仓库，未审查安全性或兼容性。司器只在本地保存元数据与源码归档；安装或执行始终需要你明确操作。'**
  String get pluginCatalogNotice;

  /// No description provided for @searchPlugins.
  ///
  /// In zh, this message translates to:
  /// **'搜索名称、作者、描述或分类'**
  String get searchPlugins;

  /// No description provided for @pluginSyncProgress.
  ///
  /// In zh, this message translates to:
  /// **'页面 {completed}/{total} · 已保存 {count} 个插件'**
  String pluginSyncProgress(int completed, int total, int count);

  /// No description provided for @noPluginsSynced.
  ///
  /// In zh, this message translates to:
  /// **'本地尚未保存插件目录。'**
  String get noPluginsSynced;

  /// No description provided for @pluginSecurityTitle.
  ///
  /// In zh, this message translates to:
  /// **'核对第三方源码'**
  String get pluginSecurityTitle;

  /// No description provided for @pluginSecurityBody.
  ///
  /// In zh, this message translates to:
  /// **'下载 {repository} 的源码归档吗？司器未审查该仓库。下载不会安装或运行代码；在外部运行时启用前，请检查许可证、提交版本和构建脚本。'**
  String pluginSecurityBody(String repository);

  /// No description provided for @downloadSourceArchive.
  ///
  /// In zh, this message translates to:
  /// **'下载源码'**
  String get downloadSourceArchive;

  /// No description provided for @removePluginArchive.
  ///
  /// In zh, this message translates to:
  /// **'移除本地归档'**
  String get removePluginArchive;

  /// No description provided for @removePluginArchiveBody.
  ///
  /// In zh, this message translates to:
  /// **'删除 {name} 的已下载归档吗？已同步的目录元数据会保留。'**
  String removePluginArchiveBody(String name);

  /// No description provided for @downloaded.
  ///
  /// In zh, this message translates to:
  /// **'已下载'**
  String get downloaded;

  /// No description provided for @copyInstallCommand.
  ///
  /// In zh, this message translates to:
  /// **'复制安装命令'**
  String get copyInstallCommand;

  /// No description provided for @errorHarnessDeepSeekRequired.
  ///
  /// In zh, this message translates to:
  /// **'Harness 模式仅支持已测试且已保存密钥的 DeepSeek API 配置。请先在实验室的 Harness 页面完成选择。'**
  String get errorHarnessDeepSeekRequired;

  /// No description provided for @modeTeam.
  ///
  /// In zh, this message translates to:
  /// **'AI 团队'**
  String get modeTeam;

  /// No description provided for @startupFailureTitle.
  ///
  /// In zh, this message translates to:
  /// **'司器暂时无法启动'**
  String get startupFailureTitle;

  /// No description provided for @startupFailureBody.
  ///
  /// In zh, this message translates to:
  /// **'本地初始化遇到问题。你的数据没有被删除，请重新打开应用；若问题持续，可在日志与缓存中导出运行日志。'**
  String get startupFailureBody;

  /// No description provided for @permissionPrivacy.
  ///
  /// In zh, this message translates to:
  /// **'权限与隐私'**
  String get permissionPrivacy;

  /// No description provided for @permissionPrivacyMenuDescription.
  ///
  /// In zh, this message translates to:
  /// **'查看每项权限的用途、当前状态与调用记录'**
  String get permissionPrivacyMenuDescription;

  /// No description provided for @permissionPrivacyBody.
  ///
  /// In zh, this message translates to:
  /// **'司器仅在你使用对应功能时申请权限。拒绝不会阻止应用启动，你可以在系统设置中重新授权，也可以删除本页保存的权限调用记录。'**
  String get permissionPrivacyBody;

  /// No description provided for @openSystemSettings.
  ///
  /// In zh, this message translates to:
  /// **'系统设置'**
  String get openSystemSettings;

  /// No description provided for @currentPermissions.
  ///
  /// In zh, this message translates to:
  /// **'当前权限'**
  String get currentPermissions;

  /// No description provided for @permissionHistory.
  ///
  /// In zh, this message translates to:
  /// **'调用记录'**
  String get permissionHistory;

  /// No description provided for @clearHistory.
  ///
  /// In zh, this message translates to:
  /// **'清空记录'**
  String get clearHistory;

  /// No description provided for @noPermissionHistory.
  ///
  /// In zh, this message translates to:
  /// **'尚无权限调用记录'**
  String get noPermissionHistory;

  /// No description provided for @deleteRecord.
  ///
  /// In zh, this message translates to:
  /// **'删除此记录'**
  String get deleteRecord;

  /// No description provided for @systemPickerManaged.
  ///
  /// In zh, this message translates to:
  /// **'由系统选择器管理'**
  String get systemPickerManaged;

  /// No description provided for @permissionNotifications.
  ///
  /// In zh, this message translates to:
  /// **'通知'**
  String get permissionNotifications;

  /// No description provided for @permissionMicrophone.
  ///
  /// In zh, this message translates to:
  /// **'麦克风'**
  String get permissionMicrophone;

  /// No description provided for @permissionCamera.
  ///
  /// In zh, this message translates to:
  /// **'相机'**
  String get permissionCamera;

  /// No description provided for @permissionPhotos.
  ///
  /// In zh, this message translates to:
  /// **'照片与视频'**
  String get permissionPhotos;

  /// No description provided for @permissionWorkspace.
  ///
  /// In zh, this message translates to:
  /// **'工作区目录'**
  String get permissionWorkspace;

  /// No description provided for @permissionNotificationsDescription.
  ///
  /// In zh, this message translates to:
  /// **'仅在模型下载或长任务开始时，用于显示进度与完成状态。'**
  String get permissionNotificationsDescription;

  /// No description provided for @permissionMicrophoneDescription.
  ///
  /// In zh, this message translates to:
  /// **'仅在你主动录音进行语音转文字时调用。'**
  String get permissionMicrophoneDescription;

  /// No description provided for @permissionCameraDescription.
  ///
  /// In zh, this message translates to:
  /// **'仅在你主动拍摄多模态附件时调用。'**
  String get permissionCameraDescription;

  /// No description provided for @permissionPhotosDescription.
  ///
  /// In zh, this message translates to:
  /// **'仅在你主动选择图片或视频附件时调用。'**
  String get permissionPhotosDescription;

  /// No description provided for @permissionWorkspaceDescription.
  ///
  /// In zh, this message translates to:
  /// **'通过 Android 系统目录选择器授权；不申请所有文件访问或 Root。'**
  String get permissionWorkspaceDescription;

  /// No description provided for @purposeModelDownload.
  ///
  /// In zh, this message translates to:
  /// **'显示模型下载与后台任务进度'**
  String get purposeModelDownload;

  /// No description provided for @purposeSpeechToText.
  ///
  /// In zh, this message translates to:
  /// **'录制需要转写的语音'**
  String get purposeSpeechToText;

  /// No description provided for @purposeCameraAttachment.
  ///
  /// In zh, this message translates to:
  /// **'拍摄对话附件'**
  String get purposeCameraAttachment;

  /// No description provided for @purposeImageAttachment.
  ///
  /// In zh, this message translates to:
  /// **'选择多模态附件'**
  String get purposeImageAttachment;

  /// No description provided for @purposeWorkspace.
  ///
  /// In zh, this message translates to:
  /// **'读取或修改已选择的工作区'**
  String get purposeWorkspace;

  /// No description provided for @purposeModelStorage.
  ///
  /// In zh, this message translates to:
  /// **'选择模型存储目录'**
  String get purposeModelStorage;

  /// No description provided for @permissionGranted.
  ///
  /// In zh, this message translates to:
  /// **'已允许'**
  String get permissionGranted;

  /// No description provided for @permissionDenied.
  ///
  /// In zh, this message translates to:
  /// **'已拒绝'**
  String get permissionDenied;

  /// No description provided for @permissionPermanentlyDenied.
  ///
  /// In zh, this message translates to:
  /// **'已永久拒绝'**
  String get permissionPermanentlyDenied;

  /// No description provided for @permissionRestricted.
  ///
  /// In zh, this message translates to:
  /// **'受系统限制'**
  String get permissionRestricted;

  /// No description provided for @permissionLimited.
  ///
  /// In zh, this message translates to:
  /// **'部分允许'**
  String get permissionLimited;

  /// No description provided for @permissionUnknown.
  ///
  /// In zh, this message translates to:
  /// **'检查中'**
  String get permissionUnknown;

  /// No description provided for @logsAndCache.
  ///
  /// In zh, this message translates to:
  /// **'日志与缓存'**
  String get logsAndCache;

  /// No description provided for @logsAndCacheDescription.
  ///
  /// In zh, this message translates to:
  /// **'导出工作日志、诊断启动问题并清理临时缓存'**
  String get logsAndCacheDescription;

  /// No description provided for @cache.
  ///
  /// In zh, this message translates to:
  /// **'临时缓存'**
  String get cache;

  /// No description provided for @calculating.
  ///
  /// In zh, this message translates to:
  /// **'正在计算…'**
  String get calculating;

  /// No description provided for @clearCache.
  ///
  /// In zh, this message translates to:
  /// **'清理缓存'**
  String get clearCache;

  /// No description provided for @runtimeLogs.
  ///
  /// In zh, this message translates to:
  /// **'运行日志'**
  String get runtimeLogs;

  /// No description provided for @runtimeLogsDescription.
  ///
  /// In zh, this message translates to:
  /// **'本地异常与启动诊断，不包含已保存的 API 密钥'**
  String get runtimeLogsDescription;

  /// No description provided for @shareLogs.
  ///
  /// In zh, this message translates to:
  /// **'导出日志'**
  String get shareLogs;

  /// No description provided for @clearLogs.
  ///
  /// In zh, this message translates to:
  /// **'清空日志'**
  String get clearLogs;

  /// No description provided for @workLogs.
  ///
  /// In zh, this message translates to:
  /// **'工作日志'**
  String get workLogs;

  /// No description provided for @noWorkLogs.
  ///
  /// In zh, this message translates to:
  /// **'尚无工作日志'**
  String get noWorkLogs;

  /// No description provided for @developerMode.
  ///
  /// In zh, this message translates to:
  /// **'开发者模式'**
  String get developerMode;

  /// No description provided for @developerModeDescription.
  ///
  /// In zh, this message translates to:
  /// **'开启后才显示本地 Shell。命令仅在应用沙箱或已授权工作区中运行，不提供 Root、提权或系统分区写入。'**
  String get developerModeDescription;

  /// No description provided for @developerModeRequired.
  ///
  /// In zh, this message translates to:
  /// **'需要开启开发者模式'**
  String get developerModeRequired;

  /// No description provided for @developerModeRequiredDescription.
  ///
  /// In zh, this message translates to:
  /// **'请前往设置 > Shell 设置阅读安全边界并手动开启。普通用户无需输入任何命令。'**
  String get developerModeRequiredDescription;

  /// No description provided for @aiTeamMode.
  ///
  /// In zh, this message translates to:
  /// **'AI 团队'**
  String get aiTeamMode;

  /// No description provided for @aiTeamDescription.
  ///
  /// In zh, this message translates to:
  /// **'让最多 8 个已配置的云端 AI 共享上下文、分轮协作并汇总结果'**
  String get aiTeamDescription;

  /// No description provided for @aiTeamNotice.
  ///
  /// In zh, this message translates to:
  /// **'每一轮都会按顺序调用所有成员，成员能看到之前成员的输出。调用会消耗各 API 的额度；任务、成员输出与工作日志仅保存在本机。'**
  String get aiTeamNotice;

  /// No description provided for @aiTeamNeedsProfiles.
  ///
  /// In zh, this message translates to:
  /// **'需要已测试的 API 配置'**
  String get aiTeamNeedsProfiles;

  /// No description provided for @aiTeamNeedsProfilesDescription.
  ///
  /// In zh, this message translates to:
  /// **'先在设置的自定义 API 投射中添加并测试至少一个云端模型，然后即可创建团队，全程无需输入命令。'**
  String get aiTeamNeedsProfilesDescription;

  /// No description provided for @noAiTeams.
  ///
  /// In zh, this message translates to:
  /// **'尚未创建 AI 团队'**
  String get noAiTeams;

  /// No description provided for @noAiTeamsDescription.
  ///
  /// In zh, this message translates to:
  /// **'选择 1–8 个已测试模型，并设置协作轮数。'**
  String get noAiTeamsDescription;

  /// No description provided for @newAiTeam.
  ///
  /// In zh, this message translates to:
  /// **'新建团队'**
  String get newAiTeam;

  /// No description provided for @activeAiTeam.
  ///
  /// In zh, this message translates to:
  /// **'当前团队'**
  String get activeAiTeam;

  /// No description provided for @editAiTeam.
  ///
  /// In zh, this message translates to:
  /// **'编辑团队'**
  String get editAiTeam;

  /// No description provided for @deleteAiTeam.
  ///
  /// In zh, this message translates to:
  /// **'删除团队'**
  String get deleteAiTeam;

  /// No description provided for @deleteAiTeamBody.
  ///
  /// In zh, this message translates to:
  /// **'删除“{name}”及其本地协作记录吗？'**
  String deleteAiTeamBody(String name);

  /// No description provided for @aiTeamTask.
  ///
  /// In zh, this message translates to:
  /// **'团队任务'**
  String get aiTeamTask;

  /// No description provided for @aiTeamTaskHint.
  ///
  /// In zh, this message translates to:
  /// **'描述目标、约束和期望交付物'**
  String get aiTeamTaskHint;

  /// No description provided for @startCollaboration.
  ///
  /// In zh, this message translates to:
  /// **'开始协作'**
  String get startCollaboration;

  /// No description provided for @teamTranscript.
  ///
  /// In zh, this message translates to:
  /// **'团队工作记录'**
  String get teamTranscript;

  /// No description provided for @noTeamMessages.
  ///
  /// In zh, this message translates to:
  /// **'尚无团队协作记录'**
  String get noTeamMessages;

  /// No description provided for @teamFinalAnswer.
  ///
  /// In zh, this message translates to:
  /// **'团队最终汇总'**
  String get teamFinalAnswer;

  /// No description provided for @teamMemberRound.
  ///
  /// In zh, this message translates to:
  /// **'{name} · 第 {round} 轮'**
  String teamMemberRound(String name, int round);

  /// No description provided for @aiTeamName.
  ///
  /// In zh, this message translates to:
  /// **'团队名称'**
  String get aiTeamName;

  /// No description provided for @aiTeamMembers.
  ///
  /// In zh, this message translates to:
  /// **'团队成员 {count}/8'**
  String aiTeamMembers(int count);

  /// No description provided for @collaborationRounds.
  ///
  /// In zh, this message translates to:
  /// **'协作轮数：{count}'**
  String collaborationRounds(int count);

  /// No description provided for @mcpStore.
  ///
  /// In zh, this message translates to:
  /// **'MCP 商店'**
  String get mcpStore;

  /// No description provided for @mcpStoreDescription.
  ///
  /// In zh, this message translates to:
  /// **'浏览、缓存并管理 ModelScope MCP 服务'**
  String get mcpStoreDescription;

  /// No description provided for @syncCatalog.
  ///
  /// In zh, this message translates to:
  /// **'同步目录'**
  String get syncCatalog;

  /// No description provided for @openOfficialCatalog.
  ///
  /// In zh, this message translates to:
  /// **'打开官方目录'**
  String get openOfficialCatalog;

  /// No description provided for @searchMcpStore.
  ///
  /// In zh, this message translates to:
  /// **'搜索名称、作者或说明'**
  String get searchMcpStore;

  /// No description provided for @mcpStoreSynced.
  ///
  /// In zh, this message translates to:
  /// **'已同步 {count} 个 MCP 服务'**
  String mcpStoreSynced(int count);

  /// No description provided for @mcpStoreProtected.
  ///
  /// In zh, this message translates to:
  /// **'ModelScope 暂时要求浏览器安全验证，自动同步未完成。'**
  String get mcpStoreProtected;

  /// No description provided for @mcpStoreCacheNotice.
  ///
  /// In zh, this message translates to:
  /// **'现有本地缓存仍可使用，也可以打开官方目录查看最新内容。'**
  String get mcpStoreCacheNotice;

  /// No description provided for @mcpStoreEmpty.
  ///
  /// In zh, this message translates to:
  /// **'本地还没有 MCP 商店缓存。同步只读取公开目录，不会上传本地配置。'**
  String get mcpStoreEmpty;

  /// No description provided for @mcpImported.
  ///
  /// In zh, this message translates to:
  /// **'已导入 MCP 管理器，请先测试连接再启用。'**
  String get mcpImported;

  /// No description provided for @mcpImportManualRequired.
  ///
  /// In zh, this message translates to:
  /// **'该服务没有公开的托管端点，请查看官方详情完成授权或部署。'**
  String get mcpImportManualRequired;

  /// No description provided for @importToMcp.
  ///
  /// In zh, this message translates to:
  /// **'导入管理器'**
  String get importToMcp;

  /// No description provided for @details.
  ///
  /// In zh, this message translates to:
  /// **'详情'**
  String get details;

  /// No description provided for @serverUrl.
  ///
  /// In zh, this message translates to:
  /// **'服务器 URL'**
  String get serverUrl;

  /// No description provided for @multimodalZone.
  ///
  /// In zh, this message translates to:
  /// **'多模态专区'**
  String get multimodalZone;

  /// No description provided for @multimodalZoneDescription.
  ///
  /// In zh, this message translates to:
  /// **'语音模型、内存评估与音频时长建议'**
  String get multimodalZoneDescription;

  /// No description provided for @audioMemoryGuard.
  ///
  /// In zh, this message translates to:
  /// **'60% 内存保护'**
  String get audioMemoryGuard;

  /// No description provided for @audioMemorySummary.
  ///
  /// In zh, this message translates to:
  /// **'设备总内存 {total}；模型与任务最多使用 {budget}；当前可用 {available}。'**
  String audioMemorySummary(String total, String budget, String available);

  /// No description provided for @audioMemoryPolicy.
  ///
  /// In zh, this message translates to:
  /// **'只有具备可验证来源、Android 端侧运行时且峰值占用不超过总内存 60% 的模型才会开放下载。'**
  String get audioMemoryPolicy;

  /// No description provided for @speechToText.
  ///
  /// In zh, this message translates to:
  /// **'语音转文字'**
  String get speechToText;

  /// No description provided for @textToSpeech.
  ///
  /// In zh, this message translates to:
  /// **'文字转语音'**
  String get textToSpeech;

  /// No description provided for @officialWeightSize.
  ///
  /// In zh, this message translates to:
  /// **'官方权重大小：{size}'**
  String officialWeightSize(String size);

  /// No description provided for @audioRuntimeUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'权重大小符合预算，但目前没有经过验证的 Android 量化运行时，因此暂不开放下载。'**
  String get audioRuntimeUnavailable;

  /// No description provided for @audioModelExceedsLimit.
  ///
  /// In zh, this message translates to:
  /// **'该官方模型超过本设备的 60% 内存上限，已阻止下载和加载。'**
  String get audioModelExceedsLimit;

  /// No description provided for @audioDurationUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'当前没有安全的端侧内存余量，建议最大音频时长：0 分钟。'**
  String get audioDurationUnavailable;

  /// No description provided for @audioDurationSuggestion.
  ///
  /// In zh, this message translates to:
  /// **'按剩余内存估算，建议单次音频不超过 {duration}。'**
  String audioDurationSuggestion(String duration);

  /// No description provided for @notCompatible.
  ///
  /// In zh, this message translates to:
  /// **'当前设备不兼容'**
  String get notCompatible;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.countryCode) {
          case 'TW':
            return AppLocalizationsZhTw();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
