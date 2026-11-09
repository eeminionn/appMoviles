import 'package:flutter/material.dart';

class AppColors {
  static const verde = Color(0xFF0D9F3F);
  static const verdeAccion = Color(0xFF0A7A2E);
  static const verdeOscuro = Color(0xFF075A20);
  static const verdeClaro = Color(0xFFF0F2E8);
  static const seleccion = Color(0xFFD8F5C8);
  static const azul = Color(0xFF3870D2);
  static const azulClaro = Color(0xFFEEF3FC);
  static const texto = Color(0xFF111827);
  static const secundario = Color(0xFF6B7280);
  static const borde = Color(0xFFE2E8EE);
  static const contorno = Color(0xFF9AA6B2);
  static const suave = Color(0xFFF8F9FB);
  static const blanco = Color(0xFFFFFFFF);
  static const error = Color(0xFFD41515);
  static const sombra = Color(0x14111827);
}

class AppSpacing {
  static const spacing2 = 2.0;
  static const spacing4 = 4.0;
  static const spacing8 = 8.0;
  static const spacing12 = 12.0;
  static const spacing16 = 16.0;
  static const spacing20 = 20.0;
  static const spacing24 = 24.0;
  static const spacing32 = 32.0;
  static const spacing40 = 40.0;
  static const spacing48 = 48.0;
  static const spacing56 = 56.0;
  static const spacing64 = 64.0;
  static const spacing72 = 72.0;
}

class AppRadius {
  static const tarjeta = 20.0;
  static const boton = 12.0;
  static const hoja = 23.0;
  static const barra = 10.0;
  static const circulo = 40.0;
}

class AppSize {
  static const anchoReferencia = 360.0;
  static const mapaInicio = 305.0;
  static const mapaTarifa = 476.0;
  static const mapaNegociacion = 293.0;
  static const mapaConfirmacion = 352.0;
  static const tarjeta = 156.0;
  static const barra = 64.0;
  static const icono = 24.0;
  static const boton = 44.0;
  static const guia = 45.0;
  static const grosorGuia = 3.0;
  static const elevacionMapa = 2.0;
  static const elevacionHoja = 3.0;
  static const anchoMenu = .84;
  static const proporcionMapa = .44;
}

class AppTheme {
  // Aquí van los estilos del Figma.
  static final tema = ThemeData(
    fontFamily: 'Inter',
    colorScheme: const ColorScheme.light(
      primary: AppColors.verdeAccion,
      onPrimary: AppColors.blanco,
      primaryContainer: AppColors.seleccion,
      onPrimaryContainer: AppColors.verdeOscuro,
      secondary: AppColors.azul,
      secondaryContainer: AppColors.azulClaro,
      surface: AppColors.blanco,
      onSurface: AppColors.texto,
      onSurfaceVariant: AppColors.secundario,
      outline: AppColors.contorno,
      outlineVariant: AppColors.borde,
      error: AppColors.error,
      shadow: AppColors.texto,
    ),
    scaffoldBackgroundColor: AppColors.blanco,
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.w700,
        letterSpacing: .5,
      ),
      headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
      headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w400),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w500,
        letterSpacing: .15,
      ),
      titleMedium: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w400,
        letterSpacing: .15,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: .1,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 1.5,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: .25,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: .4,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.25,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.25,
      ),
      labelSmall: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.5,
      ),
    ),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: AppColors.blanco,
      foregroundColor: AppColors.texto,
    ),
    inputDecorationTheme: InputDecorationTheme(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.spacing16,
        vertical: AppSpacing.spacing12,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.tarjeta),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.tarjeta),
        borderSide: const BorderSide(color: AppColors.contorno),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.tarjeta),
        borderSide: const BorderSide(color: AppColors.verdeOscuro),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, AppSize.boton),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.boton),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, AppSize.boton),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.boton),
        ),
        side: const BorderSide(color: AppColors.verdeOscuro),
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.blanco,
      surfaceTintColor: AppColors.blanco,
      shadowColor: AppColors.sombra,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.tarjeta),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.blanco,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.hoja),
        ),
      ),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      height: AppSize.barra,
      elevation: 0,
      backgroundColor: AppColors.blanco,
      indicatorColor: AppColors.seleccion,
      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(fontFamily: 'Inter', fontSize: 12, letterSpacing: .4),
      ),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.borde),
  );
}
