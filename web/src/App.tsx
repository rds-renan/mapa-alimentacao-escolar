import { useState } from 'react'

import { Button } from '@/components/ui/button'
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'

/*
 * Página de conferência dos tokens da E3 (issue #56). Não é tela do produto:
 * ela existe para que a paleta, a tipografia, os raios e o alvo de toque
 * possam ser vistos — no claro e no escuro — antes da primeira tela de
 * verdade, e sai quando a autenticação entrar (issue #59).
 */

const paleta = [
  { nome: 'primary', classe: 'bg-primary', rotulo: 'Acento do logo' },
  { nome: 'accent', classe: 'bg-accent', rotulo: 'Acento suave' },
  { nome: 'background', classe: 'bg-background', rotulo: 'Fundo' },
  { nome: 'card', classe: 'bg-card', rotulo: 'Cartão' },
  { nome: 'muted', classe: 'bg-muted', rotulo: 'Neutro' },
  { nome: 'success', classe: 'bg-success', rotulo: 'Confirmação' },
  { nome: 'warning', classe: 'bg-warning', rotulo: 'Atenção' },
  { nome: 'destructive', classe: 'bg-destructive', rotulo: 'Erro' },
  { nome: 'chart-1', classe: 'bg-chart-1', rotulo: 'Aceitação ótima' },
  { nome: 'chart-2', classe: 'bg-chart-2', rotulo: 'Aceitação boa' },
  { nome: 'chart-3', classe: 'bg-chart-3', rotulo: 'Aceitação ruim' },
]

const tipografia = [
  {
    classe: 'text-3xl font-semibold',
    rotulo: '3xl · 30 px · número em destaque',
  },
  { classe: 'text-2xl font-semibold', rotulo: '2xl · 22 px · título de seção' },
  { classe: 'text-xl font-semibold', rotulo: 'xl · 17 px · título de tela' },
  { classe: 'text-lg font-medium', rotulo: 'lg · 16 px · título de cartão' },
  { classe: 'text-base', rotulo: 'base · 14 px · corpo' },
  { classe: 'text-sm', rotulo: 'sm · 13 px · apoio' },
  { classe: 'text-xs', rotulo: 'xs · 12 px · rótulo' },
  { classe: 'text-2xs', rotulo: '2xs · 11 px · metadado' },
]

function App() {
  // A preferência de tema ainda não é gravada: persistir e seguir o aparelho
  // é a história do tema escuro (US024, issue #71). Aqui só se confere que a
  // variante escura dos tokens existe e fecha.
  const [escuro, setEscuro] = useState(false)

  return (
    <div className={escuro ? 'dark' : undefined}>
      <div className="min-h-dvh bg-background text-foreground">
        <div className="mx-auto flex max-w-screen flex-col gap-6 px-4 py-6">
          <header className="flex items-center gap-3">
            <img src="/logo.png" alt="" className="size-10" />
            <div className="flex flex-col">
              <span className="text-xl font-semibold">MAE</span>
              <span className="text-xs text-muted-foreground">
                Mapa da Alimentação Escolar
              </span>
            </div>
          </header>

          <Card>
            <CardHeader>
              <CardTitle>Fundação da web</CardTitle>
              <CardDescription>
                Os tokens da E3 no tema, antes da primeira tela.
              </CardDescription>
            </CardHeader>
            <CardContent className="flex flex-col gap-3">
              <p className="text-base">
                Tudo que se toca tem 44 px de altura, o alvo de toque mínimo da
                decisão 6 da E3. Os tamanhos menores existem só para a área de
                administração, que é de mouse.
              </p>
              <Button onClick={() => setEscuro((atual) => !atual)}>
                {escuro ? 'Ver no claro' : 'Ver no escuro'}
              </Button>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle>Paleta</CardTitle>
            </CardHeader>
            <CardContent className="grid grid-cols-2 gap-3">
              {paleta.map((cor) => (
                <div key={cor.nome} className="flex items-center gap-2">
                  <div
                    className={`size-10 shrink-0 rounded-md border border-border ${cor.classe}`}
                  />
                  <div className="flex min-w-0 flex-col">
                    <span className="truncate text-sm font-medium">
                      {cor.rotulo}
                    </span>
                    <span className="truncate text-2xs text-muted-foreground">
                      {cor.nome}
                    </span>
                  </div>
                </div>
              ))}
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle>Tipografia</CardTitle>
            </CardHeader>
            <CardContent className="flex flex-col gap-2">
              {tipografia.map((linha) => (
                <span key={linha.classe} className={linha.classe}>
                  {linha.rotulo}
                </span>
              ))}
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle>Controles</CardTitle>
              <CardDescription>
                O tamanho normal é o de dedo; o resto é exceção.
              </CardDescription>
            </CardHeader>
            <CardContent className="flex flex-col gap-4">
              <div className="flex flex-wrap items-center gap-2">
                <Button>Ótimo</Button>
                <Button variant="outline">Bom</Button>
                <Button variant="secondary">Ruim</Button>
                <Button variant="ghost">Cancelar</Button>
                <Button variant="destructive">Apagar</Button>
              </div>
              <div className="flex flex-wrap items-center gap-2">
                <Button size="lg">Grande · 48 px</Button>
                <Button size="sm">Médio · 40 px</Button>
                <Button size="xs">Pequeno · 32 px</Button>
              </div>
              <div className="flex flex-col gap-2">
                <Label htmlFor="exemplo">Número de refeições servidas</Label>
                <Input id="exemplo" inputMode="numeric" placeholder="0" />
              </div>
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  )
}

export default App
