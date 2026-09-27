using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Windows;
using System.Windows.Automation;
using System.Windows.Controls;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Animation;
using Molaway.Core;
using WpfButton = System.Windows.Controls.Button;

namespace Molaway.Windows;
internal static class Design
{
    internal static readonly Brush Green=new SolidColorBrush(Color.FromRgb(41,145,121));
    internal static readonly Brush Blue=new SolidColorBrush(Color.FromRgb(90,113,206));
    internal static TextBlock Label(string text,double size=14,Brush? color=null) {
        var block=new TextBlock {Text=Text.L(text),FontSize=size,TextWrapping=TextWrapping.Wrap,Margin=new Thickness(0,0,0,8)};
        if(color is not null)block.Foreground=color;
        return block;
    }
    internal static WpfButton Button(string text,Action action,bool accent=false) {
        var b=new WpfButton {Content=Text.L(text),Padding=new Thickness(16,10,16,10),Margin=new Thickness(0,4,8,4),MinHeight=40,BorderThickness=new Thickness(0),Cursor=Cursors.Hand,HorizontalContentAlignment=HorizontalAlignment.Center};
        if(accent){b.Background=Green;b.Foreground=Brushes.White;}
        b.Click+=(_,_)=>action();AutomationProperties.SetName(b,Text.L(text));return b;
    }
    internal static Border Card(UIElement child,Brush? background=null) => new() {Child=child,CornerRadius=new CornerRadius(16),Padding=new Thickness(20),Margin=new Thickness(0,0,12,14),Background=background??new SolidColorBrush(Color.FromArgb(18,120,145,145)),BorderThickness=new Thickness(1),BorderBrush=new SolidColorBrush(Color.FromArgb(30,120,145,145))};
    internal static void Colors(Window w,Preferences p) {
        bool dark=p.Theme==AppTheme.Dark || p.Theme==AppTheme.System && SystemColors.WindowColor.R<100;
        w.Background=SystemParameters.HighContrast?SystemColors.WindowBrush:new SolidColorBrush(dark?Color.FromRgb(24,29,35):Color.FromRgb(246,248,250));
        w.Foreground=SystemParameters.HighContrast?SystemColors.WindowTextBrush:new SolidColorBrush(dark?Color.FromRgb(233,238,241):Color.FromRgb(32,46,55));
        w.FontFamily=new FontFamily("Segoe UI Variable, Segoe UI");w.FontSize=14;
    }
}

internal sealed class Rings : FrameworkElement
{
    private double eyes,movement;
    internal void Set(double e,double m) { if(e==eyes && m==movement)return;eyes=e;movement=m;InvalidateVisual(); }
    protected override void OnRender(DrawingContext dc) {
        base.OnRender(dc);double size=Math.Min(ActualWidth,ActualHeight),cx=ActualWidth/2,cy=ActualHeight/2;
        Draw(dc,new Point(cx,cy),size*.43,eyes,Design.Green);Draw(dc,new Point(cx,cy),size*.30,movement,Design.Blue);
    }
    private static void Draw(DrawingContext dc,Point center,double radius,double progress,Brush brush) {
        if(radius<=0)return;
        var track=new Pen(new SolidColorBrush(Color.FromArgb(35,128,145,150)),5);dc.DrawEllipse(null,track,center,radius,radius);
        double a=Math.Max(.02,Math.Clamp(progress,0,1))*(Math.PI*2-.04)-Math.PI/2;
        var g=new StreamGeometry();using(var c=g.Open()){c.BeginFigure(new Point(center.X,center.Y-radius),false,false);c.ArcTo(new Point(center.X+Math.Cos(a)*radius,center.Y+Math.Sin(a)*radius),new Size(radius,radius),0,progress>.5,SweepDirection.Clockwise,true,false);}
        dc.DrawGeometry(null,new Pen(brush,5){StartLineCap=PenLineCap.Round,EndLineCap=PenLineCap.Round},g);
    }
}

internal sealed class MainWindow : Window
{
    private readonly Controller model;
    private string section="Overview";
    private ContentControl page=new();
    private TextBlock? eyeTime,movementTime,state,message,watchingLabel;
    private Rings? rings;
    private WpfButton? pauseButton;
    internal MainWindow(Controller controller){model=controller;Title="Molaway";Width=900;Height=730;MinWidth=700;MinHeight=520;WindowStartupLocation=WindowStartupLocation.Manual;Rebuild();}
    internal void Rebuild() {
        Design.Colors(this,model.Engine.Settings);
        var root=new Grid();root.ColumnDefinitions.Add(new ColumnDefinition{Width=new GridLength(195)});root.ColumnDefinitions.Add(new ColumnDefinition());
        var nav=new DockPanel{Margin=new Thickness(18,28,10,20)};
        var footer=new StackPanel();footer.Children.Add(Design.Label("Local only · no account, no telemetry",11));footer.Children.Add(Design.Label("Windows 0.1.0-preview.1 · MIT",11));DockPanel.SetDock(footer,Dock.Bottom);nav.Children.Add(footer);
        var links=new StackPanel();var brand=new DockPanel{Margin=new Thickness(4,0,0,28)};var logo=new Rings{Width=36,Height=36,Margin=new Thickness(0,0,6,0)};logo.Set(.85,.72);brand.Children.Add(logo);brand.Children.Add(Design.Label("Molaway",25,Design.Green));links.Children.Add(brand);
        foreach(var name in new[]{"Overview","Settings","Privacy"}) {var button=Design.Button(name,()=>ShowSection(name));button.HorizontalContentAlignment=HorizontalAlignment.Left;button.HorizontalAlignment=HorizontalAlignment.Stretch;button.MinHeight=48;links.Children.Add(button);}nav.Children.Add(links);root.Children.Add(nav);
        page=new ContentControl{Margin=new Thickness(22,28,20,12)};Grid.SetColumn(page,1);root.Children.Add(page);Content=root;ShowSection(section);
    }
    internal void ShowSection(string name) {
        section=name;eyeTime=movementTime=state=message=watchingLabel=null;rings=null;pauseButton=null;
        var content=new StackPanel();content.Children.Add(Design.Label(name,28));
        switch(name){case "Settings":Settings(content);break;case "Privacy":Privacy(content);break;default:Overview(content);break;}
        page.Content=new ScrollViewer{Content=content,VerticalScrollBarVisibility=ScrollBarVisibility.Auto,HorizontalScrollBarVisibility=ScrollBarVisibility.Disabled};Refresh();
    }
    private void Overview(StackPanel body) {
        body.Children.Add(Design.Label("A little space for your eyes and body.",15));
        var header=new DockPanel{Margin=new Thickness(0,15,0,8)};rings=new Rings{Width=100,Height=100,Margin=new Thickness(0,0,20,0)};header.Children.Add(rings);
        var status=new StackPanel{VerticalAlignment=VerticalAlignment.Center};status.Children.Add(Design.Label("Your next pause",19));state=Design.Label("",14);status.Children.Add(state);watchingLabel=Design.Label("",12);status.Children.Add(watchingLabel);header.Children.Add(status);body.Children.Add(header);
        var grid=new Grid();grid.ColumnDefinitions.Add(new ColumnDefinition());grid.ColumnDefinitions.Add(new ColumnDefinition());
        var eyes=new StackPanel();eyes.Children.Add(Design.Label("Eye break · outer ring",13,Design.Green));eyeTime=Design.Label("20:00",36);eyes.Children.Add(eyeTime);eyes.Children.Add(Design.Button("Take an eye break",()=>model.Begin(BreakKind.Eyes)));
        var movement=new StackPanel();movement.Children.Add(Design.Label("Movement break · inner ring",13,Design.Blue));movementTime=Design.Label("40:00",36);movement.Children.Add(movementTime);movement.Children.Add(Design.Button("Take a movement break",()=>model.Begin(BreakKind.Movement)));
        grid.Children.Add(Design.Card(eyes));var right=Design.Card(movement);Grid.SetColumn(right,1);grid.Children.Add(right);body.Children.Add(grid);
        var controls=new WrapPanel();pauseButton=Design.Button("Pause",model.Pause);controls.Children.Add(pauseButton);controls.Children.Add(Design.Button(model.Engine.IsWatching(model.Now)?"End watching":"Watching mode",()=>{model.Watching();ShowSection("Overview");}));controls.Children.Add(Design.Button(model.Engine.QuietUntil>model.Now?"End quiet mode":"Quiet for 30 min",()=>{model.Quiet();ShowSection("Overview");}));body.Children.Add(controls);
        if(model.Engine.Resting!=BreakKind.None)body.Children.Add(Design.Button("Continue",()=>{model.Continue();ShowSection("Overview");},true));
        message=Design.Label("",12);body.Children.Add(message);body.Children.Add(Design.Label("This week",20));
        if(!model.Engine.Settings.StatisticsEnabled){body.Children.Add(Design.Label("Summaries are off. Enable them in Settings."));return;}
        var days=model.Summaries.Days.Where(x=>DateOnly.ParseExact(x.Date,"yyyy-MM-dd",CultureInfo.InvariantCulture)>=DateOnly.FromDateTime(DateTime.Now).AddDays(-6)).TakeLast(7).ToList();
        if(days.Count==0){body.Children.Add(Design.Label("No recorded activity yet."));return;}
        body.Children.Add(Design.Label("Daily active minutes",12));var bars=new StackPanel();double max=Math.Max(60,days.Max(x=>x.ActiveSeconds));
        foreach(var day in days){var row=new Grid{Margin=new Thickness(0,3,12,3)};row.ColumnDefinitions.Add(new ColumnDefinition{Width=new GridLength(72)});row.ColumnDefinitions.Add(new ColumnDefinition());row.ColumnDefinitions.Add(new ColumnDefinition{Width=new GridLength(56)});
            row.Children.Add(Design.Label(day.Date[5..],12));var bg=new Border{Background=Design.Green,CornerRadius=new CornerRadius(4),Height=13,HorizontalAlignment=HorizontalAlignment.Left,Width=250*day.ActiveSeconds/max};Grid.SetColumn(bg,1);row.Children.Add(bg);var value=Design.Label(Math.Round(day.ActiveSeconds/60).ToString(CultureInfo.CurrentCulture),12);Grid.SetColumn(value,2);row.Children.Add(value);bars.Children.Add(row);}
        body.Children.Add(Design.Card(bars));
    }
    private void Settings(StackPanel body) {
        var p=model.Engine.Settings;var numbers=new Dictionary<string,TextBox>();
        void Number(string name,int value,int min,int max){var row=new Grid{Margin=new Thickness(0,5,14,5)};row.ColumnDefinitions.Add(new ColumnDefinition());row.ColumnDefinitions.Add(new ColumnDefinition{Width=new GridLength(100)});row.Children.Add(Design.Label(name));var box=new TextBox{Text=value.ToString(CultureInfo.InvariantCulture),Padding=new Thickness(8),Tag=(min,max),ToolTip=$"{min}–{max}"};AutomationProperties.SetName(box,Text.L(name));Grid.SetColumn(box,1);row.Children.Add(box);numbers[name]=box;body.Children.Add(row);}
        Number("Eye interval (min)",p.EyeMinutes,1,180);Number("Eye rest (sec)",p.EyeRestSeconds,5,600);Number("Movement interval (min)",p.MovementMinutes,1,240);Number("Movement rest (sec)",p.MovementRestSeconds,15,900);Number("Idle threshold (sec)",p.IdleSeconds,15,600);Number("Watching duration (min)",p.WatchingMinutes,5,240);
        body.Children.Add(Design.Label("Permissions: no elevation, keyboard capture or screen recording. Only elapsed input time and playback status are read.",12));
        CheckBox Check(string label,bool enabled){var c=new CheckBox{Content=Text.L(label),IsChecked=enabled,Margin=new Thickness(0,8,0,8)};body.Children.Add(c);return c;}
        var media=Check("Count supported media playback",p.MediaEnabled);var quiet=Check("Respect Windows notification availability",p.RespectQuietState);var stats=Check("Keep local daily summaries",p.StatisticsEnabled);var merge=Check("Combine simultaneous breaks",p.MergeBreaks);
        ComboBox Select<T>(string label,T value) where T:struct,Enum {body.Children.Add(Design.Label(label));var box=new ComboBox{Margin=new Thickness(0,0,14,12),MinHeight=34,ItemsSource=Enum.GetValues<T>().Select(x=>new KeyValuePair<T,string>(x,Text.L(x.ToString()))).ToArray(),DisplayMemberPath="Value",SelectedValuePath="Key",SelectedValue=value};AutomationProperties.SetName(box,Text.L(label));body.Children.Add(box);return box;}
        var style=Select("Alert style",p.Style);var display=Select("Display",p.Display);var language=Select("Language",p.Language);var theme=Select("Theme",p.Theme);var sound=Select("Sound",p.Sound);
        body.Children.Add(Design.Label("Opacity"));var opacity=new Slider{Minimum=.7,Maximum=1,Value=p.Opacity,TickFrequency=.05,IsSnapToTickEnabled=true,Margin=new Thickness(0,0,20,12)};AutomationProperties.SetName(opacity,Text.L("Opacity"));body.Children.Add(opacity);
        message=Design.Label("",12);body.Children.Add(message);
        body.Children.Add(Design.Button("Save settings",()=>{
            var values=new Dictionary<string,int>();foreach(var (key,box) in numbers){var (min,max)=((int,int))box.Tag;if(!int.TryParse(box.Text,out int n)||n<min||n>max){Status(Text.L("Enter whole numbers in the shown ranges."));box.Focus();return;}values[key]=n;}
            model.Save(p with {EyeMinutes=values["Eye interval (min)"],EyeRestSeconds=values["Eye rest (sec)"],MovementMinutes=values["Movement interval (min)"],MovementRestSeconds=values["Movement rest (sec)"],IdleSeconds=values["Idle threshold (sec)"],WatchingMinutes=values["Watching duration (min)"],MediaEnabled=media.IsChecked==true,RespectQuietState=quiet.IsChecked==true,StatisticsEnabled=stats.IsChecked==true,MergeBreaks=merge.IsChecked==true,Style=(AlertStyle)style.SelectedValue,Display=(DisplayTarget)display.SelectedValue,Language=(AppLanguage)language.SelectedValue,Theme=(AppTheme)theme.SelectedValue,Sound=(Tone)sound.SelectedValue,Opacity=opacity.Value});
        },true));body.Children.Add(Design.Button("Preview alert",()=>model.ShowAlert(true)));
        body.Children.Add(Design.Label("Windows quiet-state support is limited. Camera/meeting detection is not available in this preview.",12));
    }
    private void Privacy(StackPanel body) {
        body.Children.Add(Design.Card(Design.Label("Local files: settings and optional daily totals. No keystrokes, screenshots, media titles, URLs or app history are stored.",16)));
        body.Children.Add(Design.Label("Permissions: no elevation, keyboard capture or screen recording. Only elapsed input time and playback status are read."));
        body.Children.Add(Design.Label("Offline implementation; this Windows preview has no OS-enforced network sandbox."));
        body.Children.Add(Design.Label("Windows quiet-state support is limited. Camera/meeting detection is not available in this preview."));
        body.Children.Add(Design.Button("Delete summaries",()=>{if(MessageBox.Show(this,Text.L("Delete local summaries? This cannot be undone."),"Molaway",MessageBoxButton.YesNo,MessageBoxImage.Question)==MessageBoxResult.Yes){model.Summaries.Clear();model.Store.DeleteStatistics();}}));
        body.Children.Add(Design.Label("Windows preview · not yet validated for daily use",12));
        body.Children.Add(Design.Label("Burak Yelkenci · ChatGPT/Codex\nBased on Offscreen by Dayo Akinkuowo · MIT",12));
    }
    internal void SessionChanged() { if(section=="Overview")ShowSection(section); }
    internal void Status(string text){if(message is not null)message.Text=text;}
    internal void Refresh() {
        if(section!="Overview")return;var e=model.Engine;
        if(eyeTime is not null)eyeTime.Text=Text.Clock(e.Resting.HasFlag(BreakKind.Eyes)?e.RestRemaining:e.Eyes.Remaining);
        if(movementTime is not null)movementTime.Text=Text.Clock(e.Resting.HasFlag(BreakKind.Movement)?e.RestRemaining:e.Movement.Remaining);
        if(state is not null)state.Text=Text.State(e.State);rings?.Set(e.Eyes.Progress,e.Movement.Progress);
        if(pauseButton is not null)pauseButton.Content=Text.L(e.Paused?"Resume":"Pause");
        if(watchingLabel is not null)watchingLabel.Text=e.IsWatching(model.Now)?Text.L("Watching mode")+" · "+Text.Clock(e.WatchingUntil-model.Now):e.QuietUntil>model.Now?Text.L("Quiet for 30 min")+" · "+Text.Clock(e.QuietUntil-model.Now):"";
        Status(!model.InputAvailable?Text.L("Input status unavailable; timers are paused."):model.Store.Error is not null?Text.L("Local storage unavailable. Settings may not be saved."):e.Settings.MediaEnabled&&!model.Media.Available?Text.L("Media status unavailable. Use watching mode."):"");
    }
}

internal sealed class AlertWindow : Window
{
    private readonly Controller model;
    private readonly bool preview;
    private readonly TextBlock time;
    internal AlertWindow(Controller controller,bool isPreview,AlertStyle style) {
        model=controller;preview=isPreview;Title="Molaway";Width=480;SizeToContent=SizeToContent.Height;MaxHeight=700;WindowStyle=WindowStyle.None;ResizeMode=ResizeMode.NoResize;ShowInTaskbar=false;ShowActivated=false;Topmost=true;
        Design.Colors(this,model.Engine.Settings);Opacity=SystemParameters.HighContrast?1:model.Engine.Settings.Opacity;
        var kind=model.Engine.Resting!=BreakKind.None?model.Engine.Resting:model.Engine.Reminder;
        var body=new StackPanel{Margin=new Thickness(28)};body.Children.Add(Design.Label(preview?"Preview · your timers are unchanged":Text.Kind(kind),22));
        body.Children.Add(Design.Label(model.Engine.Eyes.Overdue||model.Engine.Movement.Overdue?"You have postponed several breaks. Make some time to rest.":kind.HasFlag(BreakKind.Movement)?"Stand up and move a little.":"Look away and relax your eyes.",15));
        time=Design.Label("",32);body.Children.Add(time);var buttons=new WrapPanel();
        if(preview)buttons.Children.Add(Design.Button("Close",model.CloseAlerts));
        else if(model.Engine.Resting!=BreakKind.None)buttons.Children.Add(Design.Button("Continue",model.Continue,true));
        else {buttons.Children.Add(Design.Button("Take a break",()=>model.Begin(kind),true));buttons.Children.Add(Design.Button("Snooze 5 min",model.Snooze));buttons.Children.Add(Design.Button("Close",model.Dismiss));}
        body.Children.Add(buttons);if(!preview&&model.Engine.Resting==BreakKind.None)body.Children.Add(Design.Label("Snooze quiets both reminders for 5 active minutes.",12));
        var scroll=new ScrollViewer{Content=body,VerticalScrollBarVisibility=ScrollBarVisibility.Auto};
        if(style==AlertStyle.FullScreen){SizeToContent=SizeToContent.Manual;MaxHeight=double.PositiveInfinity;Height=900;var grid=new Grid();scroll.Width=480;scroll.VerticalAlignment=VerticalAlignment.Center;grid.Children.Add(scroll);Content=grid;}
        else Content=new Border{CornerRadius=new CornerRadius(18),BorderBrush=Design.Green,BorderThickness=new Thickness(1),Child=scroll};
        KeyDown+=(_,e)=>{if(e.Key==Key.Escape){if(preview)model.CloseAlerts();else model.Dismiss();}};
        if(!SystemParameters.HighContrast&&SystemParameters.ClientAreaAnimation)Loaded+=(_,_)=>BeginAnimation(OpacityProperty,new DoubleAnimation(0,Opacity,TimeSpan.FromMilliseconds(160)));
        Refresh();
    }
    internal void Refresh(){time.Text=!preview&&model.Engine.Resting!=BreakKind.None?Text.Clock(model.Engine.RestRemaining):"";}
}
