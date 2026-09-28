# Levels Manager — MVP Product Specification

## 1. MVP Product Goal

The MVP is a mobile self-improvement application centered on a structured level-progression system.

The application allows the user to:

1. Define a self-improvement level.
2. Complete its requirements every day.
3. Record successes and failures.
4. Reflect on each day through journaling.
5. Manage supporting tasks.
6. Track how time was spent.
7. Review basic progress statistics.
8. Complete, restart, or regress between levels according to predefined rules.

The MVP is not intended to implement the complete personal analytics platform. Its purpose is to validate the core behavioral loop:

```text
Define a level
→ Perform daily requirements
→ Submit the day
→ Reflect on the result
→ Review progress
→ Complete, restart, or regress
```

---

# 2. Feature Priority

The product priority should be interpreted as follows:

0. **Levels Manager — core product**
1. **Journaling and daily reflection**
2. **Task management**
3. **Activity tracking**
4. **Basic monitoring and statistics**
5. **AI analytics — later release**
6. **Currency and rewards — later release**

AI analytics and currency mechanics should not be included in the initial MVP.

They depend on reliable historical data and do not help validate whether the core level system works. Building them too early would increase development complexity without proving the central product assumption.

---

# 3. MVP Scope Summary

## Included

| Area | MVP functionality |
|---|---|
| Levels | Create, configure, start, track, complete, fail, restart, and regress |
| Level items | Daily completion requirements with several basic evaluation types |
| Daily submission | Manual and automatic item evaluation |
| Failure analysis | Record why an item or day failed |
| Journaling | Free-form journal and structured daily reflection |
| Tasks | Basic task lists, status, estimates, tags, and work tracking |
| Activities | Manual activity timeline and start/stop timer |
| Statistics | Basic level, journal, task, and activity metrics |
| Notifications | Basic reminders and end-of-day submission notification |
| History | Preserve level attempts, daily results, tasks, journals, and activities |
| Settings | Daily cutoff time and basic notification preferences |

## Excluded

The following features should be postponed:

- AI-generated insights.
- AI questions and recommendations.
- AI-generated PDF reports.
- Currency and rewards.
- Smartwatch and health integrations.
- Screen-time integrations.
- Automatic activity detection.
- Advanced statistical correlations.
- Weekly frequency-based level items.
- Advanced task dependencies.
- Sub-items and subtasks.
- Detailed interruption event tracking.
- Long-term goals and baseline assessment.
- Weekly and monthly review systems.
- Full journal revision history.
- Advanced offline conflict resolution.
- Multiple users, teams, or social functionality.

---

# 4. Core Levels Manager

## 4.1 Level Structure

The system supports up to 100 sequential levels.

Each level contains:

- Level number.
- Title.
- Description.
- List of level items.
- Status.
- Creation date.
- Activation date.
- Completion date, when applicable.

A level can have one of the following statuses:

```text
DRAFT
ACTIVE
COMPLETED
ARCHIVED
```

Only one level can be active at a time.

The user may create future levels gradually. There is no requirement to configure all 100 levels in advance.

---

## 4.2 Level Lifecycle

### Draft

The user may:

- Add items.
- Edit items.
- Remove items.
- Reorder items.
- Configure notifications.
- Change completion rules.

### Active

Once the level starts:

- Its definition becomes immutable.
- Items cannot be added, edited, removed, or reordered.
- The user records results for each day.
- An active attempt is created.

### Completed

After 10 successful days:

- The level is marked as completed.
- Its definition remains permanently locked.
- The user may start the next level after defining it.

### Restarted

When the user chooses to modify an active level:

1. The current attempt is closed as abandoned.
2. Its history remains available.
3. A new editable level version is created.
4. A new attempt starts from day one.

---

## 4.3 Level Attempts

A **Level Attempt** represents one specific attempt by the user to complete a particular version of a level.

A level itself is a permanent logical entity. For example, there should be only one **Level 10** entity for a user. However, the user may attempt Level 10 multiple times throughout the application's lifetime.

Examples include:

- The user starts Level 10 and fails.
- The user starts Level 10 again and completes it.
- The user later progresses to Level 12, regresses back to Level 10, and starts another attempt.

Each of these cases creates a new **Level Attempt**, while the original Level 10 entity remains unchanged.

The relationship is therefore:

```text
Level
  └── LevelVersion
        ├── LevelAttempt
        ├── LevelAttempt
        └── LevelAttempt
```

Each Level Attempt belongs to a specific **Level Version**, rather than directly representing the level's configuration.

This distinction is important because the requirements of a level may change between attempts.

For example:

```text
Level 10
│
├── Version 1
│   ├── Exercise for 30 minutes
│   ├── Read 20 pages
│   └── Avoid sweets
│
│   ├── Attempt 1 → FAILED
│   └── Attempt 2 → COMPLETED
│
└── Version 2
    ├── Exercise for 30 minutes
    ├── Read 10 pages
    └── Avoid sweets

    └── Attempt 3 → COMPLETED
```

If the user returns to a previously completed level because of regression and the level definition has not changed, the new attempt should reference the same Level Version.

Example:

```text
Level 10
└── Version 1
    ├── Attempt 1 → FAILED
    ├── Attempt 2 → COMPLETED
    └── Attempt 3 → COMPLETED after regression
```

If the user changes the level's requirements before starting again, a new Level Version must be created. Historical attempts continue referencing the original version so that past results always reflect the exact rules that existed at the time.

### Level Attempt Data

A Level Attempt should contain:

- Level Version ID.
- Attempt number.
- Start date and time.
- End date and time.
- Current number of successful days.
- Attempt status.
- Failure date, when applicable.
- Failure reason, when applicable.
- Whether the attempt started normally, after a failure, after a regression, or after a manual restart.
- Previous attempt ID, when applicable.

Possible attempt statuses include:

```text
ACTIVE
COMPLETED
FAILED
ABANDONED
```

### Attempt Lifecycle

#### Starting an Attempt

A new Level Attempt is created whenever the user begins or re-enters a level.

This includes:

- Starting a level for the first time.
- Restarting after a failed attempt.
- Returning to a previous level because of regression.
- Restarting after changing the level definition.

Only one Level Attempt may be active at a time.

#### Successful Completion

When the user completes the required 10 successful days:

- The attempt is marked as `COMPLETED`.
- Its end date is recorded.
- The associated level is considered completed for that progression cycle.
- The user may proceed to the next level.

The completed attempt remains permanently available in history.

#### Failed Attempt

If a mandatory level item fails:

- The current Level Attempt is marked as `FAILED`.
- Its end date is recorded.
- The failed day and responsible items are preserved.
- The successful-day progress of that attempt is not deleted.
- A new Level Attempt is created for the same Level Version unless regression rules require returning to a previous level.

The previous attempt remains unchanged for historical analysis.

#### Manual Restart

If the user decides to restart an active level without completing or failing it:

- The current attempt is marked as `ABANDONED`.
- The reason for the restart may be recorded.
- Historical daily results remain preserved.
- A new attempt is created.

If the level definition was changed, the new attempt must reference a newly created Level Version.

If the level definition was not changed, the new attempt may reference the existing Level Version.

### Attempt Numbering

Attempts should be numbered sequentially within the logical level.

For example:

```text
Level 10

Attempt 1 → FAILED
Attempt 2 → COMPLETED

User later regresses back to Level 10

Attempt 3 → FAILED
Attempt 4 → COMPLETED
```

Attempt numbering should not restart when the user completes a level and later returns to it.

This provides a complete lifetime history of the user's relationship with that level.

### Failure Counter vs. Attempt Number

The permanent attempt number and the progression failure counter should be treated separately.

The attempt number represents historical identity and always increases.

The failure counter is used only to determine whether the user should regress to the previous level.

For example:

```text
Level 10 lifetime history:

Attempt 1 → FAILED
Attempt 2 → COMPLETED

Later regression back to Level 10:

Attempt 3 → FAILED
Attempt 4 → FAILED
Attempt 5 → COMPLETED
```

The lifetime attempt number reaches 5, but the current regression-cycle failure counter only reached 2.

Historical failures should therefore never be deleted or reset, while the active progression failure counter may reset according to the level-regression rules.

This separation preserves complete historical data while keeping progression logic predictable.

## 4.4 Successful-Day Rule

A level requires 10 successful days.

A day is successful only when every mandatory level item is completed successfully.

When a day succeeds:

- The level's successful-day count increases by one.
- The daily result is permanently recorded.
- The next day begins after the configured daily cutoff.

When the tenth successful day is submitted, the level is completed.

---

## 4.5 Failure Rule

When any mandatory item fails:

1. The current day is marked as failed.
2. The active attempt is marked as failed.
3. Progress returns to zero successful days.
4. A new attempt starts for the same level.
5. The level failure counter increases.

After three failed attempts at the same level:

1. The user regresses by one level.
2. A new attempt begins for the previous level.
3. Historical attempts remain unchanged.

### Recommended counter behavior

The three-failure counter should apply to the user's current continuous stay at a level.

When the user is demoted and later returns to that level, the counter should restart at zero. Previous failures remain visible in history but should not permanently penalize future attempts.

This rule is simpler to understand and avoids an indefinitely accumulating punishment.

---

## 4.6 Planned Pause Days

A minimal planned-pause mechanism should be included because the level system is strict.

The user may declare a pause day before the daily cutoff for reasons such as:

- Illness.
- Travel.
- Vacation.
- Family event.
- Unavoidable work obligation.
- Other exceptional circumstances.

A pause day:

- Does not count as a successful day.
- Does not count as a failed day.
- Does not reset level progress.
- Requires a reason.
- Remains visible in history.

For the MVP, pause rules do not need complex per-item configuration. The entire day is either active or paused.

---

# 5. Level Items

## 5.1 User-Facing Item Types

The MVP should support:

### Binary action

The user either completed or failed the action.

Example:

> Meditate today.

### Avoidance

The user must avoid an unwanted behavior.

Example:

> Do not eat sweets.

### Minimum quantity

The user must reach or exceed a number.

Example:

> Read at least 20 pages.

### Maximum quantity

The user must remain below a limit.

Example:

> Use social media for no more than 30 minutes.

### Duration

The user must complete a minimum or maximum duration.

Example:

> Study for at least 30 minutes.

### Range

The recorded value must remain within an accepted interval.

Example:

> Go to sleep between 22:30 and 23:30.

---

## 5.2 Recommended Internal Data Model

The backend does not need a separate implementation for every user-facing item type.

Most item types can be represented through:

```text
BOOLEAN
NUMBER
TIME
```

Combined with an evaluation operator:

```text
EQUALS
AT_LEAST
AT_MOST
BETWEEN
```

Examples:

| User-facing type | Internal representation |
|---|---|
| Binary action | BOOLEAN equals true |
| Avoidance | BOOLEAN equals false |
| Read 20 pages | NUMBER at least 20 |
| Maximum screen time | NUMBER at most 30 |
| Exercise for 30 minutes | NUMBER at least 30, unit minutes |
| Sleep during a time window | TIME between two values |

This avoids creating separate backend logic for every possible habit type.

---

## 5.3 Deferred Item Types

Frequency-based items such as “exercise four times per week” should not be included in the MVP.

They conflict with the current rule that every individual day must pass or fail. A weekly target cannot always be evaluated meaningfully at the end of each day.

Frequency-based evaluation should be designed later as a separate progression model.

Sub-items should also be postponed. A level can initially contain several separate items instead of one item containing a checklist.

---

## 5.4 Level Item Fields

Each item contains:

- Title.
- Optional description.
- User-facing type.
- Internal value type.
- Evaluation operator.
- Target value.
- Optional second target value.
- Unit.
- Mandatory status.
- End-of-day behavior.
- Notification configuration.
- Display order.

---

## 5.5 Daily Item Status

Each daily item result can have one of the following statuses:

```text
PENDING
COMPLETED
FAILED
AUTO_COMPLETED
AUTO_FAILED
```

The final result must be stored permanently as part of the daily history.

---

## 5.6 Automatic End-of-Day Behavior

Each item supports one of three behaviors:

### Assume success

The item is automatically completed unless the user explicitly reports a failure.

This is appropriate for avoidance items.

Example:

> Do not eat sweets.

### Assume failure

The item is automatically failed unless the user confirms completion.

This is appropriate for active requirements.

Example:

> Exercise for 30 minutes.

### Require confirmation

The application asks the user to submit a result before closing the day.

For the MVP, automatic evaluation should be based only on configured defaults and data collected inside the application. External health, screen-time, and device integrations should be deferred.

---

# 6. Daily Submission

## 6.1 Daily State

A level day can have one of the following states:

```text
OPEN
SUBMITTED_SUCCESS
SUBMITTED_FAILURE
AUTO_FINALIZED
PAUSED
```

The user should be able to update item values throughout the day.

At the configured cutoff time, the application:

1. Evaluates items with automatic behavior.
2. Checks whether any items remain unresolved.
3. Sends a notification when user input is required.
4. Finalizes the day when all results are known.

The application should never silently mark an unresolved item as successful unless the item's configuration explicitly allows it.

---

## 6.2 Failed-Item Explanation

When an item fails, the user selects an optional failure reason:

- Forgot.
- Low motivation.
- Poor planning.
- Too tired.
- Unexpected event.
- Lack of time.
- Too difficult.
- Unsuitable environment.
- Emotional stress.
- Intentional decision.
- Requirement unclear.
- Other.

The user may also add a short note.

For MVP purposes, this should be a lightweight input rather than a long questionnaire.

---

# 7. Journaling and Daily Reflection

Journaling is the highest-priority supporting feature because it captures the context that numerical tracking cannot explain.

## 7.1 Daily Journal

The user has one journal entry per calendar day.

The entry contains:

- Free-form text.
- Creation date.
- Last edited date.
- Connection to the current level day.

The user may edit previous journal entries.

A complete revision history is not necessary for the MVP. The application should record that an entry was edited and preserve its last modification time.

---

## 7.2 Structured Reflection

The daily reflection should contain:

- Wins.
- Obstacles.
- Boosters.
- Conclusions.
- Mood rating.
- Energy rating.
- Stress rating.
- Focus rating.
- Sleep-quality rating.

Ratings can use a simple scale from 1 to 5.

Each text section should be optional. The user should be able to submit a reflection quickly rather than being forced to complete a long form every day.

---

## 7.3 Journal Experience

The journal screen should support two modes:

### Quick reflection

Designed for daily use:

- Rating controls.
- Short text fields.
- Fast submission.

### Full journal

A larger free-form writing area for detailed entries.

Both modes save into the same daily journal record.

---

# 8. Task Management

The MVP should provide useful task management without attempting to compete with mature productivity applications.

## 8.1 Task Fields

A task contains:

- Title.
- Optional description.
- List.
- Status.
- Priority.
- Due date.
- Estimated duration.
- Tags.
- Creation date.
- Completion date.
- Archive date.

Task statuses:

```text
NOT_STARTED
IN_PROGRESS
COMPLETED
CANCELLED
ARCHIVED
```

---

## 8.2 Supported Operations

The user can:

- Create a task.
- Edit a task.
- Start a task.
- Complete a task.
- Reopen a task.
- Cancel a task.
- Archive a task.
- Move a task between lists.
- Assign tags.
- Set an estimated duration.
- Set a due date.

Tasks that have become part of historical statistics should not be permanently deleted.

For the MVP, archive and cancel replace permanent deletion.

---

## 8.3 Deferred Task Features

Do not initially implement:

- Subtasks.
- Task dependencies.
- Recurring tasks.
- Shared tasks.
- Attachments.
- Comments.
- Advanced priorities.
- Complex reminder rules.
- Detailed interruption event records.

Subtasks can be represented temporarily as separate tasks sharing a tag or list.

---

## 8.4 Task Tag System

The user should be able to create reusable tags and attach them to tasks.

Tags provide a flexible way to categorize tasks independently of task lists. While a task belongs to a specific task list, it may have multiple tags describing its type, context, purpose, or characteristics.

Examples:

- Work
- Personal
- Learning
- Health
- Startup
- Deep Work
- Administrative
- Urgent

A task may have zero, one, or multiple tags.

For example:

```text
Task: Implement authentication API

List: Startup

Tags:
- Development
- Backend
- Deep Work
```

### Tag Fields

A tag should contain:

- **Label** — the name displayed to the user.
- **Color** — used to visually distinguish the tag throughout the application.
- **Created date**.
- **Status** — active or archived.

The label should be unique for the user so that multiple tags with the same name cannot accidentally be created.

### Tag Management

The user should be able to:

- Create a tag.
- Edit a tag's label.
- Change its color.
- Archive a tag.
- Restore an archived tag.
- Attach one or more tags to a task.
- Remove tags from a task.

Archiving a tag should not remove it from historical tasks.

For example, if the user previously used the tag `University` and later no longer needs it, the tag can be archived so that it does not appear when assigning tags to new tasks. Existing tasks should still retain the tag.

This preserves historical information for future statistics and analysis.

### Task Filtering by Tags

The task list should allow the user to filter tasks by tag.

For example:

```text
Filter: Deep Work

- Implement authentication API
- Design database schema
- Research synchronization strategy
```

For the MVP, filtering by a single tag is sufficient. More advanced combinations such as AND/OR tag queries can be added later if needed.

### Tag Display

Tags should be displayed as small colored labels alongside tasks where appropriate.

Example:

```text
Implement authentication API

[Backend] [Deep Work] [Startup]
```

The tag color should primarily help visually distinguish tags and should not have any functional meaning.

### Historical and Analytics Considerations

Task-tag relationships should be preserved for completed and archived tasks.

This is important because tags can later be used as dimensions for statistics and AI analysis, for example:

- Completion rate by tag.
- Estimated versus actual duration by tag.
- Time spent on Deep Work tasks.
- Tasks associated with specific goals or areas.
- Categories of tasks that are frequently postponed.

These analytics do not need to be implemented as part of the initial tag-system MVP, but the underlying tag relationships should be stored so they can be analyzed later.

### Deferred Tag Features

The MVP should not include:

- Nested or hierarchical tags.
- Tag groups.
- Automatic tag assignment.
- AI-generated tags.
- Tag-specific notification rules.
- Tag permissions.
- Complex tag filtering expressions.
- Icons in addition to colors.
- Separate tag types or categories.

A simple reusable many-to-many tag system is sufficient for the MVP.

# 9. Activity and Time Tracking

## 9.1 Unified Activity Model

Task work sessions and general activities should use one shared activity model.

An activity contains:

- Title.
- Category.
- Start time.
- End time.
- Duration.
- Description.
- Tags.
- Optional related task.
- Optional related level item.
- Planned or unplanned status.

When an activity is connected to a task, its duration contributes to the task's actual working time.

This prevents duplicate implementations for task timers and activity timers.

---

## 9.2 Activity Operations

The user can:

- Start an activity timer.
- Stop the active timer.
- Create an activity manually.
- Edit start and end times.
- Connect an activity to a task.
- Connect an activity to a level item.
- Record a distraction quickly.

Only one timer should be active at a time.

---

## 9.3 Fast Distraction Entry

A quick action should allow the user to record:

- Distraction title.
- Time.
- Optional category.
- Optional related activity or task.
- Estimated time lost.

Advanced interruption analysis should be postponed. The MVP only needs enough information to identify common distractions.

---

# 10. Basic Monitoring and Statistics

The MVP needs enough analytics to make the collected data useful, but it does not need prediction, correlations, or AI.

## 10.1 Levels Dashboard

Show:

- Current level.
- Current successful day.
- Highest completed level.
- Current attempt number.
- Failures in the current level cycle.
- Total failed days.
- Total pause days.
- Most frequently failed items.
- Recent level history.

---

## 10.2 Journal Dashboard

Show:

- Mood trend.
- Energy trend.
- Stress trend.
- Focus trend.
- Sleep-quality trend.
- Number of journaled days.
- Most frequently selected failure reasons.

No natural-language journal analysis is required.

---

## 10.3 Task Dashboard

Show:

- Tasks created.
- Tasks completed.
- Completion rate.
- Overdue tasks.
- Estimated versus actual duration.
- Time spent by tag or list.

Actual duration is calculated from linked activities.

---

## 10.4 Activity Dashboard

Show:

- Total tracked time.
- Time by category.
- Time by day.
- Planned versus unplanned time.
- Time connected to tasks.
- Number of recorded distractions.

---

## 10.5 Deferred Analytics

Postpone:

- Productivity predictions.
- Causal conclusions.
- Correlation matrices.
- AI recommendations.
- Automatic theme extraction.
- Best-time-of-day recommendations.
- Adaptive level suggestions.
- PDF reports.
- Cross-period behavioral analysis.

---

# 11. Main Mobile Screens

## 11.1 Today

This is the application's main screen.

It shows:

- Current level and day.
- Today's level items.
- Submit-day action.
- Today's tasks.
- Active activity timer.
- Quick journal status.
- Quick distraction action.
- Progress toward the daily cutoff.

The main screen should answer:

> What do I need to do next?

---

## 11.2 Levels

Contains:

- Current level.
- Level list.
- Draft level editor.
- Level-attempt history.
- Failed-day history.
- Start, restart, complete, and regress states.

---

## 11.3 Journal

Contains:

- Today's reflection.
- Full journal editor.
- Calendar of previous entries.
- Basic mood and energy trends.

---

## 11.4 Tasks

Contains:

- Task lists.
- Active tasks.
- Completed tasks.
- Task editor.
- Task timer.
- Tags and filters.

---

## 11.5 Activity

Contains:

- Daily timeline.
- Active timer.
- Manual activity editor.
- Activity history.
- Category summary.

---

## 11.6 Progress

Contains:

- Level statistics.
- Journal trends.
- Task statistics.
- Activity statistics.

The screen should be called **Progress** rather than **AI Analytics** because the MVP does not yet contain AI.

---

## 11.7 Settings

Contains:

- Daily cutoff time.
- Notification settings.
- Level rules.
- Pause-day settings.
- Theme.
- Data export.
- Account settings.

---

# 12. Suggested Navigation

A five-tab mobile navigation structure is sufficient:

```text
Today
Levels
Tasks
Journal
More
```

The **More** section contains:

- Activities.
- Progress.
- Settings.

Activity tracking remains accessible directly from the Today screen through the active timer and quick-add controls.

---

# 13. Backend Modules

The NestJS backend should initially contain:

```text
AuthModule
UsersModule
LevelsModule
LevelAttemptsModule
DailyResultsModule
JournalsModule
TasksModule
ActivitiesModule
StatisticsModule
NotificationsModule
SettingsModule
```

AI, rewards, health integrations, and PDF generation should not have modules in the initial implementation.

---

# 14. Core Database Entities

## User

Stores account information and settings.

## Level

Stores the identity and sequence of a level.

## LevelVersion

Stores an immutable version of a level's configuration.

## LevelItem

Stores the items belonging to a level version.

## LevelAttempt

Stores an attempt to complete a level.

## LevelDay

Stores the result of one calendar day within an attempt.

## LevelItemResult

Stores the value and status of each level item for a particular day.

## FailureReason

Stores the reason associated with a failed item or day.

## JournalEntry

Stores the free-form journal and structured reflection for a day.

## TaskList

Stores user-defined task lists.

## Task

Stores task information and status.

## Tag

Stores reusable task, activity, and goal labels.

## Activity

Stores manually created or timed activities.

## UserSettings

Stores cutoff time, notification preferences, and level configuration.

---

# 15. Important Domain Constraints

The backend must enforce the following rules rather than relying only on the Flutter client:

1. Only one level may be active.
2. Only one level attempt may be active.
3. An active level version cannot be edited.
4. A completed level version cannot be edited.
5. Only one level day may exist for a calendar date and active attempt.
6. A submitted day cannot be submitted a second time without an explicit correction operation.
7. A successful day requires every mandatory item to succeed.
8. A failed day resets the active level progress.
9. The third failure triggers regression.
10. Only one activity timer may be active.
11. Archived historical tasks cannot be permanently deleted through normal operations.
12. A level cannot start without at least one mandatory item.

These rules should be validated transactionally in PostgreSQL wherever possible.

---

# 16. Authentication Recommendation

Because the first version is for personal use, authentication should remain minimal.

Two reasonable options exist:

### Fastest private MVP

- One locally configured user.
- No registration.
- No password reset.
- Backend accessible only through the developer's account or private environment.

### Expandable MVP

- Email and password login.
- Secure password hashing.
- Access token and refresh token.
- Logout.
- Basic password update.

Registration, social login, email verification, and forgotten-password flows can be added later.

For a personal MVP, the first option is sufficient and avoids spending development time on functionality unrelated to the core product.

---

# 17. Offline Behavior

Complete offline-first synchronization is a large feature and should not be implemented initially.

However, the Flutter application should protect the most important actions from temporary network failure.

The client should locally queue:

- Item-status changes.
- Daily submission.
- Journal changes.
- Task changes.
- Activity start and stop actions.

Queued operations should synchronize when connectivity returns.

A lightweight local persistence layer such as SQLite can store:

- Today's level.
- Today's item results.
- Current journal.
- Current tasks.
- Active activity timer.
- Pending synchronization operations.

Complex conflict resolution can be postponed because the MVP has only one user and one primary device.

---

# 18. MVP Notification Scope

Include only:

- Level-item reminders.
- End-of-day reminder.
- Unresolved-item reminder.
- Task deadline reminder.
- Active-timer reminder.

Postpone:

- Adaptive reminders.
- AI-generated reminders.
- Multiple conditional reminder rules.
- Location-based notifications.
- Smartwatch notifications.
- Escalation schedules.

---

# 19. Explicit Product Decisions

## Sub-items

Do not include them in the MVP.

Use separate level items instead.

## Subtasks

Do not include them in the MVP.

Use separate tasks in the same list or with the same tag.

## Frequency-based level items

Do not include them because they do not align cleanly with daily pass-or-fail evaluation.

## AI-calculated rewards

Do not include rewards in the MVP.

When rewards are implemented, coin earning should initially use deterministic rules. AI may recommend adjustments but should not directly control balances.

## Historical editing

Allow corrections, but store:

- Last edited time.
- Whether the record was changed after submission.
- Optional correction reason.

A complete event-sourced revision system is unnecessary for the MVP.

## Blocked periods

Support one-day pauses first. Multi-day periods can be implemented as repeated pause days.

---

# 20. Development Sequence

## Milestone 1 — Foundation

- Flutter project.
- NestJS project.
- PostgreSQL schema.
- Basic user handling.
- Settings.
- Local persistence.
- API client and synchronization foundation.

## Milestone 2 — Levels

- Level creation.
- Level-item configuration.
- Level activation and locking.
- Daily tracking.
- Daily submission.
- Failure handling.
- Attempt restart.
- Three-failure regression.
- Level completion.
- Level history.
- Pause days.

This milestone should produce a usable standalone application.

## Milestone 3 — Journaling

- Daily journal.
- Structured reflection.
- Ratings.
- Journal calendar.
- Journal history.

## Milestone 4 — Tasks and Activities

- Task lists.
- Task CRUD.
- Task status.
- Estimated duration.
- Activity timer.
- Activity timeline.
- Task-to-activity connection.
- Quick distraction recording.

## Milestone 5 — Progress

- Level dashboard.
- Journal trends.
- Task statistics.
- Activity statistics.
- Basic charts.

## Milestone 6 — Reliability

- Notifications.
- Offline operation queue.
- Data export.
- Error handling.
- Backup and restore testing.
- End-to-end tests for progression rules.

---

# 21. MVP Acceptance Criteria

The MVP is complete when the user can:

1. Create a level with multiple items.
2. Start the level and lock its definition.
3. Record item results during the day.
4. Submit a successful day.
5. Submit a failed day and provide a failure reason.
6. See progress reset after failure.
7. Regress after three failures.
8. Complete a level after 10 successful days.
9. Define and start the next level.
10. Record a daily journal and reflection.
11. Create and complete tasks.
12. Track time through activities.
13. See basic historical statistics.
14. Use core daily functions during temporary network failure.
15. Recover all historical data after restarting the application.

---

# 22. MVP Success Criteria

Because this is initially a personal product, success should not be measured through downloads or revenue.

The MVP succeeds when:

- It is used consistently for at least 30 days.
- Daily level submission takes less than approximately one minute.
- Journaling does not feel burdensome.
- Level history remains understandable after several failures and restarts.
- The system produces at least one useful behavioral observation without AI.
- The user trusts that recorded data will not disappear.
- The strict failure rules motivate behavior instead of causing abandonment.
- Tasks and activity tracking support the levels rather than distracting from them.

---

# 23. Post-MVP Roadmap

## Version 1.1

- Weekly and monthly reviews.
- Baseline assessment.
- Long-term goals.
- Advanced pause periods.
- Expanded item types.
- Task recurrence.
- Subtasks.

## Version 1.2

- Advanced statistics.
- Correlations between sleep, mood, activities, and failures.
- Focus and interruption analysis.
- Data annotations.
- Health and screen-time integrations.

## Version 2.0

- AI insights.
- AI-generated questions.
- Adaptive level recommendations.
- Weekly and monthly AI reports.
- PDF export.
- Confidence and evidence presentation.

## Version 2.1

- Currency ledger.
- Configurable earning rules.
- Reward list.
- Reward redemption.
- Coin-economy safeguards.
- Reward-effectiveness analysis.

---

# 24. Final MVP Definition

The first release should be described as:

> A personal mobile application that helps the user progress through self-defined improvement levels, track daily requirements, document successes and failures, reflect through journaling, manage supporting tasks, record time usage, and review basic progress.

The MVP should not attempt to be an AI coach, a complete productivity suite, or a comprehensive life-analytics platform.

It should first prove that the combination of strict levels, daily tracking, journaling, and basic behavioral feedback creates a system that the user can follow consistently.