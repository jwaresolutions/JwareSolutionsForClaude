# Domain: Tailwind CSS Styling
**Loaded when:** Agent is implementing or modifying UI styling, component layout, or responsive design.
**Key concern:** Consistent use of the design system's spacing, color, and breakpoint scales. No raw hex values in components.

---

## Utility-First Approach

All styling uses Tailwind utility classes. Custom CSS is a last resort, not a starting point.

```tsx
// RIGHT: Tailwind utilities
<button className="px-4 py-2 bg-primary-600 text-white rounded-lg hover:bg-primary-700 transition-colors">
  Submit
</button>

// WRONG: custom CSS for what Tailwind handles
<button className="submit-button">Submit</button>
// .submit-button { padding: 8px 16px; background: #2563eb; ... }
```

## Design Tokens

Colors, spacing, and typography are defined as design tokens in `tailwind.config.ts`. Use semantic names, not raw values.

```typescript
// tailwind.config.ts
theme: {
  extend: {
    colors: {
      primary: { 600: "#2563eb", 700: "#1d4ed8" },
      danger: { 500: "#ef4444", 600: "#dc2626" },
      success: { 500: "#22c55e", 600: "#16a34a" },
    },
  },
}
```

```tsx
// RIGHT: semantic token
<span className="text-danger-500">Position at risk</span>

// WRONG: raw hex
<span className="text-[#ef4444]">Position at risk</span>

// WRONG: arbitrary value when token exists
<span className="text-red-500">Position at risk</span>  // Use danger-500 for consistency
```

## Spacing Scale

Use Tailwind's spacing scale consistently. The scale is based on `0.25rem` (4px) increments:

| Class | Value | Use for |
|---|---|---|
| `p-1` / `m-1` | 4px | Tight gaps (icon padding) |
| `p-2` / `m-2` | 8px | Small gaps (between inline elements) |
| `p-4` / `m-4` | 16px | Standard padding (cards, sections) |
| `p-6` / `m-6` | 24px | Generous padding (page sections) |
| `gap-2` | 8px | Flex/grid gap between items |
| `gap-4` | 16px | Standard gap between cards/rows |
| `space-y-4` | 16px | Vertical stack spacing |

Do not use arbitrary values (`p-[13px]`) when a scale value is close enough. Arbitrary values break visual consistency.

## Responsive Design

Use Tailwind's breakpoint prefixes. Design mobile-first: base classes are mobile, prefixed classes are overrides for larger screens.

```tsx
// Mobile-first: stack on mobile, grid on desktop
<div className="flex flex-col gap-4 md:grid md:grid-cols-2 lg:grid-cols-3">
  <Card />
  <Card />
  <Card />
</div>
```

| Prefix | Min width | Target |
|---|---|---|
| (none) | 0px | Mobile (default) |
| `sm:` | 640px | Large phones / small tablets |
| `md:` | 768px | Tablets |
| `lg:` | 1024px | Desktops |
| `xl:` | 1280px | Large desktops |
| `2xl:` | 1536px | Extra-large screens |

## Dark Mode

Use the `dark:` prefix for dark mode variants. The project uses class-based dark mode (`darkMode: "class"` in config).

```tsx
<div className="bg-white dark:bg-gray-900 text-gray-900 dark:text-gray-100">
  <p className="text-gray-600 dark:text-gray-400">Secondary text</p>
</div>
```

## Component Composition

Build reusable components with variant props (maps of variant name to class string), not by duplicating utility strings across files. Use `clsx` or a `cn` utility for conditional class merging.

## Common Pitfalls

| Pitfall | Why it breaks | Fix |
|---|---|---|
| Raw hex in components (`text-[#ff0000]`) | Bypasses design system, inconsistent | Use semantic color tokens |
| Arbitrary spacing (`p-[13px]`) | Breaks visual rhythm | Use nearest scale value |
| Desktop-first responsive | Mobile layout breaks | Design mobile-first, add `md:`/`lg:` overrides |
| Inconsistent breakpoint usage | Layout breaks at some sizes | Use the same breakpoints across features |
| `className` string concatenation without template | Messy, hard to read | Use template literals or `clsx`/`cn` utility |
| Over-nesting utilities | Long unreadable class strings | Extract to component with variant props |
| No dark mode variants | Broken in dark theme | Add `dark:` variants for bg, text, border |
