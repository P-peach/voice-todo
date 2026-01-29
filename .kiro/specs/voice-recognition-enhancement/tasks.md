# Implementation Plan: Voice Recognition Enhancement

## Overview

This implementation plan breaks down the voice recognition enhancement feature into incremental coding tasks. The plan follows a phased approach: (1) Custom Vocabulary Service foundation, (2) Post-Recognition Editing, (3) Todo Item Editing, (4) Material Design 3 Styling, (5) Animation Implementation, and (6) Performance Optimization. Each phase builds on the previous one, with property-based tests integrated throughout to validate correctness properties early.

## Tasks

- [x] 1. Set up Custom Vocabulary Service foundation
  - [x] 1.1 Create CustomVocabularyService class with singleton pattern
    - Implement SharedPreferences storage for vocabulary entries
    - Create methods: initialize(), addEntry(), removeEntry(), getAllEntries()
    - Add JSON serialization for VocabularyEntry model
    - _Requirements: 1.1, 1.4_
  
  - [x] 1.2 Implement fuzzy matching algorithm for vocabulary corrections
    - Integrate string_similarity package
    - Create applyCorrections() method with threshold 0.8
    - Implement word splitting and matching logic
    - _Requirements: 1.2, 6.2_
  
  - [x] 1.3 Load default grocery vocabulary (50+ items)
    - Create loadDefaultGroceryVocabulary() method
    - Add Chinese vegetables, fruits, and units to default vocabulary
    - Call on first app launch
    - _Requirements: 1.3_
  
  - [x] 1.4 Write property test for vocabulary storage round-trip
    - **Property 1: Vocabulary Storage Round-Trip**
    - **Validates: Requirements 1.1**
  
  - [x] 1.5 Write property test for vocabulary corrections applied before parsing
    - **Property 2: Vocabulary Corrections Applied Before Parsing**
    - **Validates: Requirements 1.2, 6.1**
  
  - [x] 1.6 Write property test for vocabulary persistence immediacy
    - **Property 3: Vocabulary Persistence Immediacy**
    - **Validates: Requirements 1.4, 7.2**
  
  - [x] 1.7 Write property test for fuzzy vocabulary matching
    - **Property 10: Fuzzy Vocabulary Matching**
    - **Validates: Requirements 6.2**
  
  - [x] 1.8 Write property test for highest confidence match selection
    - **Property 11: Highest Confidence Match Selected**
    - **Validates: Requirements 6.3**
  
  - [x] 1.9 Write unit tests for default vocabulary and edge cases
    - Test default vocabulary contains 50+ entries
    - Test empty vocabulary handling
    - Test special characters in vocabulary entries
    - _Requirements: 1.3, 8.5_

- [x] 2. Integrate vocabulary corrections into VoiceProvider
  - [x] 2.1 Add CustomVocabularyService integration to VoiceProvider
    - Import CustomVocabularyService
    - Add _applyVocabularyCorrections() private method
    - Call corrections in stopListening() before parsing
    - Store corrected text in _correctedText field
    - _Requirements: 1.2, 6.1_
  
  - [ ]* 2.2 Write property test for vocabulary correction performance
    - **Property 20: Vocabulary Correction Performance**
    - **Validates: Requirements 10.2**
  
  - [ ]* 2.3 Write unit tests for VoiceProvider vocabulary integration
    - Test corrections are applied before parsing
    - Test corrected text is stored
    - Test error handling when vocabulary service fails
    - _Requirements: 1.2, 6.1_

- [x] 3. Create vocabulary management UI in settings
  - [x] 3.1 Create VocabularySettingsScreen widget
    - Display list of vocabulary entries
    - Add "Add Entry" button
    - Add delete action for each entry
    - Use Material 3 Card and ListTile components
    - _Requirements: 1.5_
  
  - [x] 3.2 Create AddVocabularyEntryDialog widget
    - Two text fields: incorrect term and correct term
    - Validation for non-empty fields
    - Save button calls CustomVocabularyService.addEntry()
    - _Requirements: 1.5_
  
  - [ ]* 3.3 Write widget tests for vocabulary management UI
    - Test vocabulary list displays entries
    - Test add entry dialog validation
    - Test delete action removes entry
    - _Requirements: 1.5_

- [~] 4. Checkpoint - Ensure vocabulary service tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [x] 5. Create RecognitionEditDialog for post-recognition editing
  - [x] 5.1 Create RecognitionEditDialog widget with Material 3 styling
    - Use BottomSheet with rounded top corners (16dp)
    - Add OutlinedTextField with 4 lines minimum
    - Add FilledButton for "确认" and TextButton for "取消"
    - Auto-focus text field when dialog opens
    - _Requirements: 2.1, 2.2, 2.4_
  
  - [x] 5.2 Integrate RecognitionEditDialog into VoiceProvider
    - Add stopListeningWithEdit() method to VoiceProvider
    - Call dialog after stopListening() with corrected text
    - Handle confirm action: parse text and create todos
    - Handle cancel action: reset state to ready
    - _Requirements: 2.1, 2.5, 2.6_
  
  - [ ]* 5.3 Write property test for recognition edit confirmation
    - **Property 4: Recognition Edit Confirmation Creates Todos**
    - **Validates: Requirements 2.5**
  
  - [ ]* 5.4 Write property test for recognition edit cancellation
    - **Property 5: Recognition Edit Cancellation Resets State**
    - **Validates: Requirements 2.6**
  
  - [ ]* 5.5 Write widget tests for RecognitionEditDialog
    - Test dialog displays with initial text
    - Test text field is editable
    - Test confirm and cancel buttons exist
    - Test keyboard auto-focus
    - _Requirements: 2.1, 2.2, 2.4_

- [x] 6. Create TodoEditDialog for editing existing todos
  - [x] 6.1 Create TodoEditDialog widget with comprehensive form
    - Use Material 3 Dialog with elevated Card
    - Add form fields: title, description, category, priority, deadline
    - Implement form validation (required title, valid date)
    - Add FilledButton for "保存" and TextButton for "取消"
    - Show inline error messages for validation failures
    - _Requirements: 3.1, 3.2, 3.3_
  
  - [x] 6.2 Add tap handler to todo list items
    - Modified TodoCard to make items tappable (click instead of long-press)
    - Call TodoEditDialog on tap
    - Pass selected todo to dialog
    - _Requirements: 3.1_
  
  - [x] 6.3 Implement TodoProvider.updateTodoWithValidation()
    - Validate todo properties before update
    - Call SqliteService.updateTodo() if valid
    - Preserve original createdAt timestamp
    - Refresh UI after successful update
    - Handle database errors gracefully
    - Handle reminder configuration changes
    - _Requirements: 3.3, 3.4, 3.6, 7.3_
  
  - [ ]* 6.4 Write property test for todo edit dialog shows all properties
    - **Property 6: Todo Edit Dialog Shows All Properties**
    - **Validates: Requirements 3.1**
  
  - [ ]* 6.5 Write property test for invalid todo edits rejected
    - **Property 7: Invalid Todo Edits Are Rejected**
    - **Validates: Requirements 3.3, 8.4**
  
  - [ ]* 6.6 Write property test for todo edit round-trip
    - **Property 8: Todo Edit Round-Trip Preserves Data**
    - **Validates: Requirements 3.4, 3.6, 7.4**
  
  - [ ]* 6.7 Write property test for todo edit cancellation
    - **Property 9: Todo Edit Cancellation Preserves Original**
    - **Validates: Requirements 3.5**
  
  - [x]* 6.8 Write unit tests for TodoEditDialog validation
    - Test empty title shows error
    - Test invalid date shows error
    - Test all form fields display correctly
    - Test can edit all fields
    - Test cancel and save buttons
    - Test delete confirmation
    - _Requirements: 3.3, 8.4_

- [~] 7. Checkpoint - Ensure editing functionality tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 8. Implement Material Design 3 theming
  - [~] 8.1 Create AppTheme class with light and dark themes
    - Define ColorScheme.fromSeed() for both themes
    - Configure Typography.material2021()
    - Set CardTheme with elevation and rounded corners
    - Set FilledButtonTheme with proper sizing and shape
    - Set TextButtonTheme, OutlinedButtonTheme
    - Set InputDecorationTheme for text fields
    - _Requirements: 4.1, 4.2, 4.3, 4.4_
  
  - [~] 8.2 Apply Material 3 theme to MaterialApp
    - Set theme and darkTheme in MaterialApp
    - Enable useMaterial3 flag
    - Test theme switching
    - _Requirements: 4.1, 4.5_
  
  - [~] 8.3 Update existing UI components to use Material 3 widgets
    - Replace ElevatedButton with FilledButton
    - Update Card widgets with proper elevation
    - Update TextField to OutlinedTextField
    - Ensure consistent border radius (12dp)
    - _Requirements: 4.1_
  
  - [ ]* 8.4 Write property test for color contrast compliance
    - **Property 18: Color Contrast Compliance**
    - **Validates: Requirements 9.3**
  
  - [ ]* 8.5 Write unit tests for theme configuration
    - Test light theme exists and has correct colors
    - Test dark theme exists and has correct colors
    - Test theme switching works
    - _Requirements: 4.5_

- [ ] 9. Implement animation system
  - [~] 9.1 Create AnimationConstants utility class
    - Define duration constants (fast: 200ms, normal: 300ms, slow: 400ms)
    - Define curve constants (easeInOut, overshoot)
    - _Requirements: 5.5_
  
  - [~] 9.2 Create AnimatedListItem widget for todo list animations
    - Implement SlideTransition and FadeTransition
    - Use AnimationConstants for duration
    - Apply to todo list items on add/remove
    - _Requirements: 5.1, 5.2_
  
  - [~] 9.3 Add dialog animations to RecognitionEditDialog and TodoEditDialog
    - Implement scale and fade animation on open
    - Implement reverse animation on close
    - Use AnimationConstants.normal duration
    - _Requirements: 5.3, 5.4_
  
  - [~] 9.4 Add completion checkmark animation
    - Create ScaleTransition with bounce effect
    - Trigger when todo is marked complete
    - Use AnimationConstants.normal duration
    - _Requirements: 5.6_
  
  - [~] 9.5 Implement reduced motion support
    - Check MediaQuery.of(context).disableAnimations
    - Set animation duration to 0ms when reduced motion enabled
    - Apply to all animations
    - _Requirements: 5.7_
  
  - [ ]* 9.6 Write property test for animation duration bounds
    - **Property 14: Animation Duration Bounds**
    - **Validates: Requirements 5.5**
  
  - [ ]* 9.7 Write property test for reduced motion respected
    - **Property 15: Reduced Motion Respected**
    - **Validates: Requirements 5.7**
  
  - [ ]* 9.8 Write widget tests for animations
    - Test list item slide-in animation
    - Test dialog scale animation
    - Test checkmark bounce animation
    - _Requirements: 5.1, 5.3, 5.6_

- [ ] 10. Implement performance optimizations
  - [~] 10.1 Add performance monitoring for database operations
    - Wrap database calls with Stopwatch
    - Log operations exceeding 100ms threshold
    - _Requirements: 7.1_
  
  - [~] 10.2 Optimize vocabulary correction algorithm
    - Cache compiled regex patterns
    - Use efficient string matching algorithm
    - Limit vocabulary size to 1000 entries
    - _Requirements: 10.2_
  
  - [~] 10.3 Implement lazy loading for large todo lists
    - Use ListView.builder with itemCount
    - Load todos in batches of 50
    - Implement pagination when scrolling
    - _Requirements: 10.4_
  
  - [ ]* 10.4 Write property test for database update performance
    - **Property 12: Database Update Performance**
    - **Validates: Requirements 7.1**
  
  - [ ]* 10.5 Write property test for edit dialog display performance
    - **Property 19: Edit Dialog Display Performance**
    - **Validates: Requirements 10.1**
  
  - [ ]* 10.6 Write property test for vocabulary correction performance
    - **Property 20: Vocabulary Correction Performance**
    - **Validates: Requirements 10.2**

- [ ] 11. Implement error handling and user feedback
  - [~] 11.1 Add error handling to VoiceProvider
    - Display user-friendly error messages for permission denied
    - Show device unsupported dialog
    - Handle recognition failures gracefully
    - _Requirements: 8.1_
  
  - [~] 11.2 Add error handling to TodoProvider
    - Show snackbar for database failures
    - Implement optimistic UI with rollback
    - Display validation errors inline
    - _Requirements: 8.2, 8.4_
  
  - [~] 11.3 Add error handling to CustomVocabularyService
    - Skip invalid vocabulary entries
    - Log warnings for malformed entries
    - Handle storage failures gracefully
    - _Requirements: 8.5_
  
  - [ ]* 11.4 Write property test for database failure preserves state
    - **Property 13: Database Failure Preserves State**
    - **Validates: Requirements 7.3**
  
  - [ ]* 11.5 Write property test for invalid vocabulary entries skipped
    - **Property 16: Invalid Vocabulary Entries Skipped**
    - **Validates: Requirements 8.5**
  
  - [ ]* 11.6 Write unit tests for error handling
    - Test voice recognition error messages
    - Test database error snackbars
    - Test validation error display
    - _Requirements: 8.1, 8.2, 8.4_

- [ ] 12. Implement accessibility features
  - [~] 12.1 Add semantic labels to all interactive elements
    - Add Semantics widgets to buttons
    - Add labels to text fields
    - Add labels to list items
    - _Requirements: 9.1_
  
  - [~] 12.2 Ensure minimum touch target sizes
    - Set minimum size constraints on all buttons (48x48 dp)
    - Add padding to small interactive elements
    - Test on physical device
    - _Requirements: 9.2_
  
  - [~] 12.3 Implement system text scaling support
    - Use MediaQuery.textScaleFactor
    - Test with large text sizes
    - Ensure layouts don't break
    - _Requirements: 9.5_
  
  - [ ]* 12.4 Write property test for touch target minimum size
    - **Property 17: Touch Target Minimum Size**
    - **Validates: Requirements 9.2**
  
  - [ ]* 12.5 Write unit tests for accessibility
    - Test semantic labels exist
    - Test touch target sizes
    - Test text scaling
    - _Requirements: 9.1, 9.2, 9.5_

- [ ] 13. Final integration and testing
  - [~] 13.1 Wire all components together
    - Integrate CustomVocabularyService with VoiceProvider
    - Integrate RecognitionEditDialog with home screen
    - Integrate TodoEditDialog with todo list
    - Apply Material 3 theme throughout app
    - Enable animations on all transitions
    - _Requirements: All_
  
  - [ ]* 13.2 Write integration tests for complete user flows
    - Test voice → vocabulary correction → edit → save flow
    - Test tap todo → edit → save flow
    - Test theme switching
    - Test reduced motion
    - _Requirements: All_
  
  - [ ]* 13.3 Write performance tests
    - Test database operations under 100ms
    - Test vocabulary corrections under 50ms
    - Test dialog display under 100ms
    - Test animation frame rates
    - _Requirements: 7.1, 10.1, 10.2, 10.3_

- [~] 14. Final checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Property tests validate universal correctness properties with 100+ iterations
- Unit tests validate specific examples and edge cases
- Integration tests validate end-to-end user flows
- Performance tests validate timing requirements
- All tests use Flutter's testing framework with mockito for mocking
- Checkpoints ensure incremental validation at key milestones
