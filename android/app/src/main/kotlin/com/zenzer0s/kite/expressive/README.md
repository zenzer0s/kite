# Kite Expressive UI Components

This directory implements a **Unified Platform View** system for hosting Jetpack Compose components inside Flutter. Instead of creating a new `PlatformViewFactory` for every UI element, we use a single "Universal Host" that dynamically switches between components.

## Architecture

1. **`ExpressiveCatalog.kt`**: The source of truth for UI. Contains all `@Composable` functions.
2. **`ExpressiveView.kt`**: The "Universal Host". It handles lifecycle, Material You dynamic coloring, and communication.
3. **`ExpressiveViewFactory.kt`**: The factory registered with the Flutter Engine.

---

## How to add a new Component

### 1. Define the UI in Native
Add a new `@Composable` function to `ExpressiveCatalog.kt`:

```kotlin
@Composable
fun MyNewWidget(someParam: String) {
    Button(
        onClick = { /* ... */ },
        shape = RoundedCornerShape(16.dp)
    ) {
        Text("Hello $someParam")
    }
}
```

### 2. Map the type in the Host
Update the `when(type)` block in `ExpressiveView.kt`:

```kotlin
when (type) {
    "loading" -> ExpressiveCatalog.LoadingIndicator()
    "my_widget" -> {
        val param = creationParams?.get("myParam") as? String ?: ""
        ExpressiveCatalog.MyNewWidget(param)
    }
}
```

---

## How to use in Flutter

Use the `AndroidView` widget with the unified view type:

```dart
AndroidView(
  viewType: 'com.zenzer0s.kite/expressive_element',
  creationParams: {
    'type': 'my_widget', // Matches the string in ExpressiveView.kt
    'myParam': 'World',
  },
  creationParamsCodec: const StandardMessageCodec(),
)
```

### Handling callbacks
Each `ExpressiveView` automatically sets up a `MethodChannel` named:
`com.zenzer0s.kite/expressive_$id`

In Flutter, you can listen to it via `onPlatformViewCreated`:

```dart
onPlatformViewCreated: (id) {
  final channel = MethodChannel('com.zenzer0s.kite/expressive_$id');
  channel.setMethodCallHandler((call) async {
    // Handle native events
  });
}
```

## Benefits
- **Zero Boilerplate**: No need to touch `MainActivity.kt` or create new Factory classes.
- **Material You**: All components automatically support Android 12+ dynamic coloring.
- **Lifecycle Safe**: Handles the common `ViewTreeLifecycleOwner` issues inherent to Flutter's Platform Views.
