---
name: Guardian Sentinel
colors:
  surface: '#f8f9ff'
  surface-dim: '#cbdbf5'
  surface-bright: '#f8f9ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#eff4ff'
  surface-container: '#e5eeff'
  surface-container-high: '#dce9ff'
  surface-container-highest: '#d3e4fe'
  on-surface: '#0b1c30'
  on-surface-variant: '#3d4a42'
  inverse-surface: '#213145'
  inverse-on-surface: '#eaf1ff'
  outline: '#6d7a72'
  outline-variant: '#bccac0'
  surface-tint: '#006c4a'
  primary: '#006948'
  on-primary: '#ffffff'
  primary-container: '#00855c'
  on-primary-container: '#f5fff7'
  inverse-primary: '#65dca8'
  secondary: '#516071'
  on-secondary: '#ffffff'
  secondary-container: '#d4e4f8'
  on-secondary-container: '#576677'
  tertiary: '#b61722'
  on-tertiary: '#ffffff'
  tertiary-container: '#da3437'
  on-tertiary-container: '#fffbff'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#82f9c2'
  primary-fixed-dim: '#65dca8'
  on-primary-fixed: '#002114'
  on-primary-fixed-variant: '#005237'
  secondary-fixed: '#d4e4f8'
  secondary-fixed-dim: '#b8c8db'
  on-secondary-fixed: '#0d1d2b'
  on-secondary-fixed-variant: '#394858'
  tertiary-fixed: '#ffdad7'
  tertiary-fixed-dim: '#ffb3ad'
  on-tertiary-fixed: '#410004'
  on-tertiary-fixed-variant: '#930013'
  background: '#f8f9ff'
  on-background: '#0b1c30'
  surface-variant: '#d3e4fe'
typography:
  headline-xl:
    fontFamily: Plus Jakarta Sans
    fontSize: 36px
    fontWeight: '700'
    lineHeight: 44px
    letterSpacing: -0.02em
  headline-xl-mobile:
    fontFamily: Plus Jakarta Sans
    fontSize: 28px
    fontWeight: '700'
    lineHeight: 36px
    letterSpacing: -0.01em
  headline-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 28px
    fontWeight: '600'
    lineHeight: 36px
    letterSpacing: -0.015em
  headline-lg-mobile:
    fontFamily: Plus Jakarta Sans
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
    letterSpacing: -0.01em
  headline-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
  headline-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 16px
    fontWeight: '600'
    lineHeight: 24px
  body-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  body-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 13px
    fontWeight: '400'
    lineHeight: 18px
  label-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
  label-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.01em
  caption-technical:
    fontFamily: Plus Jakarta Sans
    fontSize: 11px
    fontWeight: '500'
    lineHeight: 14px
    letterSpacing: 0.02em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  gutter: 1.5rem
  gutter-mobile: 1rem
  margin: 2rem
  margin-mobile: 1rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 1rem
  space-lg: 1.5rem
  space-xl: 2rem
  space-2xl: 3rem
---

## Brand & Style
The design system establishes a posture of composed vigilance, reassurance, and instantaneous clarity. Serving individuals and administrators in moments of peak vulnerability—such as device loss, physical theft, or active security breaches—the visual interface prioritizes high legibility and cognitive decompression over ornamental decoration.

The overarching aesthetic blends **Corporate/Modern Precision** with **Human-Centered Reassurance**. Visual noise is aggressively eliminated; every component presents explicit spatial hierarchy and unambiguous status signals. Rather than inducing panic through loud visual alarms, the interface relies on stable neutrals, soothing emerald accents, and strictly governed semantic states. The user experience maintains emotional composure while enabling immediate, error-free physical and remote actions.

## Colors
The palette operates strictly in **light mode** to ensure maximum outdoor screen legibility and reduce eye strain during emergency mobile recovery workflows. 

### Palette Architecture
- **Canvas Base (`#F7F9F8`):** A soft, anti-glare off-white foundation designed to provide comfort and contrast against elevated surfaces.
- **Surface / Card Background (`#FFFFFF`):** Pure white container surfaces framing mission-critical data.
- **Primary Brand (`#0F9D6E`):** Emerald green conveying system integrity, protection, and operational safety.
- **Primary Interactive Hover (`#0B7A55`):** Grounded deep emerald for confident tactile feedback.
- **Primary Subtle / Badge Surface (`#E6F7F1`):** A gentle tint providing low-friction contextual identification.
- **Text & Navigation Slate (`#3B4A5A`):** Cool slate-blue for comfortable sustained reading across navigational elements.
- **Headings & High-Emphasis Data (`#1E293B`):** Deep charcoal delivering decisive visual anchoring.
- **Text Muted & Secondary Data (`#64748B`):** Neutral gray-blue dedicated to secondary metrics, serial numbers, and microcopy.
- **Border / Divider (`#E2E8F0`):** Subtle structural delimiters maintaining container boundaries without visual clutter.

### Semantic Triage Roles
- **Safe / Connected (`#22C55E`):** Active telemetry, live ping, encrypted status.
- **Warning / Degraded Alert (`#F59E0B`):** Battery critically low, SIM swap detected, geofence boundary breached.
- **Danger / Theft & Lock Mode (`#EF4444`):** Strictly reserved for destructive or high-consequence recovery operations, including device lockout, siren deployment, and irreversible remote data erasure.

## Typography
Plus Jakarta Sans provides balanced geometric clarity with humane warmth, avoiding cold, robotic aesthetics while preserving crisp definition across screens of varying pixel densities.

### Hierarchy & Usage Rules
- **Display & Headings:** Rendered in `fontWeight: 600` or `700` using `#1E293B`. Used sparingly for critical screen titles, high-level device state transitions, and immediate actionable prompts.
- **Interactive Triggers:** All button labels, primary action calls, and tab identifiers strictly utilize `label-md` or `label-sm` with `fontWeight: 600` for crisp legibility.
- **Operational Data & Telemetry:** Timestamps, GPS coordinates, IMEI strings, and firmware version identifiers leverage `body-sm` or `caption-technical` in `fontWeight: 400` or `500` set in `#64748B`.
- **Tabular Figures:** For live battery drain, real-time signal monitors, and countdown timers, typography must enforce monospace numeric alignment (`font-variant-numeric: tabular-nums`) to avoid layout jitter during active recovery.

## Layout & Spacing
The layout leverages a responsive fluid-grid structure anchored by predictable vertical rhythm, ensuring high-urgency interactions never require hunting across dense clusters.

### Structural Breakpoints
- **Mobile (< 640px):** Single-column layout. Margin set to `margin-mobile` (16px) with an 8px base rhythm. Primary action buttons are pinned above bottom safe areas for effortless one-handed thumb interaction.
- **Tablet (641px - 1024px):** 8-column layout. Margin set to 24px. Splits live telemetry maps and device command panels into clear dual-pane interactions.
- **Desktop (> 1024px):** 12-column layout capped at a maximum width of `1280px` centered. Margins fixed at `margin` (32px). Dedicated to security operations, device fleet overviews, and deep forensics inspection.

### Internal Spacing Rhythm
- Compact internal card spacing defaults to `space-md` (16px).
- External structural stacking between independent functional widgets employs `space-lg` (24px) or `space-xl` (32px).
- Tight inline groupings (e.g., status dot + label) strictly utilize `space-xs` (4px) or `space-sm` (8px).

## Elevation & Depth
The system utilizes **Tonal Layers with Ambient Micro-Shadows**, combined with delicate structural outlines to create a grounded, calm atmosphere that prevents floating visual ambiguity.

### Surface Hierarchy
- **Canvas (Elevation 0):** Pure `#F7F9F8`. The grounding backdrop for all layouts.
- **Cards & Primary Modules (Elevation 1):** Solid `#FFFFFF` enclosed by a 1px border of `#E2E8F0` and an ambient shadow: `box-shadow: 0 1px 3px 0 rgba(15, 23, 42, 0.04), 0 1px 2px -1px rgba(15, 23, 42, 0.03)`.
- **Floating Overlays & Action Trays (Elevation 2):** Elevated interactive modals, location tracking sheets, and sticky recovery control bars. Built with a 1px border of `#E2E8F0` and `box-shadow: 0 10px 15px -3px rgba(15, 23, 42, 0.06), 0 4px 6px -4px rgba(15, 23, 42, 0.03)`.
- **Critical Action Modals & Drawers (Elevation 3):** Reserved for destructive actions (Wipe, Siren, Lock). Supported by a tinted backdrop (`rgba(30, 41, 59, 0.40)`) and an elevated drop shadow: `box-shadow: 0 20px 25px -5px rgba(15, 23, 42, 0.08), 0 8px 10px -6px rgba(15, 23, 42, 0.04)`.

Never apply aggressive blur filters or high-contrast drop shadows; visual calmness requires smooth, low-contrast tonal transitions.

## Shapes
A roundedness level of `2` provides a reassuring, approachable demeanor while upholding technical order.

### Geometric Conventions
- **Cards & Panels:** Standardize on `rounded-lg` (16px / `1rem`) to form clean, friendly protective containers.
- **Interactive Controls (Inputs, Standard Buttons):** Formed with `rounded` (12px / `0.75rem`), optimizing touch targets for ergonomic activation.
- **Pill Badges & Live Status Indicators:** Employ full circular curves (`rounded-full` / `9999px`) to immediately separate dynamic diagnostic tags from clickable rectangular elements.
- **Strict Regularity:** Inconsistent corner radii within identical hierarchies are prohibited to preserve order and calm.

## Components

### Buttons & Trigger Controls
- **Primary Action (Standard Protection):** Background `#0F9D6E`, text `#FFFFFF`, radius 12px. Minimum height of 48px on mobile for safe, touch-friendly engagement. Hover transition to `#0B7A55`. Focus ring of 3px `#0F9D6E` with 2px offset.
- **Destructive Action (Theft & Wipe Mode):** Background `#EF4444`, text `#FFFFFF`, radius 12px. Requires deliberate two-step confirmation (press-and-hold or secondary modal verification) to prevent catastrophic accidental activation.
- **Secondary / Ghost Button:** Background transparent or `#FFFFFF`, border 1px solid `#E2E8F0`, text `#3B4A5A`. Hover background `#F7F9F8`.

### Input Fields & Controls
- **Text & Search Fields:** Height 48px, background `#FFFFFF`, border 1px solid `#E2E8F0`, radius 12px, text `#1E293B`, placeholder `#64748B`. Active focus introduces a crisp 1.5px border of `#0F9D6E` and an emerald-tinted outer glow (`rgba(15, 157, 110, 0.15)`).
- **Switches & Toggles (Security Protections):** Track size 52px x 32px. Inactive track: `#E2E8F0`; Active track: `#0F9D6E`. The physical toggle thumb is `#FFFFFF` with elevation 1.

### Badges & Status Chips
- **Secure State:** Background `#E6F7F1`, text `#0B7A55`, border 1px solid rgba(15, 157, 110, 0.2). Accompanied by a solid `#22C55E` micro-dot.
- **Critical / Theft State:** Background `#FEF2F2`, text `#B91C1C`, border 1px solid rgba(239, 68, 68, 0.2). Accompanied by a pulsing `#EF4444` indicator.
- **Metadata Chip:** Background `#F1F5F9`, text `#475569`, border none, radius `9999px`, font `caption-technical`.

### Cards & Structured Lists
- **Device Card:** Surface `#FFFFFF`, border 1px solid `#E2E8F0`, padding 20px, radius 16px. Top header aligns device name, model badge, and live tracking status dot. Body rows display battery life, network carrier, and last verified timestamp in tabular `body-sm`.
- **Event Audit Log:** Alternating transparent and subtle surfaces (`#F8FAFC`). Each entry displays an icon representing the triggered event (e.g., SIM Removed, Geofence Exit), a brief label in `#1E293B`, and an unambiguous timestamp in `#64748B`.

### Domain-Specific Components
- **Emergency Action Bar:** Fixed-position bottom tray dedicated to high-stress recovery: includes three high-contrast buttons—*Trigger Sound Alarm*, *Lock Device Remotely*, and *Erase Sensitive Data*.
- **Telemetry Radar Widget:** Live GPS perimeter map card featuring an embedded emerald radial pulse indicating signal confidence, with a dedicated toggle to copy precise emergency coordinates for law enforcement reporting.