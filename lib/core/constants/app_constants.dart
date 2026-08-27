import '../models/app_models.dart';

abstract final class AppConstants {
  static const applicationId = 'com.psq.siqi';
  static const exportExtension = 'siqi';
  static const configExtension = 'siji_config';
  static const databaseName = 'siqi_local.db';
  static const databaseVersion = 5;
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
      'https://registry.npmjs.org/@deepseek-ai/dsh/-/dsh-0.1.1-rc.2.tgz';
  static const harnessNpmSha512 =
      'UP1UIh6q3Gme/yXRn/QL2P8IsVlv8Shpg22TRJIZPsCRWLm4CBiA1MUvXmJAfsOEETBMLAl+xWPtFw6ICsN3wg==';
  static const harnessVersion = '0.1.1-rc.2';

  static const supportedTextExtensions = <String>{
    'dart',
    'kt',
    'kts',
    'java',
    'py',
    'pyi',
    'js',
    'jsx',
    'ts',
    'tsx',
    'go',
    'rs',
    'c',
    'h',
    'cpp',
    'cc',
    'cxx',
    'hpp',
    'swift',
    'm',
    'mm',
    'cs',
    'fs',
    'fsx',
    'vb',
    'scala',
    'rb',
    'php',
    'lua',
    'r',
    'pl',
    'sql',
    'sh',
    'bash',
    'zsh',
    'fish',
    'ps1',
    'bat',
    'cmd',
    'gradle',
    'groovy',
    'vue',
    'svelte',
    'txt',
    'md',
    'markdown',
    'rst',
    'tex',
    'json',
    'jsonl',
    'yaml',
    'yml',
    'toml',
    'xml',
    'html',
    'htm',
    'css',
    'scss',
    'sass',
    'less',
    'csv',
    'tsv',
    'log',
    'ini',
    'cfg',
    'conf',
    'properties',
    'env',
    'gitignore',
    'dockerfile',
  };

  static const richDocumentExtensions = <String>{
    'pdf',
    'docx',
    'pptx',
    'xlsx',
    'odt',
    'ods',
    'odp',
    'epub',
    'rtf',
  };

  static const imageExtensions = <String>{
    'png',
    'jpg',
    'jpeg',
    'webp',
    'gif',
    'bmp',
    'tif',
    'tiff',
    'heic',
    'heif',
  };

  static const audioExtensions = <String>{
    'wav',
    'wave',
    'mp3',
    'm4a',
    'aac',
    'flac',
    'ogg',
    'oga',
    'opus',
    'amr',
    '3gp',
    'mp4',
  };
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
      isMultimodal: true,
      sizeBytes: 3106738272,
      minimumMemoryGb: 6,
      downloadUrl:
          'https://modelscope.cn/models/unsloth/gemma-4-e2b-it-GGUF/resolve/master/gemma-4-E2B-it-Q4_K_M.gguf',
      sourceUrl: 'https://modelscope.cn/models/unsloth/gemma-4-e2b-it-GGUF',
      expectedSha256:
          '740185b21d22ceb83a11c3aa62ad5842ef32c70f6096d756bbee85a1e4ec34b8',
      task: ModelTask.visionLanguage,
      capabilities: {ModelCapability.text, ModelCapability.imageInput},
      artifacts: [
        ModelArtifact(
          id: 'model',
          fileName: 'gemma-4-E2B-it-Q4_K_M.gguf',
          role: ModelArtifactRole.model,
          format: ModelFormat.gguf,
          downloadUrl:
              'https://modelscope.cn/models/unsloth/gemma-4-e2b-it-GGUF/resolve/master/gemma-4-E2B-it-Q4_K_M.gguf',
          sizeBytes: 3106738272,
          expectedSha256:
              '740185b21d22ceb83a11c3aa62ad5842ef32c70f6096d756bbee85a1e4ec34b8',
        ),
        ModelArtifact(
          id: 'projector',
          fileName: 'mmproj-F16.gguf',
          role: ModelArtifactRole.projector,
          format: ModelFormat.gguf,
          downloadUrl:
              'https://modelscope.cn/models/unsloth/gemma-4-e2b-it-GGUF/resolve/master/mmproj-F16.gguf',
          sizeBytes: 985654080,
          expectedSha256:
              '140be8d7849741f88c50757d529b84373ee8e27052cc2236855b537f4a8215fa',
        ),
      ],
    ),
    ModelDefinition(
      id: 'local-gemma4-e4b-q4km',
      displayName: 'Gemma4-E4B IT · Q4_K_M',
      family: ModelFamily.local,
      provider: 'Google Gemma · Unsloth quantization',
      apiFormat: ApiFormat.local,
      license: 'Apache-2.0',
      isMultimodal: true,
      sizeBytes: 4977171584,
      minimumMemoryGb: 9,
      downloadUrl:
          'https://modelscope.cn/models/unsloth/gemma-4-e4b-it-GGUF/resolve/master/gemma-4-E4B-it-Q4_K_M.gguf',
      sourceUrl: 'https://modelscope.cn/models/unsloth/gemma-4-e4b-it-GGUF',
      expectedSha256:
          '85a896a047553e842f25297ee5b031d64ff30147d9c4af17b1e4b394cd1fab87',
      task: ModelTask.visionLanguage,
      capabilities: {ModelCapability.text, ModelCapability.imageInput},
      artifacts: [
        ModelArtifact(
          id: 'model',
          fileName: 'gemma-4-E4B-it-Q4_K_M.gguf',
          role: ModelArtifactRole.model,
          format: ModelFormat.gguf,
          downloadUrl:
              'https://modelscope.cn/models/unsloth/gemma-4-e4b-it-GGUF/resolve/master/gemma-4-E4B-it-Q4_K_M.gguf',
          sizeBytes: 4977171584,
          expectedSha256:
              '85a896a047553e842f25297ee5b031d64ff30147d9c4af17b1e4b394cd1fab87',
        ),
        ModelArtifact(
          id: 'projector',
          fileName: 'mmproj-F16.gguf',
          role: ModelArtifactRole.projector,
          format: ModelFormat.gguf,
          downloadUrl:
              'https://modelscope.cn/models/unsloth/gemma-4-e4b-it-GGUF/resolve/master/mmproj-F16.gguf',
          sizeBytes: 990372672,
          expectedSha256:
              'ddf46c21d7078e95338cfc22306b19b276a29a5ad089023449dd54d4b6170a51',
        ),
      ],
    ),
    ModelDefinition(
      id: 'local-qwen35-08b-q4km',
      displayName: 'Qwen3.5-0.8B · Q4_K_M',
      family: ModelFamily.local,
      provider: 'Qwen · Unsloth quantization',
      apiFormat: ApiFormat.local,
      license: 'Apache-2.0',
      isMultimodal: true,
      sizeBytes: 532517120,
      minimumMemoryGb: 3,
      downloadUrl:
          'https://modelscope.cn/models/unsloth/Qwen3.5-0.8B-GGUF/resolve/master/Qwen3.5-0.8B-Q4_K_M.gguf',
      sourceUrl: 'https://modelscope.cn/models/unsloth/Qwen3.5-0.8B-GGUF',
      expectedSha256:
          'bd258782e35f7f458f8aced1adc053e6e92e89bc735ba3be89d38a06121dc517',
      task: ModelTask.visionLanguage,
      capabilities: {ModelCapability.text, ModelCapability.imageInput},
      artifacts: [
        ModelArtifact(
          id: 'model',
          fileName: 'Qwen3.5-0.8B-Q4_K_M.gguf',
          role: ModelArtifactRole.model,
          format: ModelFormat.gguf,
          downloadUrl:
              'https://modelscope.cn/models/unsloth/Qwen3.5-0.8B-GGUF/resolve/master/Qwen3.5-0.8B-Q4_K_M.gguf',
          sizeBytes: 532517120,
          expectedSha256:
              'bd258782e35f7f458f8aced1adc053e6e92e89bc735ba3be89d38a06121dc517',
        ),
        ModelArtifact(
          id: 'projector',
          fileName: 'mmproj-F16.gguf',
          role: ModelArtifactRole.projector,
          format: ModelFormat.gguf,
          downloadUrl:
              'https://modelscope.cn/models/unsloth/Qwen3.5-0.8B-GGUF/resolve/master/mmproj-F16.gguf',
          sizeBytes: 204987232,
          expectedSha256:
              '56e4c6cfe73b0c82e3e82bc518d7591997e61d81f723fc41a586f4fa69ea2453',
        ),
      ],
    ),
    ModelDefinition(
      id: 'local-qwen35-2b-q4km',
      displayName: 'Qwen3.5-2B · Q4_K_M',
      family: ModelFamily.local,
      provider: 'Qwen · Unsloth quantization',
      apiFormat: ApiFormat.local,
      license: 'Apache-2.0',
      isMultimodal: true,
      sizeBytes: 1280835840,
      minimumMemoryGb: 5,
      downloadUrl:
          'https://modelscope.cn/models/unsloth/Qwen3.5-2B-GGUF/resolve/master/Qwen3.5-2B-Q4_K_M.gguf',
      sourceUrl: 'https://modelscope.cn/models/unsloth/Qwen3.5-2B-GGUF',
      expectedSha256:
          'aaf42c8b7c3cab2bf3d69c355048d4a0ee9973d48f16c731c0520ee914699223',
      task: ModelTask.visionLanguage,
      capabilities: {ModelCapability.text, ModelCapability.imageInput},
      artifacts: [
        ModelArtifact(
          id: 'model',
          fileName: 'Qwen3.5-2B-Q4_K_M.gguf',
          role: ModelArtifactRole.model,
          format: ModelFormat.gguf,
          downloadUrl:
              'https://modelscope.cn/models/unsloth/Qwen3.5-2B-GGUF/resolve/master/Qwen3.5-2B-Q4_K_M.gguf',
          sizeBytes: 1280835840,
          expectedSha256:
              'aaf42c8b7c3cab2bf3d69c355048d4a0ee9973d48f16c731c0520ee914699223',
        ),
        ModelArtifact(
          id: 'projector',
          fileName: 'mmproj-F16.gguf',
          role: ModelArtifactRole.projector,
          format: ModelFormat.gguf,
          downloadUrl:
              'https://modelscope.cn/models/unsloth/Qwen3.5-2B-GGUF/resolve/master/mmproj-F16.gguf',
          sizeBytes: 668227264,
          expectedSha256:
              '7035e9cb8d7c6a9681d07eef9a364783e86ea4cd73faab2eabb4f43a101830c7',
        ),
      ],
    ),
    ModelDefinition(
      id: 'local-qwen35-4b-q4km',
      displayName: 'Qwen3.5-4B · Q4_K_M',
      family: ModelFamily.local,
      provider: 'Qwen · Unsloth quantization',
      apiFormat: ApiFormat.local,
      license: 'Apache-2.0',
      isMultimodal: true,
      sizeBytes: 2740937888,
      minimumMemoryGb: 7,
      downloadUrl:
          'https://modelscope.cn/models/unsloth/Qwen3.5-4B-GGUF/resolve/master/Qwen3.5-4B-Q4_K_M.gguf',
      sourceUrl: 'https://modelscope.cn/models/unsloth/Qwen3.5-4B-GGUF',
      expectedSha256:
          '00fe7986ff5f6b463e62455821146049db6f9313603938a70800d1fb69ef11a4',
      task: ModelTask.visionLanguage,
      capabilities: {ModelCapability.text, ModelCapability.imageInput},
      artifacts: [
        ModelArtifact(
          id: 'model',
          fileName: 'Qwen3.5-4B-Q4_K_M.gguf',
          role: ModelArtifactRole.model,
          format: ModelFormat.gguf,
          downloadUrl:
              'https://modelscope.cn/models/unsloth/Qwen3.5-4B-GGUF/resolve/master/Qwen3.5-4B-Q4_K_M.gguf',
          sizeBytes: 2740937888,
          expectedSha256:
              '00fe7986ff5f6b463e62455821146049db6f9313603938a70800d1fb69ef11a4',
        ),
        ModelArtifact(
          id: 'projector',
          fileName: 'mmproj-F16.gguf',
          role: ModelArtifactRole.projector,
          format: ModelFormat.gguf,
          downloadUrl:
              'https://modelscope.cn/models/unsloth/Qwen3.5-4B-GGUF/resolve/master/mmproj-F16.gguf',
          sizeBytes: 672423616,
          expectedSha256:
              'cd88edcf8d031894960bb0c9c5b9b7e1fea6ebee02b9f7ce925a00d12891f864',
        ),
      ],
    ),
    ModelDefinition(
      id: 'local-qwen35-9b-q4km',
      displayName: 'Qwen3.5-9B · Q4_K_M',
      family: ModelFamily.local,
      provider: 'Qwen · Unsloth quantization',
      apiFormat: ApiFormat.local,
      license: 'Apache-2.0',
      isMultimodal: true,
      sizeBytes: 5680522464,
      minimumMemoryGb: 12,
      downloadUrl:
          'https://modelscope.cn/models/unsloth/Qwen3.5-9B-GGUF/resolve/master/Qwen3.5-9B-Q4_K_M.gguf',
      sourceUrl: 'https://modelscope.cn/models/unsloth/Qwen3.5-9B-GGUF',
      expectedSha256:
          '03b74727a860a56338e042c4420bb3f04b2fec5734175f4cb9fa853daf52b7e8',
      task: ModelTask.visionLanguage,
      capabilities: {ModelCapability.text, ModelCapability.imageInput},
      artifacts: [
        ModelArtifact(
          id: 'model',
          fileName: 'Qwen3.5-9B-Q4_K_M.gguf',
          role: ModelArtifactRole.model,
          format: ModelFormat.gguf,
          downloadUrl:
              'https://modelscope.cn/models/unsloth/Qwen3.5-9B-GGUF/resolve/master/Qwen3.5-9B-Q4_K_M.gguf',
          sizeBytes: 5680522464,
          expectedSha256:
              '03b74727a860a56338e042c4420bb3f04b2fec5734175f4cb9fa853daf52b7e8',
        ),
        ModelArtifact(
          id: 'projector',
          fileName: 'mmproj-F16.gguf',
          role: ModelArtifactRole.projector,
          format: ModelFormat.gguf,
          downloadUrl:
              'https://modelscope.cn/models/unsloth/Qwen3.5-9B-GGUF/resolve/master/mmproj-F16.gguf',
          sizeBytes: 918166080,
          expectedSha256:
              'f70dc3509053962b0d0d3ee8a7eacebf5d60aa560cad78254ae8698516ae029f',
        ),
      ],
    ),
    ModelDefinition.compatibilityTarget(
      id: 'target-openpangu-20-7b',
      displayName: 'openPangu 2.0 7B',
      provider: 'Huawei openPangu',
      license: 'Official weights not published',
      task: ModelTask.chat,
      sourceUrl: 'https://www.huawei.com/cn/news/2026/7/openpangu',
    ),
    ModelDefinition.compatibilityTarget(
      id: 'target-bluelm-35-nano',
      displayName: 'BlueLM 3.5 Nano',
      provider: 'vivo AI Lab',
      license: 'Official weights not published',
      task: ModelTask.chat,
      sourceUrl: 'https://github.com/vivo-ai-lab/BlueLM',
    ),
    ModelDefinition.compatibilityTarget(
      id: 'target-mimo-3b',
      displayName: 'MiMo 3B',
      provider: 'Xiaomi MiMo',
      license: 'Official weights not published',
      task: ModelTask.chat,
      sourceUrl: 'https://mimo.mi.com/',
    ),
    ModelDefinition.compatibilityTarget(
      id: 'target-andesgpt',
      displayName: 'AndesGPT',
      provider: 'OPPO',
      license: 'Proprietary',
      task: ModelTask.chat,
      sourceUrl:
          'https://open.oppomobile.com/new/introduction?page_name=andesgpt',
    ),
    ModelDefinition(
      id: 'local-supertonic-3-onnx',
      displayName: 'Supertonic 3 · Sherpa ONNX',
      family: ModelFamily.local,
      provider: 'Supertone · sherpa-onnx FFI',
      apiFormat: ApiFormat.local,
      license: 'OpenRAIL',
      isMultimodal: false,
      sizeBytes: 398653248,
      minimumMemoryGb: 2,
      sourceUrl: 'https://modelscope.cn/models/Supertone/supertonic-3',
      task: ModelTask.speechSynthesis,
      runtime: ModelRuntime.sherpaOnnx,
      format: ModelFormat.onnx,
      capabilities: {ModelCapability.text, ModelCapability.audioOutput},
      quantization: 'ONNX FP32',
      artifacts: [
        ModelArtifact(
          id: 'durationPredictor',
          fileName: 'duration_predictor.onnx',
          role: ModelArtifactRole.model,
          format: ModelFormat.onnx,
          downloadUrl:
              'https://modelscope.cn/models/Supertone/supertonic-3/resolve/master/onnx/duration_predictor.onnx',
          sizeBytes: 3700147,
          expectedSha256:
              'c3eb91414d5ff8a7a239b7fe9e34e7e2bf8a8140d8375ffb14718b1c639325db',
        ),
        ModelArtifact(
          id: 'textEncoder',
          fileName: 'text_encoder.onnx',
          role: ModelArtifactRole.runtime,
          format: ModelFormat.onnx,
          downloadUrl:
              'https://modelscope.cn/models/Supertone/supertonic-3/resolve/master/onnx/text_encoder.onnx',
          sizeBytes: 36416150,
          expectedSha256:
              'c7befd5ea8c3119769e8a6c1486c4edc6a3bc8365c67621c881bbb774b9902ff',
        ),
        ModelArtifact(
          id: 'vectorEstimator',
          fileName: 'vector_estimator.onnx',
          role: ModelArtifactRole.runtime,
          format: ModelFormat.onnx,
          downloadUrl:
              'https://modelscope.cn/models/Supertone/supertonic-3/resolve/master/onnx/vector_estimator.onnx',
          sizeBytes: 256534781,
          expectedSha256:
              '883ac868ea0275ef0e991524dc64f16b3c0376efd7c320af6b53f5b780d7c61c',
        ),
        ModelArtifact(
          id: 'vocoder',
          fileName: 'vocoder.onnx',
          role: ModelArtifactRole.runtime,
          format: ModelFormat.onnx,
          downloadUrl:
              'https://modelscope.cn/models/Supertone/supertonic-3/resolve/master/onnx/vocoder.onnx',
          sizeBytes: 101424195,
          expectedSha256:
              '085de76dd8e8d5836d6ca66826601f615939218f90e519f70ee8a36ed2a4c4ba',
        ),
        ModelArtifact(
          id: 'ttsJson',
          fileName: 'tts.json',
          role: ModelArtifactRole.config,
          format: ModelFormat.bundle,
          downloadUrl:
              'https://modelscope.cn/models/Supertone/supertonic-3/resolve/master/onnx/tts.json',
          sizeBytes: 8253,
          expectedSha256:
              '42078d3aef1cd43ab43021f3c54f47d2d75ceb4e75f627f118890128b06a0d09',
        ),
        ModelArtifact(
          id: 'unicodeIndexer',
          fileName: 'unicode_indexer.json',
          role: ModelArtifactRole.vocabulary,
          format: ModelFormat.bundle,
          downloadUrl:
              'https://modelscope.cn/models/Supertone/supertonic-3/resolve/master/onnx/unicode_indexer.json',
          sizeBytes: 277676,
          expectedSha256:
              '9bf7346e43883a81f8645c81224f786d43c5b57f3641f6e7671a7d6c493cb24f',
        ),
        ModelArtifact(
          id: 'voiceStyle',
          fileName: 'F1.json',
          role: ModelArtifactRole.config,
          format: ModelFormat.bundle,
          downloadUrl:
              'https://modelscope.cn/models/Supertone/supertonic-3/resolve/master/voice_styles/F1.json',
          sizeBytes: 292046,
          expectedSha256:
              'bbdec6ee00231c2c742ad05483df5334cab3b52fda3ba38e6a07059c4563dbc2',
        ),
      ],
    ),
    ModelDefinition(
      id: 'local-moss-tts-nano-source',
      displayName: 'MOSS-TTS-Nano · Official weights',
      family: ModelFamily.local,
      provider: 'OpenMOSS',
      apiFormat: ApiFormat.local,
      license: 'Apache-2.0',
      isMultimodal: false,
      sizeBytes: 235312083,
      minimumMemoryGb: 3,
      sourceUrl: 'https://modelscope.cn/models/openmoss/MOSS-TTS-Nano',
      isDeviceCompatible: false,
      task: ModelTask.speechSynthesis,
      runtime: ModelRuntime.external,
      format: ModelFormat.bundle,
      capabilities: {ModelCapability.text, ModelCapability.audioOutput},
      quantization: 'PyTorch FP32',
      runtimeBundled: false,
      artifacts: [
        ModelArtifact(
          id: 'model',
          fileName: 'pytorch_model.bin',
          role: ModelArtifactRole.model,
          format: ModelFormat.bundle,
          downloadUrl:
              'https://modelscope.cn/models/openmoss/MOSS-TTS-Nano/resolve/master/pytorch_model.bin',
          sizeBytes: 234693095,
          expectedSha256:
              '24003f2f11ac8a2cbf70514db2d8f1c02fb451aa6b3c0bffc9da09f31cd7caa5',
        ),
        ModelArtifact(
          id: 'tokenizerModel',
          fileName: 'tokenizer.model',
          role: ModelArtifactRole.tokenizer,
          format: ModelFormat.bundle,
          downloadUrl:
              'https://modelscope.cn/models/openmoss/MOSS-TTS-Nano/resolve/master/tokenizer.model',
          sizeBytes: 470897,
          expectedSha256:
              'c353ee1479b536bf414c1b247f5542b6607fb8ae91320e5af1781fee200fddff',
        ),
        ModelArtifact(
          id: 'config',
          fileName: 'config.json',
          role: ModelArtifactRole.config,
          format: ModelFormat.bundle,
          downloadUrl:
              'https://modelscope.cn/models/openmoss/MOSS-TTS-Nano/resolve/master/config.json',
          sizeBytes: 5210,
          expectedSha256:
              'ba36b08c80d4ae0805a2bab32b6ac90ec0d1815d01d3854ba42811db1d5bde99',
        ),
        ModelArtifact(
          id: 'tokenizerConfig',
          fileName: 'tokenizer_config.json',
          role: ModelArtifactRole.config,
          format: ModelFormat.bundle,
          downloadUrl:
              'https://modelscope.cn/models/openmoss/MOSS-TTS-Nano/resolve/master/tokenizer_config.json',
          sizeBytes: 1140,
          expectedSha256:
              '2e00db82fd2ba8020e7263a25f31bb8ec6c5cefbfe0b5e0bbd4723ae874d1be1',
        ),
        ModelArtifact(
          id: 'specialTokens',
          fileName: 'special_tokens_map.json',
          role: ModelArtifactRole.config,
          format: ModelFormat.bundle,
          downloadUrl:
              'https://modelscope.cn/models/openmoss/MOSS-TTS-Nano/resolve/master/special_tokens_map.json',
          sizeBytes: 552,
          expectedSha256:
              '358c249e2fb29060c6b73157d428853b0c48710deffc8ee670ab1013880946c9',
        ),
        ModelArtifact(
          id: 'modelCode',
          fileName: 'modeling_moss_tts_nano.py',
          role: ModelArtifactRole.runtime,
          format: ModelFormat.bundle,
          downloadUrl:
              'https://modelscope.cn/models/openmoss/MOSS-TTS-Nano/resolve/master/modeling_moss_tts_nano.py',
          sizeBytes: 110984,
          expectedSha256:
              'b68ffef1173eb39625dc9321f4ca4bfb7644dff54463e08df348e045b8cb5e04',
        ),
        ModelArtifact(
          id: 'decoderCode',
          fileName: 'gpt2_decoder.py',
          role: ModelArtifactRole.runtime,
          format: ModelFormat.bundle,
          downloadUrl:
              'https://modelscope.cn/models/openmoss/MOSS-TTS-Nano/resolve/master/gpt2_decoder.py',
          sizeBytes: 26647,
          expectedSha256:
              'cee01966c5eeeb8f84b83c7a197615b2d7fa876118992dae8a8f851688d868d7',
        ),
        ModelArtifact(
          id: 'tokenizerCode',
          fileName: 'tokenization_moss_tts_nano.py',
          role: ModelArtifactRole.runtime,
          format: ModelFormat.bundle,
          downloadUrl:
              'https://modelscope.cn/models/openmoss/MOSS-TTS-Nano/resolve/master/tokenization_moss_tts_nano.py',
          sizeBytes: 3558,
          expectedSha256:
              '22872a5cf91aaefcd93b2563a25f31bb8ec4c8da8f1efd670cbe4710474a6cd',
        ),
      ],
    ),
    ModelDefinition.compatibilityTarget(
      id: 'target-soprano-11-80m',
      displayName: 'Soprano-1.1-80M',
      provider: 'Soprano',
      license: 'See official repository',
      task: ModelTask.speechSynthesis,
      sourceUrl: 'https://github.com/ekwek1/soprano',
      capabilities: {ModelCapability.text, ModelCapability.audioOutput},
    ),
    ModelDefinition.compatibilityTarget(
      id: 'target-qwen35-tts',
      displayName: 'Qwen3.5-TTS',
      provider: 'Qwen',
      license: 'Official weights not published',
      task: ModelTask.speechSynthesis,
      sourceUrl: 'https://qwen.ai/',
      capabilities: {ModelCapability.text, ModelCapability.audioOutput},
    ),
    ModelDefinition.compatibilityTarget(
      id: 'target-pangu-tts',
      displayName: 'Pangu-TTS',
      provider: 'Huawei Pangu',
      license: 'Proprietary',
      task: ModelTask.speechSynthesis,
      sourceUrl: 'https://www.huaweicloud.com/product/pangu.html',
      capabilities: {ModelCapability.text, ModelCapability.audioOutput},
    ),
    ModelDefinition(
      id: 'local-qwen3-asr-17b-source',
      displayName: 'Qwen3-ASR-1.7B · Official weights',
      family: ModelFamily.local,
      provider: 'Qwen',
      apiFormat: ApiFormat.local,
      license: 'Apache-2.0',
      isMultimodal: false,
      sizeBytes: 4705379039,
      minimumMemoryGb: 10,
      sourceUrl: 'https://modelscope.cn/models/Qwen/Qwen3-ASR-1.7B',
      isDeviceCompatible: false,
      task: ModelTask.speechRecognition,
      runtime: ModelRuntime.external,
      format: ModelFormat.safetensors,
      capabilities: {ModelCapability.audioInput, ModelCapability.text},
      quantization: 'BF16',
      runtimeBundled: false,
      artifacts: [
        ModelArtifact(
          id: 'model',
          fileName: 'model-00001-of-00002.safetensors',
          role: ModelArtifactRole.model,
          format: ModelFormat.safetensors,
          downloadUrl:
              'https://modelscope.cn/models/Qwen/Qwen3-ASR-1.7B/resolve/master/model-00001-of-00002.safetensors',
          sizeBytes: 4220320824,
          expectedSha256:
              'a4cd1f1a04d90b757dc7f7dd26254e69a013b19e80efe590a83c6a3bde8608d6',
        ),
        ModelArtifact(
          id: 'model2',
          fileName: 'model-00002-of-00002.safetensors',
          role: ModelArtifactRole.runtime,
          format: ModelFormat.safetensors,
          downloadUrl:
              'https://modelscope.cn/models/Qwen/Qwen3-ASR-1.7B/resolve/master/model-00002-of-00002.safetensors',
          sizeBytes: 478200688,
          expectedSha256:
              '6e0b9d9e09e2e0238e7ef3cc8a484ab387e91b90f1900bedf88bc92d7929ccfc',
        ),
        ModelArtifact(
          id: 'vocab',
          fileName: 'vocab.json',
          role: ModelArtifactRole.vocabulary,
          format: ModelFormat.bundle,
          downloadUrl:
              'https://modelscope.cn/models/Qwen/Qwen3-ASR-1.7B/resolve/master/vocab.json',
          sizeBytes: 2776833,
          expectedSha256:
              'ca10d7e9fb3ed18575dd1e277a2579c16d108e32f27439684afa0e10b1440910',
        ),
        ModelArtifact(
          id: 'merges',
          fileName: 'merges.txt',
          role: ModelArtifactRole.tokenizer,
          format: ModelFormat.bundle,
          downloadUrl:
              'https://modelscope.cn/models/Qwen/Qwen3-ASR-1.7B/resolve/master/merges.txt',
          sizeBytes: 1671853,
          expectedSha256:
              '8831e4f1a044471340f7c0a83d7bd71306a5b867e95fd870f74d0c5308a904d5',
        ),
        ModelArtifact(
          id: 'index',
          fileName: 'model.safetensors.index.json',
          role: ModelArtifactRole.config,
          format: ModelFormat.bundle,
          downloadUrl:
              'https://modelscope.cn/models/Qwen/Qwen3-ASR-1.7B/resolve/master/model.safetensors.index.json',
          sizeBytes: 64821,
          expectedSha256:
              'f994739fe38e5210b9e3e8ce6c6307315e2ceac3cb630e7b7414d69dce520f60',
        ),
        ModelArtifact(
          id: 'config',
          fileName: 'config.json',
          role: ModelArtifactRole.config,
          format: ModelFormat.bundle,
          downloadUrl:
              'https://modelscope.cn/models/Qwen/Qwen3-ASR-1.7B/resolve/master/config.json',
          sizeBytes: 6194,
          expectedSha256:
              '2e74a751548b8ad7d7526d29365ad8144c345d8b412b1152d25dc6698452712f',
        ),
        ModelArtifact(
          id: 'tokenizerConfig',
          fileName: 'tokenizer_config.json',
          role: ModelArtifactRole.config,
          format: ModelFormat.bundle,
          downloadUrl:
              'https://modelscope.cn/models/Qwen/Qwen3-ASR-1.7B/resolve/master/tokenizer_config.json',
          sizeBytes: 12487,
          expectedSha256:
              '4942d005604266809309cabc9f4e9cb89ce855d59b14681fdc0e1cc62ea26c4c',
        ),
        ModelArtifact(
          id: 'preprocessor',
          fileName: 'preprocessor_config.json',
          role: ModelArtifactRole.config,
          format: ModelFormat.bundle,
          downloadUrl:
              'https://modelscope.cn/models/Qwen/Qwen3-ASR-1.7B/resolve/master/preprocessor_config.json',
          sizeBytes: 330,
          expectedSha256:
              '45e120a4eda2c20c5d7f2ea9354e63536bf35e27aa573fb7cdf78017b378770d',
        ),
      ],
    ),
    ModelDefinition.compatibilityTarget(
      id: 'target-qwen35-asr',
      displayName: 'Qwen3.5-ASR',
      provider: 'Qwen',
      license: 'Official weights not published',
      task: ModelTask.speechRecognition,
      sourceUrl: 'https://qwen.ai/',
      capabilities: {ModelCapability.audioInput, ModelCapability.text},
    ),
    ModelDefinition.compatibilityTarget(
      id: 'target-octo-asr',
      displayName: 'OctoASR',
      provider: 'Unverified publisher',
      license: 'Official model card unavailable',
      task: ModelTask.speechRecognition,
      sourceUrl: 'https://modelscope.cn/models?name=OctoASR',
      capabilities: {ModelCapability.audioInput, ModelCapability.text},
    ),
    ModelDefinition.compatibilityTarget(
      id: 'target-moonshine-asr',
      displayName: 'Moonshine',
      provider: 'Moonshine AI',
      license: 'MIT',
      task: ModelTask.speechRecognition,
      sourceUrl: 'https://github.com/moonshine-ai/moonshine',
      capabilities: {ModelCapability.audioInput, ModelCapability.text},
    ),
    ModelDefinition.compatibilityTarget(
      id: 'target-pangu-asr',
      displayName: 'Pangu-ASR',
      provider: 'Huawei Pangu',
      license: 'Proprietary',
      task: ModelTask.speechRecognition,
      sourceUrl: 'https://www.huaweicloud.com/product/pangu.html',
      capabilities: {ModelCapability.audioInput, ModelCapability.text},
    ),
    ModelDefinition.compatibilityTarget(
      id: 'target-pp-ocrv6-tiny',
      displayName: 'PP-OCRv6 Tiny',
      provider: 'PaddlePaddle',
      license: 'Apache-2.0',
      task: ModelTask.opticalCharacterRecognition,
      sourceUrl:
          'https://www.paddleocr.ai/main/version3.x/algorithm/PP-OCRv6/PP-OCRv6.html',
      capabilities: {ModelCapability.imageInput, ModelCapability.text},
      isMultimodal: true,
    ),
    ModelDefinition.compatibilityTarget(
      id: 'target-xcuros-ocr',
      displayName: 'XCurOS-OCR',
      provider: 'Unverified publisher',
      license: 'Official model card unavailable',
      task: ModelTask.opticalCharacterRecognition,
      sourceUrl: 'https://modelscope.cn/models?name=XCurOS-OCR',
      capabilities: {ModelCapability.imageInput, ModelCapability.text},
      isMultimodal: true,
    ),
    ModelDefinition(
      id: 'local-glm-ocr-source',
      displayName: 'GLM-OCR · Official weights',
      family: ModelFamily.local,
      provider: 'Zhipu AI',
      apiFormat: ApiFormat.local,
      license: 'MIT',
      isMultimodal: true,
      sizeBytes: 2657437653,
      minimumMemoryGb: 7,
      sourceUrl: 'https://modelscope.cn/models/ZhipuAI/GLM-OCR',
      isDeviceCompatible: false,
      task: ModelTask.opticalCharacterRecognition,
      runtime: ModelRuntime.external,
      format: ModelFormat.safetensors,
      capabilities: {ModelCapability.imageInput, ModelCapability.text},
      quantization: 'BF16',
      runtimeBundled: false,
      artifacts: [
        ModelArtifact(
          id: 'model',
          fileName: 'model.safetensors',
          role: ModelArtifactRole.model,
          format: ModelFormat.safetensors,
          downloadUrl:
              'https://modelscope.cn/models/ZhipuAI/GLM-OCR/resolve/master/model.safetensors',
          sizeBytes: 2650579464,
          expectedSha256:
              'a16eb0de98d199293371c560f95f83130d2a2c9612449df16839f08ff9498815',
        ),
        ModelArtifact(
          id: 'tokenizer',
          fileName: 'tokenizer.json',
          role: ModelArtifactRole.tokenizer,
          format: ModelFormat.bundle,
          downloadUrl:
              'https://modelscope.cn/models/ZhipuAI/GLM-OCR/resolve/master/tokenizer.json',
          sizeBytes: 6838609,
          expectedSha256:
              'aa0fd058c73a5718bb191f6672dc16d122ee0147b20c123d1726514298f9968a',
        ),
        ModelArtifact(
          id: 'config',
          fileName: 'config.json',
          role: ModelArtifactRole.config,
          format: ModelFormat.bundle,
          downloadUrl:
              'https://modelscope.cn/models/ZhipuAI/GLM-OCR/resolve/master/config.json',
          sizeBytes: 1570,
          expectedSha256:
              '4e1daf0d8a3f63e58960ac14bcb58b7be96758cad231fb7a1e5fec60f42dcd8c',
        ),
        ModelArtifact(
          id: 'preprocessor',
          fileName: 'preprocessor_config.json',
          role: ModelArtifactRole.config,
          format: ModelFormat.bundle,
          downloadUrl:
              'https://modelscope.cn/models/ZhipuAI/GLM-OCR/resolve/master/preprocessor_config.json',
          sizeBytes: 367,
          expectedSha256:
              '02cc50c36240882ae35e8cd4077a25a379664108185d728d261cb785aefeccff',
        ),
        ModelArtifact(
          id: 'tokenizerConfig',
          fileName: 'tokenizer_config.json',
          role: ModelArtifactRole.config,
          format: ModelFormat.bundle,
          downloadUrl:
              'https://modelscope.cn/models/ZhipuAI/GLM-OCR/resolve/master/tokenizer_config.json',
          sizeBytes: 1066,
          expectedSha256:
              '23404f517abeb2893f1c175c6d7c539f733f6fca287414a2ce9ab569d99a1c06',
        ),
        ModelArtifact(
          id: 'generationConfig',
          fileName: 'generation_config.json',
          role: ModelArtifactRole.config,
          format: ModelFormat.bundle,
          downloadUrl:
              'https://modelscope.cn/models/ZhipuAI/GLM-OCR/resolve/master/generation_config.json',
          sizeBytes: 165,
          expectedSha256:
              '6e2a3412f65e72118facff437e03f2e24a23311e3bdeb2368973fe77e5f275c',
        ),
        ModelArtifact(
          id: 'chatTemplate',
          fileName: 'chat_template.jinja',
          role: ModelArtifactRole.config,
          format: ModelFormat.bundle,
          downloadUrl:
              'https://modelscope.cn/models/ZhipuAI/GLM-OCR/resolve/master/chat_template.jinja',
          sizeBytes: 4606,
          expectedSha256:
              '062e7ee4cc8defa88a5938b5d456dc60366ffd80647f918946ee747bf09ddc7c',
        ),
      ],
    ),
    ModelDefinition.compatibilityTarget(
      id: 'target-qwen35-vision-ocr',
      displayName: 'Qwen3.5-Vision · Reuse chat model',
      provider: 'Qwen · llama.cpp FFI',
      license: 'Apache-2.0',
      task: ModelTask.opticalCharacterRecognition,
      sourceUrl: 'https://modelscope.cn/models/Qwen',
      capabilities: {ModelCapability.imageInput, ModelCapability.text},
      isMultimodal: true,
      blockReason: 'reuse-installed-qwen35-vision-model',
    ),
    ModelDefinition.compatibilityTarget(
      id: 'target-pangu-vision',
      displayName: 'Pangu-Vision',
      provider: 'Huawei Pangu',
      license: 'Proprietary',
      task: ModelTask.opticalCharacterRecognition,
      sourceUrl: 'https://www.huaweicloud.com/product/pangu.html',
      capabilities: {ModelCapability.imageInput, ModelCapability.text},
      isMultimodal: true,
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
