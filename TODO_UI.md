# UI Restructure: Tab-Based Interface

**Status**: Planning
**Priority**: High
**Estimated Effort**: 2-3 days

---

## Overview

Transform RepoReconnoiter from a fragmented UI into a cohesive tab-based interface that clearly separates the two core functionalities:

1. **Compare Libraries** - AI-powered comparison of open source tools for specific use cases
2. **Deep Analysis** - Comprehensive analysis of individual GitHub repositories

This restructure improves discoverability, reduces cognitive load, and creates a professional, tool-like experience similar to GitHub, Linear, and Stripe.

---

## Current State vs. Proposed State

### Current State
- Homepage (`/`) - Shows comparison feed with dual feature cards at top (authenticated only)
- Deep Analysis page (`/repositories`) - Separate page with repo search form
- Repository show page (`/repositories/:id`) - Shows individual repo analysis
- Fragmented navigation - Users must navigate between different pages

### Proposed State
- Homepage (`/`) - Hero section + tabbed interface
  - **Tab 1: Comparisons** - Feed of comparisons with filters
  - **Tab 2: Analyses** - Feed of analyzed repositories
- Sticky quick actions bar - Always accessible creation flows
- Repository show page (`/repositories/:id`) - Enhanced with cross-linking
- Unified navigation - Everything accessible from homepage

---

## Detailed Component Breakdown

### 1. Hero Section (Above the Fold)

**Purpose**: Explain value prop and provide primary CTAs for new/unauthenticated users

**Layout**:
```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│  🔍 AI-Powered Open Source Intelligence                        │
│                                                                 │
│  Discover, analyze, and compare GitHub repositories            │
│  to make better tech stack decisions.                          │
│                                                                 │
│  ┌───────────────────────┐  ┌──────────────────────────────┐  │
│  │ 📊 COMPARE LIBRARIES  │  │ 🔍 ANALYZE REPOSITORY        │  │
│  ├───────────────────────┤  ├──────────────────────────────┤  │
│  │ Find the best open    │  │ Deep dive into any GitHub    │  │
│  │ source tools for your │  │ repo with AI-powered         │  │
│  │ specific needs        │  │ insights                     │  │
│  │                       │  │                              │  │
│  │ [Compare Tools →]     │  │ [Analyze Repo →]             │  │
│  └───────────────────────┘  └──────────────────────────────┘  │
│                                                                 │
│  [× Dismiss]  ← localStorage: don't show for returning users   │
└─────────────────────────────────────────────────────────────────┘
```

**Features**:
- Dismissible (stored in localStorage: `hero_dismissed: true`)
- Auto-hides for authenticated users after first dismissal
- "Compare Tools" button opens Comparisons tab + focuses search
- "Analyze Repo" button opens Analyses tab + focuses repo input

**Visual Design**:
- Gradient background (subtle blue/purple)
- Two equal-width cards side-by-side (grid-cols-2)
- Clear icon differentiation (📊 vs 🔍)
- Hover states with shadow lift effect

---

### 2. Tabbed Navigation

**Purpose**: Separate the two core use cases into distinct, focused views

**Layout**:
```
┌─────────────────────────────────────────────────────────────────┐
│  ┌──────────────────┐  ┌──────────────────┐                    │
│  │  Comparisons  (42)│  │  Analyses  (18)  │                    │
│  └──────────────────┘  └──────────────────┘                    │
│  ────────────────────                                           │
│  Active tab underline                                           │
└─────────────────────────────────────────────────────────────────┘
```

**Behavior**:
- URL-based routing:
  - `/?tab=comparisons` (default)
  - `/?tab=analyses`
- Turbo Frames for instant tab switching (no page reload)
- Count badges showing total items in each tab
- Active state: Underline + bold text + blue color
- Preserves scroll position when switching tabs

**Implementation Notes**:
- Use Stimulus controller for tab switching (`tabs_controller.js`)
- Store active tab in URL params (bookmarkable, shareable)
- Turbo Frame lazy loading for inactive tabs (performance)

---

### 3. Comparisons Tab Content

**Purpose**: Browse, search, and filter existing comparisons

**Layout**:
```
┌─────────────────────────────────────────────────────────────────┐
│  [Search...]  [Date ▾]  [Sort ▾]  [Apply Filters]  [Clear]     │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │ 📊 Rails background job library                           │ │
│  │ Tech Stack: Rails, Ruby • Problem: Background Processing  │ │
│  │                                                            │ │
│  │ 1. sidekiq/sidekiq ⭐ 13.2k  [Analyze This Repo →]        │ │
│  │ 2. mperham/sidekiq-pro ⭐ 8.1k  [Analyze This Repo →]     │ │
│  │ 3. collectiveidea/delayed_job ⭐ 4.8k                     │ │
│  │                                                            │ │
│  │ Created 2 days ago • 3 repositories compared              │ │
│  └───────────────────────────────────────────────────────────┘ │
│                                                                 │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │ 📊 Python web frameworks for APIs                         │ │
│  │ ...                                                        │ │
│  └───────────────────────────────────────────────────────────┘ │
│                                                                 │
│  [Load More]                                                   │
└─────────────────────────────────────────────────────────────────┘
```

**Components**:
- **Filter Bar**: Search, date range, sort order (existing functionality)
- **Comparison Cards**: Existing design with NEW cross-link buttons
- **Infinite Scroll**: Keep existing implementation
- **Empty State**: Show when no comparisons match filters

**New Feature - Cross-linking**:
- Each repository in comparison results gets "Analyze This Repo →" button
- Button checks if repo already analyzed:
  - **If yes**: Links to `/repositories/:id` (view existing analysis)
  - **If no**: Opens analyses tab + pre-fills repo URL (ready to analyze)

---

### 4. Analyses Tab Content

**Purpose**: Browse analyzed repositories and run new analyses

**Layout**:
```
┌─────────────────────────────────────────────────────────────────┐
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ 🔍 Analyze a Repository                                  │   │
│  │                                                           │   │
│  │ [https://github.com/owner/repo or owner/repo]  [Analyze] │   │
│  │                                                           │   │
│  │ Cost: ~$0.03-0.05 per analysis                           │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  [Search...]  [Language ▾]  [Sort ▾]  [Apply Filters]          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │ 🔍 sidekiq/sidekiq                                        │ │
│  │ Simple, efficient background processing for Ruby          │ │
│  │                                                            │ │
│  │ ⭐ 13.2k • 🍴 2.3k • 💻 Ruby • ✓ 3 analyses               │ │
│  │                                                            │ │
│  │ Last analyzed: 2 hours ago                                │ │
│  │ [View Details →]  [Compare Similar Tools →]               │ │
│  └───────────────────────────────────────────────────────────┘ │
│                                                                 │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │ 🔍 rails/rails                                            │ │
│  │ ...                                                        │ │
│  └───────────────────────────────────────────────────────────┘ │
│                                                                 │
│  [Load More]                                                   │
└─────────────────────────────────────────────────────────────────┘
```

**Components**:
- **Analysis Form**: Prominent search box (moved from `/repositories` page)
- **Filter Bar**: Search, language filter, sort by stars/recent analysis
- **Repository Cards**: Condensed version of repository list
- **Infinite Scroll**: Pagination for large repository lists

**New Features**:
- **"Compare Similar Tools" Button**: Pre-fills comparison search with inferred query
  - Example: For `sidekiq/sidekiq` → "Ruby background job processing libraries"
  - Uses AI to generate comparison query based on repo description + categories
- **Analysis Status Indicator**: Shows if analysis is queued/processing/complete
- **Re-analysis Logic**: Show "Re-analyze" button if repo hasn't been analyzed in 7+ days

---

### 5. Sticky Quick Action Bar (Authenticated Users Only)

**Purpose**: Provide always-accessible creation flows without scrolling

**Layout**:
```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│  [Sticky to bottom of viewport]                                │
│                                                                 │
│  ┌──────────────────────────────┐  ┌─────────────────────────┐ │
│  │ ➕ New Comparison            │  │ ➕ Analyze Repository   │ │
│  └──────────────────────────────┘  └─────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

**Behavior**:
- Fixed position: `bottom-6 right-6` (desktop) or full-width (mobile)
- Opens modal/slide-over with respective form
- Floating action button (FAB) style on mobile
- Shadow + hover states for discoverability
- Hide when user is already in a creation flow (prevent duplication)

**Implementation**:
- Stimulus controller for modal management
- Turbo Frame for form rendering
- Same forms as tab content (shared partials)

**Mobile Variant**:
```
┌──────────────────────┐
│  [➕]                │  ← Single FAB that opens menu
│                      │
│  • New Comparison    │  ← Menu slides up from bottom
│  • Analyze Repo      │
│  • [Cancel]          │
└──────────────────────┘
```

---

### 6. Enhanced Repository Show Page

**Current**: Just analysis history and "Run New Analysis" button
**Proposed**: Add contextual cross-links + suggested comparisons

**New Sections**:

```
┌─────────────────────────────────────────────────────────────────┐
│  sidekiq/sidekiq                                                │
│  Simple, efficient background processing for Ruby               │
│                                                                 │
│  [View on GitHub →]  [Compare Similar Tools →]  NEW!           │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  💡 Related Comparisons                                    NEW! │
│                                                                 │
│  • "Rails background job library" (3 repos)                    │
│  • "Ruby job queue with retries" (5 repos)                     │
│                                                                 │
│  [View All Comparisons Including This Repo →]                  │
└─────────────────────────────────────────────────────────────────┘

[Existing stats + analysis sections below...]
```

**New Features**:
- **"Compare Similar Tools"**: Opens comparison search pre-filled with intelligent query
- **Related Comparisons**: Shows existing comparisons that include this repo
- **Smart Suggestions**: AI-generated comparison queries based on repo metadata

---

## User Flows

### Flow 1: New User Discovers Compare Feature

1. User lands on homepage
2. Sees hero section with two clear options
3. Clicks "Compare Tools →"
4. Hero dismisses, Comparisons tab becomes active, search focused
5. User types "Rails background job library"
6. Sees existing comparison OR creates new one
7. Reviews comparison results
8. Clicks "Analyze This Repo →" on interesting repo (sidekiq)
9. Switches to Analyses tab, repo URL pre-filled
10. Clicks "Analyze" button
11. Views deep analysis results

### Flow 2: Returning User Analyzes Repo First

1. User lands on homepage (hero auto-hidden)
2. Tabs directly to "Analyses"
3. Pastes GitHub URL into analysis form
4. Reviews analysis results on show page
5. Clicks "Compare Similar Tools →" button
6. Redirected to Comparisons tab with pre-filled search
7. Discovers alternative libraries

### Flow 3: Mobile User Creates Comparison

1. User lands on homepage (hero collapsed)
2. Scrolls through existing comparisons
3. Taps floating action button (FAB) at bottom-right
4. Menu slides up: "New Comparison" | "Analyze Repo"
5. Taps "New Comparison"
6. Modal/bottom-sheet opens with search form
7. Types query, submits
8. Modal closes, new comparison appears in feed

---

## Implementation Checklist

### Phase 1: Foundation (Day 1)

- [ ] Create `TODO_UI.md` (this file)
- [ ] Create Stimulus controller: `app/javascript/controllers/tabs_controller.js`
- [ ] Create Stimulus controller: `app/javascript/controllers/quick_actions_controller.js`
- [ ] Create Stimulus controller: `app/javascript/controllers/hero_controller.js`
- [ ] Update routes to support `?tab=` param
- [ ] Create shared partials:
  - [ ] `_hero_section.html.erb`
  - [ ] `_tab_navigation.html.erb`
  - [ ] `_quick_action_bar.html.erb`
  - [ ] `_comparison_tab_content.html.erb`
  - [ ] `_analyses_tab_content.html.erb`

### Phase 2: Hero Section (Day 1)

- [ ] Build hero section component
- [ ] Add localStorage persistence for dismissal
- [ ] Add gradient background styling
- [ ] Add dual CTA cards with icons
- [ ] Add responsive design (mobile: stacked cards)
- [ ] Wire up CTA click handlers (focus search, switch tabs)

### Phase 3: Tabbed Interface (Day 2)

- [ ] Refactor homepage controller to support tabs
- [ ] Create Turbo Frames for tab content
- [ ] Add tab switching logic (URL param sync)
- [ ] Add count badges (comparisons count, repositories count)
- [ ] Style active/inactive tab states
- [ ] Test tab switching performance

### Phase 4: Cross-Linking (Day 2)

- [ ] Add "Analyze This Repo →" buttons to comparison cards
- [ ] Add "Compare Similar Tools →" button to repository show page
- [ ] Build AI query generator for "Compare Similar Tools"
- [ ] Add "Related Comparisons" section to repository show page
- [ ] Wire up cross-link click handlers

### Phase 5: Quick Actions Bar (Day 2)

- [ ] Build sticky action bar component
- [ ] Add modal/slide-over for forms
- [ ] Add FAB variant for mobile
- [ ] Add menu slide-up animation (mobile)
- [ ] Test on various screen sizes

### Phase 6: Analyses Tab Enhancements (Day 3)

- [ ] Move analysis form from `/repositories` to analyses tab
- [ ] Build repository cards for analyses feed
- [ ] Add filter bar (search, language, sort)
- [ ] Add "Re-analyze" button logic (7+ days check)
- [ ] Add analysis status indicators (queued/processing/complete)

### Phase 7: Polish & Testing (Day 3)

- [ ] Add empty states for both tabs
- [ ] Add loading states (skeleton screens)
- [ ] Add error states (failed analysis, rate limited)
- [ ] Test all user flows (see above)
- [ ] Test on mobile devices
- [ ] Accessibility audit (keyboard nav, ARIA labels)
- [ ] Performance testing (tab switching, infinite scroll)

### Phase 8: Cleanup

- [ ] Remove old `/repositories` index page (redirect to `/?tab=analyses`)
- [ ] Update navigation links
- [ ] Update documentation (README, OVERVIEW)
- [ ] Deploy to production
- [ ] Monitor analytics (tab usage, cross-link clicks)

---

## Design Considerations

### Visual Hierarchy

1. **Primary Actions**: Hero CTAs, Quick action bar buttons (high contrast, large)
2. **Secondary Actions**: Tab navigation, filter buttons (medium contrast)
3. **Tertiary Actions**: Cross-links, "Load More" (lower contrast, inline)

### Color Coding

- **Comparisons**: Blue theme (`bg-blue-50`, `text-blue-600`, `border-blue-200`)
- **Analyses**: Purple theme (`bg-purple-50`, `text-purple-600`, `border-purple-200`)
- Consistent use throughout tabs, cards, buttons

### Typography

- **H1 (Hero)**: `text-4xl font-bold` - Main value prop
- **H2 (Tab Headings)**: `text-2xl font-semibold` - Section titles
- **H3 (Card Titles)**: `text-lg font-medium` - Individual items
- **Body**: `text-base text-gray-700` - Descriptions

### Spacing

- **Hero Section**: `mb-8` (large bottom margin)
- **Tab Content**: `py-6` (vertical padding)
- **Cards**: `gap-4` (between cards in feed)
- **Quick Action Bar**: `bottom-6 right-6` (fixed positioning)

---

## Mobile/Responsive Considerations

### Breakpoints

- **Mobile** (`< 768px`): Single column, stacked cards, FAB
- **Tablet** (`768px - 1024px`): Two-column grid for hero cards, sidebar filters
- **Desktop** (`> 1024px`): Full layout, sticky sidebar

### Mobile Adaptations

1. **Hero Section**:
   - Stack CTA cards vertically (`grid-cols-1`)
   - Reduce padding (`p-4` instead of `p-6`)
   - Smaller text (`text-2xl` instead of `text-4xl`)

2. **Tabs**:
   - Full-width tabs (no side margins)
   - Slightly smaller text (`text-base` instead of `text-lg`)
   - Swipe gesture support (optional enhancement)

3. **Filters**:
   - Collapse into expandable drawer
   - "Filters" button opens bottom sheet
   - Apply/Clear buttons sticky at bottom

4. **Quick Actions**:
   - Single FAB instead of dual buttons
   - Menu slides up from bottom
   - Full-width action buttons

5. **Cards**:
   - Full-width (no grid)
   - Truncate long text
   - Tap to expand details

---

## Technical Notes

### Stimulus Controllers

**`tabs_controller.js`**:
```javascript
// Handles tab switching, URL param sync, active state
connect() {
  this.syncTabFromURL()
}

switchTab(event) {
  const tab = event.target.dataset.tab
  this.updateURL(tab)
  this.activateTab(tab)
}
```

**`hero_controller.js`**:
```javascript
// Handles hero dismissal, localStorage persistence
connect() {
  if (localStorage.getItem('hero_dismissed') === 'true') {
    this.element.classList.add('hidden')
  }
}

dismiss() {
  localStorage.setItem('hero_dismissed', 'true')
  this.element.classList.add('hidden')
}
```

**`quick_actions_controller.js`**:
```javascript
// Handles modal open/close, form rendering
openComparison() {
  this.showModal('comparison')
}

openAnalysis() {
  this.showModal('analysis')
}
```

### Turbo Frames

```erb
<!-- Homepage -->
<turbo-frame id="tab_content" src="/?tab=comparisons">
  <!-- Tab content loaded here -->
</turbo-frame>

<!-- Quick action modal -->
<turbo-frame id="quick_action_modal">
  <!-- Form loaded here -->
</turbo-frame>
```

### Routes

```ruby
# Keep existing routes, add tab param support
root "comparisons#index"  # Supports ?tab=comparisons|analyses

# Redirect old repositories index to analyses tab
get "/repositories", to: redirect("/?tab=analyses")
```

### Performance

- **Lazy Load Tabs**: Only load active tab content initially
- **Infinite Scroll**: Keep existing Turbo Stream implementation
- **Modal Forms**: Use Turbo Frames for instant loading
- **LocalStorage**: Cache hero dismissal, tab preference

---

## Analytics to Track

1. **Tab Usage**:
   - Comparisons tab views vs. Analyses tab views
   - Tab switches per session

2. **Hero Effectiveness**:
   - CTA click rate (before dismissal)
   - Time to dismissal
   - Return user behavior

3. **Cross-Linking**:
   - "Analyze This Repo" clicks from comparisons
   - "Compare Similar Tools" clicks from analyses
   - Conversion rate (click → action)

4. **Quick Actions**:
   - FAB/sticky bar usage rate
   - Modal open rate
   - Form completion rate

---

## Future Enhancements

### V2 Features (Post-Launch)

- [ ] **Saved Searches**: Bookmark comparisons/analyses for later
- [ ] **History Tab**: See personal activity feed (analyses created, comparisons viewed)
- [ ] **Collections**: Group related repositories into custom lists
- [ ] **Notifications**: Email when repo gets new analysis or comparison includes it
- [ ] **Trending Tab**: Most popular comparisons this week

### V3 Features (Long-term)

- [ ] **Compare Mode**: Side-by-side diff view for two repos
- [ ] **Export**: Download comparison/analysis as PDF/Markdown
- [ ] **API**: Public API for programmatic access
- [ ] **Browser Extension**: Analyze repos directly from GitHub

---

## Questions to Answer Before Implementation

1. **Should unauthenticated users see both tabs or just comparisons?**
   - Option A: Show both tabs, but disable analysis creation (sign in prompt)
   - Option B: Hide analyses tab entirely (simpler, but less transparent)
   - **Recommendation**: Option A (transparency builds trust)

2. **Should hero section persist for authenticated users?**
   - Option A: Auto-hide after first visit (cleaner for power users)
   - Option B: Always show, but collapsible (more guidance)
   - **Recommendation**: Option A (with easy way to re-show if needed)

3. **Should we add swipe gestures for mobile tab switching?**
   - Adds polish but increases complexity
   - **Recommendation**: Ship V1 without, add in V2 if users request

4. **How should we handle the old `/repositories` URL?**
   - Option A: Redirect to `/?tab=analyses` (seamless)
   - Option B: Show deprecation notice + link (more explicit)
   - **Recommendation**: Option A (seamless)

5. **Should quick action bar be visible on desktop or just mobile?**
   - Option A: Desktop + mobile (always accessible)
   - Option B: Mobile only (desktop has hero CTAs)
   - **Recommendation**: Option A (power users love shortcuts)

---

## Success Metrics

**Immediate (Week 1)**:
- [ ] Zero UI-related bug reports
- [ ] Tab switching works smoothly (< 100ms perceived)
- [ ] Mobile usability score > 90% (Google Lighthouse)

**Short-term (Month 1)**:
- [ ] 30%+ increase in analyses created (easier discovery)
- [ ] 20%+ increase in cross-linking usage (comparisons → analyses)
- [ ] < 5% bounce rate from homepage (engaging hero section)

**Long-term (Quarter 1)**:
- [ ] 50%+ of users use both features (comparisons + analyses)
- [ ] Average session time increases by 25% (more exploration)
- [ ] User feedback: "I understand what the app does now"

---

## Notes

- Maintain CLAUDE.md coding standards (alphabetized methods, section headers)
- Use Heroicons for all icons (consistency)
- Keep Tailwind classes (no custom CSS unless necessary)
- Test with real data (don't rely on empty states)
- Ship incrementally (Phase 1-3 could be V1, rest in V2)

---

**Created**: 2025-11-11
**Last Updated**: 2025-11-11
**Owner**: Jimmy Pocock
**Status**: Ready for Review
