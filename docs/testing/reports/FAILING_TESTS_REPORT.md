# Comprehensive Failing Tests Report

**Test Run Date:** 2026-01-23
**Total Tests:** 1536
**Passed:** 1506
**Failed:** 30
**Pass Rate:** 98.05%

## Failing Tests by Category

### 1. Discovery Bloc Tests (6 failures)
- DiscoveryBloc LoadDiscoveryStudies emits [DiscoveryLoading, DiscoveryLoaded] when studies load successfully
- DiscoveryBloc LoadDiscoveryStudy emits [DiscoveryStudyLoading, DiscoveryLoaded] when study loads successfully
- DiscoveryBloc AnswerDiscoveryQuestion calls progressTracker.answerQuestion
- DiscoveryBloc MarkSectionCompleted calls progressTracker.markSectionCompleted
- DiscoveryBloc CompleteDiscoveryStudy calls progressTracker.completeStudy
- DiscoveryBloc RefreshDiscoveryStudies refreshes available studies list

### 2. Discovery List Page Tests (10 failures)
- DiscoveryListPage State Tests Shows loading indicator when loading
- DiscoveryListPage State Tests Shows error message when error occurs
- DiscoveryListPage Carousel Tests Carousel renders with fluid transition settings
- DiscoveryListPage Carousel Tests Carousel uses BouncingScrollPhysics for smooth scrolling
- DiscoveryListPage Carousel Tests Progress dots display with minimalistic border style
- DiscoveryListPage Grid Tests Grid orders incomplete studies first, completed last
- DiscoveryListPage Grid Tests Grid cards display minimalistic bordered icons
- DiscoveryListPage Grid Tests Completed studies show primary color checkmark with border
- DiscoveryListPage Navigation Tests Tapping carousel card navigates to detail page
- DiscoveryListPage Navigation Tests Grid toggle button switches between carousel and grid view

### 3. Testimony Bloc Tests (2 failures)
- TestimonyBloc Tests should not add testimony with empty text
- TestimonyBloc Tests should clear error message

### 4. Discovery Share Helper Tests (3 failures)
- DiscoveryShareHelper should generate summary text for sharing
- DiscoveryShareHelper should generate complete study text
- DiscoveryShareHelper should handle study without optional fields

### 5. Discovery Model Tests (1 failure)
- DiscoveryDevotional Model Tests should handle serialization to JSON

### 6. Prayers Page Badges Tests (6 failures)
- Prayers Page Count Badges should display count badge for active prayers
- Prayers Page Count Badges should display count badge for answered prayers
- Prayers Page Count Badges should display count badge for thanksgivings
- Prayers Page Count Badges should display 99+ for counts over 99
- Prayers Page Count Badges should not display badge when count is zero
- Prayers Page Count Badges should display multiple badges for different tabs

### 7. Service Locator Tests (1 failure)
- ServiceLocator Error Handling Error message mentions setupServiceLocator

### 8. Splash Screen Tests (1 failure)
- SplashScreen renders successfully

