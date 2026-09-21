import { inflateRawSync } from 'node:zlib'

/*
 * Abrir o .docx que o teste baixou, o suficiente para ler o que está escrito
 * dentro dele.
 *
 * Um .docx é um zip, e o corpo do documento é uma entrada só —
 * `word/document.xml`. Percorrer os cabeçalhos locais e descomprimir a
 * entrada procurada cabe em vinte linhas e evita uma dependência que só o
 * teste usaria; e ler o conteúdo é o que separa "o arquivo chegou" de "o
 * arquivo é o que eu registrei", que é a pergunta que este teste responde.
 */

const ASSINATURA = 0x04034b50

export function readFromDocx(pacote: Buffer, entrada: string): string {
  let offset = 0

  while (
    offset + 30 <= pacote.length &&
    pacote.readUInt32LE(offset) === ASSINATURA
  ) {
    const method = pacote.readUInt16LE(offset + 8)
    const compressedSize = pacote.readUInt32LE(offset + 18)
    const nameLength = pacote.readUInt16LE(offset + 26)
    const extraLength = pacote.readUInt16LE(offset + 28)

    const nameStart = offset + 30
    const name = pacote
      .subarray(nameStart, nameStart + nameLength)
      .toString('utf8')
    const dataStart = nameStart + nameLength + extraLength
    const data = pacote.subarray(dataStart, dataStart + compressedSize)

    if (name === entrada) {
      return (method === 8 ? inflateRawSync(data) : data).toString('utf8')
    }

    offset = dataStart + compressedSize
  }

  throw new Error(
    `O arquivo baixado não tem a entrada ${entrada}. Ele é mesmo um .docx?`
  )
}

/** O texto corrido do documento: cada `w:t` do XML, na ordem em que aparece. */
export function documentText(xml: string): string {
  return [...xml.matchAll(/<w:t[^>]*>([^<]*)<\/w:t>/g)]
    .map((achado) => achado[1])
    .join('\n')
}
