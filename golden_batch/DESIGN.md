# Design System Document

## 1. Overview & Creative North Star: "The Artisanal Ledger"

This design system rejects the sterile, "SaaS-blue" aesthetics of traditional finance apps. Instead, it adopts the **Artisanal Ledger**—a Creative North Star that blends the tactile warmth of a high-end bakery with the precision of a professional treasury.

We break the "template" look by treating the mobile screen as a series of layered parchment and glass. By utilizing intentional asymmetry, oversized editorial typography for financial totals, and a total ban on traditional dividing lines, we create an experience that feels "appetizing" yet authoritative. The goal is to make managing cash flow feel as satisfying as the scent of freshly baked cookies.

---

## 2. Colors: Tonal Warmth & The "No-Line" Rule

The palette is rooted in organic earth tones, moving from deep "burnt sugar" primaries to soft "clotted cream" neutrals. The color mode is currently **dark**, setting a sophisticated, rich backdrop for the artisanal aesthetic.

### Palette Strategy
*   **Primary (`#001474`) & Primary Container (`#6173c6`):** Use these for high-intent actions. To provide "visual soul," apply a subtle linear gradient (Top-Left to Bottom-Right) between these two tokens for hero buttons or active states.
*   **Surface Hierarchy (The Nesting Principle):**
    *   **Base:** Use `surface` (`#fdf9ee`) for the overall page background.
    *   **Sectioning:** Use `surface-container-low` (`#f7f3e8`) to define large content blocks.
    *   **Highlight:** Use `surface-container-lowest` (`#ffffff`) for individual cards or interactive elements.
*   **The "No-Line" Rule:** 1px solid borders are strictly prohibited for sectioning. Definition must be achieved through background shifts. If a `surface-container-highest` element sits on a `surface` background, the contrast provides the boundary.
*   **Glassmorphism:** For floating action buttons or bottom navigation, use `surface` at 80% opacity with a `20px` backdrop-blur to allow cookie product imagery or list data to bleed through softly.

---

## 3. Typography: Editorial Precision

We use a high-contrast pairing: **Plus Jakarta Sans** for characterful brand moments and **Inter** for data-heavy financial tracking.

*   **Display (Plus Jakarta Sans):** Used for "Big Numbers" (Daily Revenue, Profit). Use `display-lg` (3.5rem) to make the IDR currency feel monumental.
*   **Headline (Plus Jakarta Sans):** Used for category headers (e.g., "Top Selling Cookies"). It adds a bespoke, editorial feel.
*   **Body & Labels (Inter):** Used for all IDR values in lists and micro-copy. Inter’s tall x-height ensures `Rp 1.000.000` remains legible even at `body-sm`.
*   **Visual Weight:** Always use `on-surface-variant` (`#564338`) for labels to create a sophisticated, low-contrast look against the cream backgrounds, reserving `on-surface` (`#1c1c15`) for primary data.

---

## 4. Elevation & Depth: Tonal Layering

Traditional shadows are "heavy." We utilize **Tonal Layering** to create a sense of physical presence.

*   **The Layering Principle:** Depth is achieved by stacking. A `surface-container-lowest` card placed on a `surface-container-high` section creates a natural "lift" without a single drop shadow.
*   **Ambient Shadows:** Where floating elements (like the Bottom Nav) require separation, use a shadow with a `24px` blur and `4%` opacity, tinted with the `shadow` color (derived from `on-surface`). Never use pure black or grey.
*   **The "Ghost Border" Fallback:** If accessibility requires a stroke, use `outline-variant` (`#ddc1b3`) at **15% opacity**. It should feel like a watermark, not a wall.

---

## 5. Components: Tactile & Integrated

### Buttons
*   **Primary:** Rounded with **subtle roundedness** (1). Use the Primary-to-Container gradient. Text is `on-primary` (`#ffffff`).
*   **Tertiary:** No background, no border. Use `primary` text weight `600`.

### Cards & Lists (The "Anti-Divider" List)
*   **Constraint:** Forbid `hr` tags or divider lines.
*   **Execution:** Separate list items using `spacing-4` (1rem) of vertical white space or by alternating background colors between `surface-container-low` and `surface-container-lowest`.
*   **Currency Display:** Always right-align IDR values. Use `tertiary` (`#006290`) for neutral cash flow and `error` (`#ba1a1a`) for expenses.

### Input Fields
*   **Style:** Pill-shaped (`full` roundedness) or `xl` (3rem).
*   **Background:** Use `surface-container-highest`.
*   **Active State:** A `2px` "Ghost Border" of `primary` at 40% opacity.

### Bottom Navigation
*   **Visual:** A floating "dock" using Glassmorphism.
*   **Spacing:** `spacing-4` (1rem) margin from the bottom and sides of the screen, creating an island effect that feels modern and unconstrained.

### Custom Component: The "Batch Status" Chip
*   Use these for cookie inventory (e.g., "Baking," "Ready," "Sold Out"). Use `secondary-container` with `on-secondary-container` text. Roundedness must be `full` to mimic the circular nature of the product.

---

## 6. Do’s and Don’ts

### Do
*   **Do** use `display-lg` for the total balance in IDR. It should be the loudest thing on the screen.
*   **Do** use asymmetrical spacing (e.g., more padding at the top of a card than the bottom) to create a high-end, gallery feel.
*   **Do** ensure all interactive elements use a minimum `12px` (`sm`) corner radius to maintain the "soft/appetizing" brand promise.

### Don’t
*   **Don't** use pure `#000000` for text. Use `on-surface` (`#1c1c15`) to keep the "warmth" of the cream background intact.
*   **Don't** use standard Material Design elevation shadows. Stick to Tonal Layering.
*   **Don't** cram data. If the cash flow list is long, use `spacing-8` between logical groups to let the design breathe.