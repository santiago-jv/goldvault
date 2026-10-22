import 'dart:math';
import 'package:intl/intl.dart';

const List<String> kMonthsEs = [
  'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
  'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
];

String genId(String prefix) {
  final rnd = Random();
  final ts = DateTime.now().millisecondsSinceEpoch;
  final tail = List.generate(5, (_) => rnd.nextInt(36).toRadixString(36)).join();
  return '${prefix}_${ts}_$tail';
}

String todayIso() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}

String currentYm() => todayIso().substring(0, 7);

String formatMoney(num val) {
  final rounded = val.round();
  final fmt = NumberFormat.decimalPattern('es_CO');
  return '\$${fmt.format(rounded)}';
}

String formatCompact(num val) {
  final n = val.round();
  if (n.abs() >= 1000000) {
    final m = n / 1000000.0;
    return '\$${m.toStringAsFixed(n.abs() >= 10000000 ? 0 : 1).replaceAll('.', ',')}M';
  }
  if (n.abs() >= 1000) {
    return '\$${(n / 1000.0).round()}k';
  }
  return '\$$n';
}

String monthShortLabel(String ym) {
  final parts = ym.split('-');
  if (parts.length < 2) return ym;
  final y = int.tryParse(parts[0]) ?? DateTime.now().year;
  final m = (int.tryParse(parts[1]) ?? 1).clamp(1, 12);
  final mon = kMonthsEs[m - 1].substring(0, 3);
  return '${mon[0].toUpperCase()}${mon.substring(1)} $y';
}

String monthFullLabel(String ym) {
  final parts = ym.split('-');
  if (parts.length < 2) return ym;
  final y = int.tryParse(parts[0]) ?? DateTime.now().year;
  final m = (int.tryParse(parts[1]) ?? 1).clamp(1, 12);
  final mon = kMonthsEs[m - 1];
  return '${mon[0].toUpperCase()}${mon.substring(1)} $y';
}

String normText(String input) {
  const withDia = 'áéíóúàèìòùäëïöüâêîôûñÁÉÍÓÚÀÈÌÒÙÄËÏÖÜÂÊÎÔÛÑ';
  const withoutDia = 'aeiouaeiouaeiouaeiounAEIOUAEIOUAEIOUAEIOUN';
  var out = input;
  for (var i = 0; i < withDia.length; i++) {
    out = out.replaceAll(withDia[i], withoutDia[i]);
  }
  return out.toLowerCase().trim();
}

class CategoryItem {
  String name;
  String icon;

  CategoryItem({required this.name, required this.icon});

  factory CategoryItem.fromJson(Map<String, dynamic> j) => CategoryItem(
        name: (j['name'] ?? 'Otros').toString(),
        icon: (j['icon'] ?? '✨').toString(),
      );

  Map<String, dynamic> toJson() => {'name': name, 'icon': icon};
}

class FrequentItem {
  String id;
  String desc;
  String category;
  int amount;
  String account;
  int? day;
  String mode;
  String? startYm;

  FrequentItem({
    required this.id,
    required this.desc,
    required this.category,
    required this.amount,
    required this.account,
    this.day,
    this.mode = 'ask',
    this.startYm,
  });

  factory FrequentItem.fromJson(Map<String, dynamic> j) => FrequentItem(
        id: (j['id'] ?? genId('fq')).toString(),
        desc: (j['desc'] ?? '').toString(),
        category: (j['category'] ?? 'Otros').toString(),
        amount: (num.tryParse(j['amount']?.toString() ?? '0') ?? 0).round(),
        account: (j['account'] ?? 'Efectivo').toString(),
        day: j['day'] != null ? int.tryParse(j['day'].toString()) : null,
        mode: (j['mode'] ?? 'ask').toString(),
        startYm: j['startYm']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'desc': desc,
        'category': category,
        'amount': amount,
        'account': account,
        if (day != null) 'day': day,
        'mode': mode,
        if (startYm != null) 'startYm': startYm,
      };
}

class GoalItem {
  String id;
  String name;
  int target;
  String? achievedAt;

  GoalItem({
    required this.id,
    required this.name,
    required this.target,
    this.achievedAt,
  });

  factory GoalItem.fromJson(Map<String, dynamic> j) => GoalItem(
        id: (j['id'] ?? genId('goal')).toString(),
        name: (j['name'] ?? 'Meta').toString(),
        target: (num.tryParse(j['target']?.toString() ?? '0') ?? 0).round(),
        achievedAt: j['achievedAt']?.toString() ?? j['achieved_at']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'target': target,
        'achievedAt': achievedAt,
      };
}

class SpaceModel {
  String id;
  String name;
  String emoji;
  List<CategoryItem> categories;
  List<String> accounts;
  List<String> sources;
  List<FrequentItem> frequents;
  Map<String, int> budgets;
  List<String> recSkipped;
  List<GoalItem> goals;

  SpaceModel({
    required this.id,
    required this.name,
    required this.emoji,
    required this.categories,
    required this.accounts,
    required this.sources,
    required this.frequents,
    required this.budgets,
    required this.recSkipped,
    required this.goals,
  });

  String iconForCategory(String? catName) {
    if (catName == null) return '✨';
    for (final c in categories) {
      if (normText(c.name) == normText(catName)) return c.icon;
    }
    return '✨';
  }

  factory SpaceModel.fromTemplate(String tpl, {String? customName, bool first = false}) {
    final id = first ? 'space_main' : genId('sp');
    if (tpl == 'zero') {
      return SpaceModel(
        id: id,
        name: customName ?? 'Mi espacio',
        emoji: '✨',
        categories: [CategoryItem(name: 'General', icon: '✨')],
        accounts: ['Principal', 'Nequi', 'Nu Bank', 'Lulo Bank', 'ARQ', 'Morse'],
        sources: ['Ingreso'],
        frequents: [],
        budgets: {},
        recSkipped: [],
        goals: [],
      );
    }
    return SpaceModel(
      id: id,
      name: customName ?? 'Personal',
      emoji: '💰',
      categories: [
        CategoryItem(name: 'Vivienda', icon: '🏠'),
        CategoryItem(name: 'Mercado', icon: '🛒'),
        CategoryItem(name: 'Comida', icon: '🍔'),
        CategoryItem(name: 'Transporte', icon: '🚗'),
        CategoryItem(name: 'Suscripciones', icon: '📱'),
        CategoryItem(name: 'Salud', icon: '🩺'),
        CategoryItem(name: 'Educación', icon: '📚'),
        CategoryItem(name: 'Ocio', icon: '🎉'),
        CategoryItem(name: 'Ropa', icon: '👕'),
        CategoryItem(name: 'Deudas', icon: '💳'),
        CategoryItem(name: 'Regalos', icon: '🎁'),
        CategoryItem(name: 'Otros', icon: '✨'),
      ],
      accounts: ['Efectivo', 'Nequi', 'Nu Bank', 'Lulo Bank', 'ARQ', 'Morse'],
      sources: ['Salario', 'Freelance', 'Inversiones', 'Otros'],
      frequents: [
        FrequentItem(id: genId('fq'), desc: 'Almuerzo', category: 'Comida', amount: 22000, account: 'Nequi'),
        FrequentItem(id: genId('fq'), desc: 'Café', category: 'Comida', amount: 8000, account: 'Efectivo'),
        FrequentItem(id: genId('fq'), desc: 'Transporte', category: 'Transporte', amount: 15000, account: 'Nequi'),
      ],
      budgets: {},
      recSkipped: [],
      goals: [
        GoalItem(id: genId('goal'), name: 'Fondo de emergencia', target: 5000000),
        GoalItem(id: genId('goal'), name: 'Viaje', target: 3000000),
      ],
    );
  }

  factory SpaceModel.fromRow(Map<String, dynamic> r, List<GoalItem> spaceGoals) {
    final rawCats = (r['categories'] as List?) ?? [];
    final rawAccts = (r['accounts'] as List?) ?? [];
    final rawSrcs = (r['sources'] as List?) ?? [];
    final rawFreqs = (r['frequents'] as List?) ?? [];
    final rawBudgets = (r['budgets'] as Map?) ?? {};
    final rawSkipped = (r['rec_skipped'] as List?) ?? (r['recSkipped'] as List?) ?? [];

    final budgetsMap = <String, int>{};
    rawBudgets.forEach((k, v) {
      final n = (num.tryParse(v.toString()) ?? 0).round();
      if (n > 0) budgetsMap[k.toString()] = n;
    });

    return SpaceModel(
      id: (r['id'] ?? 'space_main').toString(),
      name: (r['name'] ?? 'Mi espacio').toString(),
      emoji: (r['emoji'] ?? '💰').toString(),
      categories: rawCats.map((e) => CategoryItem.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
      accounts: rawAccts.map((e) => e.toString()).toList(),
      sources: rawSrcs.map((e) => e.toString()).toList(),
      frequents: rawFreqs.map((e) => FrequentItem.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
      budgets: budgetsMap,
      recSkipped: rawSkipped.map((e) => e.toString()).toList(),
      goals: spaceGoals,
    );
  }

  Map<String, dynamic> toRow() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        'categories': categories.map((c) => c.toJson()).toList(),
        'accounts': accounts,
        'sources': sources,
        'frequents': frequents.map((f) => f.toJson()).toList(),
        'budgets': budgets,
        'rec_skipped': recSkipped,
      };
}

class FxInfo {
  final String ccy;
  final double amount;
  final double rate;

  const FxInfo({required this.ccy, required this.amount, required this.rate});

  factory FxInfo.fromJson(Map<String, dynamic> j) => FxInfo(
        ccy: (j['ccy'] ?? 'USD').toString(),
        amount: double.tryParse(j['amount']?.toString() ?? '0') ?? 0,
        rate: double.tryParse(j['rate']?.toString() ?? '4200') ?? 4200,
      );

  Map<String, dynamic> toJson() => {'ccy': ccy, 'amount': amount, 'rate': rate};
}

class MovementModel {
  String id;
  String space;
  String date;
  String type; // 'expense' | 'saving' | 'income'
  String desc;
  int amount;
  String? category;
  String? account;
  String status; // 'paid' | 'pending' | 'cancelled'
  String? goalId;
  String? source;
  FxInfo? fx;
  String? autoBank;
  String? autoRaw;
  bool autoReviewed;

  MovementModel({
    required this.id,
    required this.space,
    required this.date,
    required this.type,
    required this.desc,
    required this.amount,
    this.category,
    this.account,
    this.status = 'paid',
    this.goalId,
    this.source,
    this.fx,
    this.autoBank,
    this.autoRaw,
    this.autoReviewed = true,
  });

  factory MovementModel.fromRow(Map<String, dynamic> r) {
    FxInfo? fxInfo;
    if (r['orig_currency'] != null) {
      fxInfo = FxInfo(
        ccy: r['orig_currency'].toString(),
        amount: double.tryParse(r['orig_amount']?.toString() ?? '0') ?? 0,
        rate: double.tryParse(r['fx_rate']?.toString() ?? '4200') ?? 4200,
      );
    } else if (r['fx'] is Map) {
      fxInfo = FxInfo.fromJson(Map<String, dynamic>.from(r['fx'] as Map));
    }

    return MovementModel(
      id: (r['id'] ?? genId('mv')).toString(),
      space: (r['space_id'] ?? r['space'] ?? 'space_main').toString(),
      date: (r['date'] ?? todayIso()).toString(),
      type: (r['type'] ?? 'expense').toString(),
      desc: (r['desc'] ?? '').toString(),
      amount: (num.tryParse(r['amount']?.toString() ?? '0') ?? 0).round(),
      category: r['category']?.toString(),
      account: r['account']?.toString(),
      status: (r['status'] ?? 'paid').toString(),
      goalId: (r['goal_id'] ?? r['goalId'])?.toString(),
      source: r['source']?.toString(),
      fx: fxInfo,
      autoBank: (r['auto_bank'] ?? r['autoBank'])?.toString(),
      autoRaw: (r['auto_raw'] ?? r['autoRaw'])?.toString(),
      autoReviewed: (r['auto_reviewed'] ?? r['autoReviewed']) != false,
    );
  }

  Map<String, dynamic> toRow() => {
        'id': id,
        'space_id': space,
        'date': date,
        'type': type,
        'desc': desc.isEmpty ? null : desc,
        'amount': amount,
        'category': category,
        'account': account,
        'status': status,
        'goal_id': goalId,
        'source': source,
        'orig_currency': fx?.ccy,
        'orig_amount': fx?.amount,
        'fx_rate': fx?.rate,
        'auto_bank': autoBank,
        'auto_raw': autoRaw,
        'auto_reviewed': autoReviewed,
      };
}

class BankSample {
  final String bank;
  final String pkg;
  final String title;
  final String text;

  const BankSample({
    required this.bank,
    required this.pkg,
    required this.title,
    required this.text,
  });
}

const List<BankSample> kBankSamples = [
  BankSample(
    bank: 'Nequi',
    pkg: 'com.nequi.MobileApp',
    title: 'Nequi',
    text: 'Pagaste \$ 28.500,00 en CORRAL GOURMET con tu Nequi',
  ),
  BankSample(
    bank: 'Nu Bank',
    pkg: 'com.nu.production',
    title: 'Nu',
    text: 'Compra aprobada por \$ 64.900,00 en MERCADO EXITO con tu Moradita',
  ),
  BankSample(
    bank: 'Lulo Bank',
    pkg: 'com.lulobank.app',
    title: 'Lulo Bank',
    text: 'Compraste \$ 18.400 en UBER TRIP con tu tarjeta Lulo',
  ),
  BankSample(
    bank: 'ARQ',
    pkg: 'com.arq.app',
    title: 'ARQ',
    text: 'Compra aprobada por US\$ 14.99 en NETFLIX.COM con tu tarjeta ARQ',
  ),
  BankSample(
    bank: 'Morse',
    pkg: 'com.morse.app',
    title: 'Morse',
    text: 'Pago realizado por \$ 35.000 en RAPPI con Morse',
  ),
];

class BankParseResult {
  final bool ok;
  final bool ignored;
  final String? reason;
  final String bank;
  final String desc;
  final int amount;
  final String category;
  final String account;
  final bool accountAdded;
  final FxInfo? fx;
  final String raw;

  const BankParseResult({
    required this.ok,
    this.ignored = false,
    this.reason,
    this.bank = 'Banco',
    this.desc = '',
    this.amount = 0,
    this.category = 'Otros',
    this.account = '',
    this.accountAdded = false,
    this.fx,
    this.raw = '',
  });
}

class BankNotificationParser {
  static BankParseResult parse({
    required String rawText,
    String rawTitle = '',
    String rawApp = '',
    required SpaceModel space,
    required double fxRate,
  }) {
    final full = '$rawApp $rawTitle $rawText'.trim();
    final lower = full.toLowerCase();

    final ignoreRe = RegExp(
      r'(clave dinamica|clave dinámica|codigo de verificacion|código de verificación|codigo de seguridad|\botp\b|iniciaste sesion|iniciaste sesión|rechazad[ao]|declinad[ao]|fallid[ao]|fondos insuficientes|saldo insuficiente|recibiste|te enviaron|te transfirieron)',
      caseSensitive: false,
    );
    if (ignoreRe.hasMatch(lower)) {
      return const BankParseResult(
        ok: false,
        ignored: true,
        reason: 'Notificación informativa o no es un gasto realizado',
      );
    }

    final payRe = RegExp(
      r'(pagaste|pago|compraste|compra|enviaste|transferiste|transferencia|retiraste|retiro|aprobada|exitos[ao]|realizaste|spent|paid|payment|purchase|cargo|debito|débito)',
      caseSensitive: false,
    );
    if (!payRe.hasMatch(lower)) {
      return const BankParseResult(
        ok: false,
        ignored: true,
        reason: 'El texto no corresponde a un pago o compra',
      );
    }

    var bank = 'Banco';
    if (RegExp(r'(nequi|com\.nequi)', caseSensitive: false).hasMatch(lower)) {
      bank = 'Nequi';
    } else if (RegExp(r'(lulobank|lulo\s*bank|\blulo\b|com\.lulobank)', caseSensitive: false).hasMatch(lower)) {
      bank = 'Lulo Bank';
    } else if (RegExp(r'(\barq\b|com\.arq|littio|co\.littio)', caseSensitive: false).hasMatch(lower)) {
      bank = 'ARQ';
    } else if (RegExp(r'(\bmorse\b|com\.morse)', caseSensitive: false).hasMatch(lower)) {
      bank = 'Morse';
    } else if (RegExp(r'(nubank|\bnu\b|moradita|com\.nu\.)', caseSensitive: false).hasMatch(lower)) {
      bank = 'Nu Bank';
    } else if (lower.contains('bancolombia')) {
      bank = 'Bancolombia';
    } else if (lower.contains('daviplata')) {
      bank = 'Daviplata';
    }

    final isUsd = RegExp(r'(us\$|\busd\b|\busdc\b|\busdt\b|dolares|dólares)', caseSensitive: false).hasMatch(lower) &&
        !RegExp(r'\bcop\b', caseSensitive: false).hasMatch(lower);

    final bodyAndTitle = '$rawText $rawTitle';
    final amtRe1 = RegExp(
      r'(?:US\$|COP|\$|USD|por|de|of|paid|spent)\s*([0-9]{1,3}(?:[.,][0-9]{3})*(?:[.,][0-9]{1,2})?|[0-9]+(?:[.,][0-9]{1,2})?)',
      caseSensitive: false,
    );
    final amtRe2 = RegExp(r'([0-9]{1,3}(?:\.[0-9]{3})+|[0-9]{4,}|[0-9]+\.[0-9]{2})');
    final mAmt = amtRe1.firstMatch(bodyAndTitle) ?? amtRe2.firstMatch(bodyAndTitle);
    if (mAmt == null) {
      return const BankParseResult(
        ok: false,
        ignored: true,
        reason: 'No se detectó un monto válido en la notificación',
      );
    }

    var numStr = mAmt.group(1) ?? '0';
    double origAmount = 0;
    int amountCop = 0;
    final rate = fxRate > 0 ? fxRate : 4200.0;

    if (isUsd) {
      numStr = numStr.replaceAll(',', '.').replaceAll(RegExp(r'[^0-9.]'), '');
      origAmount = double.tryParse(numStr) ?? 0;
      amountCop = (origAmount * rate).round();
    } else {
      numStr = numStr.replaceFirst(RegExp(r'[.,][0-9]{2}$'), '').replaceAll(RegExp(r'[^0-9]'), '');
      amountCop = int.tryParse(numStr) ?? 0;
      origAmount = amountCop.toDouble();
    }

    if (amountCop <= 0) {
      return const BankParseResult(ok: false, ignored: true, reason: 'El monto detectado es 0');
    }

    var desc = '';
    final descRe = RegExp(
      r'(?:compra(?:\s+aprobada)?\s+en|pagaste\s+.*?\s+en|pago(?:\s+exitoso|\s+aprobado|\s+realizado)?\s+.*?\s+en|compraste\s+.*?\s+en|en\s+el\s+comercio|\ben\s+|\bat\s+|enviaste\s+.*?\s+a\s+|transferiste\s+.*?\s+a\s+|transferencia(?:\s+exitosa|\s+enviada)?\s+.*?\s+a\s+)([A-Za-zÁÉÍÓÚÑáéíóúñ0-9 ._*&-]{2,40})',
      caseSensitive: false,
    );
    final mDesc = descRe.firstMatch(rawText);
    if (mDesc != null && mDesc.group(1) != null) {
      desc = mDesc
          .group(1)!
          .replaceFirst(
            RegExp(
              r'\s+(con\s+(?:tu|nequi|nu|nubank|lulo|lulobank|arq|morse|tarjeta|billetera)|por\s+\$|por\s+valor|el\s+d[ií]a|a\s+las|exitos[ao]|desde\s+tu).*$',
              caseSensitive: false,
            ),
            '',
          )
          .replaceAll(RegExp(r'^[ .,:-]+|[ .,:-]+$'), '')
          .trim();
    }
    if (desc.length < 2) desc = 'Pago $bank';

    var targetCat = 'Otros';
    if (RegExp(r'(rappi|didi\s*food|uber\s*eats|restaurante|crepes|mcdonald|corral|starbucks|juan\s*valdez|cafe|café|panaderia|almuerzo|cena|pizza|sushi|burger|kfc|subway|frisby|popsy|antojo)', caseSensitive: false).hasMatch(lower)) {
      targetCat = 'Comida';
    } else if (RegExp(r'(exito|éxito|carulla|jumbo|olimpica|olímpica|d1|tiendas\s*d1|ara|alkosto|makro|pricesmart|mercado|supermercado|fruver|oxxo|farmatodo)', caseSensitive: false).hasMatch(lower)) {
      targetCat = 'Mercado';
    } else if (RegExp(r'(uber|didi|cabify|indrive|picap|gasolina|terpel|primax|texaco|biomax|peaje|flypass|gopass|transmilenio|metro|civica|cívica|parqueadero|taxi)', caseSensitive: false).hasMatch(lower)) {
      targetCat = 'Transporte';
    } else if (RegExp(r'(netflix|spotify|youtube|google|apple|icloud|amazon\s*prime|disney|hbo|max|openai|chatgpt|claude|cursor|github|playstation|xbox|steam|canva|adobe|microsoft|suscripcion|suscripción)', caseSensitive: false).hasMatch(lower)) {
      targetCat = 'Suscripciones';
    } else if (RegExp(r'(cruz\s*verde|drogueria|droguería|la\s*rebaja|pasteur|cafam|colsubsidio|eps|sura|sanitas|medicina|farmacia|consulta|odontolog|smartfit|bodytech|gym|gimnasio)', caseSensitive: false).hasMatch(lower)) {
      targetCat = 'Salud';
    } else if (RegExp(r'(arriendo|epm|enel|codensa|vanti|acueducto|triple\s*a|claro|movistar|tigo|wom|etb|servicios|administracion|administración)', caseSensitive: false).hasMatch(lower)) {
      targetCat = 'Vivienda';
    } else if (RegExp(r'(zara|h&m|adidas|nike|falabella|arturo\s*calle|gef|punto\s*blanco|velez|vélez|shein|ropa|calzado)', caseSensitive: false).hasMatch(lower)) {
      targetCat = 'Ropa';
    } else if (RegExp(r'(cine|cinecolombia|procinal|cinemark|bar|discoteca|boleta|tuboleta|taquillalive|eticket|concierto|juego)', caseSensitive: false).hasMatch(lower)) {
      targetCat = 'Ocio';
    }

    String chosenCat = 'Otros';
    final catMatch = space.categories.where((c) => normText(c.name) == normText(targetCat)).toList();
    if (catMatch.isNotEmpty) {
      chosenCat = catMatch.first.name;
    } else if (space.categories.isNotEmpty) {
      final fallback = space.categories.where((c) => ['otros', 'general', 'compras'].contains(normText(c.name))).toList();
      chosenCat = fallback.isNotEmpty ? fallback.first.name : space.categories.first.name;
    }

    String? matchedAcct;
    for (final a in space.accounts) {
      final na = normText(a);
      final nb = normText(bank);
      if (na == nb ||
          (bank == 'Nu Bank' && ['nu', 'nubank', 'nu bank', 'tarjeta nu'].contains(na)) ||
          (bank == 'Lulo Bank' && ['lulo', 'lulo bank', 'lulobank'].contains(na)) ||
          (bank == 'ARQ' && ['arq', 'littio'].contains(na))) {
        matchedAcct = a;
        break;
      }
    }

    var acctAdded = false;
    if (matchedAcct == null) {
      matchedAcct = bank;
      if (!space.accounts.contains(matchedAcct)) {
        space.accounts.add(matchedAcct);
        acctAdded = true;
      }
    }

    return BankParseResult(
      ok: true,
      bank: bank,
      desc: desc,
      amount: amountCop,
      category: chosenCat,
      account: matchedAcct,
      accountAdded: acctAdded,
      fx: isUsd ? FxInfo(ccy: 'USD', amount: origAmount, rate: rate) : null,
      raw: rawText.trim(),
    );
  }
}
