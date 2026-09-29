import 'package:flutter/widgets.dart';

/// Centralized product copy. English is the fallback for unsupported locales.
class AppStrings {
  final Locale locale;
  const AppStrings(this.locale);
  bool get zh => locale.languageCode == 'zh';

  String get appName => 'ZhuangMa';
  String get homeDescription => zh
      ? '用于评估 AI 应用安全性的对抗测试工具包。'
      : 'An adversarial testing toolkit for evaluating AI application security.';

  // Navigation
  String get navHome => zh ? '首页' : 'Home';
  String get navAttackComposer => zh ? '攻击生成器' : 'Attack Composer';
  String get navTransformer => zh ? '转换器' : 'Transformer';
  String get navLibrary => zh ? '用例库' : 'Library';

  // Home actions
  String get createAttack => zh ? '创建攻击测试' : 'Create Attack Test';
  String get transformPayload => zh ? '转换载荷' : 'Transform Payload';

  // Composer
  String get composerTitle => zh ? '攻击生成器' : 'Attack Composer';
  String get category => zh ? '攻击分类' : 'Category';
  String get intensity => zh ? '复杂度' : 'Complexity';
  String get objective => zh ? '测试目标' : 'Objective';
  String get targetBoundary => zh ? '防护边界' : 'Target Boundary';
  String get generateMultiTurn =>
      zh ? '生成多轮对话' : 'Generate multi-turn conversation';
  String get generate => zh ? '生成' : 'Generate';
  String get conversationTurns => zh ? '对话轮次' : 'Conversation turns';
  String get turnLabel => zh ? '轮次' : 'Turn';
  String get plainText => 'Plain Text';
  String get jsonText => 'JSON';
  String get markdownText => 'Markdown';
  String get exportPreview => zh ? '导出预览' : 'Export preview';
  String get close => zh ? '关闭' : 'Close';

  // Transformer
  String get transformerTitle => zh ? '转换器演练场' : 'Transformer Playground';
  String get originalText => zh ? '原始文本' : 'Original text';
  String get pipelineSteps => zh ? '流水线步骤' : 'Pipeline steps';
  String get addTransformation => zh ? '添加转换' : 'Add transformation';
  String get transform => zh ? '转换' : 'Transform';
  String get restore => zh ? '恢复' : 'Restore';
  String get reset => zh ? '重置' : 'Reset';
  String get reversibilityFully => zh ? '完全可逆' : 'Fully Reversible';
  String get reversibilityPartial => zh ? '部分可逆' : 'Partially Reversible';
  String get reversibilityNone => zh ? '不可逆' : 'Not Reversible';

  // Library
  String get libraryTitle => zh ? '攻击用例库' : 'Attack Library';
  String savedScenarios(int count) =>
      zh ? '已保存 $count 个测试用例' : '$count saved scenarios';
  String get createLocalScenario => zh ? '创建本地用例' : 'Create local scenario';
  String get noSavedScenarios => zh ? '暂无保存的用例。' : 'No saved scenarios yet.';
  String get searchScenario => zh ? '搜索用例' : 'Search scenarios';

  // Errors
  String get transformFailed => zh ? '转换失败' : 'Transformation failed';
  String get restoreFailed => zh ? '恢复失败' : 'Restoration failed';
  String get dbError => zh ? '数据库操作失败' : 'Database operation failed';
}
