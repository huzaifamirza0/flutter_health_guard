# Overlay & in-app report

## GuardianOverlay

Wraps your app (usually in `MaterialApp.builder`) and shows a **draggable** green shield button.

```dart
MaterialApp(
  builder: (context, child) => GuardianOverlay(
    visible: kDebugMode,
    child: child ?? const SizedBox.shrink(),
  ),
  // ...
)
```

### Behavior

- **Drag** — reposition the FAB
- **Tap** — opens `GuardianReportPage` on your app’s `Navigator` (fullscreen dialog)
- **System back / close** — pops the report only; does **not** exit the app
- Sitting above the `Navigator` in `builder` is supported — the overlay finds the navigator and pushes a real route

### Props

| Prop | Default | Meaning |
|------|---------|---------|
| `child` | required | Your app subtree |
| `visible` | `true` | Set `false` (or `kDebugMode`) to hide the FAB |

## GuardianReportPage

Full-screen dark health UI. You normally open it via the overlay; you can also push it yourself:

```dart
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (_) => const GuardianReportPage(),
  ),
);
```

### App bar actions

| Icon | Action |
|------|--------|
| Close (`X`) | Close report (`onClose` or `Navigator.pop`) |
| Copy | Entire report as indented JSON → clipboard |
| Save | `Guardian.exportReport()` — write HTML/JSON once; try bridge sync on mobile |
| Refresh | `Guardian.analyze()` again |

![Export dialog](images/03-export-dialog.png)

### Sections

1. Overall score  
2. Category score bars  
3. Recommendations  
4. Session stats (crashes, requests, FPS, startup)  
5. Network (latest calls)  
6. Crashes  
7. Navigation timeline  
8. Device info  

Pull-to-refresh also re-runs analysis.

## Tips

- Prefer `visible: kDebugMode` so production users never see the FAB.
- Export is **one-shot** — it does not continuously overwrite your PC project folder via the bridge. Tap Save when you want a snapshot.
- Desktop Save already writes under `<project>/flutter_health_guard/`; bridge is for mobile.
