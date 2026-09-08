#!/usr/bin/env python3
"""Exporta os diagramas Mermaid da documentação para PNG.

Os diagramas vivem em blocos ```mermaid dentro dos Markdown de
docs/04-banco-de-dados/ — o GitHub os renderiza direto, então o Markdown
continua sendo a fonte. Este script só fotografa cada um em PNG, porque o
documento da faculdade recebe imagem, não bloco de código.

Precisa de Chrome, Chromium ou Brave (o script acha sozinho) e de internet:
a biblioteca Mermaid vem de CDN.

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

MERMAID = 'https://cdnjs.cloudflare.com/ajax/libs/mermaid/11.15.0/mermaid.min.js'
ESCALA = 2

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


def blocos(arquivo):
    texto = open(os.path.join(ENTRADA, arquivo), encoding='utf-8').read()
    return re.findall(r'```mermaid\n(.*?)```', texto, re.S)


def pagina(codigo):
    """Uma página que desenha o diagrama e anuncia o tamanho final no título."""
    return f'''<!doctype html>
<html><head><meta charset="utf-8">
<script src="{MERMAID}"></script>
<style>
  body {{ margin: 0; background: #ffffff; }}
  #alvo {{ display: inline-block; padding: 24px; }}
</style>
</head><body>
<pre class="mermaid" id="alvo">{html.escape(codigo)}</pre>
<script>
  mermaid.initialize({{ startOnLoad: false, theme: 'neutral' }});
  mermaid.run({{ nodes: [document.getElementById('alvo')] }})
    .then(() => {{
      const svg = document.querySelector('#alvo svg');
      const caixa = svg.viewBox.baseVal;
      svg.removeAttribute('style');
      svg.setAttribute('width', caixa.width);
      svg.setAttribute('height', caixa.height);
      const r = document.getElementById('alvo').getBoundingClientRect();
      document.title = 'PRONTO ' + Math.ceil(r.width) + ' ' + Math.ceil(r.height);
    }})
    .catch(e => {{ document.title = 'ERRO ' + e.message; }});
</script>
</body></html>'''


def medir(chrome, arquivo_html):
    """Roda a página uma vez só para descobrir o tamanho do desenho."""
    saida = subprocess.run(
        [chrome, '--headless=new', '--disable-gpu', '--hide-scrollbars',
         '--virtual-time-budget=20000', '--window-size=2400,2400',
         '--dump-dom', 'file://' + arquivo_html],
        capture_output=True, text=True, timeout=120).stdout
    achado = re.search(r'<title>(PRONTO|ERRO) ([^<]*)</title>', saida)
    if not achado or achado.group(1) == 'ERRO':
        detalhe = achado.group(2) if achado else 'a página não terminou de desenhar'
        sys.exit(f'Mermaid falhou: {detalhe}')
    largura, altura = achado.group(2).split()
    return int(largura), int(altura)


def fotografar(chrome, arquivo_html, destino, largura, altura):
    subprocess.run(
        [chrome, '--headless=new', '--disable-gpu', '--hide-scrollbars',
         '--virtual-time-budget=20000',
         f'--window-size={largura},{altura}',
         f'--force-device-scale-factor={ESCALA}',
         '--screenshot=' + destino, 'file://' + arquivo_html],
        capture_output=True, timeout=120)


def main():
    chrome = navegador()
    os.makedirs(SAIDA, exist_ok=True)
    with tempfile.TemporaryDirectory() as tmp:
        for arquivo, indice, imagem in DIAGRAMAS:
            codigo = blocos(arquivo)[indice]
            html_path = os.path.join(tmp, imagem.replace('.png', '.html'))
            open(html_path, 'w', encoding='utf-8').write(pagina(codigo))
            largura, altura = medir(chrome, html_path)
            destino = os.path.join(SAIDA, imagem)
            fotografar(chrome, html_path, destino, largura, altura)
            print(f'{imagem:36s} {largura}×{altura} @{ESCALA}×  ({arquivo})')


if __name__ == '__main__':
    main()
