using Molaway.Core;

int passed = 0;
void Check(bool value, string message) { if (!value) throw new Exception(message); passed++; }
Scheduler Fresh(int eye = 1, int movement = 10) => new(new() { EyeMinutes = eye, MovementMinutes = movement });
void Run(Scheduler s, int start, int end, Func<int, Sample>? make = null) { for (int t = start; t <= end; t++) s.Tick(make?.Invoke(t) ?? new(t, 0)); }

var s = Fresh(); Run(s, 0, 59); Check(s.Reminder == BreakKind.None, "early first alert"); s.Tick(new(60, 0)); Check(s.Reminder == BreakKind.Eyes, "due eye alert");
s.Snooze(); Run(s, 61, 359); Check(s.Reminder == BreakKind.None, "snooze elapsed early"); s.Tick(new(360, 0)); Check(s.Reminder == BreakKind.Eyes, "snooze missing");
s.Snooze(); Run(s, 361, 659); Check(s.Reminder == BreakKind.None, "other timer interrupted snooze"); s.Tick(new(660, 0)); Check(s.Reminder == BreakKind.Both, "two due timers");
s.Snooze(); Check(s.Eyes.Deferrals == 3 && s.Movement.Deferrals == 1, "only shown deferrals count"); Run(s, 661, 959); Check(s.Reminder == BreakKind.None, "third snooze early");
var noAlert = Fresh(); noAlert.Snooze(); Check(noAlert.Eyes.Remaining == 60 && noAlert.Eyes.Deferrals == 0, "stale button changed timers");
var later = Fresh(1, 40); Run(later, 0, 60); later.Snooze(); Check(later.Movement.Remaining == 2340, "snooze shortened later deadline");
var idle = Fresh(); Run(idle, 0, 30); Run(idle, 31, 160, t => new(t, t - 30)); Check(idle.State == Activity.Away && idle.Eyes.Work == 0 && idle.Movement.Work == 0, "natural rest failed"); idle.Tick(new(161, 0)); Check(idle.Reminder == BreakKind.None && idle.Eyes.Remaining == 60, "stale alert on return");
var shortAway = new Scheduler(new() { EyeMinutes = 20, MovementMinutes = 40, IdleSeconds = 15, MovementRestSeconds = 120 }); Run(shortAway, 0, 100); Run(shortAway, 101, 130, t => new(t, t - 100)); Check(shortAway.Eyes.Work == 0 && shortAway.Movement.Work == 100, "short absence reset long timer or counted idle");
var startup = Fresh(); Run(startup, 0, 20, t => new(t, 50 + t)); Check(startup.Eyes.Work == 0 && startup.State == Activity.Waiting, "counted pre-start idle"); startup.Tick(new(21, 0)); startup.Tick(new(22, 0)); Check(startup.Eyes.Work == 1, "start on input");
var media = Fresh(); Run(media, 0, 200, t => new(t, t + 200, true)); Check(media.State == Activity.Media && media.Eyes.Work == 200, "media did not count"); media.Dismiss(); Run(media, 201, 220, t => new(t, 500)); Check(media.State == Activity.Active, "media-stop used old input idle");
var manualWatch = Fresh(); manualWatch.ToggleWatching(0); Run(manualWatch, 0, 200, t => new(t, 500)); Check(manualWatch.State == Activity.Media, "watching timer"); manualWatch.ToggleWatching(200); Check(!manualWatch.IsWatching(201), "watching off");
var pause = Fresh(); Run(pause, 0, 20); pause.TogglePause(); Run(pause, 21, 100); Check(pause.Eyes.Work == 20 && pause.State == Activity.Paused, "pause counted work"); pause.TogglePause(); Run(pause, 101, 102); Check(pause.Eyes.Work == 21, "resume counting");
var sleep = Fresh(); Run(sleep, 0, 59); sleep.Tick(new(60, 0, Locked:true)); sleep.Tick(new(600, 0)); Check(sleep.Eyes.Work == 0 && sleep.Movement.Work == 0 && sleep.Reminder == BreakKind.None, "sleep credit / wake alert");
var jump = Fresh(); Run(jump, 0, 20); jump.Tick(new(1000, 0)); Check(jump.Eyes.Work == 20, "clock jump counted work"); jump.Tick(new(-10, 0)); Check(jump.Eyes.Work == 20, "negative time counted");
var rest = Fresh(); Run(rest, 0, 60); rest.StartRest(BreakKind.Eyes, 60); TickResult completed = default; for (int t=61;t<=80;t++) completed=rest.Tick(new(t,t-60)); Check(rest.Resting == BreakKind.None && rest.Eyes.Work == 0 && completed.RestSeconds == 20, "guided rest completion"); Check(rest.Movement.Work == 60, "short eye rest reset movement");
var early = Fresh(); Run(early, 0, 60); early.StartRest(BreakKind.Eyes, 60); Run(early, 61, 64); early.Continue(); Check(early.Eyes.Work == 0 && early.Resting == BreakKind.None, "explicit Continue did not reset");
var auto = Fresh(); Run(auto, 0, 60); auto.StartRest(BreakKind.Eyes, 60); Run(auto, 61, 65); Check(auto.Resting == BreakKind.None && auto.Eyes.Work == 60 && auto.Eyes.Remaining == 300, "automatic early return semantics");
var quiet = Fresh(); Run(quiet, 0, 100, t=>new(t,0,Quiet:true)); Check(quiet.Reminder == BreakKind.None, "quiet interruption"); quiet.Tick(new(101,0)); Run(quiet,102,160); Check(quiet.Reminder == BreakKind.None, "quiet grace period"); quiet.Tick(new(161,0)); Check(quiet.Reminder == BreakKind.Eyes, "held reminder lost");
var bad = Fresh(); bad.Tick(new(double.NaN,0)); Check(bad.State == Activity.Waiting && double.IsFinite(bad.Eyes.Remaining), "invalid sensor poisoning");
var settings = new Preferences { EyeMinutes = -1, MovementMinutes = int.MaxValue, Style = (AlertStyle)100, Opacity = double.NaN }.Validate(); Check(settings.EyeMinutes == 1 && settings.MovementMinutes == 240 && settings.Style == AlertStyle.Banner && settings.Opacity == .96, "settings validation");
string temp = Path.Combine(Environment.CurrentDirectory, ".molaway-tests-" + Guid.NewGuid().ToString("N"));
try {
 var store = new LocalStore(temp); Check(store.Write("settings.json",new Preferences()), "atomic save"); Check(store.Read<Preferences>("settings.json")?.EyeMinutes == 20, "read settings");
 File.WriteAllText(Path.Combine(temp,"settings.json"),"{invalid"); Check(store.Read<Preferences>("settings.json") == null && store.Error != null, "corrupt settings accepted");
 File.WriteAllText(Path.Combine(temp,"settings.json"),new string('x',300000)); Check(store.Read<Preferences>("settings.json") == null, "oversized settings accepted");
 var stats = new SummaryBook([new("not-a-date",123),new("2026-01-01",double.NaN)]); Check(stats.Days.Count == 0, "invalid summaries");
 for(int i=0;i<120;i++)stats.Record(new DateOnly(2026,1,1).AddDays(i),new(BreakKind.None,1,0,BreakKind.None,0),false);
 Check(stats.Days.Count == 90, "retention"); stats.Clear(); Check(stats.Days.Count == 0, "delete summaries");
} finally { Directory.Delete(temp,true); }
var soak = Fresh(); for(int t=0;t<=28800;t++) { soak.Tick(new(t, t%900>=750?t%900-750:0)); if(soak.Reminder!=BreakKind.None)soak.Snooze(); }
Check(double.IsFinite(soak.Eyes.Remaining) && double.IsFinite(soak.Movement.Remaining), "8h schedule invalid");
Console.WriteLine($"PASS: {passed} assertions; scheduler, snooze, activity, privacy storage and 8h simulation.");
