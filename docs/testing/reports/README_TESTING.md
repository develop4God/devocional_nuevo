# Testing Strategy

This repository uses tagged tests to optimize test execution time.

## Test Tags

### `slow` Tag
Integration and critical coverage tests that take more than 2 minutes are tagged with `@Tags(['slow'])`.

## Running Tests

### Fast Tests (Default)
Run only fast unit and behavioral tests (recommended for development):
```bash
flutter test --exclude-tags=slow
```

### All Tests
Run all tests including slow integration tests:
```bash
flutter test
```

### Only Slow Tests
Run only integration and critical coverage tests:
```bash
flutter test --tags=slow
```

## Test Counts
- Fast tests (unit + behavioral): ~900 tests (~2 minutes)
- Slow tests (integration + critical): ~570 tests (~10+ minutes)
- Total: ~1470 tests

## Tagged Test Files
The following directories contain tagged slow tests:
- `test/integration/` - Integration tests
- `test/critical_coverage/` - Critical path coverage tests
