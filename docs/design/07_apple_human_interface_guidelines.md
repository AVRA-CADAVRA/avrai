# Apple Human Interface Guidelines

Core principles and guidelines from Apple's Human Interface Guidelines for iOS, macOS, and other Apple platforms.

## Fundamental Design Principles

### 1. Clarity

**Definition**: Content is legible and understandable. Every element has a purpose.

**Implementation**:
- **Typography**: Use system fonts (SF Pro) appropriately sized
- **Icons**: Clear, recognizable icons
- **Graphics**: Purposeful, not decorative
- **Spacing**: Generous whitespace
- **Focus**: Remove unnecessary elements

**Key Points**:
- Text is readable at all sizes
- Icons are clear and precise
- Functionality is obvious
- Negative space focuses attention

### 2. Deference

**Definition**: The UI supports and enhances the content, never competing with it.

**Implementation**:
- **Content First**: UI gets out of the way
- **Fluid Motion**: Smooth transitions
- **Clean Interface**: Minimal chrome
- **Content Hierarchy**: Clear visual hierarchy
- **Native Behaviors**: Use platform conventions

**Key Points**:
- Content is the focus
- UI enhances, doesn't distract
- Motion provides clarity
- Native patterns feel natural

### 3. Depth

**Definition**: Visual hierarchy and motion provide vitality and heighten users' delight and understanding.

**Implementation**:
- **Layering**: Visual depth through layers
- **Motion**: Purposeful animations
- **Transitions**: Smooth screen transitions
- **Hierarchy**: Clear information hierarchy
- **Feedback**: Responsive interactions

**Key Points**:
- Visual layers create hierarchy
- Motion clarifies relationships
- Transitions feel natural
- Depth guides attention

## iOS Design Principles

### Navigation

**Navigation Patterns**:
- **Hierarchical**: Drill down into content (Navigation Controller)
- **Flat**: Switch between content categories (Tab Bar)
- **Content-Driven**: Content itself drives navigation (Pages)

**Navigation Bar**:
- Shows current location
- Provides back navigation
- Can include title and buttons
- Translucent by default
- Adapts to content

**Tab Bar**:
- 3-5 primary sections
- Always visible
- Badges for notifications
- Icons with labels
- Persistent across app

### Bars

**Navigation Bar**:
- Title and navigation controls
- Translucent background
- Back button (automatic)
- Customizable buttons

**Tab Bar**:
- Primary navigation
- 3-5 tabs maximum
- Icons + labels
- Badges for updates
- Persistent

**Toolbar**:
- Action buttons
- Context-specific
- Appears when needed
- Translucent

**Search Bar**:
- Prominent placement
- Clear, scannable results
- Recent searches
- Suggestions

### Views

**Content Views**:
- **Collection Views**: Grid layouts
- **Table Views**: List layouts
- **Text Views**: Editable text
- **Web Views**: Web content

**Container Views**:
- **Split View**: Master-detail (iPad)
- **Page View**: Page-based navigation
- **Popover**: Temporary content (iPad)

### Controls

**Buttons**:
- Clear purpose
- Appropriate size (44x44pt minimum)
- Visual feedback
- System styles available

**Input Controls**:
- Text fields
- Sliders
- Switches
- Steppers
- Pickers

**Progress Indicators**:
- Activity indicators (spinners)
- Progress bars
- Network activity indicators

### Alerts and Action Sheets

**Alerts**:
- Critical information
- Require user action
- Two buttons maximum (typically)
- Clear, actionable titles

**Action Sheets**:
- Multiple options
- Destructive actions in red
- Cancel option always available
- Bottom sheet on iPhone

### Modality

**Modal Presentation**:
- Focused tasks
- Clear completion path
- Dismissible
- Appropriate presentation style

**Presentation Styles**:
- Full screen
- Page sheet
- Form sheet
- Current context

## Typography

### System Fonts

**SF Pro** (iOS):
- Designed for legibility
- Multiple weights
- Dynamic Type support
- Optimized for screens

**Usage**:
- Use system fonts by default
- Support Dynamic Type
- Appropriate sizes
- Clear hierarchy

### Dynamic Type

**Definition**: System feature that allows users to choose preferred text size.

**Implementation**:
- Use text styles (not fixed sizes)
- Support all size categories
- Test at largest sizes
- Maintain readability
- Adjust layouts as needed

**Text Styles**:
- Large Title
- Title 1, 2, 3
- Headline
- Body
- Callout
- Subhead
- Footnote
- Caption 1, 2

## Color

### System Colors

**Semantic Colors**:
- Adapt to light/dark mode
- Accessible by default
- Purpose-driven (not decorative)

**Usage**:
- Use semantic colors
- Support Dark Mode
- Ensure contrast
- Test in both modes

### Dark Mode

**Support**:
- Automatic adaptation
- Custom dark mode assets
- Test in both modes
- Maintain readability
- Preserve brand identity

## Layout

### Safe Areas

**Definition**: Areas of the screen that are not obscured by system UI.

**Implementation**:
- Respect safe areas
- Account for notches
- Handle different screen sizes
- Test on all devices

### Size Classes

**Regular/Compact**:
- **Regular**: Spacious (iPad, iPhone landscape)
- **Compact**: Constrained (iPhone portrait)

**Usage**:
- Adapt layouts to size classes
- Optimize for each context
- Maintain usability
- Test all combinations

## Animation and Motion

### Principles

**Purposeful**:
- Every animation has a purpose
- Clarifies relationships
- Provides feedback
- Enhances understanding

**Natural**:
- Follows physics
- Feels organic
- Appropriate timing
- Smooth transitions

### Transitions

**Screen Transitions**:
- Push (hierarchical)
- Modal (focused tasks)
- Custom (when appropriate)

**Principles**:
- Smooth and fast
- Purposeful
- Consistent
- Natural feeling

## Accessibility

### VoiceOver

**Support**:
- Semantic markup
- Accessible labels
- Traits and hints
- Navigation support

### Dynamic Type

**Support**:
- All text styles
- Scalable layouts
- Readable at all sizes
- Maintain usability

### Other Features

**Support**:
- Reduce Motion preference
- High Contrast
- Voice Control
- Switch Control
- AssistiveTouch

## Platform-Specific Considerations

### iPhone

**Considerations**:
- One-handed use
- Thumb zones
- Portrait primary
- Notch/Dynamic Island
- Home indicator

### iPad

**Considerations**:
- Larger screen
- Multitasking
- Split View
- Keyboard shortcuts
- Apple Pencil support

### Apple Watch

**Considerations**:
- Glanceable information
- Quick interactions
- Complications
- Digital Crown
- Haptic feedback

## Best Practices

### Do's

✅ **Do**:
- Use system fonts and components
- Support Dynamic Type
- Support Dark Mode
- Respect safe areas
- Use semantic colors
- Provide clear navigation
- Use appropriate animations
- Test on real devices
- Follow platform conventions
- Design for accessibility

### Don'ts

❌ **Don't**:
- Use custom fonts unnecessarily
- Ignore Dynamic Type
- Ignore Dark Mode
- Ignore safe areas
- Use decorative colors
- Create confusing navigation
- Overuse animations
- Design only for one device
- Break platform conventions
- Ignore accessibility

## Design Checklist

- [ ] Follows Clarity principle
- [ ] Follows Deference principle
- [ ] Follows Depth principle
- [ ] Uses appropriate navigation pattern
- [ ] System fonts and Dynamic Type support
- [ ] Semantic colors and Dark Mode support
- [ ] Respects safe areas
- [ ] Appropriate animations
- [ ] Accessible (VoiceOver, etc.)
- [ ] Tested on real devices
- [ ] Follows platform conventions
- [ ] Appropriate touch targets (44x44pt)
- [ ] Clear visual hierarchy
- [ ] Purposeful motion

---

**Source**: [Apple Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines)

**Last Updated**: November 2024

