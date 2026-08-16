import 'package:flutter/material.dart';

/// Paleta e estilo visual do WHITE CHAT (clone Kwai).
class AppColors {
  AppColors._();

  /// Fundo das telas Editar Perfil e Mensagens.
  static const Color background = Color(0xFFFFFFFF);

  /// Fundo do feed de videos.
  static const Color feedBackground = Color(0xFF000000);

  /// Roxo escuro dos overlays de gift.
  static const Color giftOverlay = Color(0xFF0A0A2A);

  /// Rosa Kwai (acoes, botoes, coracoes).
  static const Color pink = Color(0xFFFF2D55);

  /// Degrade rosa (Curtidas & Compartilhamentos).
  static const Color pinkStart = Color(0xFFFF2D55);
  static const Color pinkEnd = Color(0xFFFF6B81);

  /// Degrade amarelo (Comentarios e Mencoes).
  static const Color yellowStart = Color(0xFFFFB800);
  static const Color yellowEnd = Color(0xFFFFE066);

  /// Degrade roxo (Novos seguidores).
  static const Color purpleStart = Color(0xFF8E2DE2);
  static const Color purpleEnd = Color(0xFF4A00E0);

  /// Vermelho de badge nao lida.
  static const Color badgeRed = Color(0xFFF52D56);

  static const Color textDark = Color(0xFF1A1A1A);
  static const Color textGrey = Color(0xFF8A8A8E);
}

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'Roboto',
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.pink,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Roboto',
          fontWeight: FontWeight.w700,
          fontSize: 18,
          color: AppColors.textDark,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF0A0A0A),
        selectedItemColor: AppColors.pink,
        unselectedItemColor: Color(0xFF9A9A9A),
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.feedBackground,
      fontFamily: 'Roboto',
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.pink,
        brightness: Brightness.dark,
      ),
    );
  }
}

/// Gradiente padrao usado nos botoes de acao (pink -> pink claro).
List<Color> pinkGradient() => const [AppColors.pinkStart, AppColors.pinkEnd];

/// Gradiente das abas de notificacao conforme o tipo.
List<Color> notificationGradient(int type) {
  switch (type) {
    case 1: // Curtidas & Compartilhamentos
      return const [AppColors.pinkStart, AppColors.pinkEnd];
    case 2: // Comentarios e Mencoes
      return const [AppColors.yellowStart, AppColors.yellowEnd];
    default: // Novos seguidores
      return const [AppColors.purpleStart, AppColors.purpleEnd];
  }
}
