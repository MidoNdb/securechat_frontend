// lib/core/utils/phone_formatter.dart

import 'dart:io';

class PhoneFormatter {
  // Détecte le code pays depuis la locale de l'appareil
  static String getDefaultCountryCode() {
    try {
      final locale = Platform.localeName; // "fr_MR", "en_US", etc.
      final countryCode = locale.split('_').last.toUpperCase();
      
      final countryMap = {
        'MR': '+222', // Mauritanie
        'FR': '+33',  // France
        'SN': '+221', // Sénégal
        'ML': '+223', // Mali
        'DZ': '+213', // Algérie
        'MA': '+212', // Maroc
        'TN': '+216', // Tunisie
        'US': '+1',   // USA
        'GB': '+44',  // UK
      };
      
      return countryMap[countryCode] ?? '+222'; // Par défaut Mauritanie
    } catch (e) {
      return '+222'; // Fallback
    }
  }
  
  // Normalise au format E.164 : +22244010447
  static String normalizePhoneNumber(String input, String countryCode) {
    // 1. Enlever tous les caractères non-numériques sauf +
    String cleaned = input.replaceAll(RegExp(r'[^0-9+]'), '');
    
    // 2. Si vide, retourner vide
    if (cleaned.isEmpty) return '';
    
    // 3. Si commence par +, vérifier si déjà complet
    if (cleaned.startsWith('+')) {
      return cleaned;
    }
    
    // 4. Si commence par 00 (format international alternatif)
    if (cleaned.startsWith('00')) {
      return '+${cleaned.substring(2)}';
    }
    
    // 5. Enlever le code pays si déjà présent sans +
    final codeWithoutPlus = countryCode.substring(1); // +222 → 222
    if (cleaned.startsWith(codeWithoutPlus)) {
      return '+$cleaned';
    }
    
    // 6. Enlever le 0 initial (numéro local)
    if (cleaned.startsWith('0')) {
      cleaned = cleaned.substring(1);
    }
    
    // 7. Ajouter le code pays
    return '$countryCode$cleaned';
  }
  
  // Formate pour affichage : +222 44 01 04 47
  static String formatForDisplay(String e164Number) {
    if (!e164Number.startsWith('+')) return e164Number;
    
    // Détecter le code pays
    String countryCode = '+222';
    final codes = ['+222', '+33', '+221', '+223', '+1'];
    
    for (var code in codes) {
      if (e164Number.startsWith(code)) {
        countryCode = code;
        break;
      }
    }
    
    // Extraire le numéro sans code pays
    String number = e164Number.substring(countryCode.length);
    
    // Pattern de formatage par pays
    if (countryCode == '+222') {
      // Mauritanie : +222 44 01 04 47
      if (number.length >= 8) {
        return '+222 ${number.substring(0, 2)} ${number.substring(2, 4)} ${number.substring(4, 6)} ${number.substring(6)}';
      }
    } else if (countryCode == '+33') {
      // France : +33 6 12 34 56 78
      if (number.length >= 9) {
        return '+33 ${number.substring(0, 1)} ${number.substring(1, 3)} ${number.substring(3, 5)} ${number.substring(5, 7)} ${number.substring(7)}';
      }
    }
    
    // Par défaut : espaces tous les 2 chiffres
    String formatted = countryCode;
    for (int i = 0; i < number.length; i += 2) {
      formatted += ' ${number.substring(i, i + 2 > number.length ? number.length : i + 2)}';
    }
    return formatted.trim();
  }
  
  // Valide le format E.164
  static bool isValidPhoneNumber(String e164Number) {
    // Regex E.164 : +[1-9]\d{1,14}
    final regex = RegExp(r'^\+[1-9]\d{7,14}$');
    return regex.hasMatch(e164Number);
  }
  
  // Retourne le flag emoji du pays
  static String getFlagEmoji(String countryCode) {
    final flags = {
      '+222': '🇲🇷', // Mauritanie
      '+33': '🇫🇷',  // France
      '+221': '🇸🇳', // Sénégal
      '+223': '🇲🇱', // Mali
      '+213': '🇩🇿', // Algérie
      '+212': '🇲🇦', // Maroc
      '+216': '🇹🇳', // Tunisie
      '+1': '🇺🇸',   // USA
      '+44': '🇬🇧',  // UK
    };
    return flags[countryCode] ?? '🌍';
  }
  
  // Liste des pays disponibles
  static Map<String, Map<String, String>> getCountries() {
    return {
      'MR': {'code': '+222', 'flag': '🇲🇷', 'name': 'Mauritanie'},
      'FR': {'code': '+33', 'flag': '🇫🇷', 'name': 'France'},
      'SN': {'code': '+221', 'flag': '🇸🇳', 'name': 'Sénégal'},
      'ML': {'code': '+223', 'flag': '🇲🇱', 'name': 'Mali'},
      'DZ': {'code': '+213', 'flag': '🇩🇿', 'name': 'Algérie'},
      'MA': {'code': '+212', 'flag': '🇲🇦', 'name': 'Maroc'},
      'TN': {'code': '+216', 'flag': '🇹🇳', 'name': 'Tunisie'},
      'US': {'code': '+1', 'flag': '🇺🇸', 'name': 'USA'},
      'GB': {'code': '+44', 'flag': '🇬🇧', 'name': 'Royaume-Uni'},
    };
  }
}