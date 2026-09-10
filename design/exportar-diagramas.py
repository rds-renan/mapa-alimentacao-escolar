#!/usr/bin/env python3
"""Exporta os diagramas Mermaid da documentação para PNG.

Os diagramas vivem em blocos ```mermaid dentro dos Markdown de
docs/04-banco-de-dados/ — o GitHub os renderiza direto, então o Markdown
continua sendo a fonte. Este script só os fotografa em PNG, porque o
documento da faculdade recebe imagem, não bloco de código.

Duas escolhas que valem saber:

1. **O desenho é feito com o ELK**, e não com o layout padrão do Mermaid. O
   padrão empurra as caixas para longe umas das outras e liga tudo com curvas
   que atravessam o desenho inteiro, deixando os rótulos soltos longe das
   suas ligações. O ELK roteia em ângulos retos e mantém a hierarquia legível.
   Isso vale só para a exportação: no GitHub, o Markdown continua sendo
   desenhado pelo layout padrão, que ele suporta.

2. **O desenho acontece uma vez só.** A primeira passada renderiza e devolve
   o SVG pronto; a segunda apenas fotografa esse SVG, sem Mermaid nenhum na
   página. Desenhar de novo para fotografar arriscaria um layout diferente
   do que foi medido, e aí a imagem sairia cortada.

Precisa de Chrome, Chromium ou Brave (o script acha sozinho) e de internet:
as bibliotecas vêm de CDN.

    python3 design/exportar-diagramas.py
"""

import html
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ENTRADA = os.path.join(RAIZ, 'docs', '04-banco-de-dados')
SAIDA = os.path.join(RAIZ, 'docs', 'assets')

MERMAID = 'https://cdn.jsdelivr.net/npm/mermaid@11.15.0/dist/mermaid.esm.min.mjs'
ELK = 'https://cdn.jsdelivr.net/npm/@mermaid-js/layout-elk@0.2.3/dist/mermaid-layout-elk.esm.min.mjs'
ESCALA = 2
MARGEM = 24

# Um PNG por bloco: (arquivo de origem, índice do bloco, nome da imagem).
DIAGRAMAS = [
    ('diagrama-de-classes.md', 0, 'e4-diagrama-de-classes.png'),
    ('diagrama-de-classes.md', 1, 'e4-enumeracoes.png'),
    ('modelo-conceitual.md', 0, 'e4-modelo-conceitual.png'),
    ('modelo-er.md', 0, 'e4-modelo-er.png'),
]

NAVEGADORES = ['google-chrome-stable', 'google-chrome', 'chromium',
               'chromium-browser', 'brave', 'brave-browser']


def navegador():
    for nome in NAVEGADORES:
        caminho = shutil.which(nome)
        if caminho:
            return caminho
    sys.exit('Nenhum navegador encontrado. Instale Chrome, Chromium ou Brave.')


def chrome(executavel, *argumentos):
    return subprocess.run(
        [executavel, '--headless=new', '--disable-gpu', '--hide-scrollbars',
         '--virtual-time-budget=30000', *argumentos],
        capture_output=True, text=True, timeout=180)


def blocos(arquivo):
    texto = open(os.path.join(ENTRADA, arquivo), encoding='utf-8').read()
    return re.findall(r'```mermaid\n(.*?)```', texto, re.S)


def pagina_de_desenho(codigo):
    config = json.dumps({'startOnLoad': False, 'theme': 'neutral', 'layout': 'elk'})
    return f'''<!doctype html>
<html><head><meta charset="utf-8">
<style> body {{ margin: 0; background: #ffffff; }} </style>
</head><body>
<pre class="mermaid" id="alvo">{html.escape(codigo)}</pre>
<script type="module">
  import mermaid from '{MERMAID}';
  import elk from '{ELK}';
  mermaid.registerLayoutLoaders(elk);
  mermaid.initialize({config});
  try {{
    await mermaid.run({{ nodes: [document.getElementById('alvo')] }});
    const svg = document.querySelector('#alvo svg');
    const caixa = svg.viewBox.baseVal;
    svg.removeAttribute('style');
    svg.setAttribute('width', caixa.width);
    svg.setAttribute('height', caixa.height);
    document.title = 'PRONTO ' + Math.ceil(caixa.width) + ' ' + Math.ceil(caixa.height);
  }} catch (e) {{
    document.title = 'ERRO ' + e.message;
  }}
</script>
</body></html>'''


def pagina_de_foto(svg, largura, altura):
    """Só o SVG já desenhado. Sem Mermaid: nada é recalculado aqui."""
    return f'''<!doctype html>
<html><head><meta charset="utf-8">
<style>
  body {{ margin: 0; background: #ffffff; }}
  #moldura {{ display: inline-block; padding: {MARGEM}px; }}
  svg {{ display: block; width: {largura}px; height: {altura}px; }}
</style>
</head><body><div id="moldura">{svg}</div></body></html>'''


def desenhar(executavel, arquivo_html):
    """Devolve o SVG pronto e o seu tamanho, ou encerra explicando a falha."""
    dom = chrome(executavel, '--window-size=4000,4000', '--dump-dom',
                 'file://' + arquivo_html).stdout
    achado = re.search(r'<title>(PRONTO|ERRO) ([^<]*)</title>', dom)
    if not achado:
        sys.exit('O Mermaid não terminou de desenhar — provavelmente falta internet.')
    if achado.group(1) == 'ERRO':
        sys.exit(f'O Mermaid recusou o diagrama: {achado.group(2)}')
    largura, altura = (int(n) for n in achado.group(2).split())
    inicio, fim = dom.find('<svg'), dom.rfind('</svg>')
    return dom[inicio:fim + len('</svg>')], largura, altura


def main():
    executavel = navegador()
    os.makedirs(SAIDA, exist_ok=True)
    with tempfile.TemporaryDirectory() as tmp:
        for arquivo, indice, imagem in DIAGRAMAS:
            base = os.path.join(tmp, imagem[:-len('.png')])
            desenho = base + '-desenho.html'
            open(desenho, 'w', encoding='utf-8').write(
                pagina_de_desenho(blocos(arquivo)[indice]))
            svg, largura, altura = desenhar(executavel, desenho)

            foto = base + '-foto.html'
            open(foto, 'w', encoding='utf-8').write(
                pagina_de_foto(svg, largura, altura))
            chrome(executavel,
                   f'--window-size={largura + 2 * MARGEM},{altura + 2 * MARGEM}',
                   f'--force-device-scale-factor={ESCALA}',
                   '--screenshot=' + os.path.join(SAIDA, imagem),
                   'file://' + foto)
            print(f'{imagem:36s} {largura}×{altura} @{ESCALA}×  ({arquivo})')


if __name__ == '__main__':
    main()
