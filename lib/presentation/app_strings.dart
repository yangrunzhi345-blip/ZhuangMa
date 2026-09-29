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
  String get createAttack => zh ? '创建攻击测试' : 'Create Attack Test';
  String get transformPayload => zh ? '转换载荷' : 'Transform Payload';
  String get restore => zh ? '恢复' : 'Restore';
  String get transform => zh ? '转换' : 'Transform';
}
