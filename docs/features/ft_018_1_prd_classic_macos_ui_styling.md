# Feature ft_018: Classic Mac OS UI Styling System

## Product Requirements Document (PRD)

### Executive Summary

This PRD outlines the implementation of a comprehensive Classic Mac OS-inspired UI styling system for the Flutter chat application, drawing inspiration from the nostalgic design metaphors of System 7 era Mac OS and ryo.lu's web OS aesthetic. The system will transform the current modern Material Design interface into a retro computing experience that evokes the golden age of personal computing while maintaining modern functionality and accessibility.

### Background & Context

The current chat application uses standard Flutter Material Design components with basic theming. While functional, it lacks personality and the distinctive visual character that made classic computing interfaces memorable and beloved. Drawing inspiration from:

- **Classic Mac OS System 7** (1991-1997): Iconic window chrome, distinctive title bars, and pioneering UI patterns
- **ryo.lu's Web OS**: Modern interpretation of classic desktop metaphors in web environments  
- **Platinum Appearance**: The refined visual language introduced in Mac OS 8
- **Desktop Publishing Era**: The aesthetic that defined creative computing in the 1990s

### Problem Statement

Current chat app interface lacks:
1. **Visual Personality**: Generic Material Design provides no distinctive character
2. **Nostalgic Appeal**: Missing the charm and warmth of classic computing interfaces
3. **Desktop Metaphor**: No connection to the rich history of GUI design patterns
4. **Brand Differentiation**: Looks identical to countless other chat applications
5. **Emotional Connection**: Fails to evoke the joy and wonder of early personal computing

### Product Vision

**"Transform the chat application into a nostalgic computing experience that captures the magic of Classic Mac OS while delivering modern functionality - creating an interface that feels both familiar to vintage computing enthusiasts and delightfully unique to new users."**

### Target Users

**Primary Users:**
- Vintage computing enthusiasts and collectors
- Designers and developers with appreciation for classic UI/UX
- Users seeking unique, personality-driven interfaces
- Nostalgia-driven users who experienced the classic Mac era

**Secondary Users:**
- General chat app users who appreciate distinctive design
- Users interested in retro/vintage aesthetics
- Design-conscious individuals seeking alternatives to generic interfaces

### Core Features & Requirements

#### 1. Classic Window Chrome System

**Window Frame Design:**
- **Title Bar**: Implement the iconic Mac OS System 7 title bar with:
  - Horizontal pinstripe pattern background
  - Centered window title in Chicago or Charcoal font
  - Classic close box (top-left) with authentic styling
  - Zoom box (top-right) for maximize/minimize functionality
  - Window drag handle with proper visual feedback

**Window Controls:**
- **Close Box**: Square button with inset border and subtle shadow
- **Zoom Box**: Right-aligned button with standard Mac OS behavior
- **Window Borders**: 1-2 pixel black borders with proper corner handling
- **Drop Shadows**: Subtle shadows beneath windows for depth

**Technical Specifications:**
```dart
// Window chrome color palette
static const Color titleBarGray = Color(0xFFDDDDDD);
static const Color titleBarStroke = Color(0xFF999999);  
static const Color windowBorder = Color(0xFF000000);
static const Color dropShadow = Color(0x40000000);

// Typography
static const TextStyle titleBarText = TextStyle(
  fontFamily: 'Chicago',
  fontSize: 12,
  fontWeight: FontWeight.normal,
  color: Colors.black,
);
```

#### 2. Classic Typography System

**Font Hierarchy:**
- **Primary Font**: Chicago (or closest Flutter equivalent)
- **Secondary Font**: Geneva for body text
- **Monospace**: Monaco for code/technical content
- **Display**: Charcoal for larger headings

**Text Styling:**
- **Button Labels**: Bold, centered, with proper spacing
- **Menu Text**: Standard weight with appropriate leading
- **Body Text**: Comfortable reading with classic Mac line heights
- **Error Messages**: Consistent with System 7 alert styling

#### 3. Classic Color Palette

**System Colors:**
```dart
class ClassicMacPalette {
  // Grayscale foundation
  static const Color systemGray = Color(0xFFC0C0C0);
  static const Color lightGray = Color(0xFFE0E0E0);
  static const Color darkGray = Color(0xFF808080);
  
  // Interface elements
  static const Color windowBackground = Color(0xFFFFFFFF);
  static const Color menuBackground = Color(0xFFF5F5F5);
  static const Color buttonFace = Color(0xFFDDDDDD);
  
  // Accent colors (inspired by System 7.5 color labels)
  static const Color redLabel = Color(0xFFFF6666);
  static const Color orangeLabel = Color(0xFFFF9933);
  static const Color yellowLabel = Color(0xFFFFFF33);
  static const Color greenLabel = Color(0xFF33FF33);
  static const Color blueLabel = Color(0xFF3366FF);
  static const Color purpleLabel = Color(0xFF9933FF);
}
```

#### 4. Classic Button System

**Button Styles:**
- **Default Button**: 3D beveled appearance with proper highlighting
- **Cancel Button**: Flat style with subtle border
- **Push Buttons**: Raised appearance with inset when pressed
- **Radio Buttons**: Classic circular selection indicators
- **Checkboxes**: Square boxes with checkmark styling

**Button States:**
- **Normal**: Raised 3D appearance
- **Pressed**: Inset appearance with darker shadows
- **Disabled**: Grayed out with reduced contrast
- **Focus**: Subtle outline for keyboard navigation

#### 5. Classic Dialog System

**Alert Dialogs:**
- **Icon Integration**: Classic system icons (stop, caution, note)
- **Button Layout**: Right-aligned with proper spacing
- **Border Style**: Thick black border with rounded corners
- **Background**: Light gray with subtle texture

**Modal Dialogs:**
- **Title Bar**: Consistent with window chrome
- **Content Area**: White background with proper margins
- **Button Bar**: Standard gray background with button alignment

#### 6. Classic Menu System

**Menu Bar:**
- **Background**: Light gray gradient
- **Menu Titles**: Bold text with proper spacing
- **Hover States**: Dark highlight with white text
- **Separator Lines**: Subtle dividers between menu sections

**Drop-down Menus:**
- **Background**: White with gray border
- **Menu Items**: Proper padding and typography
- **Keyboard Shortcuts**: Right-aligned with standard formatting
- **Submenus**: Arrow indicators and proper nesting

#### 7. Classic Scroll System

**Scroll Bars:**
- **Track**: Inset gray channel with proper borders
- **Thumb**: 3D beveled appearance with texture
- **Arrows**: Classic up/down arrows at track ends
- **Proportional Sizing**: Thumb size reflects content ratio

#### 8. Classic Icon System

**System Icons:**
- **Application Icons**: 32x32 and 16x16 versions
- **Document Icons**: File type representations
- **Folder Icons**: Classic manila folder appearance
- **Alert Icons**: Stop sign, caution triangle, information note

**Icon Style Guidelines:**
- **Perspective**: Slight 3D appearance with consistent lighting
- **Color Palette**: Limited colors with proper contrast
- **Pixel Perfect**: Crisp edges optimized for small sizes

#### 9. Persona-Specific Styling

**Chat App Integration:**
- **Persona Icons**: Styled as classic Mac application icons
- **Message Bubbles**: Rounded rectangles with subtle shadows
- **Typing Indicators**: Classic Mac progress indicators
- **Audio Controls**: Styled as classic Mac media controls

**Persona Color Mapping:**
```dart
Map<CharacterPersona, ClassicPersonaTheme> personaThemes = {
  CharacterPersona.ariLifeCoach: ClassicPersonaTheme(
    primaryColor: ClassicMacPalette.greenLabel,
    icon: ClassicIcons.psychology,
    windowChrome: ClassicWindowChrome.teal,
  ),
  CharacterPersona.sergeantOracle: ClassicPersonaTheme(
    primaryColor: ClassicMacPalette.purpleLabel,
    icon: ClassicIcons.military,
    windowChrome: ClassicWindowChrome.purple,
  ),
  // ... other personas
};
```

### Technical Implementation

#### 1. Theme Architecture

**Flutter Theme Structure:**
```dart
class ClassicMacTheme {
  static ThemeData buildTheme() {
    return ThemeData(
      // Core theme properties
      primarySwatch: MaterialColor(0xFFC0C0C0, classicGrayShades),
      scaffoldBackgroundColor: ClassicMacPalette.systemGray,
      
      // Typography theme
      textTheme: ClassicTypography.textTheme,
      
      // Component themes
      appBarTheme: ClassicAppBarTheme.theme,
      elevatedButtonTheme: ClassicButtonTheme.elevatedTheme,
      dialogTheme: ClassicDialogTheme.theme,
      
      // Custom extensions
      extensions: [
        ClassicWindowChrome(),
        ClassicIconTheme(),
        ClassicScrollTheme(),
      ],
    );
  }
}
```

#### 2. Custom Widgets

**ClassicWindow Widget:**
```dart
class ClassicWindow extends StatelessWidget {
  final String title;
  final Widget child;
  final bool showCloseButton;
  final bool showZoomButton;
  final VoidCallback? onClose;
  final VoidCallback? onZoom;
  
  // Implementation with custom paint for window chrome
}
```

**ClassicButton Widget:**
```dart
class ClassicButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final ClassicButtonStyle style;
  
  // Implementation with 3D appearance and proper states
}
```

#### 3. Asset Requirements

**Font Assets:**
- Chicago TrueType font (or legal equivalent)
- Geneva font family
- Monaco monospace font

**Image Assets:**
- System icons (32x32, 16x16)
- Window control buttons
- Classic cursor shapes
- Texture patterns for backgrounds

#### 4. Animation System

**Classic Transitions:**
- **Window Animations**: Zoom rectangles for opening/closing
- **Button Feedback**: Immediate visual response to clicks
- **Menu Animations**: Smooth drop-down with proper easing
- **Dialog Presentations**: Classic modal appearance

### User Experience Design

#### 1. Interaction Patterns

**Mouse/Touch Behavior:**
- **Single Tap/Click**: Standard selection and activation
- **Double Tap/Click**: Open/launch actions
- **Long Press**: Context menu equivalent
- **Drag and Drop**: Where applicable in mobile context

**Keyboard Navigation:**
- **Tab Order**: Logical progression through interface elements
- **Shortcut Keys**: Classic Mac keyboard shortcuts where applicable
- **Arrow Keys**: Menu navigation and list selection

#### 2. Accessibility Considerations

**Visual Accessibility:**
- **High Contrast Mode**: Enhanced contrast version of classic theme
- **Font Scaling**: Respect system font size preferences
- **Color Blind Support**: Ensure sufficient contrast ratios

**Motor Accessibility:**
- **Touch Targets**: Minimum 44pt touch targets despite classic appearance
- **Gesture Alternatives**: Provide alternatives to complex gestures

#### 3. Responsive Design

**Screen Size Adaptation:**
- **Phone Portrait**: Optimized layout for narrow screens
- **Phone Landscape**: Adjusted proportions for wider aspect
- **Tablet**: Take advantage of larger screen real estate
- **Desktop**: Full classic Mac experience when available

### Success Metrics

#### 1. User Engagement Metrics
- **Session Duration**: Increased time spent in app due to engaging interface
- **Return Rate**: Higher user retention from distinctive experience
- **Feature Discovery**: Improved exploration of app features
- **User Feedback**: Qualitative feedback on interface personality

#### 2. Technical Performance Metrics
- **Render Performance**: Maintain 60fps despite custom drawing
- **Memory Usage**: Efficient asset loading and caching
- **Battery Impact**: Minimal impact on device battery life
- **Load Times**: Fast theme switching and asset loading

#### 3. Design Quality Metrics
- **Visual Consistency**: Coherent application of design system
- **Accessibility Compliance**: Meeting WCAG guidelines
- **Cross-Platform Consistency**: Uniform experience across devices
- **Brand Recognition**: Distinctive visual identity achievement

### First Feature Cut: Minimal Viable Classic Chat

**Objective: Transform the chat interface with the simplest possible Classic Mac OS styling that provides immediate visual impact.**

#### Core Components (Week 1 - MVP)

**1. Classic Chat App Bar**
```dart
class ClassicChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      decoration: BoxDecoration(
        color: Color(0xFFDDDDDD),
        border: Border(
          bottom: BorderSide(color: Color(0xFF999999), width: 1),
        ),
        // Horizontal pinstripe pattern
        image: DecorationImage(
          image: AssetImage('assets/patterns/mac_pinstripe.png'),
          repeat: ImageRepeat.repeatX,
          fit: BoxFit.none,
        ),
      ),
      child: Row(
        children: [
          // Classic close box (16x16)
          Container(
            margin: EdgeInsets.only(left: 6, top: 6),
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: Color(0xFFDDDDDD),
              border: Border.all(color: Color(0xFF808080), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Color(0x40000000),
                  offset: Offset(1, 1),
                  blurRadius: 0,
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                configLoader.activePersonaDisplayName,
                style: TextStyle(
                  fontFamily: 'Chicago', // fallback to system if not available
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          SizedBox(width: 22), // Balance for close box
        ],
      ),
    );
  }
  
  @override
  Size get preferredSize => Size.fromHeight(28);
}
```

**2. Classic Message Bubbles**
```dart
class ClassicMessageBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  final String? audioPath;
  
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            // Classic Mac persona icon (32x32)
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _getPersonaColor(),
                border: Border.all(color: Colors.black, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x40000000),
                    offset: Offset(1, 1),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Icon(_getPersonaIcon(), color: Colors.white, size: 20),
            ),
            SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isUser ? Color(0xFFE0E0E0) : Colors.white,
                border: Border.all(color: Colors.black, width: 1),
                borderRadius: BorderRadius.circular(8), // Subtle rounding
                boxShadow: [
                  BoxShadow(
                    color: Color(0x40000000),
                    offset: Offset(1, 1),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: audioPath != null 
                ? _buildAudioContent() 
                : Text(
                    text,
                    style: TextStyle(
                      fontFamily: 'Geneva', // fallback to system
                      fontSize: 14,
                      color: Colors.black,
                      height: 1.3,
                    ),
                  ),
            ),
          ),
          if (isUser) ...[
            SizedBox(width: 8),
            // User icon - simple square
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Color(0xFF3366FF),
                border: Border.all(color: Colors.black, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x40000000),
                    offset: Offset(1, 1),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Icon(Icons.person, color: Colors.white, size: 20),
            ),
          ],
        ],
      ),
    );
  }
}
```

**3. Classic Typing Indicator**
```dart
class ClassicTypingIndicator extends StatefulWidget {
  final String personaName;
  final Color personaColor;
  
  @override
  _ClassicTypingIndicatorState createState() => _ClassicTypingIndicatorState();
}

class _ClassicTypingIndicatorState extends State<ClassicTypingIndicator> 
    with TickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    )..repeat();
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Classic Mac progress indicator style
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: widget.personaColor,
              border: Border.all(color: Colors.black, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Color(0x40000000),
                  offset: Offset(1, 1),
                  blurRadius: 0,
                ),
              ],
            ),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  painter: ClassicProgressPainter(_controller.value),
                  size: Size(32, 32),
                );
              },
            ),
          ),
          SizedBox(width: 12),
          Text(
            '${widget.personaName} is typing...',
            style: TextStyle(
              fontFamily: 'Geneva',
              fontSize: 12,
              color: Color(0xFF808080),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
```

**4. Classic Input Field**
```dart
class ClassicChatInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final Function(String, Duration) onSendAudio;
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFFF5F5F5),
        border: Border(
          top: BorderSide(color: Color(0xFF808080), width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.black, width: 1),
                // Inset appearance
                boxShadow: [
                  BoxShadow(
                    color: Color(0x40000000),
                    offset: Offset(-1, -1),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: TextField(
                controller: controller,
                style: TextStyle(
                  fontFamily: 'Geneva',
                  fontSize: 14,
                  color: Colors.black,
                ),
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(
                    color: Color(0xFF808080),
                    fontStyle: FontStyle.italic,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
          ),
          SizedBox(width: 8),
          // Classic 3D button
          _buildClassicButton(
            label: 'Send',
            onPressed: onSend,
            isPrimary: true,
          ),
          SizedBox(width: 4),
          // Audio button (existing functionality)
          _buildClassicButton(
            icon: Icons.mic,
            onPressed: () {/* existing audio logic */},
            isPrimary: false,
          ),
        ],
      ),
    );
  }
  
  Widget _buildClassicButton({
    String? label,
    IconData? icon,
    required VoidCallback onPressed,
    required bool isPrimary,
  }) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Color(0xFFDDDDDD),
          border: Border.all(color: Colors.black, width: 1),
          boxShadow: _isPressed ? [
            // Inset when pressed
            BoxShadow(
              color: Color(0x40000000),
              offset: Offset(-1, -1),
              blurRadius: 0,
            ),
          ] : [
            // Raised when normal
            BoxShadow(
              color: Colors.white,
              offset: Offset(-1, -1),
              blurRadius: 0,
            ),
            BoxShadow(
              color: Color(0x80000000),
              offset: Offset(1, 1),
              blurRadius: 0,
            ),
          ],
        ),
        child: icon != null 
          ? Icon(icon, size: 16, color: Colors.black)
          : Text(
              label!,
              style: TextStyle(
                fontFamily: 'Chicago',
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isPrimary ? Colors.black : Color(0xFF808080),
              ),
            ),
      ),
    );
  }
}
```

**5. Classic Background**
```dart
// Simple classic Mac desktop gray background
Scaffold(
  backgroundColor: Color(0xFFC0C0C0), // Classic Mac system gray
  // ... rest of chat interface
)
```

#### Audio Integration (Existing System)
- **Keep current audio functionality** - TTS service, audio messages, transcription
- **Add typing sound effects** to input field (optional enhancement)
- **Classic Mac system sounds** for button clicks and notifications

#### Assets Needed (Minimal)
- `mac_pinstripe.png` - 1px high horizontal pinstripe pattern for title bars
- Chicago font (or fallback to system monospace)
- Geneva font (or fallback to system sans-serif)

#### Implementation Priority
1. **Replace ChatAppBar** with ClassicChatAppBar
2. **Replace message bubbles** with ClassicMessageBubble  
3. **Replace typing indicator** with ClassicTypingIndicator
4. **Replace input field** with ClassicChatInput
5. **Set classic background** color

**Result: Instant Classic Mac OS chat experience with zero impact on existing audio functionality.**

### Implementation Phases

#### Phase 1: Foundation (Weeks 1-2)
- **Core Theme Structure**: Basic theme architecture and color system
- **Typography Integration**: Font loading and text styling
- **Basic Window Chrome**: Title bars and window borders
- **Simple Button Styles**: Primary button implementations

#### Phase 2: Components (Weeks 3-4)
- **Advanced Buttons**: All button variants and states
- **Dialog System**: Alert and modal dialog implementations
- **Menu System**: Basic menu bar and dropdown functionality
- **Icon Integration**: System icons and persona-specific icons

#### Phase 3: Polish (Weeks 5-6)
- **Animations**: Smooth transitions and micro-interactions
- **Advanced Chrome**: Scroll bars and window controls
- **Accessibility**: Full accessibility compliance
- **Performance Optimization**: Asset optimization and caching

#### Phase 4: Integration (Week 7)
- **Chat App Integration**: Apply theme to all chat interfaces
- **Persona Theming**: Persona-specific styling variations
- **Testing**: Comprehensive testing across devices
- **Documentation**: Complete implementation documentation

### Risk Assessment

#### Technical Risks
- **Performance Impact**: Custom drawing may impact performance
  - *Mitigation*: Careful optimization and caching strategies
- **Platform Differences**: iOS/Android rendering inconsistencies
  - *Mitigation*: Extensive cross-platform testing
- **Font Licensing**: Legal issues with classic Mac fonts
  - *Mitigation*: Use legally available alternatives or create custom fonts

#### Design Risks
- **Accessibility Compliance**: Classic design may conflict with modern accessibility
  - *Mitigation*: Provide high contrast and accessible variants
- **User Confusion**: Some users may find retro interface confusing
  - *Mitigation*: Provide theme switching option
- **Maintenance Complexity**: Custom components require ongoing maintenance
  - *Mitigation*: Comprehensive documentation and testing

#### Business Risks
- **Limited Appeal**: Niche aesthetic may not appeal to all users
  - *Mitigation*: Position as optional theme, maintain default option
- **Development Time**: Complex implementation may exceed timeline
  - *Mitigation*: Phased approach with MVP focus

### Future Enhancements

#### Advanced Features
- **Multiple Theme Variants**: System 6, System 7, Mac OS 8 variations
- **Sound Effects**: Classic Mac system sounds integration
- **Advanced Animations**: More sophisticated window management
- **Desktop Metaphor**: File system browsing with classic Finder styling

#### Integration Opportunities
- **Other Retro Themes**: Windows 95, Amiga Workbench variants
- **Seasonal Variations**: Holiday-themed classic Mac styling
- **Community Themes**: User-generated classic computing themes
- **Productivity Features**: Classic Mac desk accessories integration

### Conclusion

The Classic Mac OS UI Styling System represents a unique opportunity to differentiate the chat application through distinctive visual personality while honoring the rich heritage of graphical user interface design. By carefully implementing the beloved design patterns of classic Mac OS while maintaining modern functionality and accessibility, we can create an interface that delights users and stands out in a crowded market.

This implementation will serve as both a functional enhancement and a tribute to the pioneering work of Apple's Human Interface Group and the broader community of classic computing enthusiasts. The result will be a chat application that feels both nostalgically familiar and refreshingly unique in today's homogenized interface landscape.

---

**Document Version:** 1.0  
**Created:** 2025-01-16  
**Status:** Draft - Pending Review  
**Priority:** Medium - Enhancement Feature  
**Estimated Effort:** 7 weeks (4 developer-weeks)  
**Dependencies:** Flutter theme system, custom font integration, asset management system