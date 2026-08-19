import '../models/app_models.dart';

abstract final class AppConstants {
  static const applicationId = 'com.psq.siqi';
  static const exportExtension = 'siqi';
  static const configExtension = 'siji_config';
  static const databaseName = 'siqi_local.db';
  static const databaseVersion = 3;
  static const preferredProjectsPath = '/storage/emulated/0/Siqi/Projects';
  static const githubCallbackScheme = 'siqi';
  static const projectUrl = 'https://github.com/psq0421/SIQI';
  static const harnessRepositoryUrl =
      'https://github.com/deepseek-ai/deepseek-harness';
  static const harnessDocumentationUrl =
      'https://deepseek-harness.github.io/deepseek-harness/develop/basic/';
  static const harnessPluginCatalogUrl =
      'https://dsh.deepseek404.com/index.php';
  static const harnessNpmTarballUrl =
      'https://registry.npmjs.org/@deepseek-ai/dsh/-/dsh-0.1.0-rc.7.tgz';
  static const harnessNpmSha512 =
      'ZceDCJ8FAywih+USW/OMk9jEhunlvJBGEz4kqrhau23hPzbciOazZrywH0nBRsaalSeAJ1JGBmjtw4OSjToStw==';
  static const harnessVersion = '0.1.0-rc.7';

  static const supportedTextExtensions = <String>{
    'dart',
    'kt',
    'java',
    'py',
    'js',
    'ts',
    'go',
    'rs',
    'c',
    'cpp',
    'swift',
    'sh',
    'txt',
    'md',
    'json',
    'yaml',
    'yml',
    'xml',
    'html',
    'csv',
    'log',
  };

  static const richDocumentExtensions = <String>{'pdf', 'docx', 'pptx'};
}

abstract final class ModelCatalog {
  static const models = <ModelDefinition>[
    ModelDefinition(
      id: 'local-hunyuan-05b-q4km',
      displayName: 'Hunyuan-0.5B · Q4_K_M',
      family: ModelFamily.local,
      provider: 'Tencent Hunyuan · bartowski quantization',
      apiFormat: ApiFormat.local,
      license: 'Tencent Hunyuan Community License',
      isMultimodal: false,
      sizeBytes: 354970464,
      minimumMemoryGb: 2,
      downloadUrl:
          'https://modelscope.cn/models/bartowski/tencent_Hunyuan-0.5B-Instruct-GGUF/resolve/master/tencent_Hunyuan-0.5B-Instruct-Q4_K_M.gguf',
      sourceUrl:
          'https://modelscope.cn/models/bartowski/tencent_Hunyuan-0.5B-Instruct-GGUF',
      expectedSha256:
          '0820d20c5fb0e4d5e1b9ec660aae6996676280486c9dae17475708efe60b3f2d',
    ),
    ModelDefinition(
      id: 'local-hunyuan-18b-q4km',
      displayName: 'Hunyuan-1.8B · Q4_K_M',
      family: ModelFamily.local,
      provider: 'Tencent Hunyuan · bartowski quantization',
      apiFormat: ApiFormat.local,
      license: 'Tencent Hunyuan Community License',
      isMultimodal: false,
      sizeBytes: 1133084864,
      minimumMemoryGb: 4,
      downloadUrl:
          'https://modelscope.cn/models/bartowski/tencent_Hunyuan-1.8B-Instruct-GGUF/resolve/master/tencent_Hunyuan-1.8B-Instruct-Q4_K_M.gguf',
      sourceUrl:
          'https://modelscope.cn/models/bartowski/tencent_Hunyuan-1.8B-Instruct-GGUF',
      expectedSha256:
          '558ae86fc4251fd73cd54685319a83e7550997537e3ad41043ad5c0b5a2a26d4',
    ),
    ModelDefinition(
      id: 'local-hunyuan-4b-q4km',
      displayName: 'Hunyuan-4B · Q4_K_M',
      family: ModelFamily.local,
      provider: 'Tencent Hunyuan · bartowski quantization',
      apiFormat: ApiFormat.local,
      license: 'Tencent Hunyuan Community License',
      isMultimodal: false,
      sizeBytes: 2607709696,
      minimumMemoryGb: 6,
      downloadUrl:
          'https://modelscope.cn/models/bartowski/tencent_Hunyuan-4B-Instruct-GGUF/resolve/master/tencent_Hunyuan-4B-Instruct-Q4_K_M.gguf',
      sourceUrl:
          'https://modelscope.cn/models/bartowski/tencent_Hunyuan-4B-Instruct-GGUF',
      expectedSha256:
          '6504332fb1c42b176d0bbac725f8072ca52bf7d600d8f5b8b4b4686f680e3f76',
    ),
    ModelDefinition(
      id: 'local-hunyuan-7b-q4km',
      displayName: 'Hunyuan-7B · Q4_K_M',
      family: ModelFamily.local,
      provider: 'Tencent Hunyuan · bartowski quantization',
      apiFormat: ApiFormat.local,
      license: 'Tencent Hunyuan Community License',
      isMultimodal: false,
      sizeBytes: 4621992960,
      minimumMemoryGb: 10,
      downloadUrl:
          'https://modelscope.cn/models/bartowski/tencent_Hunyuan-7B-Instruct-GGUF/resolve/master/tencent_Hunyuan-7B-Instruct-Q4_K_M.gguf',
      sourceUrl:
          'https://modelscope.cn/models/bartowski/tencent_Hunyuan-7B-Instruct-GGUF',
      expectedSha256:
          '37361ed44b126de00a551260fd7c3de3c3a7a58d6060bce99b6b8fe0c0665d63',
    ),
    ModelDefinition(
      id: 'local-gemma4-e2b-q4km',
      displayName: 'Gemma4-E2B IT · Q4_K_M',
      family: ModelFamily.local,
      provider: 'Google Gemma · Unsloth quantization',
      apiFormat: ApiFormat.local,
      license: 'Apache-2.0',
      isMultimodal: false,
      sizeBytes: 3106738272,
      minimumMemoryGb: 6,
      downloadUrl:
          'https://modelscope.cn/models/unsloth/gemma-4-e2b-it-GGUF/resolve/master/gemma-4-E2B-it-Q4_K_M.gguf',
      sourceUrl: 'https://modelscope.cn/models/unsloth/gemma-4-e2b-it-GGUF',
      expectedSha256:
          '740185b21d22ceb83a11c3aa62ad5842ef32c70f6096d756bbee85a1e4ec34b8',
    ),
    ModelDefinition(
      id: 'local-gemma4-e4b-q4km',
      displayName: 'Gemma4-E4B IT · Q4_K_M',
      family: ModelFamily.local,
      provider: 'Google Gemma · Unsloth quantization',
      apiFormat: ApiFormat.local,
      license: 'Apache-2.0',
      isMultimodal: false,
      sizeBytes: 4977171584,
      minimumMemoryGb: 9,
      downloadUrl:
          'https://modelscope.cn/models/unsloth/gemma-4-e4b-it-GGUF/resolve/master/gemma-4-E4B-it-Q4_K_M.gguf',
      sourceUrl: 'https://modelscope.cn/models/unsloth/gemma-4-e4b-it-GGUF',
      expectedSha256:
          '85a896a047553e842f25297ee5b031d64ff30147d9c4af17b1e4b394cd1fab87',
    ),
    ModelDefinition(
      id: 'local-qwen35-08b-q4km',
      displayName: 'Qwen3.5-0.8B · Q4_K_M',
      family: ModelFamily.local,
      provider: 'Qwen · Unsloth quantization',
      apiFormat: ApiFormat.local,
      license: 'Apache-2.0',
      isMultimodal: false,
      sizeBytes: 532517120,
      minimumMemoryGb: 3,
      downloadUrl:
          'https://modelscope.cn/models/unsloth/Qwen3.5-0.8B-GGUF/resolve/master/Qwen3.5-0.8B-Q4_K_M.gguf',
      sourceUrl: 'https://modelscope.cn/models/unsloth/Qwen3.5-0.8B-GGUF',
      expectedSha256:
          'bd258782e35f7f458f8aced1adc053e6e92e89bc735ba3be89d38a06121dc517',
    ),
    ModelDefinition(
      id: 'local-qwen35-2b-q4km',
      displayName: 'Qwen3.5-2B · Q4_K_M',
      family: ModelFamily.local,
      provider: 'Qwen · Unsloth quantization',
      apiFormat: ApiFormat.local,
      license: 'Apache-2.0',
      isMultimodal: false,
      sizeBytes: 1280835840,
      minimumMemoryGb: 5,
      downloadUrl:
          'https://modelscope.cn/models/unsloth/Qwen3.5-2B-GGUF/resolve/master/Qwen3.5-2B-Q4_K_M.gguf',
      sourceUrl: 'https://modelscope.cn/models/unsloth/Qwen3.5-2B-GGUF',
      expectedSha256:
          'aaf42c8b7c3cab2bf3d69c355048d4a0ee9973d48f16c731c0520ee914699223',
    ),
    ModelDefinition(
      id: 'local-qwen35-4b-q4km',
      displayName: 'Qwen3.5-4B · Q4_K_M',
      family: ModelFamily.local,
      provider: 'Qwen · Unsloth quantization',
      apiFormat: ApiFormat.local,
      license: 'Apache-2.0',
      isMultimodal: false,
      sizeBytes: 2740937888,
      minimumMemoryGb: 7,
      downloadUrl:
          'https://modelscope.cn/models/unsloth/Qwen3.5-4B-GGUF/resolve/master/Qwen3.5-4B-Q4_K_M.gguf',
      sourceUrl: 'https://modelscope.cn/models/unsloth/Qwen3.5-4B-GGUF',
      expectedSha256:
          '00fe7986ff5f6b463e62455821146049db6f9313603938a70800d1fb69ef11a4',
    ),
    ModelDefinition(
      id: 'local-qwen35-9b-q4km',
      displayName: 'Qwen3.5-9B · Q4_K_M',
      family: ModelFamily.local,
      provider: 'Qwen · Unsloth quantization',
      apiFormat: ApiFormat.local,
      license: 'Apache-2.0',
      isMultimodal: false,
      sizeBytes: 5680522464,
      minimumMemoryGb: 12,
      downloadUrl:
          'https://modelscope.cn/models/unsloth/Qwen3.5-9B-GGUF/resolve/master/Qwen3.5-9B-Q4_K_M.gguf',
      sourceUrl: 'https://modelscope.cn/models/unsloth/Qwen3.5-9B-GGUF',
      expectedSha256:
          '03b74727a860a56338e042c4420bb3f04b2fec5734175f4cb9fa853daf52b7e8',
    ),
  ];

  static ModelDefinition byId(String id) =>
      models.firstWhere((model) => model.id == id, orElse: () => models.first);
}

abstract final class ProviderTemplates {
  static const values = <ProviderTemplate>[
    ProviderTemplate(
      'openai',
      'OpenAI',
      'https://api.openai.com/v1',
      ApiFormat.openAi,
    ),
    ProviderTemplate(
      'anthropic',
      'Anthropic',
      'https://api.anthropic.com/v1',
      ApiFormat.anthropic,
    ),
    ProviderTemplate(
      'gemini',
      'Google Gemini',
      'https://generativelanguage.googleapis.com/v1beta/openai',
      ApiFormat.openAi,
    ),
    ProviderTemplate(
      'deepseek',
      'DeepSeek',
      'https://api.deepseek.com/v1',
      ApiFormat.openAi,
    ),
    ProviderTemplate(
      'doubao',
      'ByteDance',
      'https://ark.cn-beijing.volces.com/api/v3',
      ApiFormat.openAi,
    ),
    ProviderTemplate(
      'zhipu',
      'Zhipu AI',
      'https://open.bigmodel.cn/api/paas/v4',
      ApiFormat.openAi,
    ),
    ProviderTemplate(
      'baichuan',
      'Baichuan',
      'https://api.baichuan-ai.com/v1',
      ApiFormat.openAi,
    ),
    ProviderTemplate(
      'minimax',
      'MiniMax',
      'https://api.minimax.chat/v1',
      ApiFormat.openAi,
    ),
    ProviderTemplate(
      'moonshot',
      'Moonshot AI',
      'https://api.moonshot.cn/v1',
      ApiFormat.openAi,
    ),
    ProviderTemplate(
      'yi',
      '01.AI',
      'https://api.lingyiwanwu.com/v1',
      ApiFormat.openAi,
    ),
    ProviderTemplate(
      'custom-openai',
      'OpenAI Compatible',
      '',
      ApiFormat.openAi,
    ),
    ProviderTemplate(
      'custom-anthropic',
      'Anthropic Compatible',
      '',
      ApiFormat.anthropic,
    ),
  ];
}
