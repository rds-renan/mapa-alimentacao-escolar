/// Os textos da atualização. Curtos, e com as palavras dela: "nuvem", não
/// "servidor"; "atualizar o MAE", não "versão mínima".
library;

const updateTitle = 'Atualize o MAE';

const updateBody =
    'Seus registros ficam salvos no aparelho e vão para a nuvem depois da '
    'atualização.';

const updateAction = 'Atualizar';

const updateSearching = 'Procurando a versão nova…';

String updateDownloading(int? percent) =>
    percent == null ? 'Baixando…' : 'Baixando… $percent%';

const updateInstalling =
    'Siga as instruções na tela para instalar. Se elas não apareceram, toque '
    'em Atualizar de novo.';

const updateDownloadFailed =
    'Não deu para baixar agora. Confira a internet e tente de novo.';

const updateCorrupted = 'O arquivo chegou com defeito. Tente de novo.';

const updateNotAllowed =
    'O aparelho não deixou instalar. Toque em Atualizar e, se ele pedir, '
    'permita que o MAE instale aplicativos.';
