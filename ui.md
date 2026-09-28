1. Overall Navigation
Use a persistent Material 3 NavigationBar:
┌─────────────────────────────────┐
│                                 │
│          Current screen         │
│                                 │
│                                 │
├─────────────────────────────────┤
│ Today │ Levels │ Tasks │Journal│More
└─────────────────────────────────┘

Icons:
Tab	Material icon
Today	today / home
Levels	military_tech / stairs
Tasks	check_circle_outline
Journal	book_outlined
More	more_horiz


I would not put Activities directly in the bottom navigation. Activity tracking should be quickly accessible from Today, while its full screen lives under More.
2. Visual Design System
Use a restrained Material 3 design rather than making the app look excessively like a game.
Status colors
Use semantic colors consistently:
- Green → completed/successful
- Red → failed
- Amber → paused/warning
- Blue or primary → active/current
- Grey → draft/pending
- Muted grey → archived
Don't rely on color alone. Always combine color with an icon/text status.
For example:
✓ Completed
✕ Failed
⏸ Paused
○ Pending

Cards
Use cards for meaningful entities:
- Current level
- Level items
- Tasks
- Current activity
- Statistics
Avoid making every single field a card.
Corners
Material 3 defaults are appropriate:
Cards:       ~12–16 px
Buttons:     ~20 px / pill-like
Input fields: ~12 px

Spacing
Use an 8-point grid:
4
8
16
24
32

Standard screen horizontal padding:
16 px

3. Today Screen
This is the most important screen in the application.
Its purpose is not to show everything. It should answer:
What do I need to do today?

Layout
┌─────────────────────────────────┐
│ Friday, August 7          ⚙/☁   │
│ Good afternoon                  │
│                                 │
│ ┌─────────────────────────────┐ │
│ │ LEVEL 10                    │ │
│ │ Day 6 of 10                 │ │
│ │ Attempt #2                  │ │
│ │ ████████████░░░░ 60%        │ │
│ │                             │ │
│ │ Failures this cycle: 1 / 3  │ │
│ └─────────────────────────────┘ │
│                                 │
│ Today's level items         3/5 │
│                                 │
│ ┌─────────────────────────────┐ │
│ │ ✓ Meditate                  │ │
│ │   Completed                 │ │
│ └─────────────────────────────┘ │
│                                 │
│ ┌─────────────────────────────┐ │
│ │ ○ Read 20 pages             │ │
│ │   12 / 20 pages             │ │
│ │                 [Update]    │ │
│ └─────────────────────────────┘ │
│                                 │
│ ┌─────────────────────────────┐ │
│ │ ○ Avoid sweets              │ │
│ │   Assumed success           │ │
│ └─────────────────────────────┘ │
│                                 │
│         [Review day]            │
│                                 │
│ Tasks                       2/6 │
│ ────────────────────────────── │
│ ○ Implement API                │
│ ○ Read documentation           │
│                        See all ›│
│                                 │
│ Activity                       │
│ ┌─────────────────────────────┐ │
│ │ ▶ Coding                    │ │
│ │   00:42:18           [Stop] │ │
│ └─────────────────────────────┘ │
│                                 │
│ Journal                         │
│ Reflection not completed        │
│                [Quick reflect]  │
└─────────────────────────────────┘

App bar
Show:
- Date
- Sync/offline indicator
- Optional overflow menu
Do not put Settings directly here unless needed.
Current Level Card
Show:
- Level number
- Day X / 10
- Current attempt
- Linear progress
- Failure counter
- Possibly next cutoff time
Tapping it opens Current Level Detail.
Today's Level Items
Each item renders differently depending on type.
Binary
Meditate today

[ Done ]   [ Failed ]

Use SegmentedButton or two tonal buttons.
Quantity
Read at least 20 pages

12 / 20 pages

[-]  12  [+]

Or tap value to enter via numeric dialog.
Duration
Study for 30 minutes

18 / 30 min

[Start activity]

If the activity tracker is used, this can eventually automatically contribute duration.
Avoidance
Avoid sweets

Currently successful
[Report failure]

This is better than asking the user to constantly mark it complete.
Range
Sleep between
22:30 – 23:30

Actual:
[ 23:05 ]

Review Day button
Use:
FilledButton
Text:
Review day
Do not immediately submit from Today.
First show the Daily Review screen.
4. Daily Review / Submission Screen
This screen exists to prevent accidental failures.
< Review today

Level 10 — Day 6

✓ Meditate
✓ Exercise 30 min
✓ Read 20 pages
○ Avoid sweets
✓ Sleep before 23:30

────────────────────────

1 item will be automatically completed
at 23:59 unless you report a failure.

        [Submit day]

If unresolved items exist:
⚠ 2 items need your input

The submit button remains disabled until necessary input is supplied.
5. Failed Item Explanation Bottom Sheet
When the user chooses Failed:
Why did "Read 20 pages" fail?

○ Forgot
○ Low motivation
○ Poor planning
○ Too tired
○ Unexpected event
○ Lack of time
○ Too difficult
○ Other

Note (optional)
┌─────────────────────────┐
│                         │
└─────────────────────────┘

[Cancel]          [Confirm failure]

Use a ModalBottomSheet.
Don't create a full screen for this.
6. Successful Day Result Screen
After submission:
        ✓

Day completed

Level 10
6 / 10 successful days

████████████░░░░

4 successful days remaining

[Add reflection]

[Done]

Keep the celebration subtle.
No confetti is necessary for the MVP.
7. Failed Day Result Screen
This one needs very careful UX.
        ✕

Day failed

Level 10 — Attempt #2 ended

Failed item:
Read 20 pages

Reason:
Lack of time

Your level progress has restarted.

Failures this cycle:
2 / 3

Next attempt:
Attempt #3

[Add reflection]

[Continue]

Avoid judgmental wording.
The application should explain exactly what happened.
If the third failure causes regression:
Level regression

This was your third failed attempt.

You are returning to:

Level 9

A new Level 9 attempt will begin.

[Continue]

8. Pause Day Screen
Accessible from the Today overflow menu:
Pause today

Paused days don't count as successful
or failed days.

Reason

○ Illness
○ Travel
○ Vacation
○ Family event
○ Work obligation
○ Other

Additional note
[________________________]

[Cancel]       [Pause day]

After activation, Today changes to:
⏸ Today is paused

Reason: Travel

Your Level 10 progress remains 6/10.

9. Levels Screen
This screen should feel like progression through a path.
Levels

Current progress
────────────────────

✓ Level 8
  Completed

✓ Level 9
  Completed

● Level 10
  ACTIVE
  Day 6 / 10
  Attempt #2

○ Level 11
  Draft

○ Level 12
  Not defined

○ Level 13
  Not defined

For 100 levels, don't render a giant game map.
Use a normal scrollable list/timeline.
Level states
Completed
✓ Level 9
Completed
3 attempts

Active
Highlight strongly:
● Level 10
ACTIVE

Day 6 / 10
Attempt #2

████████████░░░░

Draft
○ Level 11
Draft
3 items

[Edit]

Undefined
○ Level 12
Not configured

[Create]

10. Current Level Detail Screen
< Level 10                ⋮

ACTIVE

Day 6 of 10
Attempt #2

████████████░░░░

Failures this cycle
1 / 3

Current version
Version 2

Level items
────────────────────────
Meditate
Binary

Read 20 pages
Minimum quantity

No sweets
Avoidance

Exercise 30 minutes
Duration

────────────────────────

Attempt history
Attempt #2     ACTIVE
Attempt #1     FAILED

[View full history]

────────────────────────

[Restart level]

Since the level is active, items are read-only.
11. Create / Edit Level Screen
Use one screen for both create and edit.
< Create Level 11

Description
┌─────────────────────────────┐
│ Improve morning routine     │
└─────────────────────────────┘

Level items

≡  Wake up before 07:00       ⋮
≡  Meditate                   ⋮
≡  Read 20 pages              ⋮

[+ Add level item]

────────────────────────

3 mandatory items

[Save draft]

[Start level]

Use Flutter's ReorderableListView.
For editing:
- swipe should not delete immediately
- use overflow menu → Edit / Remove
Starting the level should show a confirmation.
12. Start Level Confirmation
Use a dialog:
Start Level 11?

Once this level starts, its current
definition cannot be edited.

To change it later, you will have to
restart the level.

[Cancel]          [Start level]

13. Level Item Editor Screen
This should be a full screen because its fields change based on item type.
< Add level item

Title
[Read books                     ]

Description
[Optional                       ]

Type
────────────────────────
○ Binary
● Minimum quantity
○ Maximum quantity
○ Duration
○ Avoidance
○ Range

Target
[ 20 ]

Unit
[ pages ▼ ]

Mandatory
[ ON ]

End-of-day behavior
[Require confirmation ▼]

Reminder
[ 20:00 ]

[Save item]

After choosing Range:
Minimum
[22:30]

Maximum
[23:30]

After choosing Avoidance:
Default recommendation:
End of day:
Assume success

14. Restart Level Flow
From active Level Detail:
Restart Level 10

What do you want to do?

○ Restart using the current definition

○ Modify the level before restarting

Then ask:
Reason for restart
[________________________]

If unchanged:
LevelVersion #2
→ New LevelAttempt

If edited:
LevelVersion #2
→ copy
→ LevelVersion #3
→ edit
→ start new attempt

This matches your version/attempt architecture.
15. Level Attempt History Screen
< Level 10 history

Current
────────────────────────
Attempt #4
ACTIVE
Aug 3 – now
5 successful days

Previous
────────────────────────

Attempt #3
✓ COMPLETED
July 20 – July 29
10 successful days
Version 2

Attempt #2
✕ FAILED
July 14 – July 19
5 successful days
Poor planning
Version 2

Attempt #1
✕ FAILED
July 2 – July 8
6 successful days
Version 1

Use status chips.
16. Level Attempt Detail Screen
< Attempt #2

Level 10
Version 2

FAILED

Started       July 14
Ended         July 19
Successful    5 days

Failure
Read 20 pages

Reason
Poor planning

Daily history
────────────────────────
Jul 14     ✓ Success
Jul 15     ✓ Success
Jul 16     ✓ Success
Jul 17     ✓ Success
Jul 18     ✓ Success
Jul 19     ✕ Failed

Tapping a day opens Day History.
17. Historical Day Detail Screen
< July 19

Level 10 — Attempt #2

✕ Failed

Items

✓ Meditate
✓ Exercise
✕ Read 20 pages
  12 / 20
  Reason: Poor planning

✓ No sweets

Journal
────────────────────
View entry >

Activities
────────────────────
Coding       2h 15m
Gym          45m

[Correct historical record]

Corrections should be visually identified afterward:
Edited after submission

18. Tasks Screen
Tasks                         🔍  ⋮

[Today] [Active] [Overdue] [Completed]

List: All Tasks ▼

────────────────────────

○ Implement levels API
  Startup
  [Backend] [Deep Work]
  Today · 2h estimate

○ Write database migration
  Startup
  [Backend]
  Tomorrow · 45m

◉ Implement UI
  IN PROGRESS
  [Flutter]
  1h 12m tracked

────────────────────────
                             ＋

Use a Material FloatingActionButton for Add Task.
I recommend filtering using FilterChip.
19. Create / Edit Task Screen
Use the same screen for create and edit.
< New Task

Title
[Implement Level API            ]

Description
[                              ]

List
[Startup ▼]

Status
[Not started ▼]

Priority
[Medium ▼]

Due date
[Aug 10]

Estimated duration
[2h 00m]

Tags
[Backend] [Deep Work] [+ Add]

[Create task]

Do not expose creation/completion/archive dates in the editor. Those are system-managed.
20. Task Detail Screen
< Implement Level API       ⋮

IN PROGRESS

[Backend] [Deep Work]

Startup

Due
Aug 10

Estimated
2h

Tracked
1h 12m

────────────────────────

Description
Implement CRUD endpoints...

────────────────────────

Activity

Today       42m
Yesterday   30m

Total       1h 12m

[▶ Continue working]

────────────────────────

[Complete task]

Overflow:
- Edit
- Cancel task
- Archive
21. Task Lists Screen
Accessible from Tasks → overflow → Manage lists.
< Task Lists

Inbox                       12
Startup                      8
Personal                     5
Learning                     3

[+ Create list]

Long press or overflow:
Rename
Archive

22. Tag Management Screen
< Tags

● Backend                    12
● Deep Work                   8
● Flutter                     6
● Learning                    4
● Health                      3

                             ＋

Tap a tag:
Edit tag

Label
[Deep Work]

Color
● ● ● ● ● ● ●

[Save]

No hierarchical tags or tag groups in MVP.
23. Tag Selection Bottom Sheet
From Task Editor:
Select tags

☑ Backend
☑ Deep Work
☐ Flutter
☐ Learning
☐ Personal

[+ Create new tag]

[Done]

Use Material FilterChip or checkbox rows.
24. Journal Screen
Journal should open directly to today.
Top:
Journal

Friday, August 7        📅

Use a SegmentedButton:
[ Quick Reflection | Full Journal ]

25. Quick Reflection
Mood
😞  😕  😐  🙂  😄
1   2   3   4   5

Energy
○ ○ ○ ● ○

Stress
○ ● ○ ○ ○

Focus
○ ○ ○ ● ○

Sleep quality
○ ○ ● ○ ○

Wins
[________________________]

Obstacles
[________________________]

Boosters
[________________________]

Conclusions
[________________________]

[Save reflection]

I would use five icon buttons rather than traditional sliders because discrete values are easier to enter quickly.
26. Full Journal Mode
Full Journal

Friday, August 7

┌───────────────────────────────┐
│ Today I noticed that...       │
│                               │
│                               │
│                               │
└───────────────────────────────┘

Last saved 16:42

[Save]

Autosave locally after changes.
The explicit Save remains because users like knowing their journal was stored.
27. Journal Calendar / History Screen
< Journal History

        August 2026
   S M T W T F S
             1 2
   3 4 5 6 ● 8 9
  10...

● = journal entry

Below:
Recent entries

Aug 7
Mood 4 · Energy 3
"Very productive day..."

Aug 6
Mood 3 · Energy 2
"Didn't sleep well..."

Tapping a date opens that journal entry in editable historical mode.
28. Activity Screen
Accessible from More or Today.
Activity

< Aug 7 >

Tracked today
5h 42m

┌─────────────────────────────┐
│ ▶ Coding                    │
│   00:42:18                  │
│   Implement Level API       │
│                    [Stop]   │
└─────────────────────────────┘

Timeline
─────────────────────────────

08:00 – 08:30
Breakfast
30m

09:00 – 10:15
Coding
1h 15m
Task: Level API

10:15 – 10:25
Distraction
10m

10:25 – 12:10
Coding
1h 45m

────────────────────────

[+ Start activity]

[⚡ Log distraction]

29. Start Activity Bottom Sheet
Start activity

Activity
[Coding]

Category
[Work ▼]

Related task
[Implement Level API ▼]

Related level item
[None ▼]

Tags
[Deep Work]

○ Planned
● Unplanned

[Start timer]

Immediately after starting, display a persistent timer.
30. Global Active Timer
When a timer is running, show a small persistent element at the bottom of relevant screens above NavigationBar:
▶ Coding     00:42:18      [■]

Tapping it opens Activity Detail.
This is important because there can only be one active timer.
31. Manual Activity Editor
< Add activity

Title
[Coding]

Category
[Work ▼]

Date
[Aug 7]

Start
[09:00]

End
[10:15]

Duration
1h 15m

Related task
[Implement API ▼]

Related level item
[None]

Planned?
[Yes / No]

Description
[Optional]

[Save]

Duration is calculated automatically.
32. Quick Distraction Bottom Sheet
This interaction should be extremely fast.
Log distraction

What distracted you?
[Instagram]

Time lost
[10 min]

Related task
[Implement Level API ▼]

Category
[Social media ▼]

[Save]

Aim for under 10 seconds to record.
33. Progress Screen
Accessible from More.
Use tabs:
Levels | Journal | Tasks | Activity

At the top:
Period

[7 days] [30 days] [All]

For MVP, avoid custom date ranges.
34. Progress — Levels
Current Level
10

Current Day
6 / 10

Highest Completed
9

Failures
7

Pause Days
3

Then:
Most Failed Items
Horizontal bar chart:
Read 20 pages       ███████ 7
Exercise             ████   4
Meditation           ██     2

Recent Level History
Level 10 Attempt #2    ACTIVE
Level 10 Attempt #1    FAILED
Level 9                COMPLETED

35. Progress — Journal
Top metrics:
Journal days
24 / 30

Metric selector:
[Mood] [Energy] [Stress] [Focus] [Sleep]

Then one line chart.
Do not draw all five metrics on one chart.
Below:
Common failure reasons

Lack of time      8
Too tired         5
Poor planning     4

36. Progress — Tasks
Summary:
Created       48
Completed     37
Completion    77%
Overdue        6

Estimate accuracy
Estimated      34h
Actual         42h

+23%

Time by tag
Deep Work      █████████ 14h
Backend        ███████   11h
Learning       ████       6h

Completion by tag
Backend       82%
Learning      71%
Administrative 55%

37. Progress — Activity
Summary:
Tracked time
42h 18m

Connected to tasks
31h 02m

Distractions
17

Time by category
Use horizontal bars rather than a pie chart where possible:
Work          █████████████ 25h
Learning      ██████        11h
Exercise      ███            5h
Other         █              1h

Planned vs unplanned
Planned       74%
Unplanned     26%

Daily tracked time
Simple 7/30-day bar chart.
38. More Screen
Very simple.
More

Activity
Track how you spend your time
                              >

Progress
Statistics and trends
                              >

Settings
Application preferences
                              >

Later AI and Rewards can be added here without changing the bottom navigation.
39. Settings Screen
Settings

DAILY SYSTEM

Daily cutoff
23:59                           >

Level rules
10 days · 3 failures            >

Pause days
Configure                       >

NOTIFICATIONS

Notifications                   >

APPEARANCE

Theme
System                          >

DATA

Sync status                     >
Export data                     >

ACCOUNT

Account                         >

Use grouped ListTiles.
40. Daily Cutoff Screen
< Daily cutoff

Your day ends at:

        23:59

[Change time]

At the cutoff the app will:

✓ Evaluate automatic items
✓ Check unresolved items
✓ Send a reminder when needed
✓ Finalize eligible days

41. Level Rules Screen
For the MVP I recommend not allowing these rules to change yet.
Show:
Level rules

Successful days required
10

Failures before regression
3

These rules are fixed for the MVP.

Why?
Because allowing:
10 days → 7 days
3 failures → 5 failures

creates another versioning problem.
Later, when configurable rules are implemented, snapshot them into the relevant Level/Attempt configuration.
42. Notifications Screen
< Notifications

Level item reminders          ON

End-of-day reminder           ON
30 minutes before cutoff

Unresolved-item reminder      ON

Task deadline reminders       ON

Active timer reminder         ON
After 2 hours

Individual level-item reminder times remain inside the Level Item editor.
43. Appearance Screen
< Appearance

Theme

● System
○ Light
○ Dark

Color theme

● ● ● ● ●

Material 3 seed colors make this easy to implement.
44. Data Export Screen
< Export Data

Export your application data.

Includes:

Levels
Journals
Tasks
Tags
Activities
Statistics source data

Format

○ JSON
○ CSV archive

[Export all data]

PDF is not needed because AI/PDF reports are post-MVP.
45. Sync Status Screen
Since you're supporting queued offline actions, give the user visibility.
< Sync Status

✓ Synced

Last sync
16:42

Pending changes
0

Offline:
⚠ Offline

7 changes waiting to sync

• Journal update
• Task completion
• Level item update
• Activity stop
...

Changes are safely stored on this device.

[Retry]

This will greatly improve user trust.
46. Account Screen
If this remains a personal application:
Account

User
ron@example.com

[Change password]

[Log out]

Don't build profile photos, usernames, bios, etc.
47. Login Screen — Only If You Implement Authentication
Levels Manager

Build yourself,
one level at a time.

Email
[________________]

Password
[________________]

[Log in]

Forgot password?

No signup screen is required if you're the only user and manually create the account.
48. Important Global UI Components
There are several components I would build once and reuse everywhere.
LevelProgressCard
Used on:
- Today
- Levels
- Current Level
LevelItemCard
Handles:
- Binary
- Avoidance
- Quantity
- Duration
- Range
StatusChip
ACTIVE
COMPLETED
FAILED
PAUSED
DRAFT
ARCHIVED

TaskTile
Used in Today and Tasks.
TagChip
Reusable across Tasks and Activity.
ActiveTimerBar
Global persistent activity timer.
MetricCard
Used throughout Progress:
┌──────────────┐
│ Completion   │
│     77%      │
└──────────────┘

EmptyState
For example:
No tasks yet

Create a task to start planning
your work.

[Create task]

49. Floating Action Buttons
Don't put a FAB everywhere.
I recommend:
Screen	FAB
Today	none
Levels	Create Level, if relevant
Tasks	Add Task
Journal	none
Activity	Start/Add Activity
Progress	none
More	none


Fast distraction recording should be accessible as an explicit action inside Today and Activity rather than introducing another floating control.
50. Offline UI
When offline, don't interrupt the user with dialogs.
Show a small Material banner:
☁ Offline — changes will sync later

Actions should continue working.
After reconnection:
✓ Changes synchronized

as a SnackBar.
51. Destructive Actions
You have several actions with meaningful consequences:
- Fail item
- Submit failed day
- Restart level
- Abandon attempt
- Cancel task
- Correct historical result
Use confirmation only when consequences are significant.
For example:
Restart Level 10?

Your current attempt will be marked
as abandoned and preserved in history.

[Cancel]       [Restart]

Don't show confirmations for ordinary task completion, tag assignment, journal save, etc.
52. Final Screen Architecture
This gives you roughly the following navigation tree:
APP
│
├── Today
│   ├── Daily Review
│   ├── Day Success
│   ├── Day Failure
│   ├── Failure Reason Sheet
│   └── Pause Day
│
├── Levels
│   ├── Level Detail
│   ├── Create/Edit Level
│   │   └── Level Item Editor
│   ├── Restart Level
│   ├── Attempt History
│   │   └── Attempt Detail
│   │       └── Historical Day Detail
│   └── Start Level Confirmation
│
├── Tasks
│   ├── Task Detail
│   ├── Create/Edit Task
│   ├── Task Lists
│   ├── Tags
│   └── Tag Selector
│
├── Journal
│   ├── Quick Reflection
│   ├── Full Journal
│   └── Journal History
│
└── More
    │
    ├── Activity
    │   ├── Start Activity
    │   ├── Activity Editor
    │   └── Quick Distraction
    │
    ├── Progress
    │   ├── Levels
    │   ├── Journal
    │   ├── Tasks
    │   └── Activity
    │
    └── Settings
        ├── Daily Cutoff
        ├── Level Rules
        ├── Notifications
        ├── Appearance
        ├── Sync Status
        ├── Data Export
        └── Account

The key UX decision I would preserve throughout the implementation is this hierarchy:
Today = execution. Levels = configuration/progression. Journal = reflection. Tasks/Activities = supporting data. Progress = analysis.
That prevents your app from turning into a collection of disconnected productivity tools; every screen remains connected to the core level loop.