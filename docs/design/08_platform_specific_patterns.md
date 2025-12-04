# Platform-Specific Design Patterns

Guidelines for designing across different platforms while maintaining consistency and respecting platform conventions.

## Platform Considerations

### iOS Design Patterns

**Navigation**:
- **Tab Bar**: Primary navigation (3-5 tabs)
- **Navigation Bar**: Hierarchical navigation with back button
- **Modal**: Full-screen or sheet presentation
- **Page View**: Page-based navigation

**Components**:
- System fonts (SF Pro)
- Native iOS components
- Haptic feedback
- 3D Touch/Haptic Touch
- Dynamic Island integration

**Conventions**:
- Left-aligned titles
- Back button on left
- Primary action on right
- Swipe gestures
- Pull to refresh

### Android Design Patterns

**Navigation**:
- **Bottom Navigation**: Primary navigation (3-5 items)
- **Navigation Drawer**: Secondary navigation
- **Top App Bar**: Title and actions
- **Back Button**: System back button

**Components**:
- Material Design components
- System fonts (Roboto)
- Material Theming
- Ripple effects
- Elevation and shadows

**Conventions**:
- Center-aligned titles
- Overflow menu (three dots)
- Floating Action Button (FAB)
- Swipe gestures
- Material Motion

### Cross-Platform Considerations

**Shared Principles**:
- User-centered design
- Accessibility
- Performance
- Consistency within app
- Platform-appropriate patterns

**Adaptation Strategy**:
- Core experience consistent
- Platform-specific UI elements
- Native navigation patterns
- Platform conventions respected
- Shared design system where possible

## Navigation Patterns

### iOS Navigation

**Hierarchical Navigation**:
- Navigation Controller
- Back button automatic
- Title in center
- Right-side actions
- Swipe back gesture

**Tab Bar Navigation**:
- Bottom placement
- 3-5 primary sections
- Icons + labels
- Badges for updates
- Persistent visibility

**Modal Presentation**:
- Full screen or sheet
- Dismiss button
- Clear completion path
- Focused task

### Android Navigation

**Bottom Navigation**:
- Primary navigation
- 3-5 items
- Icons + labels
- Active state indicator
- Persistent

**Navigation Drawer**:
- Secondary navigation
- Hamburger menu trigger
- Overlay or push
- Account section at top
- Categories below

**Top App Bar**:
- Title and actions
- Scrolling behavior
- Overflow menu
- Contextual actions

## Component Patterns

### Buttons

**iOS**:
- System button styles
- Text buttons
- Filled buttons
- Borderless buttons
- 44x44pt minimum size

**Android**:
- Contained buttons
- Outlined buttons
- Text buttons
- Icon buttons
- 48x48dp minimum size

**Cross-Platform**:
- Clear hierarchy
- Appropriate sizing
- Consistent styling
- Accessible labels

### Forms

**iOS**:
- Grouped table views
- Inline labels
- Native pickers
- Clear sections
- Validation feedback

**Android**:
- Text input layouts
- Floating labels
- Material pickers
- Clear sections
- Error states

**Cross-Platform**:
- Clear labels
- Appropriate input types
- Real-time validation
- Error messages
- Success feedback

### Lists

**iOS**:
- Table views
- Grouped or plain style
- Swipe actions
- Pull to refresh
- Native cell styles

**Android**:
- Recycler views
- Material list items
- Swipe actions
- Pull to refresh
- Material design

**Cross-Platform**:
- Clear hierarchy
- Appropriate spacing
- Swipe gestures
- Loading states
- Empty states

## Interaction Patterns

### Gestures

**iOS**:
- Swipe back
- Pull to refresh
- Long press
- 3D Touch/Haptic Touch
- Pinch to zoom

**Android**:
- Swipe actions
- Pull to refresh
- Long press
- Material ripple
- Pinch to zoom

**Cross-Platform**:
- Tap (primary)
- Long press (secondary)
- Swipe (navigation/actions)
- Pinch (zoom)
- Standard gestures

### Feedback

**iOS**:
- Haptic feedback
- Visual state changes
- Sound (optional)
- Animations
- Native feel

**Android**:
- Ripple effects
- Visual state changes
- Haptic feedback
- Material motion
- Native feel

**Cross-Platform**:
- Immediate feedback
- Clear state changes
- Appropriate timing
- Non-intrusive
- User-controllable

## Visual Design Patterns

### Typography

**iOS**:
- SF Pro font family
- Dynamic Type support
- Text styles
- System sizing

**Android**:
- Roboto font family
- Scalable text
- Type scale
- Material sizing

**Cross-Platform**:
- Clear hierarchy
- Readable sizes
- Appropriate weights
- Sufficient contrast
- Scalable text

### Color

**iOS**:
- Semantic colors
- System colors
- Dark Mode support
- Adaptive colors

**Android**:
- Material colors
- Theme colors
- Dark theme support
- Color roles

**Cross-Platform**:
- Consistent color meaning
- Accessible contrast
- Brand colors
- Semantic usage
- Theme support

### Spacing

**iOS**:
- 8pt grid system
- Standard margins
- Safe areas
- Appropriate padding

**Android**:
- 8dp grid system
- Material spacing
- Appropriate margins
- Consistent padding

**Cross-Platform**:
- Consistent spacing scale
- Appropriate whitespace
- Visual breathing room
- Clear grouping

## Platform-Specific Features

### iOS Features

**Integration**:
- Dynamic Island
- Live Activities
- Widgets
- Shortcuts
- Handoff
- Continuity Camera

**Considerations**:
- Notch/Dynamic Island
- Home indicator
- Status bar
- Safe areas
- Haptic feedback

### Android Features

**Integration**:
- Widgets
- App shortcuts
- Notification actions
- Share targets
- File providers
- Android Auto

**Considerations**:
- System bars
- Navigation gestures
- Edge-to-edge
- Material You theming
- Adaptive icons

## Responsive Design

### Screen Sizes

**iOS**:
- iPhone (multiple sizes)
- iPad (multiple sizes)
- Size classes (Regular/Compact)
- Safe areas

**Android**:
- Phones (various sizes)
- Tablets
- Foldables
- Different densities

**Cross-Platform**:
- Flexible layouts
- Responsive design
- Breakpoints
- Adaptive components

### Orientation

**iOS**:
- Portrait primary
- Landscape support
- Size class changes
- Layout adaptation

**Android**:
- Portrait and landscape
- Configuration changes
- Layout adaptation
- State preservation

**Cross-Platform**:
- Support both orientations
- Maintain usability
- Preserve state
- Adapt layouts

## Best Practices

### Platform Adaptation

✅ **Do**:
- Use platform-native components
- Follow platform conventions
- Respect platform guidelines
- Test on real devices
- Adapt navigation patterns
- Use platform-appropriate gestures
- Support platform features

❌ **Don't**:
- Force one platform's patterns on another
- Ignore platform conventions
- Use non-native components unnecessarily
- Design for one platform only
- Break platform expectations
- Ignore platform guidelines

### Consistency

**Within App**:
- Consistent visual design
- Consistent interactions
- Consistent terminology
- Consistent patterns

**Across Platforms**:
- Core experience consistent
- Brand identity consistent
- Functionality consistent
- Platform-appropriate UI

## Design Checklist

- [ ] Platform-native navigation patterns
- [ ] Platform-appropriate components
- [ ] Platform conventions followed
- [ ] Native gestures supported
- [ ] Platform features integrated
- [ ] Responsive to screen sizes
- [ ] Orientation support
- [ ] Consistent within app
- [ ] Tested on real devices
- [ ] Platform guidelines followed

---

**Sources**:
- Apple Human Interface Guidelines
- Material Design Guidelines
- Platform-specific best practices

**Last Updated**: November 2024

