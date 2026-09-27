namespace Molaway.Core;

[Flags] public enum BreakKind { None = 0, Eyes = 1, Movement = 2, Both = 3 }
public enum Activity { Waiting, Active, Media, Away, Paused, Sleeping, Resting }
public readonly record struct Sample(double Now, double Idle, bool Media = false, bool Locked = false, bool Quiet = false);
public readonly record struct TickResult(BreakKind Alert, double ActiveSeconds, double Rollback, BreakKind Completed, double RestSeconds);

public sealed class BreakTimer(BreakKind kind)
{
    public BreakKind Kind { get; } = kind;
    public double Work { get; private set; }
    public double Interval { get; internal set; }
    public double RestTarget { get; internal set; }
    public int Deferrals { get; private set; }
    private double next;
    public double Remaining => Math.Max(0, Math.Max(Interval, next) - Work);
    public double Progress => Math.Clamp(Work / Math.Max(1, Interval), 0, 1);
    public bool Overdue => Work - Interval >= 1200 && Deferrals >= 3;
    internal void Advance(double seconds) => Work += seconds;
    internal void Rollback(double seconds) => Work = Math.Max(0, Work - seconds);
    internal void Defer(double seconds, bool explicitAction = false) {
        next = Work + Math.Max(seconds, Remaining);
        if (explicitAction) Deferrals = Math.Min(1000, Deferrals + 1);
    }
    internal void Reset() { Work = next = 0; Deferrals = 0; }
}

/// Monotonic, deterministic scheduler. No operating-system or data-collection APIs.
public sealed class Scheduler
{
    public BreakTimer Eyes { get; } = new(BreakKind.Eyes);
    public BreakTimer Movement { get; } = new(BreakKind.Movement);
    public Preferences Settings { get; private set; }
    public Activity State { get; private set; } = Activity.Waiting;
    public bool Paused { get; private set; }
    public double WatchingUntil { get; private set; }
    public double QuietUntil { get; private set; }
    public BreakKind Reminder { get; private set; }
    public BreakKind Resting { get; private set; }
    public double RestRemaining => Math.Max(0, restTarget - restElapsed);
    public bool IsWatching(double now) => WatchingUntil > now;
    private double? last, lastMedia, lockStart;
    private double lastIdle, provisional, restElapsed, restTarget, restStarted, graceUntil;
    private bool started, wasQuiet;
    private BreakKind credited;
    public IEnumerable<BreakTimer> Timers { get { yield return Eyes; yield return Movement; } }
    public Scheduler(Preferences? settings = null) { Settings = (settings ?? new()).Validate(); Apply(Settings); }
    public void Apply(Preferences settings) {
        Settings = settings.Validate();
        Eyes.Interval = Settings.EyeMinutes * 60; Eyes.RestTarget = Settings.EyeRestSeconds;
        Movement.Interval = Settings.MovementMinutes * 60; Movement.RestTarget = Settings.MovementRestSeconds;
    }
    public void TogglePause() { Paused = !Paused; Reminder = BreakKind.None; provisional = 0; if (Resting != BreakKind.None) Continue(false); }
    public void ToggleWatching(double now) => WatchingUntil = IsWatching(now) ? 0 : now + Settings.WatchingMinutes * 60;
    public void ToggleQuiet(double now) => QuietUntil = QuietUntil > now ? 0 : now + 1800;
    public void Dismiss() => Reminder = BreakKind.None;
    public void Snooze() {
        if (Reminder == BreakKind.None) return;
        foreach (var timer in Timers) timer.Defer(300, Reminder.HasFlag(timer.Kind));
        Reminder = BreakKind.None;
    }
    public void StartRest(BreakKind kind, double now) {
        if (kind is not (BreakKind.Eyes or BreakKind.Movement or BreakKind.Both)) return;
        Resting = kind; restTarget = kind.HasFlag(BreakKind.Movement) ? Movement.RestTarget : Eyes.RestTarget;
        restElapsed = 0; restStarted = now; provisional = 0; Reminder = BreakKind.None; State = Activity.Resting;
    }
    public void Continue(bool restart = true) {
        foreach (var timer in Timers) {
            if (restart && Resting.HasFlag(timer.Kind)) timer.Reset();
            else if (Resting.HasFlag(timer.Kind)) timer.Defer(300);
        }
        Resting = BreakKind.None; restElapsed = restTarget = 0; provisional = 0; State = Activity.Active;
    }
    private BreakKind Credit(double seconds) {
        BreakKind complete = BreakKind.None;
        foreach (var timer in Timers) if (seconds >= timer.RestTarget && !credited.HasFlag(timer.Kind)) {
            bool hadWork = timer.Work > 0;
            timer.Reset(); credited |= timer.Kind; Reminder &= ~timer.Kind;
            if (hadWork) complete |= timer.Kind;
        }
        return complete;
    }
    public TickResult Tick(Sample sample) {
        if (!double.IsFinite(sample.Now) || !double.IsFinite(sample.Idle) || sample.Idle < 0) {
            last = null; State = Activity.Waiting; Reminder = BreakKind.None; return default;
        }
        double raw = last.HasValue ? sample.Now - last.Value : 0;
        double delta = raw is >= 0 and <= 5 ? raw : 0;
        last = sample.Now;
        bool media = Settings.MediaEnabled && sample.Media || IsWatching(sample.Now);
        bool quiet = sample.Quiet && Settings.RespectQuietState || QuietUntil > sample.Now;
        if (quiet) { wasQuiet = true; Reminder = BreakKind.None; }
        else if (wasQuiet) { wasQuiet = false; graceUntil = sample.Now + 60; }
        if (media) lastMedia = sample.Now;
        double idle = media ? 0 : Math.Min(sample.Idle, lastMedia.HasValue ? Math.Max(0, sample.Now - lastMedia.Value) : sample.Idle);
        BreakKind complete = BreakKind.None;
        if (sample.Locked) {
            lockStart ??= sample.Now;
            if (Resting != BreakKind.None) Continue(false);
            complete = Credit(sample.Now - lockStart.Value);
            State = Activity.Sleeping; Reminder = BreakKind.None; provisional = 0;
            return new(BreakKind.None, 0, 0, complete, 0);
        }
        if (lockStart.HasValue) { complete |= Credit(Math.Max(0, sample.Now - lockStart.Value)); lockStart = null; }
        if (State == Activity.Away) complete |= Credit(lastIdle + delta);
        if (Resting != BreakKind.None) {
            restElapsed += delta;
            if (restElapsed >= restTarget) {
                complete |= Credit(restElapsed);
                var duration = restElapsed;
                Resting = BreakKind.None; restTarget = restElapsed = 0; State = Activity.Active; provisional = 0;
                return new(BreakKind.None, 0, 0, complete, duration);
            }
            if (sample.Now - restStarted >= 5 && idle < 1) Continue(false);
            else State = Activity.Resting;
            return default;
        }
        if (!media && idle >= Settings.IdleSeconds) {
            double rollback = provisional;
            foreach (var timer in Timers) timer.Rollback(rollback);
            provisional = 0; lastIdle = idle; complete |= Credit(idle);
            State = Paused ? Activity.Paused : Activity.Away; Reminder = BreakKind.None;
            return new(BreakKind.None, 0, rollback, complete, 0);
        }
        if (Paused) { State = Activity.Paused; Reminder = BreakKind.None; provisional = 0; lastIdle = idle; return new(BreakKind.None, 0, 0, complete, 0); }
        if (media || idle < 2) started = true;
        if (!started) { State = Activity.Waiting; lastIdle = idle; return default; }
        double active = State is Activity.Active or Activity.Media ? delta : 0;
        if (media || idle < lastIdle || idle < 1) provisional = 0; else provisional += active;
        credited = BreakKind.None;
        foreach (var timer in Timers) timer.Advance(active);
        lastIdle = idle; State = media ? Activity.Media : Activity.Active;
        BreakKind due = BreakKind.None;
        if (!quiet && sample.Now >= graceUntil && Reminder == BreakKind.None) {
            foreach (var timer in Timers) if (timer.Remaining <= 0) due |= timer.Kind;
            // Never merge a timer before an explicit snooze ends. Due-only merging
            // avoids shortening a quiet period even after different natural rests.
            if (due != BreakKind.None) {
                if (!Settings.MergeBreaks && due == BreakKind.Both) due = BreakKind.Movement;
                Reminder = due;
                foreach (var timer in Timers) if (due.HasFlag(timer.Kind)) timer.Defer(300);
            }
        }
        return new(due, active, 0, complete, 0);
    }
}
