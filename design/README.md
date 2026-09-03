# design/

Fonte das telas do MAE — o que gera as imagens de [`docs/assets/`](../docs/assets/).

```
design/
├── telas/                # uma tela por arquivo .dc.html, mais canvas.json e o logo
└── exportar-telas.py     # remonta cada tela e fotografa em PNG
```

## O que é um `.dc.html`

HTML comum, com os estilos escritos direto nos elementos (`style="..."`), embrulhado em duas etiquetas do editor de design: `<x-dc>` marca a tela e `<helmet>` guarda os estilos globais dela. Abrir o arquivo num navegador mostra a tela — é HTML, não um formato binário.

Uma única tela tem lógica: `Main.dc.html`, o registro do dia, onde tocar em "Ótimo" ou no `+` da quantidade muda a tela. Ali aparecem `{{valores}}` vindos de um bloco `<script>` no fim do arquivo, e trechos `<sc-if>` que só existem em certos estados. Esse script mexe apenas no estado da própria tela: não faz rede, não guarda nada, não lê nada do aparelho.

## Regerar as imagens

```bash
python3 design/exportar-telas.py
```

Refaz todos os PNGs de `docs/assets/`, cada um no tamanho declarado no `canvas.json` e a 2× (nítido o bastante para entrar no documento da faculdade). Precisa de Chrome, Chromium ou Brave instalado — o script acha sozinho. As telas usam a fonte Geist, do Google Fonts, então a exportação quer internet; sem ela, o texto sai numa fonte substituta.

Três coisas que o script resolve e valem saber:

- **A tela do registro é congelada num estado**, o mesmo estado inicial do componente: lanche da manhã aberto, "Ótimo" marcado, 312 refeições. Está em `VALORES` e `CONDICOES`, no alto do arquivo.
- **Um segundo estado da mesma tela** é exportado à parte, com o almoço aberto, para a alteração do cardápio dentro do cartão aparecer em alguma imagem (`ESTADO_EXTRA`).
- **As telas que abrem por cima de outra** — o menu e o escolher gênero — são fotografadas sobre a tela de onde saem, senão o fundo escurecido viraria um retângulo cinza sem sentido (`SOBREPOSTAS`).

## Onde as telas são editadas

Num canvas de design fora do repositório, que é a superfície de edição de verdade — arrastar, ajustar, escrever no lugar. **Os arquivos daqui são uma cópia daquele canvas num momento**: se as telas mudarem lá e a cópia não for atualizada, regerar as imagens a partir daqui traz de volta o desenho antigo.

Regra prática: mexeu no canvas, atualize `design/telas/` antes de exportar.
