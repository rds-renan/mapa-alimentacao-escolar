import 'package:mae/documents/generation_gateway.dart';

/// Um [GenerationGateway] falso, sem servidor nenhum — o mesmo raciocínio do
/// `FakeSyncGateway` (decisão 4 da E6). As respostas saem na ordem em que
/// foram enfileiradas; sem nenhuma, a geração dá certo.
class FakeGenerationGateway implements GenerationGateway {
  final List<List<String>> calls = [];
  final List<GenerationFailure> failures = [];

  @override
  Future<GeneratedDocument> generate(List<String> mealMapIds) async {
    calls.add(mealMapIds);
    if (failures.isNotEmpty) throw failures.removeAt(0);

    return const GeneratedDocument(
      id: 'doc-1',
      fileName: 'mapa-da-alimentacao-escolar-setembro-2026.docx',
    );
  }
}
