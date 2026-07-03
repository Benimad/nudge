---
name: Nudge
colors:
  surface: '#f9f9f8'
  surface-dim: '#dadad9'
  surface-bright: '#f9f9f8'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f3f4f3'
  surface-container: '#eeeeed'
  surface-container-high: '#e8e8e7'
  surface-container-highest: '#e2e2e2'
  on-surface: '#1a1c1c'
  on-surface-variant: '#474552'
  inverse-surface: '#2f3130'
  inverse-on-surface: '#f1f1f0'
  outline: '#787583'
  outline-variant: '#c8c4d4'
  surface-tint: '#5951b4'
  primary: '#574eb1'
  on-primary: '#ffffff'
  primary-container: '#7067cc'
  on-primary-container: '#fffbff'
  inverse-primary: '#c5c0ff'
  secondary: '#006c4e'
  on-secondary: '#ffffff'
  secondary-container: '#83f5c6'
  on-secondary-container: '#007151'
  tertiary: '#825100'
  on-tertiary: '#ffffff'
  tertiary-container: '#a36700'
  on-tertiary-container: '#fffbff'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#e4dfff'
  primary-fixed-dim: '#c5c0ff'
  on-primary-fixed: '#140067'
  on-primary-fixed-variant: '#41379b'
  secondary-fixed: '#86f8c9'
  secondary-fixed-dim: '#68dbae'
  on-secondary-fixed: '#002115'
  on-secondary-fixed-variant: '#00513a'
  tertiary-fixed: '#ffddb8'
  tertiary-fixed-dim: '#ffb95f'
  on-tertiary-fixed: '#2a1700'
  on-tertiary-fixed-variant: '#653e00'
  background: '#f9f9f8'
  on-background: '#1a1c1c'
  surface-variant: '#e2e2e2'
typography:
  headline-lg:
    fontFamily: Quicksand
    fontSize: 22px
    fontWeight: '500'
    lineHeight: 28px
    letterSpacing: -0.01em
  headline-md:
    fontFamily: Quicksand
    fontSize: 20px
    fontWeight: '500'
    lineHeight: 26px
  body-lg:
    fontFamily: Quicksand
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: Quicksand
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  label-lg:
    fontFamily: Quicksand
    fontSize: 14px
    fontWeight: '500'
    lineHeight: 20px
  label-sm:
    fontFamily: Quicksand
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
rounded:
  sm: 0.5rem
  DEFAULT: 1rem
  md: 1.5rem
  lg: 2rem
  xl: 3rem
  full: 9999px
spacing:
  base: 4px
  xs: 8px
  sm: 12px
  md: 16px
  lg: 24px
  xl: 32px
  gutter: 16px
  margin: 20px
---

## Brand & Style

The design system is centered on a "sensory-safe" and "neuro-inclusive" philosophy, specifically tailored for users with ADHD. The brand personality is encouraging, gentle, and non-shaming. It aims to reduce cognitive load and executive dysfunction anxiety by avoiding high-stress visual triggers.

The style is a blend of **Soft Minimalism** and **Tactile UI**. It prioritizes heavy whitespace to prevent overstimulation and utilizes a "Low-Arousal" visual hierarchy. There is a total absence of "emergency" red; instead, the system uses warm ambers and soft purples to guide attention without triggering a fight-or-flight response. The emotional response should be one of a "calm companion"—reliable, forgiving, and physically soft.

## Colors

This color palette is designed to be high-clarity but low-vibrancy to ensure a sensory-friendly experience.

- **Primary (Soft Purple):** Used for main actions and active states. It provides a distinct but calming focus point.
- **Success (Mint Green):** Used for completed habits and positive progress. It is grounded and earthy rather than neon.
- **Warning/Urgent (Amber):** This replaces all traditional "Error" or "Danger" red. It signals a need for attention (e.g., a missed habit) with a "gentle reminder" tone rather than a "failure" tone.
- **Background (Warm White):** A soft, paper-like off-white that reduces eye strain and screen glare compared to pure #FFFFFF.
- **Surface:** Use a slightly darker off-white or very faint tint of the primary color for card backgrounds to create subtle containment.

## Typography

The typography system uses **Quicksand** exclusively to maintain a consistent, friendly, and approachable feel. The rounded terminals of the glyphs mirror the roundedness of the UI components. 

To keep the interface simple and reduce "visual noise," the system is restricted to only two weights: **400 (Regular)** and **500 (Medium)**. Headlines are kept at a modest scale (max 22px) to ensure they feel like invitations rather than demands. Line heights are intentionally generous to improve readability for users who may struggle with dense blocks of text.

## Layout & Spacing

The layout follows a **fluid grid** model optimized for Android handheld devices. It emphasizes "Safe Space"—areas of the screen left intentionally empty to allow the eye to rest.

- **Margins:** A standard 20px side margin ensures content does not feel "squished" against the bezel.
- **Vertical Rhythm:** Elements are separated by generous gaps (24px or 32px) to prevent the UI from feeling cluttered, which can be overwhelming for ADHD users.
- **Touch Targets:** All interactive elements maintain a minimum 48x48dp footprint, with ample padding between adjacent buttons to prevent accidental taps.
- **Reflow:** On larger foldable screens or tablets, content is contained within a max-width of 600px to maintain focus in the center of the visual field.

## Elevation & Depth

This design system uses **Ambient Depth** rather than traditional shadows. The goal is to create a sense of soft tactility—like physical paper or felt.

- **Flat Surfaces:** Most "inactive" content sits directly on the Warm White background without shadows.
- **Elevated Cards:** Active habit cards or modals use a very soft, high-diffusion shadow: `y: 4, blur: 20, opacity: 0.04, color: #000`. 
- **Tonal Layers:** Depth is primarily communicated through subtle shifts in background color (e.g., a slightly darker tint for the "Today" view container) rather than heavy borders or deep shadows.
- **Focus States:** Instead of a harsh outline, focused items use a soft outer glow in the primary purple color.

## Shapes

The shape language is strictly **extra-rounded**. There are no sharp 90-degree corners in the entire application. 

- **Cards & Containers:** Fixed 16px radius. This provides a "friendly" containment that feels safe to the touch.
- **Buttons & Chips:** Fixed 24px radius (Pill-shaped). This makes interactive elements instantly recognizable and physically inviting.
- **Icons:** Must feature rounded caps and corners. Avoid thin, jagged lines; use a consistent 2px stroke weight with rounded ends.

## Components

### Buttons
Primary buttons are pill-shaped, using the Soft Purple background with white text. Secondary buttons use a light purple tint (10% opacity) with purple text. No "Destructive" red buttons; use the Amber color for "Archive" or "Reset" actions.

### Habit Cards
Cards include a 16px corner radius. They feature a "Gentle Status" indicator: a soft green check for completion, or a plain "nudge" icon for pending tasks. Avoid "X" marks or red symbols for missed habits; use an "It's Okay" message or a simple dash.

### Inputs
Text fields are represented by soft-tinted backgrounds rather than heavy outlines. They use the 16px corner radius. Labels are always visible (not floating) to reduce memory load.

### Chips & Tags
Used for categorizing habits (e.g., "Morning," "Self-Care"). These are pill-shaped with 24px radius. When selected, they utilize a soft glow rather than a high-contrast change.

### Progress Indicators
Use rounded, "thick" progress bars (12px height). Success is celebrated with a subtle haptic "thrum" and a soft mint green fill. Avoid countdown timers that create urgency; use "estimated time" labels instead.

### Feedback Modals
"No Shame" messaging is core. If a habit is missed, the modal should say "Life happens. Want to try again tomorrow?" or "Take a break, you're doing great." Use friendly, soft-shaped illustrations to accompany these messages.