import { Navigate, Route, Routes } from 'react-router'

import { RequireRole, RequireSession } from '@/auth/guards'
import { AdminDashboard } from '@/pages/AdminDashboard'
import { DayRegister } from '@/pages/DayRegister'
import { FoodItems } from '@/pages/FoodItems'
import { ForgotPassword } from '@/pages/ForgotPassword'
import { GeneratedDocuments } from '@/pages/GeneratedDocuments'
import { MonthView } from '@/pages/MonthView'
import { NewPassword } from '@/pages/NewPassword'
import { SignIn } from '@/pages/SignIn'
import { ROUTES } from '@/routes'

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
          <Route
            path={ROUTES.generatedDocuments}
            element={<GeneratedDocuments />}
          />
          <Route path={ROUTES.foodItems} element={<FoodItems />} />
        </Route>

        <Route element={<RequireRole role="admin" />}>
          <Route path={ROUTES.adminHome} element={<AdminDashboard />} />
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
