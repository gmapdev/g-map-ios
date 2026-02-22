# Contributing to GMap

Thank you for your interest in contributing to GMap! This document provides guidelines and instructions for contributing to the project.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Coding Standards](#coding-standards)
- [Testing Guidelines](#testing-guidelines)
- [Pull Request Process](#pull-request-process)
- [Issue Guidelines](#issue-guidelines)
- [Documentation](#documentation)

## Code of Conduct

### Our Pledge

We are committed to providing a welcoming and inclusive environment for all contributors, regardless of:  
- Experience level  
- Gender identity and expression  
- Sexual orientation  
- Disability  
- Personal appearance  
- Body size  
- Race  
- Ethnicity  
- Age  
- Religion  
- Nationality  

### Expected Behavior

- Use welcoming and inclusive language
- Be respectful of differing viewpoints and experiences
- Gracefully accept constructive criticism
- Focus on what is best for the community
- Show empathy towards other community members

### Unacceptable Behavior

- Trolling, insulting/derogatory comments, and personal attacks
- Public or private harassment
- Publishing others' private information without permission
- Other conduct which could reasonably be considered inappropriate

## Getting Started

### Prerequisites

Before you begin, ensure you have:

1. **Development Environment**
   - macOS 12.0 or later
   - Xcode 14.0 or later
   - CocoaPods 1.11.0 or later
   - Git

2. **Knowledge Requirements**
   - Swift 5.0+
   - SwiftUI
   - Combine framework
   - iOS development best practices

### Fork and Clone

1. Fork the repository on GitHub
2. Clone your fork locally:
   ```bash
   git clone https://github.com/YOUR_USERNAME/otp-ios-swiftui.git
   cd otp-ios-swiftui
   ```

3. Add upstream remote:
   ```bash
   git remote add upstream https://github.com/ORIGINAL_OWNER/otp-ios-swiftui.git
   ```

### Setup Development Environment

1. Install dependencies:
   ```bash
   pod install
   ```

2. Open the workspace:
   ```bash
   open ATLRides.xcworkspace
   ```

3. Build the project:
   - Select the `GMap` scheme
   - Choose a simulator or device
   - Press `Cmd + B` to build

## Development Workflow

### Branch Strategy

We use a simplified Git Flow:

- `main` - Production-ready code
- `develop` - Integration branch for features
- `feature/*` - New features
- `bugfix/*` - Bug fixes
- `hotfix/*` - Urgent production fixes

### Creating a Feature Branch

```bash
# Update your local repository
git checkout develop
git pull upstream develop

# Create a feature branch
git checkout -b feature/your-feature-name
```

### Making Changes

1. **Write Code**
   - Follow coding standards (see below)
   - Write self-documenting code
   - Add comments for complex logic

2. **Test Your Changes**
   - Write unit tests for new functionality
   - Run existing tests to ensure nothing breaks
   - Test on both simulator and physical device

3. **Commit Your Changes**
   ```bash
   git add .
   git commit -m "feat: add trip history feature"
   ```

### Commit Message Format

We follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types:**  
- `feat`: New feature  
- `fix`: Bug fix  
- `docs`: Documentation changes  
- `style`: Code style changes (formatting, etc.)  
- `refactor`: Code refactoring  
- `test`: Adding or updating tests  
- `chore`: Maintenance tasks  

**Examples:**  

- feat(trip-planning): add multi-modal route options    
- fix(map): resolve annotation clustering issue  
- docs(readme): update installation instructions  
- refactor(api): simplify network request handling  
- test(location): add unit tests for location service  

## Coding Standards

### Swift Style Guide

We follow the [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/) and [Ray Wenderlich Swift Style Guide](https://github.com/raywenderlich/swift-style-guide).

#### Key Principles

1. **Clarity at the point of use**  
   // ✅ Good
   func remove(at position: Index) -> Element  
   // ❌ Bad
   func remove(_ position: Index) -> Element

2. **Prefer methods and properties to free functions**  
   // ✅ Good
   let sorted = items.sorted()  
   // ❌ Bad
   let sorted = sort(items)

3. **Use type inference**  
   // ✅ Good
   let name = "John"  
   // ❌ Bad
   let name: String = "John"

### Code Organization

```swift
// MARK: - Type Definition
class TripPlanningManager {

    // MARK: - Properties
    private var trips: [Trip] = []
    public var currentTrip: Trip?

    // MARK: - Initialization
    init() {
        // Setup
    }

    // MARK: - Public Methods
    public func planTrip() {
        // Implementation
    }

    // MARK: - Private Methods
    private func validateTrip() {
        // Implementation
    }
}

// MARK: - Protocol Conformance
extension TripPlanningManager: TripPlannerDelegate {
    func didCompletePlanning() {
        // Implementation
    }
}
```

### Naming Conventions

```swift
// Classes, Structs, Enums, Protocols: PascalCase
class TripPlanningManager { }
struct TripRequest { }
enum TransportMode { }
protocol TripPlannerDelegate { }

// Variables, Functions, Parameters: camelCase
var currentLocation: CLLocation
func calculateDistance(from: Location, to: Location) { }

// Constants: camelCase
let maxWalkDistance = 1000.0

// Enums: lowercase for cases
enum TransportMode {
    case transit
    case walk
    case bicycle
}
```

### Documentation

Use Swift documentation comments for public APIs:

```swift
/// Plans a trip from origin to destination.
///
/// This method calculates the optimal route considering:
/// - Available transportation modes
/// - Real-time transit data
/// - User preferences
///
/// - Parameters:
///   - from: The origin location
///   - to: The destination location
///   - modes: Available transportation modes
/// - Returns: A publisher that emits trip plans or errors
/// - Throws: `APIError` if the request fails
///
/// Example:
/// ```swift
/// tripPlanner.planTrip(from: origin, to: destination, modes: [.transit, .walk])
///     .sink(receiveCompletion: { completion in
///         // Handle completion
///     }, receiveValue: { trips in
///         // Handle trips
///     })
/// ```
public func planTrip(
    from: Location,
    to: Location,
    modes: [TransportMode]
) -> AnyPublisher<[Trip], APIError> {
    // Implementation
}
```

### SwiftUI Best Practices

```swift
// ✅ Good: Extract subviews
struct TripListView: View {
    var body: some View {
        List {
            ForEach(trips) { trip in
                TripRowView(trip: trip)
            }
        }
    }
}

struct TripRowView: View {
    let trip: Trip

    var body: some View {
        HStack {
            Text(trip.origin)
            Spacer()
            Text(trip.destination)
        }
    }
}

// ❌ Bad: Everything in one view
struct TripListView: View {
    var body: some View {
        List {
            ForEach(trips) { trip in
                HStack {
                    VStack {
                        Text(trip.origin)
                        Text(trip.departureTime)
                    }
                    Spacer()
                    VStack {
                        Text(trip.destination)
                        Text(trip.arrivalTime)
                    }
                }
            }
        }
    }
}
```

### Error Handling

```swift
// Use Result type for async operations
func fetchTrips(completion: @escaping (Result<[Trip], APIError>) -> Void) {
    // Implementation
}

// Use Combine for reactive streams
func fetchTrips() -> AnyPublisher<[Trip], APIError> {
    // Implementation
}

// Use throws for synchronous operations
func validateTrip(_ trip: Trip) throws {
    guard trip.origin != trip.destination else {
        throw ValidationError.sameOriginDestination
    }
}
```

### Logging

Use the centralized `OTPLog` system:

```swift
// ✅ Good: Use appropriate log levels
OTPLog.log(level: .info, info: "Trip planning started")
OTPLog.log(level: .warning, info: "No routes found for criteria")
OTPLog.log(level: .error, info: "API request failed: \(error)")

// ❌ Bad: Use print statements
print("Trip planning started")
print("Error: \(error)")
```

## Testing Guidelines

### Unit Tests

Write unit tests for:
- Business logic
- Data transformations
- Utility functions
- API response parsing

```swift
import XCTest
@testable import GMap

class TripPlanningTests: XCTestCase {
    var tripPlanner: TripPlanningManager!

    override func setUp() {
        super.setUp()
        tripPlanner = TripPlanningManager()
    }

    override func tearDown() {
        tripPlanner = nil
        super.tearDown()
    }

    func testTripValidation() {
        // Given
        let trip = Trip(origin: location1, destination: location2)

        // When
        let isValid = tripPlanner.validate(trip)

        // Then
        XCTAssertTrue(isValid)
    }
}
```

### UI Tests

Write UI tests for:
- Critical user flows
- Navigation
- User interactions

```swift
import XCTest

class TripPlanningUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        app = XCUIApplication()
        app.launch()
    }

    func testTripPlanning() {
        // Navigate to trip planning
        app.tabBars.buttons["Plan Trip"].tap()

        // Enter origin
        let originField = app.textFields["Origin"]
        originField.tap()
        originField.typeText("Downtown")

        // Enter destination
        let destinationField = app.textFields["Destination"]
        destinationField.tap()
        destinationField.typeText("Airport")

        // Search
        app.buttons["Search"].tap()

        // Verify results
        XCTAssertTrue(app.tables["Trip Results"].exists)
    }
}
```

### Running Tests

```bash
# Run all tests
xcodebuild test -workspace ATLRides.xcworkspace -scheme GMap -destination 'platform=iOS Simulator,name=iPhone 15'

# Run specific test
xcodebuild test -workspace ATLRides.xcworkspace -scheme GMap -only-testing:GMapTests/TripPlanningTests/testTripValidation
```

## Pull Request Process

### Before Submitting

1. **Update your branch**  
   - git checkout develop  
   - git pull upstream develop  
   - git checkout feature/your-feature  
   - git rebase develop  

2. **Run tests**
   - xcodebuild test -workspace ATLRides.xcworkspace -scheme GMap

3. **Check code style**  
   - swiftlint

4. **Update documentation**
   - Update README if needed
   - Add/update code comments
   - Update CHANGELOG

### Submitting Pull Request

1. **Push your branch**  
   ```
   git push origin feature/your-feature
   ```

2. **Create Pull Request**
   - Go to GitHub
   - Click "New Pull Request"
   - Select your branch
   - Fill out the PR template

### PR Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
- [ ] Unit tests added/updated
- [ ] UI tests added/updated
- [ ] Manual testing completed

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Comments added for complex code
- [ ] Documentation updated
- [ ] No new warnings
- [ ] Tests pass locally

## Screenshots (if applicable)
Add screenshots here

## Related Issues
Closes #123
```

### Review Process

1. **Automated Checks**
   - CI/CD pipeline runs
   - Tests must pass
   - Code coverage maintained

2. **Code Review**
   - At least one approval required
   - Address review comments
   - Update PR as needed

3. **Merge**
   - Squash and merge preferred
   - Delete branch after merge

## Issue Guidelines

### Reporting Bugs

Use the bug report template:

```markdown
**Describe the bug**
A clear description of the bug

**To Reproduce**
Steps to reproduce:
1. Go to '...'
2. Click on '...'
3. See error

**Expected behavior**
What you expected to happen

**Screenshots**
If applicable, add screenshots

**Environment:**
- Device: [e.g. iPhone 15]
- iOS Version: [e.g. 17.6]
- App Version: [e.g. 1.0.0]

**Additional context**
Any other relevant information
```

### Feature Requests

Use the feature request template:

```markdown
**Is your feature request related to a problem?**
A clear description of the problem

**Describe the solution you'd like**
A clear description of what you want to happen

**Describe alternatives you've considered**
Alternative solutions or features

**Additional context**
Any other relevant information
```

## Documentation

### When to Update Documentation

- Adding new features
- Changing existing functionality
- Fixing bugs that affect usage
- Updating dependencies
- Changing configuration

### Documentation Standards

- Use clear, concise language
- Include code examples
- Add screenshots for UI changes
- Keep README up to date
- Update inline code comments

## Recognition

Contributors will be recognized in:
- CONTRIBUTORS.md file
- Release notes
- Project README

## Questions?

- Open a discussion on GitHub
- Join our community chat
- Email: \_Global-digitalintelligence-mobile@arcadis.com

## License

By contributing, you agree that your contributions will be licensed under the same license as the project (MIT License).

---

Thank you for contributing to GMap! 🚀
