using System;
using System.Linq;
using System.Runtime.InteropServices;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Interop;
using Windows.Media.Control;
using Forms = System.Windows.Forms;
using Drawing = System.Drawing;

[assembly: DefaultDllImportSearchPaths(DllImportSearchPath.System32)]
namespace Molaway.Windows;

internal static class Platform
{
    [StructLayout(LayoutKind.Sequential)] private struct LastInput { public uint Size; public uint Time; }
    [DllImport("user32.dll", ExactSpelling = true)] private static extern bool GetLastInputInfo(ref LastInput input);
    [DllImport("shell32.dll", ExactSpelling = true)] private static extern int SHQueryUserNotificationState(out int state);
    [DllImport("user32.dll", ExactSpelling = true)] private static extern uint GetDpiForWindow(IntPtr handle);
    [DllImport("user32.dll", ExactSpelling = true)] private static extern bool SetWindowPos(IntPtr handle, IntPtr insertAfter, int x, int y, int cx, int cy, uint flags);
    [DllImport("user32.dll", ExactSpelling = true)] internal static extern bool DestroyIcon(IntPtr icon);
    internal static double IdleSeconds() {
        var value = new LastInput { Size = (uint)Marshal.SizeOf<LastInput>() };
        return GetLastInputInfo(ref value) ? unchecked((uint)Environment.TickCount - value.Time) / 1000.0 : double.NaN;
    }
    internal static bool Quiet() => SHQueryUserNotificationState(out int state) != 0 || state != 5;
    internal static Forms.Screen CursorScreen => Forms.Screen.FromPoint(Forms.Cursor.Position);
    internal static void Position(Window window, Forms.Screen screen, Core.AlertStyle style = Core.AlertStyle.Card, bool settings = false) {
        var handle = new WindowInteropHelper(window).Handle;
        var r = style == Core.AlertStyle.FullScreen && !settings ? screen.Bounds : screen.WorkingArea;
        const uint flags = 0x0010 | 0x0004; // no activation, no Z-order changes
        // First move to the destination monitor so WPF receives its DPI change.
        SetWindowPos(handle, IntPtr.Zero, r.Left, r.Top, 0, 0, flags | 0x0001);
        double scale = Math.Max(96, GetDpiForWindow(handle)) / 96.0;
        int width = (int)Math.Min(r.Width, window.ActualWidth * scale);
        int height = (int)Math.Min(r.Height, window.ActualHeight * scale);
        int gap = (int)(16 * scale);
        int x = r.Left + (r.Width - width) / 2, y = r.Top + gap;
        if (settings) y = r.Top + (r.Height - height) / 2;
        else if (style == Core.AlertStyle.Card) { x = Math.Max(r.Left, r.Right - width - gap); y = Math.Max(r.Top, r.Bottom - height - gap); }
        else if (style == Core.AlertStyle.FullScreen) { x = r.Left; y = r.Top; width = r.Width; height = r.Height; }
        SetWindowPos(handle, IntPtr.Zero, x, y, width, height, flags);
    }
    internal static Drawing.Icon Icon(double eyes = 0, double movement = 0, bool paused = false, bool overdue = false) {
        using var bitmap = new Drawing.Bitmap(32, 32);
        using (var g = Drawing.Graphics.FromImage(bitmap)) {
            g.SmoothingMode = System.Drawing.Drawing2D.SmoothingMode.AntiAlias;
            using var track = new Drawing.Pen(Drawing.Color.FromArgb(125, 145, 155), 2.5f);
            using var outer = new Drawing.Pen(overdue ? Drawing.Color.Tomato : Drawing.Color.FromArgb(105, 218, 187), 2.5f);
            using var inner = new Drawing.Pen(overdue ? Drawing.Color.Tomato : Drawing.Color.FromArgb(133, 166, 248), 2.5f);
            g.DrawArc(track, 3, 3, 26, 26, -90, 320); g.DrawArc(track, 9, 9, 14, 14, -90, 320);
            g.DrawArc(outer, 3, 3, 26, 26, -90, (float)Math.Max(16, eyes * 320));
            g.DrawArc(inner, 9, 9, 14, 14, -90, (float)Math.Max(16, movement * 320));
            if (paused) { g.DrawLine(inner, 14, 13, 14, 19); g.DrawLine(inner, 18, 13, 18, 19); }
        }
        var h = bitmap.GetHicon();
        try { using var raw = Drawing.Icon.FromHandle(h); return (Drawing.Icon)raw.Clone(); }
        finally { DestroyIcon(h); }
    }
}

internal sealed class MediaSignal
{
    private GlobalSystemMediaTransportControlsSessionManager? manager;
    private bool attempted;
    internal bool Available { get; private set; } = true;
    internal async Task<bool> ReadAsync() {
        try {
            if (!attempted) { attempted = true; manager = await GlobalSystemMediaTransportControlsSessionManager.RequestAsync().AsTask().WaitAsync(TimeSpan.FromSeconds(3)); }
            if (manager is null) { Available = false; return false; }
            bool playing = manager.GetSessions().Any(x => x.GetPlaybackInfo().PlaybackStatus == GlobalSystemMediaTransportControlsSessionPlaybackStatus.Playing);
            Available = true; return playing;
        } catch (Exception e) when (e is COMException or UnauthorizedAccessException or InvalidOperationException or TimeoutException) {
            Available = false; return false;
        }
    }
}
