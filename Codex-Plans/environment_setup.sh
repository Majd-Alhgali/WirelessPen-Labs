#!/bin/bash

# سكريبت إعداد البيئة - Environment Setup Script
# تثبيت الأدوات والمكتبات المطلوبة للخطة

set -e

echo "==============================================="
echo "إعداد بيئة الهجوم على كلمات السر Wi-Fi"
echo "WPA Password Recovery Environment Setup"
echo "==============================================="
echo ""

# الألوان للطباعة
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# دالة للطباعة بألوان
print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

# 1. تحديث القائمة
echo "1. تحديث قائمة الحزم..."
sudo apt-get update
print_status "تم تحديث قائمة الحزم"

# 2. تثبيت hashcat
echo ""
echo "2. التحقق من hashcat..."
if command -v hashcat &> /dev/null; then
    HASHCAT_VERSION=$(hashcat --version | head -n1)
    print_status "hashcat مثبت بالفعل: $HASHCAT_VERSION"
else
    echo "تثبيت hashcat..."
    sudo apt-get install -y hashcat
    print_status "تم تثبيت hashcat"
fi

# 3. تثبيت aircrack-ng
echo ""
echo "3. التحقق من aircrack-ng..."
if command -v aircrack-ng &> /dev/null; then
    AIRCRACK_VERSION=$(aircrack-ng --version | head -n1)
    print_status "aircrack-ng مثبت بالفعل: $AIRCRACK_VERSION"
else
    echo "تثبيت aircrack-ng..."
    sudo apt-get install -y aircrack-ng
    print_status "تم تثبيت aircrack-ng"
fi

# 4. تثبيت hcxtools (يحتوي على hcxpcapngtool)
echo ""
echo "4. التحقق من hcxpcapngtool..."
if command -v hcxpcapngtool &> /dev/null; then
    print_status "hcxpcapngtool مثبت بالفعل"
else
    echo "تثبيت hcxtools..."
    sudo apt-get install -y hcxtools
    print_status "تم تثبيت hcxtools"
fi

# 5. تثبيت المكتبات المساعدة
echo ""
echo "5. تثبيت المكتبات المساعدة..."
sudo apt-get install -y \
    git \
    curl \
    wget \
    openssl \
    build-essential
print_status "تم تثبيت المكتبات المساعدة"

# 6. إنشاء هيكل المجلدات
echo ""
echo "6. إنشاء هيكل المجلدات..."
WORK_DIR="$HOME/wifi_pentest"
mkdir -p "$WORK_DIR"/{captures,hashes,wordlists,output,logs}
print_status "تم إنشاء المجلدات في: $WORK_DIR"

# 7. نسخ ملفات التكوين
echo ""
echo "7. نسخ ملفات التكوين..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/wordlist_taim_base.txt" ]; then
    cp "$SCRIPT_DIR/wordlist_taim_base.txt" "$WORK_DIR/wordlists/"
    print_status "تم نسخ قاموس الكلمات الأساسي"
fi

if [ -f "$SCRIPT_DIR/taim_rules_light.rule" ]; then
    cp "$SCRIPT_DIR/taim_rules_light.rule" "$WORK_DIR/wordlists/"
    print_status "تم نسخ قواعس الهجوم"
fi

if [ -f "$SCRIPT_DIR/attack_masks.txt" ]; then
    cp "$SCRIPT_DIR/attack_masks.txt" "$WORK_DIR/wordlists/"
    print_status "تم نسخ أقنعة الهجوم"
fi

# 8. التحقق من الأدوات
echo ""
echo "8. التحقق النهائي من الأدوات..."
echo ""

print_status "hashcat: $(hashcat --version | head -n1)"
print_status "aircrack-ng: $(aircrack-ng --version | head -n1)"
print_status "hcxpcapngtool: $(hcxpcapngtool -v 2>&1 | head -n1)"

# 9. معلومات الإكمال
echo ""
echo "==============================================="
print_status "اكتمل إعداد البيئة بنجاح!"
echo ""
echo "مجلد العمل: $WORK_DIR"
echo "المجلدات الفرعية:"
echo "  - captures/  : لملفات CAP"
echo "  - hashes/    : لملفات Hash المحولة"
echo "  - wordlists/ : لقوائم الكلمات والقواعس والأقنعة"
echo "  - output/    : لنتائج الهجوم"
echo "  - logs/      : لسجلات التنفيذ"
echo ""
echo "الخطوة التالية:"
echo "1. انسخ ملف CAP إلى: $WORK_DIR/captures/"
echo "2. نفذ: hcxpcapngtool -o hashes/taim_3e.22000 captures/taim_client_3e_test-01.cap"
echo "3. ابدأ مراحل الهجوم من وثيقة attack_phases_config.md"
echo ""
echo "==============================================="
