# Firebase Analytics Events - FAB and Discovery

This document describes the new Firebase Analytics events added to track user interactions with the
Floating Action Button (FAB) and Discovery/Bible Studies features.

## Overview

The following analytics events have been implemented to provide insights into user behavior:

1. **FAB Tap Events** - Track when users tap the floating action button
2. **FAB Choice Selection** - Track which option users select (Prayer, Thanksgiving, or Testimony)
3. **Discovery Actions** - Track user interactions with Bible Studies/Discovery features

---

## Event Definitions

### 1. `fab_tapped`

**Description**: Logged when a user taps the Floating Action Button (+ button)

**Parameters**:

- `source` (string): The page where the FAB was tapped
    - Values: `'devocionales_page'`, `'prayers_page'`

**Example Usage**:

```dart
getService<AnalyticsService>
().logFabTapped
(
source
:
'
devocionales_page
'
);
```

**Use Cases**:

- Track FAB engagement across different pages
- Understand where users are more likely to create prayers/thanksgivings/testimonies
- Optimize FAB placement and visibility

---

### 2. `fab_choice_selected`

**Description**: Logged when a user selects an option from the FAB choice modal

**Parameters**:

- `source` (string): The page where the choice was made
    - Values: `'devocionales_page'`, `'prayers_page'`
- `choice` (string): The option selected by the user
    - Values: `'prayer'`, `'thanksgiving'`, `'testimony'`

**Example Usage**:

```dart
getService<AnalyticsService>
().logFabChoiceSelected
(
source: 'devocionales_page',
choice: 'prayer',
);
```

**Use Cases**:

- Understand which spiritual practice is most popular
- Track prayer vs thanksgiving vs testimony creation patterns
- Identify which page drives more engagement for each option
- Optimize the order or presentation of choices

**Analytics Queries**:

- "What percentage of users create prayers vs thanksgivings?"
- "Which page has higher testimony creation rate?"
- "Do users who start from devocionales_page prefer different options?"

---

### 3. `discovery_action`

**Description**: Logged when users interact with Discovery/Bible Studies features

**Parameters**:

- `action` (string): The action performed
    - Values:
        - `'study_opened'` - User opened a study detail page
        - `'study_completed'` - User marked a study as completed
        - `'study_shared'` - User shared a study
        - `'study_downloaded'` - User downloaded a study for offline use
        - `'toggle_grid_view'` - User switched to grid view
        - `'toggle_carousel_view'` - User switched to carousel view
- `study_id` (string, optional): The ID of the study being interacted with
    - Present for: study_opened, study_completed, study_shared, study_downloaded
    - Absent for: toggle_grid_view, toggle_carousel_view

**Example Usage**:

```dart
// With study ID
getService<AnalyticsService>
().logDiscoveryAction
(
action: 'study_opened',
studyId: 'genesis_study_1',
);

// Without study ID
getService<AnalyticsService>().logDiscoveryAction(
action: 'toggle_grid_view',
);
```

**Use Cases**:

- Track study engagement and completion rates
- Identify most popular Bible studies
- Measure offline study downloads
- Understand user preferences for viewing modes (grid vs carousel)
- Analyze sharing behavior

**Analytics Queries**:

- "Which Bible studies have the highest completion rate?"
- "How many users download studies for offline use?"
- "What percentage of users share studies?"
- "Do users prefer grid view or carousel view?"
- "Which studies are opened but not completed?"

---

## Implementation Locations

### Devocionales Page (`lib/pages/devocionales_page.dart`)

- **FAB Tap**: Logged in `_showAddPrayerOrThanksgivingChoice()` method
- **Choice Selection**: Logged in `AddEntryChoiceModal` widget when user selects an option

### Prayers Page (`lib/pages/prayers_page.dart`)

- **FAB Tap**: Logged in `_showAddPrayerOrThanksgivingChoice()` method
- **Choice Selection**: Logged in `AddEntryChoiceModal` widget when user selects an option

### Discovery List Page (`lib/pages/discovery_list_page.dart`)

- **Toggle View**: Logged in `_toggleGridOverlay()` method
- **Study Opened**: Logged in `_navigateToDetail()` method
- **Study Downloaded**: Logged in `_handleDownloadStudy()` method
- **Study Shared**: Logged in `_handleShareStudy()` method

### Discovery Detail Page (`lib/pages/discovery_detail_page.dart`)

- **Study Completed**: Logged in `_onCompleteStudy()` method

### Add Entry Choice Modal (`lib/widgets/add_entry_choice_modal.dart`)

- **Choice Selection**: Logged when user taps prayer, thanksgiving, or testimony option
- Receives `source` parameter to identify originating page

---

## Analytics Service Methods

### `logFabTapped({required String source})`

Logs when the FAB is tapped.

### `logFabChoiceSelected({required String source, required String choice})`

Logs when a user selects an option from the FAB modal.

### `logDiscoveryAction({required String action, String? studyId})`

Logs Discovery/Bible Studies user actions.

---

## Testing

Tests are located in:

- `test/services/analytics_fab_events_test.dart`

Run tests with:

```bash
flutter test test/services/analytics_fab_events_test.dart
```

All analytics methods include error handling and fail silently to prevent disrupting user
experience.

---

## Firebase Console Setup

To view these events in Firebase Console:

1. Go to **Analytics > Events**
2. Look for custom events:
    - `fab_tapped`
    - `fab_choice_selected`
    - `discovery_action`

3. Create custom reports or audiences based on:
    - Users who frequently create prayers
    - Users who complete Bible studies
    - Users who prefer specific viewing modes

---

## Future Enhancements

Potential additional tracking:

- Time spent on each discovery study section
- Favorite/unfavorite actions on studies
- Number of sections completed per study
- Prayer/Thanksgiving/Testimony edit and delete actions
- Success rate of sharing (did share complete or was it cancelled)

---

## Notes

- All analytics events are logged asynchronously and fail silently
- No personally identifiable information (PII) is logged
- Events follow Firebase Analytics best practices for parameter naming
- Error counts are tracked internally for debugging purposes
