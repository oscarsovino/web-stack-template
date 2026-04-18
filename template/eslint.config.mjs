import { defineConfig, globalIgnores } from "eslint/config"
import nextVitals from "eslint-config-next/core-web-vitals"
import nextTs from "eslint-config-next/typescript"
import jsxA11y from "eslint-plugin-jsx-a11y"
import prettierConfig from "eslint-config-prettier/flat"

// `next/core-web-vitals` already registers `jsx-a11y` with a subset of rules.
// We extend with the full recommended ruleset; do not redefine the plugin here.
// `eslint-config-prettier/flat` must be last so it turns off any rules that
// conflict with Prettier formatting.
const eslintConfig = defineConfig([
  ...nextVitals,
  ...nextTs,
  {
    files: ["**/*.{ts,tsx,js,jsx}"],
    rules: {
      ...jsxA11y.configs.recommended.rules,

      // SPEC enforcement — hard bans
      "react/no-danger": "error",
      "@typescript-eslint/ban-ts-comment": [
        "error",
        {
          "ts-ignore": true,
          "ts-nocheck": true,
          "ts-check": false,
          "ts-expect-error": "allow-with-description",
          minimumDescriptionLength: 10,
        },
      ],

      // Ban FK joins to auth.users in Supabase queries.
      // Enrich profiles with a separate query instead (SPEC §4.1).
      "no-restricted-syntax": [
        "error",
        {
          selector: "Literal[value=/auth\\.users/]",
          message:
            "Do not join auth.users. Query the profiles table separately and enrich. (SPEC §4.1)",
        },
        {
          selector: "TemplateElement[value.cooked=/auth\\.users/]",
          message:
            "Do not join auth.users. Query the profiles table separately and enrich. (SPEC §4.1)",
        },
      ],
    },
  },
  globalIgnores([".next/**", "out/**", "build/**", "next-env.d.ts"]),
  prettierConfig,
])

export default eslintConfig
