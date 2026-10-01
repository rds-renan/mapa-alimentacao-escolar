import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'generated.dart';

/// Os documentos que ficaram prontos e ela ainda não viu, do mais novo para o
/// mais velho — a regra do aviso ao abrir (issue #110).
///
/// "Pronto" é o mesmo que "dá para abrir agora" ([downloadable]): um
/// documento que saiu do ar não é notícia, e um que não terminou ainda
/// também não. [documents] já vem do mais novo para o mais velho, e a ordem
/// é mantida.
List<GeneratedDocumentRecord> unseenReady(
  List<GeneratedDocumentRecord> documents,
  Set<String> seen,
  DateTime now,
) => [
  for (final document in documents)
    if (downloadable(availabilityOf(document, now)) &&
        !seen.contains(document.id))
      document,
];

/// O "já visto" dos documentos gerados, guardado no aparelho (issue #110,
/// decisão 10 da E6).
///
/// É estado de leitura de uma pessoa num aparelho — como a preferência de
/// tema —, e não fato da escola, por isso não vai para o banco: nem para o
/// Supabase, nem para o Drift, que ganharia uma migration para guardar uma
/// lista de identificadores. Mora em `shared_preferences`, uma chave por
/// perfil (o mesmo critério do arquivo de banco por perfil: duas contas no
/// mesmo aparelho não herdam o que a outra viu).
///
/// É um [ChangeNotifier] porque quem marca (a tela de documentos) e quem lê
/// (o aviso da tela-casa) nunca estão na mesma árvore ao mesmo tempo.
///
/// Falha de armazenamento não derruba nada: sem ler, vale "nada visto"; sem
/// gravar, vale o que está na memória até fechar o aplicativo. O pior caso é
/// o aviso voltar uma vez a mais, e nunca deixar de aparecer o que ela não
/// viu.
class SeenDocuments extends ChangeNotifier {
  SeenDocuments(this.profileId);

  final String profileId;

  /// Quantos identificadores se guardam. A lista do servidor traz as últimas
  /// vinte gerações; o que passa disso já não volta, e guardar para sempre
  /// seria só acumular.
  static const limit = 100;

  final List<String> _ids = [];
  Future<void>? _loading;
  bool _loaded = false;

  String get _key => 'mae.seen_documents.$profileId';

  /// A leitura do aparelho terminou. Antes disso o aviso não aparece: mostrar
  /// e tirar logo depois seria piscar.
  bool get loaded => _loaded;

  Set<String> get ids => Set.unmodifiable(_ids);

  Future<void> load() => _loading ??= _load();

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final id in prefs.getStringList(_key) ?? const <String>[]) {
        if (!_ids.contains(id)) _ids.add(id);
      }
    } catch (_) {
      // Ver acima: sem ler, vale "nada visto".
    }

    _loaded = true;
    notifyListeners();
  }

  Future<void> markSeen(Iterable<String> ids) async {
    await load();

    final fresh = {
      for (final id in ids)
        if (!_ids.contains(id)) id,
    };
    if (fresh.isEmpty) return;

    _ids.addAll(fresh);
    if (_ids.length > limit) _ids.removeRange(0, _ids.length - limit);
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_key, List.of(_ids));
    } catch (_) {
      // Ver acima: sem gravar, vale a memória.
    }
  }
}
