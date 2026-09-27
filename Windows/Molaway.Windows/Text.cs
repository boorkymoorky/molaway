using System.Collections.Generic;
using System.Globalization;
using Molaway.Core;
namespace Molaway.Windows;
internal static class Text
{
    internal static AppLanguage Language { get; set; }
    private static bool Turkish => Language == AppLanguage.Turkish || Language == AppLanguage.System && CultureInfo.CurrentUICulture.TwoLetterISOLanguageName == "tr";
    private static readonly Dictionary<string,string> Translations = new() {
        ["Overview"]="Genel bakış",["Settings"]="Ayarlar",["Privacy"]="Gizlilik",["Your next pause"]="Sıradaki molan",
        ["A little space for your eyes and body."]="Gözlerin ve bedenin için küçük bir ara.",["Eye break · outer ring"]="Göz molası · dış halka",["Movement break · inner ring"]="Hareket molası · iç halka",
        ["Take an eye break"]="Göz molası ver",["Take a movement break"]="Hareket molası ver",["Pause"]="Duraklat",["Resume"]="Devam et",["Watching mode"]="İzleme modu",["End watching"]="İzlemeyi bitir",["Quiet for 30 min"]="30 dk sessiz",["End quiet mode"]="Sessiz modu bitir",
        ["Eye interval (min)"]="Göz aralığı (dk)",["Eye rest (sec)"]="Göz molası (sn)",["Movement interval (min)"]="Hareket aralığı (dk)",["Movement rest (sec)"]="Hareket molası (sn)",["Idle threshold (sec)"]="Hareketsizlik eşiği (sn)",["Watching duration (min)"]="İzleme süresi (dk)",
        ["Count supported media playback"]="Desteklenen medya oynatımını say",["Respect Windows notification availability"]="Windows bildirim uygunluğunu dikkate al",["Keep local daily summaries"]="Yerel günlük özetleri tut",["Combine simultaneous breaks"]="Aynı anda gelen molaları birleştir",
        ["Alert style"]="Uyarı biçimi",["Display"]="Ekran",["Language"]="Dil",["Theme"]="Tema",["Sound"]="Ses",["Opacity"]="Opaklık",["Save settings"]="Ayarları kaydet",["Preview alert"]="Uyarıyı dene",["Saved"]="Kaydedildi",["Enter whole numbers in the shown ranges."]="Gösterilen aralıklarda tam sayı gir.",
        ["Banner"]="Üst panel",["Card"]="Küçük kart",["FullScreen"]="Tam ekran",["System"]="Sistem",["Cursor"]="İmlecin ekranı",["Primary"]="Ana ekran",["All"]="Tüm ekranlar",["English"]="İngilizce",["Turkish"]="Türkçe",["Light"]="Açık",["Dark"]="Koyu",["None"]="Yok",["Asterisk"]="Bilgi",["Beep"]="Bip",["Exclamation"]="Uyarı",
        ["Waiting for activity"]="Etkinlik bekleniyor",["Tracking automatically"]="Otomatik takip açık",["Media · timers running"]="Medya · sayaçlar işliyor",["Away · paused automatically"]="Uzakta · otomatik duraklatıldı",["Timers paused"]="Sayaçlar duraklatıldı",["Locked or sleeping"]="Kilitli veya uykuda",["Enjoy your break"]="Molanın tadını çıkar",
        ["Eye break"]="Göz molası",["Movement break"]="Hareket molası",["Eye & movement break"]="Göz ve hareket molası",["Take a break"]="Mola ver",["Snooze 5 min"]="5 dk ertele",["Continue"]="Devam et",["Close"]="Kapat",["Exit"]="Çıkış",
        ["Look away and relax your eyes."]="Uzağa bak ve gözlerini dinlendir.",["Stand up and move a little."]="Ayağa kalk ve biraz hareket et.",["You have postponed several breaks. Make some time to rest."]="Birkaç molayı erteledin. Dinlenmek için biraz zaman ayır.",
        ["Snooze quiets both reminders for 5 active minutes."]="Erteleme, iki uyarıyı 5 aktif dakika susturur.",["Preview · your timers are unchanged"]="Önizleme · sayaçların değişmez",
        ["Local only · no account, no telemetry"]="Yalnızca bu cihazda · hesap ve telemetri yok",["This week"]="Bu hafta",["Daily active minutes"]="Günlük aktif dakika",["Summaries are off. Enable them in Settings."]="Özetler kapalı. Ayarlardan açabilirsin.",["No recorded activity yet."]="Henüz etkinlik kaydı yok.",["Delete summaries"]="Özetleri sil",["Delete local summaries? This cannot be undone."]="Yerel özetler silinsin mi? Geri alınamaz.",
        ["Media status unavailable. Use watching mode."]="Medya durumu okunamıyor. İzleme modunu kullan.",["Input status unavailable; timers are paused."]="Girdi durumu okunamıyor; sayaçlar duraklatıldı.",["Local storage unavailable. Settings may not be saved."]="Yerel depoya erişilemiyor. Ayarlar kaydedilmeyebilir.",
        ["Permissions: no elevation, keyboard capture or screen recording. Only elapsed input time and playback status are read."]="İzinler: yönetici, klavye kaydı veya ekran kaydı gerekmez. Yalnızca son girdiden geçen süre ve oynatma durumu okunur.",
        ["Windows quiet-state support is limited. Camera/meeting detection is not available in this preview."]="Windows sessiz durum desteği sınırlıdır. Bu önizlemede kamera/toplantı algılama yoktur.",
        ["Offline implementation; this Windows preview has no OS-enforced network sandbox."]="Uygulama çevrimdışı çalışır; bu Windows önizlemesinde işletim sistemi düzeyinde ağ engeli yoktur.",
        ["Local files: settings and optional daily totals. No keystrokes, screenshots, media titles, URLs or app history are stored."]="Yerel dosyalar: ayarlar ve isteğe bağlı günlük toplamlar. Tuşlar, ekran görüntüleri, medya adları, adresler veya uygulama geçmişi kaydedilmez.",
        ["Windows preview · not yet validated for daily use"]="Windows önizlemesi · günlük kullanım henüz doğrulanmadı"
    };
    internal static string L(string value) => Turkish && Translations.TryGetValue(value,out var translated) ? translated : value;
    internal static string Clock(double seconds) { int s = (int)System.Math.Ceiling(System.Math.Clamp(seconds,0,86400)); return $"{s/60:00}:{s%60:00}"; }
    internal static string State(Activity state) => L(state switch { Activity.Active=>"Tracking automatically",Activity.Media=>"Media · timers running",Activity.Away=>"Away · paused automatically",Activity.Paused=>"Timers paused",Activity.Sleeping=>"Locked or sleeping",Activity.Resting=>"Enjoy your break",_=>"Waiting for activity" });
    internal static string Kind(BreakKind kind) => L(kind switch { BreakKind.Both=>"Eye & movement break",BreakKind.Movement=>"Movement break",_=>"Eye break" });
}
