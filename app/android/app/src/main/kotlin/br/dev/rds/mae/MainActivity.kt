package br.dev.rds.mae

import android.content.Context
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // A tela de abertura acompanha a escolha de tema feita no app (issue
        // #111), e não só a do aparelho. O Android só conhece a do aparelho;
        // quando a escolha for outra, a janela troca de tema antes de existir.
        // O plugin shared_preferences grava em FlutterSharedPreferences, com
        // o prefixo "flutter." (lib/theme/theme_preference.dart).
        val choice = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            .getString("flutter.mae.theme", null)
        when (choice) {
            "light" -> setTheme(R.style.LaunchThemeLight)
            "dark" -> setTheme(R.style.LaunchThemeDark)
        }
        super.onCreate(savedInstanceState)
    }
}
