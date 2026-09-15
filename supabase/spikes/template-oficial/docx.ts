// Leitura e escrita do pacote OOXML de um .docx.
//
// Um .docx é um zip de XMLs. Preencher o modelo oficial sem perder o formato
// significa mexer só no `word/document.xml` e devolver todo o resto — o brasão
// no cabeçalho, os estilos, as fontes — exatamente como veio.

import { unzipSync, zipSync } from "fflate";
import { DOMParser, XMLSerializer } from "xmldom";
import type { Document, Element, Node } from "xmldom";

export type { Document as XmlDocument, Element as XmlElement, Node as XmlNode };

/** Namespace do WordprocessingML: prefixo `w:` em todo o documento. */
export const W = "http://schemas.openxmlformats.org/wordprocessingml/2006/main";

export type Package = Record<string, Uint8Array>;

export function openPackage(bytes: Uint8Array): Package {
  return unzipSync(bytes);
}

export function closePackage(pkg: Package): Uint8Array {
  return zipSync(pkg, { level: 6 });
}

export function readXml(pkg: Package, part: string): Document {
  const raw = pkg[part];
  if (!raw) throw new Error(`parte ausente no pacote: ${part}`);
  return new DOMParser().parseFromString(new TextDecoder().decode(raw), "text/xml");
}

export function writeXml(pkg: Package, part: string, doc: Document): void {
  pkg[part] = new TextEncoder().encode(new XMLSerializer().serializeToString(doc));
}

// --- navegação -------------------------------------------------------------

/** Filhos diretos `w:<local>` — não desce na árvore, ao contrário de `descendants`. */
export function children(node: Element, local: string): Element[] {
  const out: Element[] = [];
  for (let i = 0; i < node.childNodes.length; i++) {
    const child = node.childNodes[i];
    if (child.nodeType === 1) {
      const el = child as Element;
      if (el.namespaceURI === W && el.localName === local) out.push(el);
    }
  }
  return out;
}

export function firstChild(node: Element, local: string): Element | null {
  return children(node, local)[0] ?? null;
}

export function descendants(node: Element, local: string): Element[] {
  const live = node.getElementsByTagNameNS(W, local);
  const out: Element[] = [];
  for (let i = 0; i < live.length; i++) out.push(live[i]);
  return out;
}

export function textOf(node: Element): string {
  return descendants(node, "t").map((t) => t.textContent ?? "").join("");
}

// --- edição ----------------------------------------------------------------

export function makeElement(reference: Node, local: string): Element {
  const owner = reference.ownerDocument ?? (reference as Document);
  return owner.createElementNS(W, `w:${local}`);
}

export function setAttribute(el: Element, local: string, value: string): void {
  el.setAttributeNS(W, `w:${local}`, value);
}

export function getAttribute(el: Element, local: string): string | null {
  return el.getAttributeNS(W, local);
}

export function removeElement(el: Element): void {
  el.parentNode?.removeChild(el);
}

export function insertBefore(reference: Element, node: Element): void {
  reference.parentNode?.insertBefore(node, reference);
}

/**
 * Garante o `w:<local>` como primeiro filho de um bloco de propriedades
 * (`w:trPr`, `w:tcPr`): a ordem dos elementos é normativa no OOXML e o Word
 * recusa o arquivo quando ela é quebrada.
 */
export function ensureFirstChild(parent: Element, local: string): Element {
  const existing = firstChild(parent, local);
  if (existing) return existing;
  const created = makeElement(parent, local);
  parent.insertBefore(created, parent.firstChild);
  return created;
}
