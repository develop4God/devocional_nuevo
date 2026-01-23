# Detailed Test Failure Analysis

## Category 1: TEST APPROACH PROBLEMS (DI/Mocking Issues)

### 1.1 Discovery Bloc Tests (6 failures) - MOCK SIGNATURE MISMATCH
**File:** `test/critical_coverage/discovery_bloc_test.dart`
**Issue:** Mock setup doesn't match actual method signatures
**Error:** `type 'Null' is not a subtype of type 'Future<Set<String>>'`
**Root Cause:** 
- Line 43: `when(() => mockProgressTracker.getProgress(any()))` mocks 1 parameter
- Line 168 in bloc: `await progressTracker.getProgress(id, locale)` calls with 2 parameters
- When mock doesn't match, it returns null instead of the mocked DiscoveryProgress

**Fix Strategy:** Update mock to accept both parameters: `getProgress(any(), any())`

### 1.2 Testimony Bloc Tests (2 failures) - MISSING SERVICE LOCATOR SETUP
**File:** `test/critical_coverage/testimony_bloc_working_test.dart`
**Issue:** LocalizationService not registered in service locator
**Error:** `Bad state: Service LocalizationService not registered`
**Root Cause:**
- TestimonyBloc uses `getService<LocalizationService>()` on lines 38, 54
- Test doesn't initialize service locator or mock the service

**Fix Strategy:** Set up service locator with mock LocalizationService before creating bloc

### 1.3 Discovery List Page Tests (10 failures) - MISSING PROVIDER SETUP
**File:** `test/pages/discovery_list_page_test.dart`
**Issue:** Tests don't set up required BLoC providers
**Error:** Pending timers, widget not rendering properly
**Root Cause:** Widget tests must wrap the page in proper provider hierarchy

**Fix Strategy:** Wrap widget in MultiBloc Provider with all required blocs

### 1.4 Prayers Page Badges Tests (6 failures) - MISSING PROVIDER SETUP
**File:** `test/unit/widgets/prayers_page_badges_test.dart`
**Issue:** TestimonyBloc not provided in widget tree
**Error:** `Could not find the correct Provider<TestimonyBloc>`
**Root Cause:** Widget depends on BlocBuilder<TestimonyBloc> but test doesn't provide it

**Fix Strategy:** Provide TestimonyBloc in widget test setup

## Category 2: REAL PRODUCTION BUGS

### 2.1 Discovery Share Helper Tests (3 failures) - CASE SENSITIVITY BUG
**File:** `test/unit/utils/discovery_share_helper_test.dart`
**Issue:** Production code generates uppercase text, test expects title case
**Error:** Expected 'Estudio Biblico' but got 'ESTUDIO BIBLICO DIARIO'
**Root Cause:** Production code uses uppercase formatting, breaking share functionality expectations

**Fix Strategy:** Fix production code to use proper title case for share text

### 2.2 Service Locator Test (1 failure) - ERROR MESSAGE BUG
**File:** `test/unit/services/service_locator_test.dart`
**Issue:** Error message doesn't mention 'setupServiceLocator' as expected
**Root Cause:** Production error message format changed

**Fix Strategy:** Update production code error message or update test expectation

## Category 3: TEST IMPLEMENTATION ISSUES

### 3.1 Discovery Model Test (1 failure) - SERIALIZATION ISSUE
**File:** `test/unit/models/discovery_devotional_model_test.dart`
**Issue:** Model serialization test failing
**Root Cause:** Model structure or test expectation mismatch

**Fix Strategy:** Investigate and align test with actual model serialization

### 3.2 Splash Screen Test (1 failure) - RENDERING ISSUE
**File:** `test/splash_screen_font_test.dart`
**Issue:** SplashScreen widget not rendering in test
**Root Cause:** Likely missing dependencies or assets in test environment

**Fix Strategy:** Set up proper test environment with required assets

## Summary

| Category | Count | Type |
|----------|-------|------|
| DI/Mocking Issues | 24 | Test Problem |
| Production Bugs | 4 | Real Bug |
| Test Implementation | 2 | Test Problem |
| **TOTAL** | **30** | |

**Production Code Changes Required:** 2-4
**Test Code Changes Required:** 26-28
