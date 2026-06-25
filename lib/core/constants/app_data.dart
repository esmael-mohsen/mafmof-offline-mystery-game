class HostPlaytestChecklistItem {
  const HostPlaytestChecklistItem({
    required this.id,
    required this.category,
    required this.instructionAr,
    required this.importance,
  });

  final String id;
  final String category;
  final String instructionAr;
  final String importance;
}

class HostPlaytestChecklist {
  const HostPlaytestChecklist._();

  static const items = <HostPlaytestChecklistItem>[
    HostPlaytestChecklistItem(
      id: 'check_setup',
      category: 'Setup',
      instructionAr: 'تأكد من أن الجهاز غير متصل بالإنترنت قبل بدء الجلسة.',
      importance: 'P1',
    ),
    HostPlaytestChecklistItem(
      id: 'check_player_count',
      category: 'Setup',
      instructionAr: 'اختر عدد اللاعبين المناسب (5، 6، 7، أو 8) وأدخل أسماء واضحة لكل لاعب.',
      importance: 'P1',
    ),
    HostPlaytestChecklistItem(
      id: 'check_role_privacy',
      category: 'Privacy',
      instructionAr: 'سلّم الجهاز لكل لاعب واحداً واحداً. تأكد من أن الدور مخفي قبل تمرير الجهاز.',
      importance: 'P1',
    ),
    HostPlaytestChecklistItem(
      id: 'check_no_peaking',
      category: 'Privacy',
      instructionAr: 'لا تقرأ بطاقة دور أي لاعب. الدور سري حتى الكشف النهائي.',
      importance: 'P1',
    ),
    HostPlaytestChecklistItem(
      id: 'check_background_hide',
      category: 'Privacy',
      instructionAr: 'إذا وضع الجهاز في الخلفية أثناء كشف الدور، سيتم إخفاء المحتوى تلقائياً.',
      importance: 'P2',
    ),
    HostPlaytestChecklistItem(
      id: 'check_timer_pause',
      category: 'Gameplay',
      instructionAr: 'المؤقت يتوقف تلقائياً عند وضع الجهاز في الخلفية ويعود من الوقت المتبقي عند العودة.',
      importance: 'P2',
    ),
    HostPlaytestChecklistItem(
      id: 'check_stage_order',
      category: 'Gameplay',
      instructionAr: 'اتبع ترتيب المراحل المقترح. لا يمكنك الانتقال إلى مرحلة لاحقة قبل إتمام الحالية.',
      importance: 'P1',
    ),
    HostPlaytestChecklistItem(
      id: 'check_confirm_actions',
      category: 'Gameplay',
      instructionAr: 'الإجراءات الحاسمة مثل الاستبعاد وإعادة التشغيل تتطلب تأكيداً صريحاً.',
      importance: 'P2',
    ),
    HostPlaytestChecklistItem(
      id: 'check_restart_cleans',
      category: 'Gameplay',
      instructionAr: 'إعادة تشغيل الجلسة تمسح كل التقدم وتعيدك إلى شاشة الإعداد بأمان.',
      importance: 'P1',
    ),
    HostPlaytestChecklistItem(
      id: 'check_sound_optional',
      category: 'Gameplay',
      instructionAr: 'الصوت اختياري. يمكنك كتمه من لوحة المضيف دون أن يتأثر سير اللعبة.',
      importance: 'P2',
    ),
  ];
}