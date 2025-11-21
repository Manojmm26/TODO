# Chronos Project Overview

## Project Scope

**Chronos** is a comprehensive, cross-platform **personal productivity and task management application** built with Flutter. It focuses on helping users manage time effectively through structured task tracking, goal setting, focus sessions, and insightful dashboards.

### Core Features
- **Task Management**:
  - Create, update, delete tasks with titles, descriptions, priorities (1-5), status (active, completed, etc.).
  - Sub-tasks for breaking down complex tasks.
  - Due dates, start dates, estimated/actual time tracking.
  - Flagging for immediate or today actions.
- **Recurring Tasks**:
  - RRULE-based recurrence rules for repeating tasks (daily, weekly, etc.).
  - Automatic generation of task instances from templates.
- **Hierarchical Organization**:
  - **Goals**: High-level objectives with progress tracking, target dates, colors.
  - **Projects**: Grouped under goals, with status and colors.
  - Tasks linked to projects/goals.
- **Focus & Time Tracking**:
  - Pomodoro-style focus sessions linked to tasks/projects.
  - Duration tracking, ambient presets, notes.
- **Dashboard & Analytics**:
  - Real-time metrics: Time left today, goals progress, timeline overview.
  - Daily digest, upcoming deadlines.
  - Tags for tasks with colors.
- **UI/UX**:
  - Responsive design for mobile, desktop, web.
  - Dark/light theme support.
  - Navigation via bottom shell with sections: Dashboard, Timeline, Goals, Focus, Settings.

### Supported Platforms
- Android, iOS, Web, Windows, macOS, Linux.

### Architecture
```
lib/
├── main.dart
├── src/
    ├── app/          # App widget, providers
    ├── application/   # Controllers (task, focus, recurrence)
    ├── core/          # Themes, constants
    ├── data/          # Repositories, local DB (Drift/SQLite)
    │   ├── local/
    │   │   ├── daos/  # Separate DAO files
    │   │   └── app_database.dart
    │   └── repositories/
    ├── features/      # Dashboard, Timeline, Goals, Focus, Settings
    ├── routing/       # GoRouter configuration
    └── shared/        # Widgets, utils (recurrence)
```
- **State Management**: Riverpod
- **Routing**: GoRouter
- **Database**: Drift (SQLite) with tables: Goals, Projects, Tasks, SubTasks, FocusSessions, Tags, TaskTags, DigestSnapshots
- **Other**: intl, uuid, rrule, flutter_local_notifications, timezone

### Data Model (Key Entities)
- **Task**: id, projectId, goalId, parentRecurringId, title, status, priority, dates, estimates, recurrenceRule, flags.
- **Goal**: id, title, targetDate, progress, color.
- **Project**: id, goalId, title, status, color.
- Relationships: Foreign keys enforced.

## Setup & Run
1. `flutter pub get`
2. `flutter run`

## Current Status
- Functional MVP with core CRUD, streams for reactivity.
- Dashboard fully implemented with modular widgets.
- Database layer refactored for scalability.
- Recurrence bootstrapped.
- Tests: Unit tests present (dashboard_metrics_test.dart, etc.).

