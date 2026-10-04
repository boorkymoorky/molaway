using System.Text.Json;

namespace Molaway.Core;

/// Bounded local JSON; no polymorphic deserialization, imports, account or telemetry.
public sealed class LocalStore(string directory)
{
    public string? Error { get; private set; }
    private static readonly JsonSerializerOptions Json = new() { WriteIndented = true, MaxDepth = 8 };
    private void CheckDirectory() {
        var current = new DirectoryInfo(Path.GetFullPath(directory));
        for (var part = current; part is not null; part = part.Parent)
            if (part.Exists && part.Attributes.HasFlag(FileAttributes.ReparsePoint)) throw new IOException("Linked data path refused.");
        Directory.CreateDirectory(current.FullName);
    }
    private string Target(string name) {
        if (name is not ("settings.json" or "statistics.json")) throw new ArgumentException("Unknown local file.");
        CheckDirectory(); var path = Path.Combine(directory, name);
        if (File.Exists(path) && File.GetAttributes(path).HasFlag(FileAttributes.ReparsePoint)) throw new IOException("Linked data file refused.");
        return path;
    }
    public T? Read<T>(string name, int maxBytes = 262144) {
        try {
            string path = Target(name); if (!File.Exists(path)) return default;
            using var stream = new FileStream(path, FileMode.Open, FileAccess.Read, FileShare.Read);
            if (stream.Length > maxBytes) throw new IOException("Local file exceeds size limit.");
            return JsonSerializer.Deserialize<T>(stream, Json);
        } catch (Exception e) when (e is IOException or UnauthorizedAccessException or JsonException or NotSupportedException) {
            Error = "Local data could not be read. Defaults are being used."; return default;
        }
    }
    public bool Write<T>(string name, T data) {
        string? temp = null;
        try {
            string path = Target(name); var bytes = JsonSerializer.SerializeToUtf8Bytes(data, Json);
            if (bytes.Length > 262144) throw new IOException("Local file exceeds size limit.");
            temp = Path.Combine(directory, ".write-" + Guid.NewGuid().ToString("N"));
            using (var stream = new FileStream(temp, FileMode.CreateNew, FileAccess.Write, FileShare.None)) { stream.Write(bytes); stream.Flush(true); }
            _ = Target(name); File.Move(temp, path, true); Error = null; return true;
        } catch (Exception e) when (e is IOException or UnauthorizedAccessException or JsonException or NotSupportedException) {
            Error = "Local data could not be saved."; return false;
        } finally { if (temp is not null) try { File.Delete(temp); } catch (IOException) { } catch (UnauthorizedAccessException) { } }
    }
    public void DeleteStatistics() {
        try { File.Delete(Target("statistics.json")); Error = null; }
        catch (Exception e) when (e is IOException or UnauthorizedAccessException) { Error = "Local summaries could not be deleted."; }
    }
}

public sealed record DaySummary(string Date, double ActiveSeconds = 0, int Breaks = 0, double GuidedRestSeconds = 0, double MediaSeconds = 0);
public sealed class SummaryBook
{
    private readonly Dictionary<string, DaySummary> days = [];
    public IReadOnlyList<DaySummary> Days => days.Values.OrderBy(x => x.Date, StringComparer.Ordinal).ToList();
    public SummaryBook(IEnumerable<DaySummary>? saved = null) {
        foreach (var day in saved ?? []) {
            if (days.Count >= 90) break;
            if (!DateOnly.TryParseExact(day.Date, "yyyy-MM-dd", System.Globalization.CultureInfo.InvariantCulture, System.Globalization.DateTimeStyles.None, out _)) continue;
            if (!double.IsFinite(day.ActiveSeconds) || !double.IsFinite(day.GuidedRestSeconds) || !double.IsFinite(day.MediaSeconds)) continue;
            days[day.Date] = day with { ActiveSeconds = Math.Clamp(day.ActiveSeconds, 0, 86400), Breaks = Math.Clamp(day.Breaks, 0, 10000), GuidedRestSeconds = Math.Clamp(day.GuidedRestSeconds, 0, 86400), MediaSeconds = Math.Clamp(day.MediaSeconds, 0, 86400) };
        }
    }
    public void Record(DateOnly date, TickResult result, bool media) {
        string key = date.ToString("yyyy-MM-dd", System.Globalization.CultureInfo.InvariantCulture);
        var day = days.GetValueOrDefault(key) ?? new DaySummary(key);
        days[key] = day with {
            ActiveSeconds = Math.Clamp(day.ActiveSeconds + result.ActiveSeconds - result.Rollback, 0, 86400),
            Breaks = Math.Min(10000, day.Breaks + (result.Completed == BreakKind.None ? 0 : 1)),
            GuidedRestSeconds = Math.Clamp(day.GuidedRestSeconds + result.RestSeconds, 0, 86400),
            MediaSeconds = Math.Clamp(day.MediaSeconds + (media ? result.ActiveSeconds : 0), 0, 86400)
        };
        foreach (var old in days.Keys.Where(x => StringComparer.Ordinal.Compare(x, date.AddDays(-89).ToString("yyyy-MM-dd")) < 0).ToArray()) days.Remove(old);
    }
    public void Clear() => days.Clear();
}
