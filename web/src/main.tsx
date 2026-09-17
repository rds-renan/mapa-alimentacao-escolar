import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import { BrowserRouter } from 'react-router'

import { AuthProvider } from '@/auth/auth-provider'
import { SyncProvider } from '@/local/sync-provider'

import App from './App.tsx'
import './index.css'

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <BrowserRouter>
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
    </BrowserRouter>
  </StrictMode>
)
