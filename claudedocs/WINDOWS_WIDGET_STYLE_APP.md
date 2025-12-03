# Windows 위젯 스타일 데스크톱 앱 구현 가이드

## 개요

Flutter에서 Windows 네이티브 위젯은 지원되지 않지만, `window_manager` 패키지를 사용하여 위젯처럼 동작하는 데스크톱 앱을 구현할 수 있습니다.

---

## 필요 패키지

```yaml
# pubspec.yaml
dependencies:
  window_manager: ^0.4.3
  system_tray: ^2.0.3        # 시스템 트레이 아이콘 (선택)
  launch_at_startup: ^0.3.1  # 시작 프로그램 등록 (선택)
```

---

## 핵심 구현

### 1. 기본 설정 (main.dart)

```dart
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // window_manager 초기화
  await windowManager.ensureInitialized();

  // 위젯 스타일 윈도우 옵션
  WindowOptions windowOptions = const WindowOptions(
    size: Size(300, 400),              // 위젯 크기
    center: false,                      // 중앙 배치 안함
    backgroundColor: Colors.transparent, // 투명 배경
    skipTaskbar: true,                  // 작업표시줄에서 숨김
    alwaysOnTop: true,                  // 항상 위에 표시
    titleBarStyle: TitleBarStyle.hidden, // 타이틀바 숨김
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    // 초기 위치 설정 (화면 우측 하단)
    final screenSize = await windowManager.getSize();
    await windowManager.setPosition(Offset(
      1920 - screenSize.width - 20,  // 우측 여백 20px
      1080 - screenSize.height - 60, // 하단 여백 60px (작업표시줄)
    ));
    await windowManager.show();
    await windowManager.setAsFrameless();  // 프레임 제거
  });

  runApp(const MyWidgetApp());
}
```

### 2. 위젯 스타일 UI 구현

```dart
class MyWidgetApp extends StatelessWidget {
  const MyWidgetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const WidgetStyleWindow(),
    );
  }
}

class WidgetStyleWindow extends StatefulWidget {
  const WidgetStyleWindow({super.key});

  @override
  State<WidgetStyleWindow> createState() => _WidgetStyleWindowState();
}

class _WidgetStyleWindowState extends State<WidgetStyleWindow>
    with WindowListener {

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          children: [
            // 드래그 가능한 헤더
            _buildDragHeader(),

            // 위젯 컨텐츠
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildDragHeader() {
    return GestureDetector(
      onPanStart: (_) => windowManager.startDragging(),
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.blue.shade600,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            const Text(
              'DoDo Todo',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            // 최소화 버튼
            IconButton(
              icon: const Icon(Icons.remove, color: Colors.white, size: 18),
              onPressed: () => windowManager.minimize(),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 8),
            // 닫기 버튼 (트레이로 이동)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 18),
              onPressed: () => windowManager.hide(), // 숨기기만 함
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _buildTodoItem('회의 준비하기', false),
        _buildTodoItem('보고서 작성', true),
        _buildTodoItem('이메일 확인', false),
        _buildTodoItem('점심 약속', false),
      ],
    );
  }

  Widget _buildTodoItem(String title, bool completed) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            completed ? Icons.check_circle : Icons.circle_outlined,
            color: completed ? Colors.green : Colors.grey,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              decoration: completed ? TextDecoration.lineThrough : null,
              color: completed ? Colors.grey : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
```

### 3. 시스템 트레이 통합

```dart
import 'package:system_tray/system_tray.dart';

class TrayManager {
  final SystemTray _systemTray = SystemTray();

  Future<void> initSystemTray() async {
    // 트레이 아이콘 설정
    await _systemTray.initSystemTray(
      title: "DoDo Todo",
      iconPath: 'assets/icons/tray_icon.ico', // 16x16 또는 32x32 ICO
      toolTip: "DoDo Todo Widget",
    );

    // 트레이 메뉴
    final Menu menu = Menu();
    await menu.buildFrom([
      MenuItemLabel(
        label: '위젯 표시',
        onClicked: (menuItem) => windowManager.show(),
      ),
      MenuItemLabel(
        label: '위젯 숨기기',
        onClicked: (menuItem) => windowManager.hide(),
      ),
      MenuSeparator(),
      MenuItemLabel(
        label: '설정',
        onClicked: (menuItem) => _openSettings(),
      ),
      MenuSeparator(),
      MenuItemLabel(
        label: '종료',
        onClicked: (menuItem) => _exitApp(),
      ),
    ]);

    await _systemTray.setContextMenu(menu);

    // 트레이 아이콘 클릭 시 위젯 토글
    _systemTray.registerSystemTrayEventHandler((eventName) {
      if (eventName == kSystemTrayEventClick) {
        windowManager.isVisible().then((visible) {
          if (visible) {
            windowManager.hide();
          } else {
            windowManager.show();
          }
        });
      }
    });
  }

  void _openSettings() {
    // 설정 화면 열기 로직
  }

  Future<void> _exitApp() async {
    await _systemTray.destroy();
    exit(0);
  }
}
```

### 4. 시작 프로그램 등록

```dart
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:package_info_plus/package_info_plus.dart';

Future<void> setupLaunchAtStartup() async {
  final packageInfo = await PackageInfo.fromPlatform();

  launchAtStartup.setup(
    appName: packageInfo.appName,
    appPath: Platform.resolvedExecutable,
    // 선택: 시작 시 인자 전달
    args: ['--minimized'],
  );

  // 시작 프로그램 활성화
  await launchAtStartup.enable();

  // 상태 확인
  bool isEnabled = await launchAtStartup.isEnabled();
  print('시작 프로그램 등록: $isEnabled');
}

// 시작 프로그램 비활성화
Future<void> disableLaunchAtStartup() async {
  await launchAtStartup.disable();
}
```

---

## Windows 네이티브 설정

### 1. 투명 윈도우 활성화 (windows/runner/main.cpp)

```cpp
// Win32Window::Create 함수에서
HWND window = CreateWindow(
    window_class, title.c_str(), WS_POPUP, // WS_OVERLAPPEDWINDOW 대신 WS_POPUP
    Scale(origin.x, scale_factor), Scale(origin.y, scale_factor),
    Scale(size.width, scale_factor), Scale(size.height, scale_factor),
    nullptr, nullptr, GetModuleHandle(nullptr), this);

// 투명도 설정
SetWindowLong(window, GWL_EXSTYLE,
    GetWindowLong(window, GWL_EXSTYLE) | WS_EX_LAYERED);
SetLayeredWindowAttributes(window, 0, 255, LWA_ALPHA);
```

### 2. 아크릴/마이카 효과 (Windows 11)

```cpp
#include <dwmapi.h>
#pragma comment(lib, "dwmapi.lib")

// 마이카 효과 적용
BOOL value = TRUE;
DwmSetWindowAttribute(window, DWMWA_USE_IMMERSIVE_DARK_MODE, &value, sizeof(value));

// Windows 11 마이카
int backdropType = 2; // DWMSBT_MAINWINDOW
DwmSetWindowAttribute(window, 38, &backdropType, sizeof(backdropType)); // DWMWA_SYSTEMBACKDROP_TYPE
```

---

## 고급 기능

### 1. 화면 모서리 스냅

```dart
Future<void> snapToCorner(WidgetPosition position) async {
  final screen = await windowManager.getSize();
  final displaySize = Size(1920, 1080); // 또는 동적으로 가져오기

  Offset newPosition;
  const padding = 20.0;
  const taskbarHeight = 48.0;

  switch (position) {
    case WidgetPosition.topLeft:
      newPosition = Offset(padding, padding);
      break;
    case WidgetPosition.topRight:
      newPosition = Offset(
        displaySize.width - screen.width - padding,
        padding,
      );
      break;
    case WidgetPosition.bottomLeft:
      newPosition = Offset(
        padding,
        displaySize.height - screen.height - taskbarHeight - padding,
      );
      break;
    case WidgetPosition.bottomRight:
      newPosition = Offset(
        displaySize.width - screen.width - padding,
        displaySize.height - screen.height - taskbarHeight - padding,
      );
      break;
  }

  await windowManager.setPosition(newPosition);
}

enum WidgetPosition { topLeft, topRight, bottomLeft, bottomRight }
```

### 2. 크기 조절 핸들

```dart
Widget _buildResizeHandle() {
  return Positioned(
    right: 0,
    bottom: 0,
    child: GestureDetector(
      onPanUpdate: (details) async {
        final currentSize = await windowManager.getSize();
        await windowManager.setSize(Size(
          (currentSize.width + details.delta.dx).clamp(200, 500),
          (currentSize.height + details.delta.dy).clamp(300, 800),
        ));
      },
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(8),
            bottomRight: Radius.circular(16),
          ),
        ),
        child: const Icon(Icons.drag_handle, size: 14),
      ),
    ),
  );
}
```

### 3. "바탕화면 보기" 문제 해결 (부분적)

```dart
// WindowListener 구현
@override
void onWindowEvent(String eventName) {
  if (eventName == 'hide') {
    // 타이머로 다시 표시 시도 (완벽한 해결책은 아님)
    Future.delayed(const Duration(milliseconds: 500), () async {
      final shouldStayVisible = await _getShouldStayVisible();
      if (shouldStayVisible) {
        await windowManager.show();
      }
    });
  }
}
```

**참고**: "바탕화면 보기" 완벽한 해결은 네이티브 C++ 코드로 `WM_WINDOWPOSCHANGING` 메시지를 가로채야 합니다.

---

## 한계점 및 주의사항

### 알려진 한계

| 문제 | 설명 | 해결 방법 |
|------|------|----------|
| 바탕화면 보기 | Win+D 시 위젯이 숨겨짐 | 네이티브 코드 필요 또는 타이머 복구 |
| 시작 프로그램 | 수동 등록 또는 패키지 사용 | `launch_at_startup` 패키지 |
| 다중 모니터 | 모니터 간 이동 시 위치 계산 복잡 | `screen_retriever` 패키지로 해결 |
| 고DPI | 스케일링 문제 발생 가능 | Scale factor 계산 필요 |

### 성능 고려사항

```dart
// 리소스 최적화
windowManager.setPreventClose(true); // 닫기 대신 숨기기

// 숨겨진 상태에서 업데이트 최소화
bool _isVisible = true;

@override
void onWindowFocus() {
  setState(() => _isVisible = true);
}

@override
void onWindowBlur() {
  setState(() => _isVisible = false);
}

// 조건부 렌더링
if (_isVisible) {
  // 무거운 위젯 렌더링
}
```

---

## 프로젝트 적용 방안

### DoDo Todo 앱 Windows 위젯

```
lib/
├── platforms/
│   └── windows/
│       ├── widget_window.dart      # 위젯 스타일 윈도우
│       ├── tray_manager.dart       # 시스템 트레이
│       └── startup_manager.dart    # 시작 프로그램
├── presentation/
│   └── widgets/
│       └── desktop_widget/
│           ├── todo_widget_view.dart    # 위젯 UI
│           ├── widget_todo_list.dart    # 할 일 목록
│           └── widget_quick_add.dart    # 빠른 추가
```

### 조건부 초기화

```dart
// main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows) {
    await _initWindowsWidget();
  }

  runApp(const MyApp());
}

Future<void> _initWindowsWidget() async {
  await windowManager.ensureInitialized();

  // 커맨드라인 인자 확인
  final args = Platform.executableArguments;
  final isWidgetMode = args.contains('--widget');

  if (isWidgetMode) {
    // 위젯 모드로 시작
    await _setupWidgetWindow();
  } else {
    // 일반 앱 모드
    await _setupNormalWindow();
  }
}
```

---

## 캘린더 위젯 구현

### 1. 캘린더 위젯 윈도우 설정

```dart
// 캘린더 위젯에 최적화된 윈도우 크기
WindowOptions windowOptions = const WindowOptions(
  size: Size(320, 400),              // 캘린더에 적합한 크기
  minSize: Size(280, 350),           // 최소 크기
  maxSize: Size(400, 500),           // 최대 크기
  center: false,
  backgroundColor: Colors.transparent,
  skipTaskbar: true,
  alwaysOnTop: true,
  titleBarStyle: TitleBarStyle.hidden,
);
```

### 2. 캘린더 위젯 UI 구현

```dart
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:window_manager/window_manager.dart';

class CalendarWidgetWindow extends StatefulWidget {
  const CalendarWidgetWindow({super.key});

  @override
  State<CalendarWidgetWindow> createState() => _CalendarWidgetWindowState();
}

class _CalendarWidgetWindowState extends State<CalendarWidgetWindow>
    with WindowListener {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  // 날짜별 할 일 (실제로는 DB에서 가져옴)
  Map<DateTime, List<String>> _events = {};

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    // Supabase 또는 로컬 DB에서 할 일 로드
    // 실제 구현에서는 Provider/Riverpod 사용
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          children: [
            _buildDragHeader(),
            Expanded(child: _buildCalendarContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildDragHeader() {
    return GestureDetector(
      onPanStart: (_) => windowManager.startDragging(),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.blue.shade600,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            const Text(
              'DoDo Calendar',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const Spacer(),
            _buildWindowButton(Icons.remove, () => windowManager.minimize()),
            const SizedBox(width: 4),
            _buildWindowButton(Icons.close, () => windowManager.hide()),
          ],
        ),
      ),
    );
  }

  Widget _buildWindowButton(IconData icon, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, color: Colors.white, size: 14),
      ),
    );
  }

  Widget _buildCalendarContent() {
    return Column(
      children: [
        // 컴팩트 캘린더
        TableCalendar(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          calendarFormat: _calendarFormat,
          startingDayOfWeek: StartingDayOfWeek.sunday,

          // 컴팩트 스타일
          calendarStyle: CalendarStyle(
            cellMargin: const EdgeInsets.all(2),
            todayDecoration: BoxDecoration(
              color: Colors.blue.shade200,
              shape: BoxShape.circle,
            ),
            selectedDecoration: BoxDecoration(
              color: Colors.blue.shade600,
              shape: BoxShape.circle,
            ),
            markerDecoration: BoxDecoration(
              color: Colors.red.shade400,
              shape: BoxShape.circle,
            ),
            markersMaxCount: 3,
            outsideDaysVisible: false,
            defaultTextStyle: const TextStyle(fontSize: 12),
            weekendTextStyle: TextStyle(fontSize: 12, color: Colors.red.shade300),
          ),

          // 헤더 스타일
          headerStyle: HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            leftChevronPadding: EdgeInsets.zero,
            rightChevronPadding: EdgeInsets.zero,
            leftChevronMargin: const EdgeInsets.only(left: 8),
            rightChevronMargin: const EdgeInsets.only(right: 8),
            titleTextStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            leftChevronIcon: const Icon(Icons.chevron_left, size: 20),
            rightChevronIcon: const Icon(Icons.chevron_right, size: 20),
          ),

          // 요일 헤더 스타일
          daysOfWeekStyle: DaysOfWeekStyle(
            weekdayStyle: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            weekendStyle: TextStyle(fontSize: 11, color: Colors.red.shade300),
          ),

          // 이벤트 로더
          eventLoader: (day) {
            final normalizedDay = DateTime(day.year, day.month, day.day);
            return _events[normalizedDay] ?? [];
          },

          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },

          onPageChanged: (focusedDay) {
            _focusedDay = focusedDay;
          },
        ),

        // 구분선
        Divider(height: 1, color: Colors.grey.shade300),

        // 선택된 날짜의 할 일 목록
        Expanded(child: _buildSelectedDayTodos()),
      ],
    );
  }

  Widget _buildSelectedDayTodos() {
    final selectedDate = _selectedDay ?? _focusedDay;
    final normalizedDate = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );
    final todos = _events[normalizedDate] ?? [];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 날짜 헤더
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${selectedDate.month}/${selectedDate.day}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              // 할 일 추가 버튼
              InkWell(
                onTap: () => _showQuickAddDialog(selectedDate),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, size: 14, color: Colors.blue.shade600),
                      const SizedBox(width: 2),
                      Text(
                        '추가',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.blue.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 할 일 목록
          Expanded(
            child: todos.isEmpty
                ? Center(
                    child: Text(
                      '할 일 없음',
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 12,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: todos.length,
                    padding: EdgeInsets.zero,
                    itemBuilder: (context, index) {
                      return _buildCompactTodoItem(todos[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactTodoItem(String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(
            Icons.circle_outlined,
            size: 14,
            color: Colors.grey.shade500,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _showQuickAddDialog(DateTime date) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '${date.month}/${date.day} 할 일 추가',
          style: const TextStyle(fontSize: 16),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '할 일 입력...',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          style: const TextStyle(fontSize: 14),
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              _addTodo(date, value);
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                _addTodo(date, controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('추가'),
          ),
        ],
      ),
    );
  }

  void _addTodo(DateTime date, String title) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    setState(() {
      if (_events[normalizedDate] == null) {
        _events[normalizedDate] = [];
      }
      _events[normalizedDate]!.add(title);
    });
    // 실제로는 DB에 저장
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }
}
```

### 3. 캘린더 위젯 전용 main.dart

```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows) {
    await windowManager.ensureInitialized();

    // 캘린더 위젯 전용 설정
    const windowOptions = WindowOptions(
      size: Size(320, 420),
      minSize: Size(280, 350),
      backgroundColor: Colors.transparent,
      skipTaskbar: true,
      alwaysOnTop: true,
      titleBarStyle: TitleBarStyle.hidden,
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      // 우측 하단에 배치
      await _positionToBottomRight();
      await windowManager.show();
      await windowManager.setAsFrameless();
    });
  }

  runApp(const CalendarWidgetApp());
}

Future<void> _positionToBottomRight() async {
  final size = await windowManager.getSize();
  // screen_retriever 패키지로 실제 화면 크기 가져오기 권장
  const screenWidth = 1920.0;
  const screenHeight = 1080.0;
  const taskbarHeight = 48.0;
  const margin = 16.0;

  await windowManager.setPosition(Offset(
    screenWidth - size.width - margin,
    screenHeight - size.height - taskbarHeight - margin,
  ));
}

class CalendarWidgetApp extends StatelessWidget {
  const CalendarWidgetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const CalendarWidgetWindow(),
    );
  }
}
```

### 4. DoDo 앱 통합 방안

```
lib/
├── main.dart                        # 메인 앱 (모바일/웹/일반 데스크톱)
├── main_widget.dart                 # Windows 위젯 전용 진입점
├── platforms/
│   └── windows/
│       ├── calendar_widget_window.dart
│       ├── tray_manager.dart
│       └── widget_config.dart       # 위젯 설정 (크기, 위치 저장)
└── presentation/
    └── widgets/
        └── desktop_widget/
            ├── compact_calendar.dart     # 컴팩트 캘린더 뷰
            ├── day_todo_list.dart        # 날짜별 할 일
            └── quick_add_button.dart     # 빠른 추가
```

### 5. 빌드 및 배포

```bash
# Windows 위젯 빌드
flutter build windows --release --dart-define=WIDGET_MODE=true

# 별도 실행 파일로 빌드 (main_widget.dart 사용)
flutter build windows --release -t lib/main_widget.dart
```

### 6. 실제 데이터 연동 (Riverpod)

```dart
// 위젯에서 Riverpod 사용
class CalendarWidgetWindow extends ConsumerStatefulWidget {
  const CalendarWidgetWindow({super.key});

  @override
  ConsumerState<CalendarWidgetWindow> createState() => _CalendarWidgetWindowState();
}

class _CalendarWidgetWindowState extends ConsumerState<CalendarWidgetWindow>
    with WindowListener {

  @override
  Widget build(BuildContext context) {
    // 기존 앱의 Provider 재사용
    final todosAsync = ref.watch(todoListProvider);

    return todosAsync.when(
      data: (todos) => _buildCalendarWithTodos(todos),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
    );
  }

  Map<DateTime, List<Todo>> _groupTodosByDate(List<Todo> todos) {
    final grouped = <DateTime, List<Todo>>{};
    for (final todo in todos) {
      if (todo.dueDate != null) {
        final date = DateTime(
          todo.dueDate!.year,
          todo.dueDate!.month,
          todo.dueDate!.day,
        );
        grouped.putIfAbsent(date, () => []).add(todo);
      }
    }
    return grouped;
  }
}
```

---

## 참고 자료

- [window_manager 패키지](https://pub.dev/packages/window_manager)
- [system_tray 패키지](https://pub.dev/packages/system_tray)
- [launch_at_startup 패키지](https://pub.dev/packages/launch_at_startup)
- [Flutter Desktop 문서](https://docs.flutter.dev/platform-integration/desktop)
- [Stack Overflow: Desktop widgets with Flutter](https://stackoverflow.com/questions/71728231/is-it-possible-to-create-desktop-widgets-using-flutter-windows-app)

---

## 버전 정보

- 문서 작성일: 2025-12-03
- Flutter 버전: 3.35.7
- window_manager: 0.4.3
- 대상 플랫폼: Windows 10/11
