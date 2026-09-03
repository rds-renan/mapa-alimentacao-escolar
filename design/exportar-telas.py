#!/usr/bin/env python3
"""Exporta as telas de design/telas/ para PNG em docs/assets/.

Cada arquivo .dc.html é uma tela do canvas de design. Este script remonta
cada uma como uma página HTML comum e fotografa com o Chrome em modo
headless, no tamanho declarado no canvas.json e a 2x.

Uso:  python3 design/exportar-telas.py
"""

import json
import os
import re
import shutil
import subprocess
import sys
import unicodedata

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TELAS = os.path.join(RAIZ, 'design', 'telas')
SAIDA = os.path.join(RAIZ, 'docs', 'assets')
TEMP = os.path.join(RAIZ, 'design', '.tmp-paginas')

NAVEGADORES = ['google-chrome-stable', 'google-chrome', 'chromium', 'chromium-browser', 'brave']

# ---------------------------------------------------------------------------
# A tela do registro do dia (Main) é a única com lógica: os valores vêm de um
# componente em vez de estarem escritos no HTML. Para virar imagem ela precisa
# de um estado fixo — o mesmo estado inicial do componente.
# ---------------------------------------------------------------------------

ACENTO = '#397ba1'
BOTAO_ESCOLHIDO = ('flex-grow: 1; flex-basis: 0; min-height: 50px; border-radius: 10px; border: 1px solid '
                   + ACENTO + '; background: ' + ACENTO + '; color: #ffffff; font-size: 15px; font-weight: 600;')
BOTAO_NEUTRO = ('flex-grow: 1; flex-basis: 0; min-height: 50px; border-radius: 10px; border: 1px solid #e4e4e7;'
                ' background: #ffffff; color: #3f3f46; font-size: 15px; font-weight: 500;')


def seta(aberta):
    return ('display: flex; align-items: center; justify-content: center; color: #a1a1aa; flex-shrink: 0;'
            ' transform: rotate(' + ('180deg' if aberta else '0deg') + ');')


VALORES = {
    'manha.leite.qtd': '1', 'manha.pao.qtd': '4', 'almoco.arroz.qtd': '3', 'refeicoesDia': '312',
    'manha.otimo.style': BOTAO_ESCOLHIDO, 'manha.bom.style': BOTAO_NEUTRO, 'manha.ruim.style': BOTAO_NEUTRO,
    'almoco.otimo.style': BOTAO_NEUTRO, 'almoco.bom.style': BOTAO_ESCOLHIDO, 'almoco.ruim.style': BOTAO_NEUTRO,
    'tarde.otimo.style': BOTAO_NEUTRO, 'tarde.bom.style': BOTAO_NEUTRO, 'tarde.ruim.style': BOTAO_NEUTRO,
    'manha.setaStyle': seta(True), 'almoco.setaStyle': seta(False), 'tarde.setaStyle': seta(False),
    'switchTrack': ('width: 50px; height: 30px; border-radius: 999px; border: none; padding: 3px; display: flex;'
                    ' align-items: center; flex-shrink: 0; background: #d4d4d8; justify-content: flex-start;'),
    'switchKnob': ('display: block; width: 24px; height: 24px; border-radius: 999px; background: #ffffff;'
                   ' box-shadow: 0 1px 2px rgba(0, 0, 0, 0.25);'),
    'progressoBarra': 'height: 100%; border-radius: 999px; background: ' + ACENTO + '; width: 67%;',
}

# Trechos condicionais visíveis no estado acima (lanche da manhã aberto).
CONDICOES = {'letivo', 'manha.aberta', 'almoco.fechada'}

# Telas que aparecem por cima de outra: são fotografadas sobre ela.
SOBREPOSTAS = {'Menu.dc.html': 'VisaoDoMes.dc.html', 'EscolherGenero.dc.html': 'Main.dc.html'}

# Segundo estado da tela do registro, com o almoço aberto e a troca de cardápio à vista.
ESTADO_EXTRA = {
    'arquivo': 'Main.dc.html',
    'imagem': 'e3-3-registro-do-dia-alteracao.png',
    'rotulo': '3 · Registro (almoço aberto)',
    'largura': 390, 'altura': 1180,
    'condicoes': {'letivo', 'almoco.aberta', 'manha.fechada'},
    'valores': {'manha.setaStyle': seta(False), 'almoco.setaStyle': seta(True)},
}


def navegador():
    for nome in NAVEGADORES:
        caminho = shutil.which(nome)
        if caminho:
            return caminho
    sys.exit('Nenhum navegador encontrado. Instale um destes: ' + ', '.join(NAVEGADORES))


def resolver_condicoes(html, condicoes):
    """Mantém os trechos <sc-if> verdadeiros e remove os demais."""
    while True:
        abertura = re.search(r'<sc-if value="\{\{([^}]+)\}\}"[^>]*>', html)
        if not abertura:
            return html
        condicao = abertura.group(1).strip()
        profundidade, i = 1, abertura.end()
        while profundidade:
            proxima = re.search(r'<sc-if[^>]*>|</sc-if>', html[i:])
            i += proxima.end()
            profundidade += 1 if proxima.group(0).startswith('<sc-if') else -1
        dentro = html[abertura.end(): i - len('</sc-if>')]
        html = html[:abertura.start()] + (dentro if condicao in condicoes else '') + html[i:]


def fixar_valores(html, condicoes, valores):
    html = resolver_condicoes(html, condicoes)
    html = re.sub(r'\s+on[A-Za-z]+="\{\{[^}]+\}\}"', '', html)  # não há cliques numa imagem

    def trocar(achado):
        chave = achado.group(1).strip()
        if chave not in valores:
            sys.exit('Sem valor fixo para "%s" — acrescente em VALORES.' % chave)
        return valores[chave]

    return re.sub(r'\{\{([^}]+)\}\}', trocar, html)


def partes(arquivo, condicoes=CONDICOES, valores=VALORES):
    """Separa o <helmet> (estilos) do corpo da tela, já sem a lógica."""
    fonte = open(os.path.join(TELAS, arquivo), encoding='utf-8').read()
    corpo = fonte[fonte.index('<x-dc>') + len('<x-dc>'): fonte.index('</x-dc>')]
    helmet = re.search(r'<helmet>(.*?)</helmet>', corpo, re.S)
    cabeca = helmet.group(1) if helmet else ''
    if helmet:
        corpo = corpo.replace(helmet.group(0), '')
    corpo = re.sub(r'<script data-dc-script.*?</script>', '', corpo, flags=re.S)
    if '{{' in corpo or '<sc-if' in corpo:
        corpo = fixar_valores(corpo, condicoes, valores)
    return cabeca, corpo


def pagina(cabeca, corpo):
    return ('<!doctype html>\n<html lang="pt-BR">\n<head>\n<meta charset="utf-8">\n' + cabeca
            + '\n</head>\n<body>\n' + corpo + '\n</body>\n</html>\n')


def empilhada(arquivo_fundo, arquivo_topo, largura, altura):
    cabeca, fundo = partes(arquivo_fundo)
    _, topo = partes(arquivo_topo)
    corpo = ('<div style="position: relative; width: %dpx; height: %dpx; overflow: hidden;">'
             '<div style="position: absolute; inset: 0; overflow: hidden;">%s</div>'
             '<div style="position: absolute; inset: 0;">%s</div></div>') % (largura, altura, fundo, topo)
    return pagina(cabeca, corpo)


def nome_de_arquivo(titulo):
    limpo = unicodedata.normalize('NFKD', titulo).encode('ascii', 'ignore').decode()
    limpo = limpo.replace('·', ' ').lower()
    return 'e3-' + re.sub(r'-+', '-', re.sub(r'[^a-z0-9]+', '-', limpo)).strip('-') + '.png'


def fotografar(chrome, html, destino, largura, altura, apelido):
    caminho = os.path.join(TEMP, apelido + '.html')
    open(caminho, 'w', encoding='utf-8').write(html)
    subprocess.run([chrome, '--headless=new', '--disable-gpu', '--hide-scrollbars',
                    '--force-device-scale-factor=2', '--virtual-time-budget=6000',
                    '--window-size=%d,%d' % (largura, altura),
                    '--screenshot=' + destino, 'file://' + caminho],
                   check=True, capture_output=True)


def main():
    chrome = navegador()
    os.makedirs(TEMP, exist_ok=True)
    os.makedirs(SAIDA, exist_ok=True)
    # o logo é referenciado por nome pelas telas, então precisa estar ao lado delas
    shutil.copy(os.path.join(TELAS, 'logo.png'), TEMP)

    canvas = json.load(open(os.path.join(TELAS, 'canvas.json'), encoding='utf-8'))
    for tela in canvas['artboards']:
        arquivo, largura, altura = tela['file'], tela['w'], tela['h']
        if arquivo in SOBREPOSTAS:
            html = empilhada(SOBREPOSTAS[arquivo], arquivo, largura, altura)
        else:
            html = pagina(*partes(arquivo))
        imagem = nome_de_arquivo(tela['title'])
        fotografar(chrome, html, os.path.join(SAIDA, imagem), largura, altura, arquivo[:-len('.dc.html')])
        print('%-36s %s' % (imagem, tela['title']))

    extra = ESTADO_EXTRA
    valores = dict(VALORES, **extra['valores'])
    html = pagina(*partes(extra['arquivo'], extra['condicoes'], valores))
    fotografar(chrome, html, os.path.join(SAIDA, extra['imagem']),
               extra['largura'], extra['altura'], 'Main-estado-extra')
    print('%-36s %s' % (extra['imagem'], extra['rotulo']))

    shutil.rmtree(TEMP)


if __name__ == '__main__':
    main()
