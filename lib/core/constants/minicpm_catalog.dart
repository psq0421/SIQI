import '../models/app_models.dart';

/// Official ModelScope files, sizes and SHA-256 verified on 2026-10-13.
/// Runtime availability is deliberately separate from download availability.
abstract final class MiniCpmCatalog {
  static const models = <ModelDefinition>[
    ModelDefinition(
      id: 'local-minicpm5-1b-q4km',
      displayName: 'MiniCPM5 1B · Q4_K_M',
      family: ModelFamily.local,
      provider: 'OpenBMB',
      apiFormat: ApiFormat.local,
      license: 'Apache-2.0',
      isMultimodal: false,
      sizeBytes: 688065920,
      sourceUrl: 'https://modelscope.cn/models/OpenBMB/MiniCPM5-1B-GGUF',
      downloadUrl:
          'https://modelscope.cn/models/OpenBMB/MiniCPM5-1B-GGUF/resolve/master/MiniCPM5-1B-Q4_K_M.gguf',
      expectedSha256:
          '81b64d05a23b17b34c475f42b3e72fbde62d4b92cc34541f7a8031d0752deafa',
      task: ModelTask.chat,
      runtimeBundled: true,
      quantization: 'Q4_K_M',
      capabilities: {ModelCapability.text},
      artifacts: [
        ModelArtifact(
          id: 'model',
          fileName: 'MiniCPM5-1B-Q4_K_M.gguf',
          role: ModelArtifactRole.model,
          format: ModelFormat.gguf,
          downloadUrl:
              'https://modelscope.cn/models/OpenBMB/MiniCPM5-1B-GGUF/resolve/master/MiniCPM5-1B-Q4_K_M.gguf',
          sizeBytes: 688065920,
          expectedSha256:
              '81b64d05a23b17b34c475f42b3e72fbde62d4b92cc34541f7a8031d0752deafa',
        ),
      ],
    ),
    ModelDefinition(
      id: 'local-minicpm5-2b-q4km',
      displayName: 'MiniCPM5 2B · Q4_K_M',
      family: ModelFamily.local,
      provider: 'OpenBMB',
      apiFormat: ApiFormat.local,
      license: 'Apache-2.0',
      isMultimodal: false,
      sizeBytes: 1561318368,
      sourceUrl: 'https://modelscope.cn/models/OpenBMB/MiniCPM5-2B-GGUF',
      downloadUrl:
          'https://modelscope.cn/models/OpenBMB/MiniCPM5-2B-GGUF/resolve/master/MiniCPM5-2B-Q4_K_M.gguf',
      expectedSha256:
          'ec2d5801640099e97d8d7e8003ad4d81f336e757811f03a26173dddf386602fd',
      task: ModelTask.chat,
      runtimeBundled: true,
      quantization: 'Q4_K_M',
      capabilities: {ModelCapability.text},
      artifacts: [
        ModelArtifact(
          id: 'model',
          fileName: 'MiniCPM5-2B-Q4_K_M.gguf',
          role: ModelArtifactRole.model,
          format: ModelFormat.gguf,
          downloadUrl:
              'https://modelscope.cn/models/OpenBMB/MiniCPM5-2B-GGUF/resolve/master/MiniCPM5-2B-Q4_K_M.gguf',
          sizeBytes: 1561318368,
          expectedSha256:
              'ec2d5801640099e97d8d7e8003ad4d81f336e757811f03a26173dddf386602fd',
        ),
      ],
    ),
    ModelDefinition(
      id: 'local-minicpm3-4b-q4km',
      displayName: 'MiniCPM3 4B · Q4_K_M',
      family: ModelFamily.local,
      provider: 'OpenBMB',
      apiFormat: ApiFormat.local,
      license: 'MiniCPM Model License (weights); Apache-2.0 (code)',
      isMultimodal: false,
      sizeBytes: 2469791584,
      sourceUrl: 'https://modelscope.cn/models/OpenBMB/MiniCPM3-4B-GGUF',
      downloadUrl:
          'https://modelscope.cn/models/OpenBMB/MiniCPM3-4B-GGUF/resolve/master/minicpm3-4b-q4_k_m.gguf',
      expectedSha256:
          '64913247e927414ecf47fd3e9ea8e3f0c9acae293f583dfa7e24b8872e20fa4c',
      task: ModelTask.chat,
      runtimeBundled: true,
      quantization: 'Q4_K_M',
      capabilities: {ModelCapability.text},
      artifacts: [
        ModelArtifact(
          id: 'model',
          fileName: 'minicpm3-4b-q4_k_m.gguf',
          role: ModelArtifactRole.model,
          format: ModelFormat.gguf,
          downloadUrl:
              'https://modelscope.cn/models/OpenBMB/MiniCPM3-4B-GGUF/resolve/master/minicpm3-4b-q4_k_m.gguf',
          sizeBytes: 2469791584,
          expectedSha256:
              '64913247e927414ecf47fd3e9ea8e3f0c9acae293f583dfa7e24b8872e20fa4c',
        ),
      ],
    ),
    ModelDefinition(
      id: 'local-minicpm4-8b-q4km',
      displayName: 'MiniCPM4 8B · Q4_K_M',
      family: ModelFamily.local,
      provider: 'OpenBMB',
      apiFormat: ApiFormat.local,
      license: 'Apache-2.0',
      isMultimodal: false,
      sizeBytes: 4965526048,
      sourceUrl: 'https://modelscope.cn/models/OpenBMB/MiniCPM4-8B-GGUF',
      downloadUrl:
          'https://modelscope.cn/models/OpenBMB/MiniCPM4-8B-GGUF/resolve/master/MiniCPM4-8B-Q4_K_M.gguf',
      expectedSha256:
          '80b99ec4ceac302e7d474c8659e96b9f6c3bbeb73c41b2ef841c7fcb6d8250f3',
      task: ModelTask.chat,
      runtimeBundled: true,
      quantization: 'Q4_K_M',
      capabilities: {ModelCapability.text},
      artifacts: [
        ModelArtifact(
          id: 'model',
          fileName: 'MiniCPM4-8B-Q4_K_M.gguf',
          role: ModelArtifactRole.model,
          format: ModelFormat.gguf,
          downloadUrl:
              'https://modelscope.cn/models/OpenBMB/MiniCPM4-8B-GGUF/resolve/master/MiniCPM4-8B-Q4_K_M.gguf',
          sizeBytes: 4965526048,
          expectedSha256:
              '80b99ec4ceac302e7d474c8659e96b9f6c3bbeb73c41b2ef841c7fcb6d8250f3',
        ),
      ],
    ),
    ModelDefinition(
      id: 'local-minicpm41-8b-q4km',
      displayName: 'MiniCPM4.1 8B · Q4_K_M',
      family: ModelFamily.local,
      provider: 'OpenBMB',
      apiFormat: ApiFormat.local,
      license: 'Apache-2.0',
      isMultimodal: false,
      sizeBytes: 4965526048,
      sourceUrl: 'https://modelscope.cn/models/OpenBMB/MiniCPM4.1-8B-GGUF',
      downloadUrl:
          'https://modelscope.cn/models/OpenBMB/MiniCPM4.1-8B-GGUF/resolve/master/MiniCPM4.1-8B-Q4_K_M.gguf',
      expectedSha256:
          '9d2ffb9145bf7a88ddb94b2542b42d925293666c42962aa158eeb62fc9708654',
      task: ModelTask.chat,
      runtimeBundled: false,
      quantization: 'Q4_K_M',
      capabilities: {ModelCapability.text},
      artifacts: [
        ModelArtifact(
          id: 'model',
          fileName: 'MiniCPM4.1-8B-Q4_K_M.gguf',
          role: ModelArtifactRole.model,
          format: ModelFormat.gguf,
          downloadUrl:
              'https://modelscope.cn/models/OpenBMB/MiniCPM4.1-8B-GGUF/resolve/master/MiniCPM4.1-8B-Q4_K_M.gguf',
          sizeBytes: 4965526048,
          expectedSha256:
              '9d2ffb9145bf7a88ddb94b2542b42d925293666c42962aa158eeb62fc9708654',
        ),
      ],
    ),
    ModelDefinition(
      id: 'local-minicpmv26-q4km',
      displayName: 'MiniCPM-V 2.6 · Q4_K_M',
      family: ModelFamily.local,
      provider: 'OpenBMB',
      apiFormat: ApiFormat.local,
      license: 'MiniCPM Model License (weights); Apache-2.0 (code)',
      isMultimodal: true,
      sizeBytes: 4681089344,
      sourceUrl: 'https://modelscope.cn/models/OpenBMB/MiniCPM-V-2_6-gguf',
      downloadUrl:
          'https://modelscope.cn/models/OpenBMB/MiniCPM-V-2_6-gguf/resolve/master/ggml-model-Q4_K_M.gguf',
      expectedSha256:
          '3a4078d53b46f22989adbf998ce5a3fd090b6541f112d7e936eb4204a04100b1',
      task: ModelTask.visionLanguage,
      runtimeBundled: true,
      quantization: 'Q4_K_M',
      capabilities: {ModelCapability.text, ModelCapability.imageInput},
      artifacts: [
        ModelArtifact(
          id: 'model',
          fileName: 'ggml-model-Q4_K_M.gguf',
          role: ModelArtifactRole.model,
          format: ModelFormat.gguf,
          downloadUrl:
              'https://modelscope.cn/models/OpenBMB/MiniCPM-V-2_6-gguf/resolve/master/ggml-model-Q4_K_M.gguf',
          sizeBytes: 4681089344,
          expectedSha256:
              '3a4078d53b46f22989adbf998ce5a3fd090b6541f112d7e936eb4204a04100b1',
        ),
        ModelArtifact(
          id: 'projector',
          fileName: 'mmproj-model-f16.gguf',
          role: ModelArtifactRole.projector,
          format: ModelFormat.gguf,
          downloadUrl:
              'https://modelscope.cn/models/OpenBMB/MiniCPM-V-2_6-gguf/resolve/master/mmproj-model-f16.gguf',
          sizeBytes: 1044425152,
          expectedSha256:
              '4485f68a0f1aa404c391e788ea88ea653c100d8e98fe572698f701e5809711fd',
        ),
      ],
    ),
    ModelDefinition(
      id: 'local-minicpmv4-q4km',
      displayName: 'MiniCPM-V 4.0 · Q4_K_M',
      family: ModelFamily.local,
      provider: 'OpenBMB',
      apiFormat: ApiFormat.local,
      license: 'MiniCPM Model License (weights); Apache-2.0 (code)',
      isMultimodal: true,
      sizeBytes: 2189861216,
      sourceUrl: 'https://modelscope.cn/models/OpenBMB/MiniCPM-V-4-gguf',
      downloadUrl:
          'https://modelscope.cn/models/OpenBMB/MiniCPM-V-4-gguf/resolve/master/ggml-model-Q4_K_M.gguf',
      expectedSha256:
          'b0ff610e9c92b30389ff1e0dd40fffed3c1f02a9d34a735fd5fba6a5ad25672b',
      task: ModelTask.visionLanguage,
      runtimeBundled: true,
      quantization: 'Q4_K_M',
      capabilities: {ModelCapability.text, ModelCapability.imageInput},
      artifacts: [
        ModelArtifact(
          id: 'model',
          fileName: 'ggml-model-Q4_K_M.gguf',
          role: ModelArtifactRole.model,
          format: ModelFormat.gguf,
          downloadUrl:
              'https://modelscope.cn/models/OpenBMB/MiniCPM-V-4-gguf/resolve/master/ggml-model-Q4_K_M.gguf',
          sizeBytes: 2189861216,
          expectedSha256:
              'b0ff610e9c92b30389ff1e0dd40fffed3c1f02a9d34a735fd5fba6a5ad25672b',
        ),
        ModelArtifact(
          id: 'projector',
          fileName: 'mmproj-model-f16.gguf',
          role: ModelArtifactRole.projector,
          format: ModelFormat.gguf,
          downloadUrl:
              'https://modelscope.cn/models/OpenBMB/MiniCPM-V-4-gguf/resolve/master/mmproj-model-f16.gguf',
          sizeBytes: 958777792,
          expectedSha256:
              'f0faa9ae63532300999c86a196f140c716cd0fbb08bbbd81850f1f9a631f7761',
        ),
      ],
    ),
    ModelDefinition(
      id: 'local-minicpmv45-q4km',
      displayName: 'MiniCPM-V 4.5 · Q4_K_M',
      family: ModelFamily.local,
      provider: 'OpenBMB',
      apiFormat: ApiFormat.local,
      license: 'MiniCPM Model License (weights); Apache-2.0 (code)',
      isMultimodal: true,
      sizeBytes: 5026714304,
      sourceUrl: 'https://modelscope.cn/models/OpenBMB/MiniCPM-V-4_5-gguf',
      downloadUrl:
          'https://modelscope.cn/models/OpenBMB/MiniCPM-V-4_5-gguf/resolve/master/MiniCPM-V-4_5-Q4_K_M.gguf',
      expectedSha256:
          'c1c3c33100b15b4caf7319acce4e23c0eb0ce1cbd12f70e8d24f05aa67b7512f',
      task: ModelTask.visionLanguage,
      runtimeBundled: true,
      quantization: 'Q4_K_M',
      capabilities: {ModelCapability.text, ModelCapability.imageInput},
      artifacts: [
        ModelArtifact(
          id: 'model',
          fileName: 'MiniCPM-V-4_5-Q4_K_M.gguf',
          role: ModelArtifactRole.model,
          format: ModelFormat.gguf,
          downloadUrl:
              'https://modelscope.cn/models/OpenBMB/MiniCPM-V-4_5-gguf/resolve/master/MiniCPM-V-4_5-Q4_K_M.gguf',
          sizeBytes: 5026714304,
          expectedSha256:
              'c1c3c33100b15b4caf7319acce4e23c0eb0ce1cbd12f70e8d24f05aa67b7512f',
        ),
        ModelArtifact(
          id: 'projector',
          fileName: 'mmproj-model-f16.gguf',
          role: ModelArtifactRole.projector,
          format: ModelFormat.gguf,
          downloadUrl:
              'https://modelscope.cn/models/OpenBMB/MiniCPM-V-4_5-gguf/resolve/master/mmproj-model-f16.gguf',
          sizeBytes: 1095113184,
          expectedSha256:
              '7a7225a32e8d453aaa3d22d8c579b5bf833c253f784cdb05c99c9a76fd616df8',
        ),
      ],
    ),
    ModelDefinition(
      id: 'local-minicpmv46-q4km',
      displayName: 'MiniCPM-V 4.6 · Q4_K_M',
      family: ModelFamily.local,
      provider: 'OpenBMB',
      apiFormat: ApiFormat.local,
      license: 'Apache-2.0',
      isMultimodal: true,
      sizeBytes: 529101504,
      sourceUrl: 'https://modelscope.cn/models/OpenBMB/MiniCPM-V-4.6-gguf',
      downloadUrl:
          'https://modelscope.cn/models/OpenBMB/MiniCPM-V-4.6-gguf/resolve/master/MiniCPM-V-4_6-Q4_K_M.gguf',
      expectedSha256:
          '6b0c74962c44bc6bf4b655b9b02c13eda9d5a0491543ae976d1ac18e4b7892e2',
      task: ModelTask.visionLanguage,
      runtimeBundled: true,
      quantization: 'Q4_K_M',
      capabilities: {ModelCapability.text, ModelCapability.imageInput},
      artifacts: [
        ModelArtifact(
          id: 'model',
          fileName: 'MiniCPM-V-4_6-Q4_K_M.gguf',
          role: ModelArtifactRole.model,
          format: ModelFormat.gguf,
          downloadUrl:
              'https://modelscope.cn/models/OpenBMB/MiniCPM-V-4.6-gguf/resolve/master/MiniCPM-V-4_6-Q4_K_M.gguf',
          sizeBytes: 529101504,
          expectedSha256:
              '6b0c74962c44bc6bf4b655b9b02c13eda9d5a0491543ae976d1ac18e4b7892e2',
        ),
        ModelArtifact(
          id: 'projector',
          fileName: 'mmproj-model-f16.gguf',
          role: ModelArtifactRole.projector,
          format: ModelFormat.gguf,
          downloadUrl:
              'https://modelscope.cn/models/OpenBMB/MiniCPM-V-4.6-gguf/resolve/master/mmproj-model-f16.gguf',
          sizeBytes: 1108746944,
          expectedSha256:
              'ca931d861d0801d9003e50697cd764721a334107c0e0415a51168ee1938462de',
        ),
      ],
    ),
    ModelDefinition(
      id: 'local-minicpmv47-1b-q4km',
      displayName: 'MiniCPM-V 4.7 1B · Q4_K_M',
      family: ModelFamily.local,
      provider: 'OpenBMB',
      apiFormat: ApiFormat.local,
      license: 'Apache-2.0',
      isMultimodal: true,
      sizeBytes: 672003680,
      sourceUrl: 'https://modelscope.cn/models/OpenBMB/MiniCPM-V-4.7-1B-GGUF',
      downloadUrl:
          'https://modelscope.cn/models/OpenBMB/MiniCPM-V-4.7-1B-GGUF/resolve/master/MiniCPM-V-4_7-1B-Q4_K_M.gguf',
      expectedSha256:
          '588c6c94c82f756b86dba35c42ed9ba9ec187d65824eb52f039c347df563e63d',
      task: ModelTask.visionLanguage,
      runtimeBundled: false,
      quantization: 'Q4_K_M',
      capabilities: {ModelCapability.text, ModelCapability.imageInput},
      artifacts: [
        ModelArtifact(
          id: 'model',
          fileName: 'MiniCPM-V-4_7-1B-Q4_K_M.gguf',
          role: ModelArtifactRole.model,
          format: ModelFormat.gguf,
          downloadUrl:
              'https://modelscope.cn/models/OpenBMB/MiniCPM-V-4.7-1B-GGUF/resolve/master/MiniCPM-V-4_7-1B-Q4_K_M.gguf',
          sizeBytes: 672003680,
          expectedSha256:
              '588c6c94c82f756b86dba35c42ed9ba9ec187d65824eb52f039c347df563e63d',
        ),
        ModelArtifact(
          id: 'projector',
          fileName: 'mmproj-model-f16.gguf',
          role: ModelArtifactRole.projector,
          format: ModelFormat.gguf,
          downloadUrl:
              'https://modelscope.cn/models/OpenBMB/MiniCPM-V-4.7-1B-GGUF/resolve/master/mmproj-model-f16.gguf',
          sizeBytes: 1110117984,
          expectedSha256:
              'fb9cc047a3cdad5317fd8433a4aeda2d22f00f02ca4bd93b34ad84165b25a900',
        ),
      ],
    ),
    ModelDefinition(
      id: 'local-minicpmv47-35b-mixq3',
      displayName: 'MiniCPM-V 4.7 35B-A3B · mix_q3gud_im',
      family: ModelFamily.local,
      provider: 'OpenBMB',
      apiFormat: ApiFormat.local,
      license: 'Apache-2.0',
      isMultimodal: !bool.fromEnvironment('SIQI_LES_RUNTIME'),
      sizeBytes: 15503944896,
      sourceUrl:
          'https://modelscope.cn/models/OpenBMB/MiniCPM-V-4.7-35B-A3B-GGUF',
      downloadUrl:
          'https://modelscope.cn/models/OpenBMB/MiniCPM-V-4.7-35B-A3B-GGUF/resolve/master/MiniCPM-V-4_7-35B-A3B-mix_q3gud_im.gguf',
      expectedSha256:
          '51e32201f0ddaf87dbb9689ceef9e3aa1a1543a1366706aa2abbf3aabb34df6b',
      memoryBudgetBytes: 5000000000,
      runtimeProfile: 'minicpm-v47-35b-les',
      task: ModelTask.visionLanguage,
      runtimeBundled: bool.fromEnvironment('SIQI_LES_RUNTIME'),
      quantization: 'mix_q3gud_im',
      capabilities: bool.fromEnvironment('SIQI_LES_RUNTIME')
          ? {ModelCapability.text}
          : {ModelCapability.text, ModelCapability.imageInput},
      artifacts: [
        ModelArtifact(
          id: 'model',
          fileName: 'MiniCPM-V-4_7-35B-A3B-mix_q3gud_im.gguf',
          role: ModelArtifactRole.model,
          format: ModelFormat.gguf,
          downloadUrl:
              'https://modelscope.cn/models/OpenBMB/MiniCPM-V-4.7-35B-A3B-GGUF/resolve/master/MiniCPM-V-4_7-35B-A3B-mix_q3gud_im.gguf',
          sizeBytes: 15503944896,
          expectedSha256:
              '51e32201f0ddaf87dbb9689ceef9e3aa1a1543a1366706aa2abbf3aabb34df6b',
        ),
        ModelArtifact(
          id: 'projector',
          fileName: 'mmproj-model-f16.gguf',
          role: ModelArtifactRole.projector,
          format: ModelFormat.gguf,
          downloadUrl:
              'https://modelscope.cn/models/OpenBMB/MiniCPM-V-4.7-35B-A3B-GGUF/resolve/master/mmproj-model-f16.gguf',
          sizeBytes: 1119575840,
          expectedSha256:
              'bff3b688e14c300eca273092c37c50a0ddfcc2054e079af1a0480edeed5d20f1',
        ),
      ],
    ),
    ModelDefinition(
      id: 'local-minicpmv47-35b-q4km',
      displayName: 'MiniCPM-V 4.7 35B-A3B · Q4_K_M',
      family: ModelFamily.local,
      provider: 'OpenBMB',
      apiFormat: ApiFormat.local,
      license: 'Apache-2.0',
      isMultimodal: true,
      sizeBytes: 21166255008,
      sourceUrl:
          'https://modelscope.cn/models/OpenBMB/MiniCPM-V-4.7-35B-A3B-GGUF',
      downloadUrl:
          'https://modelscope.cn/models/OpenBMB/MiniCPM-V-4.7-35B-A3B-GGUF/resolve/master/MiniCPM-V-4_7-35B-A3B-Q4_K_M.gguf',
      expectedSha256:
          'bf3d1c67f7843193e4483aebd26c5dea6b6d1f6a06ffa03c2387a6f3cc6d7df5',
      memoryBudgetBytes: 5000000000,
      runtimeProfile: 'minicpm-v47-35b-les',
      task: ModelTask.visionLanguage,
      runtimeBundled: false,
      quantization: 'Q4_K_M',
      capabilities: {ModelCapability.text, ModelCapability.imageInput},
      artifacts: [
        ModelArtifact(
          id: 'model',
          fileName: 'MiniCPM-V-4_7-35B-A3B-Q4_K_M.gguf',
          role: ModelArtifactRole.model,
          format: ModelFormat.gguf,
          downloadUrl:
              'https://modelscope.cn/models/OpenBMB/MiniCPM-V-4.7-35B-A3B-GGUF/resolve/master/MiniCPM-V-4_7-35B-A3B-Q4_K_M.gguf',
          sizeBytes: 21166255008,
          expectedSha256:
              'bf3d1c67f7843193e4483aebd26c5dea6b6d1f6a06ffa03c2387a6f3cc6d7df5',
        ),
        ModelArtifact(
          id: 'projector',
          fileName: 'mmproj-model-f16.gguf',
          role: ModelArtifactRole.projector,
          format: ModelFormat.gguf,
          downloadUrl:
              'https://modelscope.cn/models/OpenBMB/MiniCPM-V-4.7-35B-A3B-GGUF/resolve/master/mmproj-model-f16.gguf',
          sizeBytes: 1119575840,
          expectedSha256:
              'bff3b688e14c300eca273092c37c50a0ddfcc2054e079af1a0480edeed5d20f1',
        ),
      ],
    ),
    ModelDefinition(
      id: 'local-minicpmo26-vision-q4km',
      displayName: 'MiniCPM-o 2.6 · text / vision · Q4_K_M',
      family: ModelFamily.local,
      provider: 'OpenBMB',
      apiFormat: ApiFormat.local,
      license: 'MiniCPM Model License (weights); Apache-2.0 (code)',
      isMultimodal: true,
      sizeBytes: 4681260960,
      sourceUrl: 'https://modelscope.cn/models/OpenBMB/MiniCPM-o-2_6-gguf',
      downloadUrl:
          'https://modelscope.cn/models/OpenBMB/MiniCPM-o-2_6-gguf/resolve/master/Model-7.6B-Q4_K_M.gguf',
      expectedSha256:
          '4f635fc0c0bb88d50ccd9cf1f1e5892b5cb085ff88fe0d8e1148fd9a8a836bc2',
      task: ModelTask.visionLanguage,
      runtimeBundled: true,
      quantization: 'Q4_K_M',
      capabilities: {ModelCapability.text, ModelCapability.imageInput},
      artifacts: [
        ModelArtifact(
          id: 'model',
          fileName: 'Model-7.6B-Q4_K_M.gguf',
          role: ModelArtifactRole.model,
          format: ModelFormat.gguf,
          downloadUrl:
              'https://modelscope.cn/models/OpenBMB/MiniCPM-o-2_6-gguf/resolve/master/Model-7.6B-Q4_K_M.gguf',
          sizeBytes: 4681260960,
          expectedSha256:
              '4f635fc0c0bb88d50ccd9cf1f1e5892b5cb085ff88fe0d8e1148fd9a8a836bc2',
        ),
        ModelArtifact(
          id: 'projector',
          fileName: 'mmproj-model-f16.gguf',
          role: ModelArtifactRole.projector,
          format: ModelFormat.gguf,
          downloadUrl:
              'https://modelscope.cn/models/OpenBMB/MiniCPM-o-2_6-gguf/resolve/master/mmproj-model-f16.gguf',
          sizeBytes: 1044425152,
          expectedSha256:
              'efa4f7d96aa0f838f2023fc8d28e519179b16f1106777fa9280b32628191aa3e',
        ),
      ],
    ),
    ModelDefinition(
      id: 'local-minicpmo45-vision-q4km',
      displayName: 'MiniCPM-o 4.5 · text / vision · Q4_K_M',
      family: ModelFamily.local,
      provider: 'OpenBMB',
      apiFormat: ApiFormat.local,
      license: 'Apache-2.0',
      isMultimodal: true,
      sizeBytes: 5026714400,
      sourceUrl: 'https://modelscope.cn/models/OpenBMB/MiniCPM-o-4_5-gguf',
      downloadUrl:
          'https://modelscope.cn/models/OpenBMB/MiniCPM-o-4_5-gguf/resolve/master/MiniCPM-o-4_5-Q4_K_M.gguf',
      expectedSha256:
          '1237a97ee081b8abebc47aa7dad565701e8f5f904cdc92f6723ac4281bbc0932',
      task: ModelTask.visionLanguage,
      runtimeBundled: true,
      quantization: 'Q4_K_M',
      capabilities: {ModelCapability.text, ModelCapability.imageInput},
      artifacts: [
        ModelArtifact(
          id: 'model',
          fileName: 'MiniCPM-o-4_5-Q4_K_M.gguf',
          role: ModelArtifactRole.model,
          format: ModelFormat.gguf,
          downloadUrl:
              'https://modelscope.cn/models/OpenBMB/MiniCPM-o-4_5-gguf/resolve/master/MiniCPM-o-4_5-Q4_K_M.gguf',
          sizeBytes: 5026714400,
          expectedSha256:
              '1237a97ee081b8abebc47aa7dad565701e8f5f904cdc92f6723ac4281bbc0932',
        ),
        ModelArtifact(
          id: 'projector',
          fileName: 'vision__MiniCPM-o-4_5-vision-F16.gguf',
          role: ModelArtifactRole.projector,
          format: ModelFormat.gguf,
          downloadUrl:
              'https://modelscope.cn/models/OpenBMB/MiniCPM-o-4_5-gguf/resolve/master/vision/MiniCPM-o-4_5-vision-F16.gguf',
          sizeBytes: 1095113184,
          expectedSha256:
              '1453678cc4e4fe18de241952962e234f265cb8dda780773526103ab8ba82f421',
        ),
      ],
    ),
    ModelDefinition(
      id: 'local-minicpmo45-omni-q4km',
      displayName: 'MiniCPM-o 4.5 · omni bundle · Q4_K_M',
      family: ModelFamily.local,
      provider: 'OpenBMB',
      apiFormat: ApiFormat.local,
      license: 'Apache-2.0',
      isMultimodal: true,
      sizeBytes: 5026714400,
      sourceUrl: 'https://modelscope.cn/models/OpenBMB/MiniCPM-o-4_5-gguf',
      downloadUrl:
          'https://modelscope.cn/models/OpenBMB/MiniCPM-o-4_5-gguf/resolve/master/MiniCPM-o-4_5-Q4_K_M.gguf',
      expectedSha256:
          '1237a97ee081b8abebc47aa7dad565701e8f5f904cdc92f6723ac4281bbc0932',
      task: ModelTask.visionLanguage,
      runtimeBundled: false,
      quantization: 'Q4_K_M',
      capabilities: {
        ModelCapability.text,
        ModelCapability.imageInput,
        ModelCapability.audioInput,
        ModelCapability.audioOutput,
      },
      artifacts: [
        ModelArtifact(
          id: 'model',
          fileName: 'MiniCPM-o-4_5-Q4_K_M.gguf',
          role: ModelArtifactRole.model,
          format: ModelFormat.gguf,
          downloadUrl:
              'https://modelscope.cn/models/OpenBMB/MiniCPM-o-4_5-gguf/resolve/master/MiniCPM-o-4_5-Q4_K_M.gguf',
          sizeBytes: 5026714400,
          expectedSha256:
              '1237a97ee081b8abebc47aa7dad565701e8f5f904cdc92f6723ac4281bbc0932',
        ),
        ModelArtifact(
          id: 'projector',
          fileName: 'vision__MiniCPM-o-4_5-vision-F16.gguf',
          role: ModelArtifactRole.projector,
          format: ModelFormat.gguf,
          downloadUrl:
              'https://modelscope.cn/models/OpenBMB/MiniCPM-o-4_5-gguf/resolve/master/vision/MiniCPM-o-4_5-vision-F16.gguf',
          sizeBytes: 1095113184,
          expectedSha256:
              '1453678cc4e4fe18de241952962e234f265cb8dda780773526103ab8ba82f421',
        ),
        ModelArtifact(
          id: 'audio_MiniCPM_o_4_5_audio_F16_gguf',
          fileName: 'audio__MiniCPM-o-4_5-audio-F16.gguf',
          role: ModelArtifactRole.config,
          format: ModelFormat.gguf,
          downloadUrl:
              'https://modelscope.cn/models/OpenBMB/MiniCPM-o-4_5-gguf/resolve/master/audio/MiniCPM-o-4_5-audio-F16.gguf',
          sizeBytes: 660167904,
          expectedSha256:
              'd5b188ac7feaf98e17175c3f9bd14bf269301bfd187439fdaa3e3a494fc32ef7',
        ),
        ModelArtifact(
          id: 'token2wav_gguf_encoder_gguf',
          fileName: 'token2wav-gguf__encoder.gguf',
          role: ModelArtifactRole.config,
          format: ModelFormat.gguf,
          downloadUrl:
              'https://modelscope.cn/models/OpenBMB/MiniCPM-o-4_5-gguf/resolve/master/token2wav-gguf/encoder.gguf',
          sizeBytes: 151339008,
          expectedSha256:
              '7f8d265da594eaf5e1de2db8f5f1867dbcb0bb75ef5878fadf2952347116f4d0',
        ),
        ModelArtifact(
          id: 'token2wav_gguf_flow_extra_gguf',
          fileName: 'token2wav-gguf__flow_extra.gguf',
          role: ModelArtifactRole.config,
          format: ModelFormat.gguf,
          downloadUrl:
              'https://modelscope.cn/models/OpenBMB/MiniCPM-o-4_5-gguf/resolve/master/token2wav-gguf/flow_extra.gguf',
          sizeBytes: 13663328,
          expectedSha256:
              'c67611aa7d02500fe395a7798bf0bfdfb55c74d37ba93934ca74d82b4e63f78d',
        ),
        ModelArtifact(
          id: 'token2wav_gguf_flow_matching_gguf',
          fileName: 'token2wav-gguf__flow_matching.gguf',
          role: ModelArtifactRole.config,
          format: ModelFormat.gguf,
          downloadUrl:
              'https://modelscope.cn/models/OpenBMB/MiniCPM-o-4_5-gguf/resolve/master/token2wav-gguf/flow_matching.gguf',
          sizeBytes: 458250240,
          expectedSha256:
              'eda6069f3edeb5dd3a87fbf2aedb2ddd1b46f3273926c4fcf09b24476a39cab8',
        ),
        ModelArtifact(
          id: 'token2wav_gguf_hifigan2_gguf',
          fileName: 'token2wav-gguf__hifigan2.gguf',
          role: ModelArtifactRole.config,
          format: ModelFormat.gguf,
          downloadUrl:
              'https://modelscope.cn/models/OpenBMB/MiniCPM-o-4_5-gguf/resolve/master/token2wav-gguf/hifigan2.gguf',
          sizeBytes: 83242816,
          expectedSha256:
              '1b8b3bf5d8d3066aeee4324fdcdd41aefce170d0ee907645858de408d82835c2',
        ),
        ModelArtifact(
          id: 'token2wav_gguf_prompt_cache_gguf',
          fileName: 'token2wav-gguf__prompt_cache.gguf',
          role: ModelArtifactRole.config,
          format: ModelFormat.gguf,
          downloadUrl:
              'https://modelscope.cn/models/OpenBMB/MiniCPM-o-4_5-gguf/resolve/master/token2wav-gguf/prompt_cache.gguf',
          sizeBytes: 211613152,
          expectedSha256:
              '81fe6f541ebe0b67db06a1e395df928da47991dc9637c2cf47d6c59d5b979f2c',
        ),
        ModelArtifact(
          id: 'tts_MiniCPM_o_4_5_projector_F16_gguf',
          fileName: 'tts__MiniCPM-o-4_5-projector-F16.gguf',
          role: ModelArtifactRole.config,
          format: ModelFormat.gguf,
          downloadUrl:
              'https://modelscope.cn/models/OpenBMB/MiniCPM-o-4_5-gguf/resolve/master/tts/MiniCPM-o-4_5-projector-F16.gguf',
          sizeBytes: 14948640,
          expectedSha256:
              '4b1b5b377358a5e594a304ff6ea5d52df606a9ba7d886c4299d232f0c67dd1fd',
        ),
        ModelArtifact(
          id: 'tts_MiniCPM_o_4_5_tts_F16_gguf',
          fileName: 'tts__MiniCPM-o-4_5-tts-F16.gguf',
          role: ModelArtifactRole.config,
          format: ModelFormat.gguf,
          downloadUrl:
              'https://modelscope.cn/models/OpenBMB/MiniCPM-o-4_5-gguf/resolve/master/tts/MiniCPM-o-4_5-tts-F16.gguf',
          sizeBytes: 1157244416,
          expectedSha256:
              'c7be3748a863dd6966ae7eed42600b7f41ca67affb03729ff245247f0e5ea088',
        ),
      ],
    ),
  ];
}
