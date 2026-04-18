"use client"

import i18n from "i18next"
import { initReactI18next } from "react-i18next"

/**
 * i18next setup for web.
 *
 * Keep the same keys and placeholder style as the mobile app (`%{var}` / `{{var}}`)
 * so a single set of translations can be shared between mobile and web.
 *
 * Monorepo consumers: replace the inline `resources` below with an import from
 * your shared i18n package, e.g.:
 *
 *   import { resources, DEFAULT_LANGUAGE, FALLBACK_LANGUAGE } from "@aldia/shared-i18n"
 *
 * Standalone projects: grow the objects here as needed.
 */
const resources = {
  es: {
    translation: {
      common: { ok: "OK", cancel: "Cancelar" },
    },
  },
  en: {
    translation: {
      common: { ok: "OK", cancel: "Cancel" },
    },
  },
}

const DEFAULT_LANGUAGE = "es"
const FALLBACK_LANGUAGE = "en"

if (!i18n.isInitialized) {
  void i18n.use(initReactI18next).init({
    resources,
    lng: DEFAULT_LANGUAGE,
    fallbackLng: FALLBACK_LANGUAGE,
    interpolation: { escapeValue: false },
  })
}

export { i18n }
