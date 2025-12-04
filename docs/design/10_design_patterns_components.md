# Design Patterns and Components

Common design patterns and reusable components for building consistent, effective interfaces.

## Navigation Patterns

### Primary Navigation

**Tab Bar (iOS)**:
- 3-5 primary sections
- Bottom placement
- Icons + labels
- Badges for notifications
- Persistent visibility

**Bottom Navigation (Android)**:
- 3-5 primary sections
- Bottom placement
- Icons + labels
- Active state indicator
- Persistent

**Navigation Bar**:
- Hierarchical navigation
- Back button
- Title display
- Action buttons
- Breadcrumbs

### Secondary Navigation

**Hamburger Menu**:
- Secondary options
- Overlay or push
- Account section
- Categories
- Settings access

**Navigation Drawer (Android)**:
- Secondary navigation
- Material design
- Account header
- Navigation items
- Footer actions

**More Menu**:
- Additional options
- Three-dot icon
- Contextual actions
- Overflow items

## Content Patterns

### Lists

**Simple List**:
- Single column
- Consistent row height
- Clear hierarchy
- Swipe actions
- Pull to refresh

**Card List**:
- Card-based layout
- Rich content
- Images and text
- Actions on cards
- Grid or list view

**Grouped List**:
- Sections with headers
- Related items grouped
- Clear separation
- Collapsible sections
- Sticky headers

### Grids

**Image Grid**:
- Uniform or masonry layout
- Thumbnail images
- Consistent spacing
- Tap to view detail
- Lazy loading

**Content Grid**:
- Cards in grid
- Rich content
- Consistent sizing
- Responsive columns
- Filter/sort options

### Cards

**Basic Card**:
- Container for content
- Rounded corners
- Shadow/elevation
- Padding
- Clear hierarchy

**Action Card**:
- Tappable card
- Primary action
- Secondary actions
- Visual feedback
- Clear affordance

**Content Card**:
- Rich content
- Images
- Text
- Metadata
- Actions

## Input Patterns

### Forms

**Single Column Form**:
- Vertical layout
- Clear labels
- Appropriate input types
- Validation feedback
- Submit button

**Multi-Step Form**:
- Progress indicator
- Step navigation
- Save progress
- Validation per step
- Review before submit

**Inline Form**:
- Compact layout
- Inline validation
- Real-time feedback
- Clear errors
- Success states

### Input Controls

**Text Input**:
- Clear labels
- Placeholders
- Appropriate keyboard
- Validation
- Error messages

**Selection Controls**:
- Radio buttons
- Checkboxes
- Switches
- Dropdowns
- Pickers

**Date/Time Pickers**:
- Native pickers
- Calendar view
- Time selection
- Range selection
- Clear format

## Feedback Patterns

### Loading States

**Skeleton Screens**:
- Content placeholders
- Shimmer effect
- Maintains layout
- Faster perceived performance
- Better than spinners

**Progress Indicators**:
- Determinate progress
- Indeterminate spinner
- Percentage display
- Cancel option
- Status messages

**Optimistic Updates**:
- Immediate UI update
- Background sync
- Rollback on error
- Clear feedback
- Better UX

### Error States

**Inline Errors**:
- Near input field
- Clear message
- Suggest solution
- Visual indicator
- Easy to correct

**Error Messages**:
- Plain language
- Explain problem
- Suggest fix
- Actionable
- Dismissible

**Empty States**:
- Helpful message
- Illustration/icon
- Suggested actions
- Not just "no data"
- Engaging

### Success States

**Confirmation Messages**:
- Clear success message
- What was accomplished
- Next steps (if any)
- Dismissible
- Non-intrusive

**Success Indicators**:
- Visual confirmation
- Checkmark/animation
- Brief display
- Clear feedback
- Positive reinforcement

## Modal Patterns

### Dialogs

**Alert Dialog**:
- Critical information
- User action required
- Two buttons (typically)
- Clear title and message
- Dismissible

**Confirmation Dialog**:
- Confirm action
- Destructive actions
- Clear consequences
- Cancel option
- Confirm button

**Information Dialog**:
- Non-critical info
- Single action
- Dismissible
- Clear message
- Optional action

### Bottom Sheets

**Action Sheet**:
- Multiple options
- Destructive actions in red
- Cancel option
- Bottom placement
- Dismissible

**Bottom Sheet**:
- Additional content
- Dismissible
- Partial or full screen
- Smooth animation
- Handle for drag

## Content Display Patterns

### Detail Views

**Master-Detail**:
- List and detail
- Split view (tablet)
- Navigation between
- Context preservation
- Back navigation

**Full-Screen Detail**:
- Focused content
- Full screen
- Clear navigation
- Actions available
- Share options

### Media Patterns

**Image Viewer**:
- Full-screen view
- Zoom and pan
- Swipe navigation
- Close option
- Share options

**Video Player**:
- Controls overlay
- Play/pause
- Progress bar
- Fullscreen option
- Quality selection

**Audio Player**:
- Playback controls
- Progress indicator
- Volume control
- Playlist (if applicable)
- Background playback

## Search Patterns

### Search Interface

**Search Bar**:
- Prominent placement
- Clear placeholder
- Search icon
- Cancel option
- Recent searches

**Search Results**:
- Clear results display
- Highlighted matches
- Filters available
- Sort options
- Empty state

**Search Suggestions**:
- As-you-type suggestions
- Recent searches
- Popular searches
- Quick actions
- Clear formatting

## Onboarding Patterns

### Welcome Flow

**Welcome Screens**:
- Value proposition
- Key features
- Visual appeal
- Skip option
- Progress indicator

**Feature Highlights**:
- New features
- Benefits explained
- Visual guides
- Dismissible
- Contextual timing

**Permission Requests**:
- Explain why needed
- Show value
- Request at right time
- Allow later
- Clear benefits

## Common Components

### Buttons

**Primary Button**:
- Main action
- Prominent styling
- Clear label
- Appropriate size
- Visual feedback

**Secondary Button**:
- Secondary action
- Less prominent
- Clear label
- Consistent styling
- Visual feedback

**Text Button**:
- Tertiary action
- Minimal styling
- Text only
- Clear label
- Hover/focus states

### Badges

**Notification Badge**:
- Unread count
- Prominent color
- Number display
- Clear visibility
- Dismissible

**Status Badge**:
- Status indicator
- Color coding
- Text label
- Clear meaning
- Consistent styling

### Tooltips

**Tooltip**:
- Additional information
- On hover/tap
- Brief text
- Positioned near element
- Auto-dismiss

## Pattern Best Practices

### When to Use Patterns

**Considerations**:
- User needs
- Content type
- Platform conventions
- Context
- Consistency

**Selection**:
- Use familiar patterns
- Match user expectations
- Consider platform
- Test with users
- Iterate based on feedback

### Pattern Customization

**Principles**:
- Maintain core pattern
- Customize for brand
- Don't break expectations
- Test recognition
- Document variations

## Pattern Library

### Building a Pattern Library

**Components**:
- Documented patterns
- Usage guidelines
- Code examples
- Design specs
- Accessibility notes

**Benefits**:
- Consistency
- Faster development
- Easier maintenance
- Better UX
- Team alignment

---

**Sources**:
- Platform design guidelines (iOS, Android)
- Design pattern libraries
- Common UI patterns

**Last Updated**: November 2024

