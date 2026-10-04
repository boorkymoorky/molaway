namespace Molaway.Core;

public enum AlertStyle { Banner, Card, FullScreen, System }
public enum DisplayTarget { Cursor, Primary, All }
public enum AppLanguage { System, English, Turkish }
public enum AppTheme { System, Light, Dark }
public enum Tone { None, Asterisk, Beep, Exclamation }

public sealed record Preferences
{
    public int EyeMinutes { get; init; } = 20;
    public int EyeRestSeconds { get; init; } = 20;
    public int MovementMinutes { get; init; } = 40;
    public int MovementRestSeconds { get; init; } = 120;
    public int IdleSeconds { get; init; } = 120;
    public int WatchingMinutes { get; init; } = 60;
    public bool MediaEnabled { get; init; } = true;
    public bool RespectQuietState { get; init; } = true;
    public bool StatisticsEnabled { get; init; }
    public bool MergeBreaks { get; init; } = true;
    public AlertStyle Style { get; init; } = AlertStyle.Banner;
    public DisplayTarget Display { get; init; } = DisplayTarget.Cursor;
    public AppLanguage Language { get; init; } = AppLanguage.System;
    public AppTheme Theme { get; init; } = AppTheme.System;
    public Tone Sound { get; init; } = Tone.None;
    public double Opacity { get; init; } = .96;

    public Preferences Validate() => this with {
        EyeMinutes = Math.Clamp(EyeMinutes, 1, 180), EyeRestSeconds = Math.Clamp(EyeRestSeconds, 5, 600),
        MovementMinutes = Math.Clamp(MovementMinutes, 1, 240), MovementRestSeconds = Math.Clamp(MovementRestSeconds, 15, 900),
        IdleSeconds = Math.Clamp(IdleSeconds, 15, 600), WatchingMinutes = Math.Clamp(WatchingMinutes, 5, 240),
        Style = Enum.IsDefined(Style) ? Style : AlertStyle.Banner,
        Display = Enum.IsDefined(Display) ? Display : DisplayTarget.Cursor,
        Language = Enum.IsDefined(Language) ? Language : AppLanguage.System,
        Theme = Enum.IsDefined(Theme) ? Theme : AppTheme.System,
        Sound = Enum.IsDefined(Sound) ? Sound : Tone.None,
        Opacity = double.IsFinite(Opacity) ? Math.Clamp(Opacity, .7, 1) : .96
    };
}
