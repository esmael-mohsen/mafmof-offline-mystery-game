import 'dart:convert';

import 'package:mafmof/core/constants/app_media.dart';

String buildTestSeedJson({int seedVersion = 1, String? caseTitleOverride}) {
  final caseTitle = caseTitleOverride ?? 'قضية فرح التجمع';

  Map<String, Object?> variant({
    required int count,
    required List<String> activeIds,
    required String label,
  }) {
    final allIds = <String>[
      'laila',
      'karim',
      'omar',
      'shady',
      'nader',
      'sara',
      'magdy',
      'bebo',
    ];

    return <String, Object?>{
      'id': 'case01_v$count',
      'playerCount': count,
      'displayLabel': label,
      'publicSynopsis': 'نسخة جاهزة لـ$count لاعبين.',
      'finalExplanation': 'التفسير النهائي لنسخة $count لاعبين.',
      'innocentWinText': 'الأبرياء كسبوا.',
      'mafiaWinText': 'المافيا كسبت.',
      'isPlayable': true,
      'variantCharacters': [
        for (var i = 0; i < allIds.length; i += 1)
          {
            'id': 'case01_v${count}_${allIds[i]}',
            'characterId': allIds[i],
            'participationType':
                activeIds.contains(allIds[i]) ? 'active' : 'evidence',
            'displayOrder': i + 1,
            'evidenceNote': activeIds.contains(allIds[i])
                ? null
                : 'يظهر كشاهد أو دليل جانبي.',
          },
      ],
      'roleAssignments': [
        for (final characterId in activeIds)
          {
            'id': 'case01_v${count}_${characterId}_role',
            'characterId': characterId,
            'team':
                characterId == 'shady' || (count >= 7 && characterId == 'magdy')
                    ? 'mafia'
                    : 'innocent',
            'roleName':
                characterId == 'shady' || (count >= 7 && characterId == 'magdy')
                    ? 'المافيا'
                    : 'البريء',
            'publicInfo': 'معلومة علنية عن $characterId',
            'secret': 'سر $characterId',
            'secretMeaning': 'معنى سر $characterId',
            'goal': 'هدف $characterId',
            'tasks': 'مهمة $characterId',
            'specialAbility': characterId == 'karim' ? 'تحليل الأدلة' : null,
            'mustNotSay': characterId == 'laila' ? 'لا تذكر الهاتف' : null,
          },
      ],
      'stages': [
        for (var stage = 1; stage <= 5; stage += 1)
          {
            'id': 'case01_v${count}_stage_$stage',
            'stageNumber': stage,
            'title': 'المرحلة $stage',
            'hostScript': 'نص المضيف للمرحلة $stage',
            'publicClue': 'الدليل العلني رقم $stage',
            'hostNote': 'ملاحظة المضيف رقم $stage',
            'expectedFocus': 'التركيز المتوقع رقم $stage',
            'discussionSeconds': 180 - ((stage - 1) * 15),
            'voteType': count == 8 && stage == 1
                ? 'elimination'
                : stage == 1
                    ? 'suspicion'
                    : stage == 5
                        ? 'final'
                        : 'elimination',
            'imageAssetPath': _stageImagePath(stage),
          },
      ],
    };
  }

  final payload = <String, Object?>{
    'seedKey': 'case_catalog',
    'seedVersion': seedVersion,
    'cases': [
      {
        'id': 'case01_farah_eltagamoa',
        'title': caseTitle,
        'subtitle': 'ليلة تتغير فيها الروايات',
        'summary': 'ملف غامض يقود المضيف خلال أدلة متصاعدة.',
        'setting': 'فيلا فخمة في التجمع الخامس أثناء فرح مصري ليلي.',
        'durationMinutes': 45,
        'difficulty': 'Medium',
        'minPlayers': 5,
        'maxPlayers': 8,
        'coverAssetPath': AppMedia.caseCover,
        'openingAssetPath': AppMedia.caseOpening,
        'finalRevealAssetPath': AppMedia.finalRevealImage,
        'roleRevealBackgroundAssetPath': AppMedia.roleRevealBackground,
        'openingScript': 'إحنا في فرح كبير في فيلا فخمة.',
        'coreTruth': 'العريس اكتشف صفقة خطيرة قبل الفرح.',
        'isActive': true,
        'characters': [
          {
            'id': 'laila',
            'name': 'ليلى',
            'title': 'العروسة',
            'portraitAssetPath': 'assets/images/characters/laila.webp',
            'publicBio': 'صحفية تبحث عن الحقيقة.',
          },
          {
            'id': 'karim',
            'name': 'كريم',
            'title': 'صاحب العريس',
            'portraitAssetPath': 'assets/images/characters/karim.webp',
            'publicBio': 'صديق يراقب التفاصيل الصغيرة.',
          },
          {
            'id': 'omar',
            'name': 'عمر',
            'title': 'أخو العروسة',
            'portraitAssetPath': 'assets/images/characters/omar.webp',
            'publicBio': 'مصور يملك لقطات حاسمة.',
          },
          {
            'id': 'shady',
            'name': 'شادي',
            'title': 'المصور',
            'portraitAssetPath': 'assets/images/characters/shady.webp',
            'publicBio': 'وجه هادئ يخفي نوايا معقدة.',
          },
          {
            'id': 'nader',
            'name': 'نادر',
            'title': 'منظم الفرح',
            'portraitAssetPath': 'assets/images/characters/nader.webp',
            'publicBio': 'حارس أمن لاحظ ما لم يره الآخرون.',
          },
          {
            'id': 'sara',
            'name': 'سارة',
            'title': 'البنت القديمة',
            'portraitAssetPath': 'assets/images/characters/sara.webp',
            'publicBio': 'شاهدة دقيقة الذاكرة.',
          },
          {
            'id': 'magdy',
            'name': 'مجدي',
            'title': 'خال العريس',
            'portraitAssetPath': 'assets/images/characters/magdy.webp',
            'publicBio': 'رجل أعمال يكره الفوضى.',
          },
          {
            'id': 'bebo',
            'name': 'بيبو',
            'title': 'DJ الفرح',
            'portraitAssetPath': 'assets/images/characters/bebo.webp',
            'publicBio': 'صديق مرح يعرف الجميع.',
          },
        ],
        'variants': [
          variant(
            count: 5,
            activeIds: ['laila', 'karim', 'omar', 'shady', 'nader'],
            label: 'نسخة 5 لاعبين',
          ),
          variant(
            count: 6,
            activeIds: ['laila', 'karim', 'omar', 'shady', 'nader', 'sara'],
            label: 'نسخة 6 لاعبين',
          ),
          variant(
            count: 7,
            activeIds: [
              'laila',
              'karim',
              'omar',
              'shady',
              'nader',
              'sara',
              'magdy',
            ],
            label: 'نسخة 7 لاعبين',
          ),
          variant(
            count: 8,
            activeIds: [
              'laila',
              'karim',
              'omar',
              'shady',
              'nader',
              'sara',
              'magdy',
              'bebo',
            ],
            label: 'نسخة 8 لاعبين',
          ),
        ],
      },
    ],
  };

  return jsonEncode(payload);
}

String _stageImagePath(int stage) {
  switch (stage) {
    case 1:
      return AppMedia.clue1Phone;
    case 2:
      return AppMedia.clue2Camera;
    case 3:
      return AppMedia.clue3Camera;
    case 4:
      return AppMedia.clue4VoiceNote;
    case 5:
      return AppMedia.clue5Contract;
    default:
      return AppMedia.caseOpening;
  }
}
