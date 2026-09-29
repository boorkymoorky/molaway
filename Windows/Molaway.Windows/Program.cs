using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Media;
using System.Threading;
using System.Windows;
using System.Windows.Threading;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using Microsoft.Win32;
using Molaway.Core;
using Forms = System.Windows.Forms;
using Activity = Molaway.Core.Activity;

namespace Molaway.Windows;
internal static class Program
{
    [STAThread] public static int Main(string[] args) {
        bool smoke = args.Length == 1 && args[0] == "--smoke-test";
        using var mutex = new Mutex(true, "Local\\Molaway.Windows.Preview", out bool first);
        if (!first) return 0;
        var app = new Application { ShutdownMode = ShutdownMode.OnExplicitShutdown };
        using var controller = new Controller(smoke);
        app.Startup += (_,_) => controller.Start();
        return app.Run();
    }
}

internal sealed class Controller : IDisposable
{
    internal Scheduler Engine { get; }
    internal LocalStore Store { get; }
    internal SummaryBook Summaries { get; }
    internal double Now => watch.Elapsed.TotalSeconds;
    internal bool InputAvailable { get; private set; } = true;
    internal MediaSignal Media { get; } = new();
    private readonly Stopwatch watch = Stopwatch.StartNew();
    private readonly DispatcherTimer ticker = new() { Interval = TimeSpan.FromSeconds(1) };
    private readonly Forms.NotifyIcon tray = new();
    private readonly List<AlertWindow> alerts = [];
    private readonly bool smoke;
    private string? smokePath;
    private MainWindow? main;
    private bool locked, suspended, readingMedia, mediaPlaying, disposed;
    private double nextMedia, nextSave, alertExpires;
    private int lastIcon = -1;
    private DispatcherTimer? nativeDismiss;
    private BreakKind nativeReminder;
    internal Controller(bool smokeTest = false) {
        smoke = smokeTest;
        string folder = smoke ? (smokePath = Path.Combine(Path.GetTempPath(), "Molaway-smoke-"+Guid.NewGuid().ToString("N"))) : Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),"Molaway","Windows");
        Store = new(folder); Engine = new(smoke ? new Preferences { Language=AppLanguage.English, Theme=AppTheme.Light, StatisticsEnabled=true } : Store.Read<Preferences>("settings.json")?.Validate());
        Text.Language = Engine.Settings.Language;
        Summaries = new(Store.Read<List<DaySummary>>("statistics.json"));
        if(smoke)for(int i=0;i<7;i++)Summaries.Record(DateOnly.FromDateTime(DateTime.Now).AddDays(i-6),new(BreakKind.None,3600+i*420,0,BreakKind.Eyes,120),false);
    }
    internal void Start() {
        tray.Icon = Platform.Icon(); tray.Text = "Molaway"; tray.Visible = true;
        tray.MouseClick += (_,e) => { if (e.Button == Forms.MouseButtons.Left) Open(); };
        tray.BalloonTipClicked += (_,_) => { if (nativeReminder != BreakKind.None && Engine.Reminder == nativeReminder) ShowAlert(false, Core.AlertStyle.Banner); };
        RebuildMenu();
        if (!smoke) { SystemEvents.SessionSwitch += SessionChanged; SystemEvents.PowerModeChanged += PowerChanged; SystemEvents.DisplaySettingsChanged += DisplaysChanged; }
        ticker.Tick += (_,_) => Tick(); ticker.Start(); Open();
        if (smoke) {
            // Exercise real Windows WPF creation, layout, data binding and native
            // tray setup with synthetic data; never touch the user's preferences.
            foreach(var section in new[]{"Overview","Settings","Privacy"}) { main!.ShowSection(section); SaveView(main,section.ToLowerInvariant()); }
            main!.ShowSection("Overview");
            ShowAlert(true); foreach(var alert in alerts)SaveView(alert,"alert");
            var stop = new DispatcherTimer { Interval = TimeSpan.FromSeconds(2) };
            stop.Tick += (_,_) => { stop.Stop(); CloseAlerts(); Application.Current.Shutdown(0); }; stop.Start();
        }
    }
    private static void SaveView(Window window,string name) {
        window.UpdateLayout();
        var image=new RenderTargetBitmap((int)Math.Ceiling(window.ActualWidth),(int)Math.Ceiling(window.ActualHeight),96,96,PixelFormats.Pbgra32);
        image.Render(window);var encoder=new PngBitmapEncoder();encoder.Frames.Add(BitmapFrame.Create(image));
        string folder=Path.Combine(AppContext.BaseDirectory,"smoke");Directory.CreateDirectory(folder);
        using var output=new FileStream(Path.Combine(folder,name+".png"),FileMode.Create,FileAccess.Write);encoder.Save(output);
    }
    private void DisplaysChanged(object? sender, EventArgs e) => Application.Current.Dispatcher.InvokeAsync(() => {
        if (main?.IsVisible == true) Platform.Position(main,Platform.CursorScreen,settings:true);
        if (alerts.Count > 0) { bool showing = Engine.Reminder != BreakKind.None || Engine.Resting != BreakKind.None; CloseAlerts(); if(showing)ShowAlert(false); }
    });
    private void SessionChanged(object sender, SessionSwitchEventArgs e) => Application.Current.Dispatcher.InvokeAsync(() => {
        if (e.Reason == SessionSwitchReason.SessionLock || e.Reason == SessionSwitchReason.SessionLogoff || e.Reason == SessionSwitchReason.ConsoleDisconnect || e.Reason == SessionSwitchReason.RemoteDisconnect) locked = true;
        if (e.Reason == SessionSwitchReason.SessionUnlock || e.Reason == SessionSwitchReason.ConsoleConnect || e.Reason == SessionSwitchReason.RemoteConnect) locked = false;
        Tick();
    });
    private void PowerChanged(object sender, PowerModeChangedEventArgs e) => Application.Current.Dispatcher.InvokeAsync(() => {
        if (e.Mode == PowerModes.Suspend) suspended = true;
        if (e.Mode == PowerModes.Resume) suspended = false;
        Tick();
    });
    private async void ReadMedia() {
        if (readingMedia) return; readingMedia = true;
        try { mediaPlaying = await Media.ReadAsync(); } finally { readingMedia = false; }
    }
    private void Tick() {
        double now = Now;
        if (!smoke && Engine.Settings.MediaEnabled && now >= nextMedia) { nextMedia = now + 5; ReadMedia(); }
        double idle = smoke ? 0 : Platform.IdleSeconds(); InputAvailable = double.IsFinite(idle);
        bool quiet = !smoke && Platform.Quiet();
        var previousRest = Engine.Resting;
        var result = Engine.Tick(new(now,idle,mediaPlaying,locked || suspended,quiet));
        if (previousRest != BreakKind.None && Engine.Resting == BreakKind.None) { CloseAlerts(); main?.SessionChanged(); }
        if (Engine.Settings.StatisticsEnabled) Summaries.Record(DateOnly.FromDateTime(DateTime.Now),result,Engine.State == Activity.Media);
        if (now >= nextSave) { SaveSummaries(); nextSave = now + 60; }
        if (Engine.State is Activity.Sleeping or Activity.Away or Activity.Paused || quiet && Engine.Settings.RespectQuietState || Engine.QuietUntil > now) CloseAlerts();
        if (result.Alert != BreakKind.None) ShowAlert(false);
        if (result.Completed != BreakKind.None && Engine.Resting == BreakKind.None) CloseAlerts();
        if (alerts.Count > 0 && Engine.Resting == BreakKind.None && now > alertExpires && !alerts.Any(x=>x.IsMouseOver || x.IsKeyboardFocusWithin)) { CloseAlerts(); Engine.Dismiss(); }
        foreach (var alert in alerts) alert.Refresh();
        UpdateTray(); main?.Refresh();
    }
    private void UpdateTray() {
        var e=Engine; int key=(int)(e.Eyes.Progress*40) + (int)(e.Movement.Progress*40)*100 + (e.Paused?10000:0) + (e.Eyes.Overdue||e.Movement.Overdue?20000:0);
        if (key != lastIcon) { var old=tray.Icon; tray.Icon=Platform.Icon(e.Eyes.Progress,e.Movement.Progress,e.Paused,e.Eyes.Overdue||e.Movement.Overdue); old?.Dispose(); lastIcon=key; }
        string suffix=e.Resting!=BreakKind.None ? Text.L("Enjoy your break")+" "+Text.Clock(e.RestRemaining) : Text.State(e.State);
        string info="Molaway · "+suffix; tray.Text=info.Length>63?info[..63]:info;
    }
    internal void Open() {
        var screen=Platform.CursorScreen;
        if(main is null) { main=new(this); main.Closed+=(_,_)=>main=null; }
        main.Show(); main.UpdateLayout(); Platform.Position(main,screen,settings:true); main.Activate();
    }
    internal void Save(Preferences p) {
        if(!Store.Write("settings.json",p.Validate())) { main?.Status(Text.L("Local storage unavailable. Settings may not be saved.")); return; }
        Engine.Apply(p); Text.Language=Engine.Settings.Language; mediaPlaying=false; nextMedia=0;
        RebuildMenu(); CloseAlerts(); Engine.Dismiss(); main?.Rebuild();
    }
    private void RebuildMenu() {
        var menu=new Forms.ContextMenuStrip();
        menu.Items.Add("Molaway",null,(_,_)=>Open());
        menu.Items.Add(Text.L("Take an eye break"),null,(_,_)=>Begin(BreakKind.Eyes));
        menu.Items.Add(Text.L("Take a movement break"),null,(_,_)=>Begin(BreakKind.Movement));
        menu.Items.Add(Text.L(Engine.Paused?"Resume":"Pause"),null,(_,_)=>Pause());
        menu.Items.Add(Text.L(Engine.IsWatching(Now)?"End watching":"Watching mode"),null,(_,_)=>Watching());
        menu.Items.Add(Text.L(Engine.QuietUntil>Now?"End quiet mode":"Quiet for 30 min"),null,(_,_)=>Quiet());
        menu.Items.Add(new Forms.ToolStripSeparator()); menu.Items.Add(Text.L("Exit"),null,(_,_)=>Application.Current.Shutdown());
        var old=tray.ContextMenuStrip; tray.ContextMenuStrip=menu; old?.Dispose();
    }
    internal void Pause() { Engine.TogglePause(); CloseAlerts(); RebuildMenu(); main?.Refresh(); }
    internal void Watching() { Engine.ToggleWatching(Now); RebuildMenu(); main?.Refresh(); }
    internal void Quiet() { Engine.ToggleQuiet(Now); CloseAlerts(); RebuildMenu(); main?.Refresh(); }
    internal void Begin(BreakKind kind) { Engine.StartRest(kind,Now); ShowAlert(false,Engine.Settings.Style==AlertStyle.System?AlertStyle.Card:null); main?.SessionChanged(); }
    internal void Continue() { Engine.Continue(); CloseAlerts(); main?.SessionChanged(); }
    internal void Snooze() { Engine.Snooze(); CloseAlerts(); main?.Refresh(); }
    internal void Dismiss() { Engine.Dismiss(); CloseAlerts(); }
    internal void CloseAlerts() { nativeDismiss?.Stop(); nativeDismiss=null; nativeReminder=BreakKind.None; foreach(var window in alerts.ToArray()) window.Close(); alerts.Clear(); }
    internal void ShowAlert(bool preview, AlertStyle? overrideStyle=null) {
        CloseAlerts(); var p=Engine.Settings; var style=overrideStyle??p.Style;
        if(style==AlertStyle.System && !preview && Engine.Resting==BreakKind.None) {
            tray.ShowBalloonTip(10000,Text.Kind(Engine.Reminder),Text.L("Snooze quiets both reminders for 5 active minutes.")+" · Molaway",Forms.ToolTipIcon.Info);
            // OS owns balloon lifetime. Let the engine schedule its next reminder.
            nativeReminder=Engine.Reminder;
            nativeDismiss=new DispatcherTimer { Interval=TimeSpan.FromSeconds(15) };
            nativeDismiss.Tick+=(_,_)=>{nativeDismiss?.Stop(); if(Engine.Reminder==nativeReminder)Engine.Dismiss();nativeReminder=BreakKind.None;};
            nativeDismiss.Start(); return;
        }
        var screens=p.Display==DisplayTarget.All?Forms.Screen.AllScreens:[p.Display==DisplayTarget.Primary?Forms.Screen.PrimaryScreen??Platform.CursorScreen:Platform.CursorScreen];
        foreach(var screen in screens) {
            var window=new AlertWindow(this,preview,style); alerts.Add(window); window.Show(); window.UpdateLayout(); Platform.Position(window,screen,style);
        }
        alertExpires=Now+15;
        if(!preview && !Platform.Quiet()) switch(p.Sound) { case Tone.Asterisk:SystemSounds.Asterisk.Play();break;case Tone.Beep:SystemSounds.Beep.Play();break;case Tone.Exclamation:SystemSounds.Exclamation.Play();break; }
    }
    private void SaveSummaries() { if(Engine.Settings.StatisticsEnabled)Store.Write("statistics.json",Summaries.Days); }
    public void Dispose() {
        if(disposed)return;disposed=true; ticker.Stop(); CloseAlerts(); SaveSummaries();
        if(!smoke) { SystemEvents.SessionSwitch-=SessionChanged;SystemEvents.PowerModeChanged-=PowerChanged;SystemEvents.DisplaySettingsChanged-=DisplaysChanged; }
        tray.Visible=false;tray.Icon?.Dispose();tray.ContextMenuStrip?.Dispose();tray.Dispose();
        if(smokePath is not null)try{Directory.Delete(smokePath,true);}catch(IOException){}catch(UnauthorizedAccessException){}
    }
}
