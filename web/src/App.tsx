import { lazy, Suspense } from 'react'
import { Navigate, Outlet, Route, Routes } from 'react-router'

import { RequireRole, RequireSession } from '@/auth/guards'
import { LoadingScreen } from '@/components/loading-screen'
import { DayRegister } from '@/pages/DayRegister'
import { FoodItems } from '@/pages/FoodItems'
import { ForgotPassword } from '@/pages/ForgotPassword'
import { GeneratedDocuments } from '@/pages/GeneratedDocuments'
import { MonthView } from '@/pages/MonthView'
import { NewPassword } from '@/pages/NewPassword'
import { SelectMaps } from '@/pages/SelectMaps'
import { SignIn } from '@/pages/SignIn'
import { ROUTES } from '@/routes'

/*
 * As telas da direção chegam sob demanda, e as da merendeira não.
 *
 * É a divisão por rota que a issue #84 deixou guardada, aplicada onde ela
 * paga: o fluxo do mapa é diário, feito de celular e numa rede ruim, e quem o
 * usa nunca abre a administração — são dois fluxos separados, não um com
 * telas a mais. Carregar a gestão junto com o login cobraria de todo dia dela
 * um peso que só a direção usa, de vez em quando e de computador.
 *
 * O `lazy` pede exportação padrão e as telas são nomeadas, como as demais;
 * o `then` é só a ponte entre as duas convenções.
 */
const AdminDashboard = lazy(() =>
  import('@/pages/AdminDashboard').then((tela) => ({
    default: tela.AdminDashboard,
  }))
)

const AdminManagement = lazy(() =>
  import('@/pages/AdminManagement').then((tela) => ({
    default: tela.AdminManagement,
  }))
)

const AdminMaps = lazy(() =>
  import('@/pages/AdminMaps').then((tela) => ({ default: tela.AdminMaps }))
)

/*
 * O mapa de rotas. Ele reproduz o fluxo de telas da E3: um fluxo para a
 * merendeira, outro para a direção, e o login como única porta de entrada dos
 * dois. As telas que faltam entram nas suas issues, cada uma dentro da guarda
 * que já está de pé aqui.
 */
export default function App() {
  return (
    <Routes>
      <Route path={ROUTES.signIn} element={<SignIn />} />
      <Route path={ROUTES.forgotPassword} element={<ForgotPassword />} />
      <Route path={ROUTES.newPassword} element={<NewPassword />} />

      <Route element={<RequireSession />}>
        <Route element={<RequireRole role="cook" />}>
          <Route path={ROUTES.cookHome} element={<MonthView />} />
          <Route path={ROUTES.dayRegister} element={<DayRegister />} />
          <Route path={ROUTES.selectMaps} element={<SelectMaps />} />
          <Route
            path={ROUTES.generatedDocuments}
            element={<GeneratedDocuments />}
          />
          <Route path={ROUTES.foodItems} element={<FoodItems />} />
        </Route>

        <Route element={<RequireRole role="admin" />}>
          {/*
           * Uma espera para as duas telas: o pedaço que chega é o mesmo, e a
           * espera é a mesma do arranque — o aplicativo já está aberto, e o
           * que falta é um arquivo pequeno.
           */}
          <Route
            element={
              <Suspense fallback={<LoadingScreen />}>
                <Outlet />
              </Suspense>
            }
          >
            <Route path={ROUTES.adminHome} element={<AdminDashboard />} />
            <Route
              path={ROUTES.adminManagement}
              element={<AdminManagement />}
            />
            <Route path={ROUTES.adminMaps} element={<AdminMaps />} />
          </Route>
        </Route>
      </Route>

      {/*
       * Endereço que não existe cai na casa de quem está logada — e, se não
       * houver ninguém logada, a guarda manda para o login.
       */}
      <Route path="*" element={<Navigate to={ROUTES.cookHome} replace />} />
    </Routes>
  )
}
