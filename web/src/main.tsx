import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import { QueryClientProvider } from '@tanstack/react-query'
import { BrowserRouter } from 'react-router'

import { AuthProvider } from '@/auth/auth-provider'
import { createQueryClient } from '@/lib/query-client'
import { SyncProvider } from '@/local/sync-provider'

import App from './App.tsx'
import './index.css'

const queryClient = createQueryClient()

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <BrowserRouter>
      {/*
       * A metade de cima da fronteira da decisão 4 da E5: o que vem do
       * servidor é da Query, o que ainda não subiu é da fila, logo abaixo.
       */}
      <QueryClientProvider client={queryClient}>
        <AuthProvider>
          {/*
           * A fila fica acima das rotas: enviar o que está no aparelho não é
           * assunto de nenhuma tela em particular, e precisa continuar
           * acontecendo com a merendeira em qualquer uma delas (CA#1 da US011).
           */}
          <SyncProvider>
            <App />
          </SyncProvider>
        </AuthProvider>
      </QueryClientProvider>
    </BrowserRouter>
  </StrictMode>
)
