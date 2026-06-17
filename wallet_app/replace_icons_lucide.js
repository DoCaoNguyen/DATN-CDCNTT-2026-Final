const fs = require('fs');
const path = require('path');

const toCamelCase = (str) => {
  return str.replace(/_([a-z0-9])/g, (g) => g[1].toUpperCase());
};

const rawIconMap = {
    'account_balance': 'landmark',
    'account_balance_outlined': 'landmark',
    'account_balance_wallet': 'wallet',
    'account_balance_wallet_outlined': 'wallet',
    'add': 'plus',
    'add_circle_outline': 'plus_circle',
    'agriculture': 'tractor',
    'apps': 'layout_grid',
    'arrow_back': 'arrow_left',
    'arrow_back_ios': 'chevron_left',
    'arrow_downward': 'arrow_down',
    'arrow_drop_down': 'chevron_down',
    'arrow_upward': 'arrow_up',
    'assignment_outlined': 'clipboard_list',
    'attach_money': 'banknote',
    'auto_awesome': 'sparkles',
    'bar_chart': 'bar_chart_2',
    'bookmark': 'bookmark',
    'bookmark_border': 'bookmark',
    'broken_image_outlined': 'image_off',
    'business': 'building',
    'calendar_today': 'calendar',
    'call_received': 'phone_incoming',
    'call_received_outlined': 'phone_incoming',
    'camera_alt_outlined': 'camera',
    'campaign': 'megaphone',
    'cancel': 'x_circle',
    'card_giftcard': 'gift',
    'change_history': 'history',
    'chat_bubble': 'message_circle',
    'chat_bubble_outline': 'message_circle',
    'check': 'check',
    'check_circle': 'check_circle',
    'check_circle_outline': 'check_circle',
    'check_circle_rounded': 'check_circle',
    'chevron_left': 'chevron_left',
    'chevron_right': 'chevron_right',
    'close': 'x',
    'computer': 'monitor',
    'contact_phone_outlined': 'contact',
    'contactless_outlined': 'nfc',
    'content_copy': 'copy',
    'copy': 'copy',
    'credit_card': 'credit_card',
    'crisis_alert': 'alert_triangle',
    'currency_exchange': 'arrow_right_left',
    'description_outlined': 'file_text',
    'devices': 'smartphone',
    'directions_car_filled_outlined': 'car',
    'download_outlined': 'download',
    'electric_bolt': 'zap',
    'email_outlined': 'mail',
    'emoji_emotions_outlined': 'smile',
    'error_outline': 'alert_circle',
    'face': 'smile',
    'face_retouching_natural': 'user_check',
    'face_retouching_natural_outlined': 'user_check',
    'favorite_border': 'heart',
    'favorite_border_outlined': 'heart',
    'fingerprint': 'fingerprint',
    'flash_off': 'zap_off',
    'flash_on': 'zap',
    'format_quote': 'quote',
    'grid_view_outlined': 'grid',
    'grid_view_rounded': 'grid',
    'headset_mic_outlined': 'headphones',
    'health_and_safety_outlined': 'shield_check',
    'help_outline': 'help_circle',
    'history': 'history',
    'history_toggle_off': 'history',
    'home': 'home',
    'home_outlined': 'home',
    'home_work_outlined': 'building_2',
    'image_outlined': 'image',
    'inbox_outlined': 'inbox',
    'info_outline': 'info',
    'input': 'log_in',
    'keyboard_arrow_down': 'chevron_down',
    'keyboard_arrow_up': 'chevron_up',
    'local_offer_outlined': 'tag',
    'lock': 'lock',
    'lock_outline': 'lock',
    'lock_outline_rounded': 'lock',
    'mail_outline': 'mail',
    'monetization_on': 'circle_dollar_sign',
    'money': 'banknote',
    'more_horiz': 'more_horizontal',
    'movie': 'film',
    'movie_creation_outlined': 'film',
    'nfc': 'nfc',
    'notifications_active_outlined': 'bell_ring',
    'notifications_none': 'bell',
    'notifications_off_outlined': 'bell_off',
    'outbox': 'outbox',
    'output': 'log_out',
    'palette_outlined': 'palette',
    'paste': 'clipboard_paste',
    'payment': 'credit_card',
    'people_outline': 'users',
    'person': 'user',
    'person_add_alt_1': 'user_plus',
    'person_outline': 'user',
    'phone': 'phone',
    'phone_android': 'smartphone',
    'phone_android_outlined': 'smartphone',
    'phone_in_talk_outlined': 'phone_call',
    'phonelink_lock_outlined': 'smartphone_nfc',
    'photo_library_outlined': 'images',
    'policy_outlined': 'file_check',
    'qr_code': 'qr_code',
    'qr_code_2': 'qr_code',
    'qr_code_scanner': 'scan',
    'radio_button_checked': 'circle_dot',
    'radio_button_off': 'circle',
    'receipt_long': 'receipt',
    'receipt_long_outlined': 'receipt',
    'receipt_outlined': 'receipt',
    'redeem': 'gift',
    'restaurant_menu': 'utensils',
    'restaurant_outlined': 'utensils',
    'school_outlined': 'graduation_cap',
    'search': 'search',
    'security': 'shield',
    'send': 'send',
    'send_outlined': 'send',
    'settings_applications_outlined': 'settings',
    'share': 'share_2',
    'shield': 'shield',
    'shield_outlined': 'shield',
    'shopping_bag_outlined': 'shopping_bag',
    'shopping_basket': 'shopping_basket',
    'shopping_basket_outlined': 'shopping_basket',
    'sort': 'list',
    'sports_esports': 'gamepad_2',
    'star': 'star',
    'star_border': 'star',
    'support_agent': 'headset',
    'support_agent_outlined': 'headset',
    'swap_horiz': 'arrow_right_left',
    'sync': 'refresh_cw',
    'translate': 'languages',
    'tune': 'sliders',
    'verified': 'badge_check',
    'verified_user': 'shield_check',
    'verified_user_outlined': 'shield_check',
    'video_library_outlined': 'video',
    'visibility': 'eye',
    'visibility_off': 'eye_off',
    'visibility_off_outlined': 'eye_off',
    'visibility_outlined': 'eye',
    'wallet': 'wallet',
    'warning_amber': 'alert_triangle',
    'warning_amber_rounded': 'alert_triangle',
    'wifi_off': 'wifi_off',
    'wifi_off_rounded': 'wifi_off'
};

const iconMap = {};
for (const key in rawIconMap) {
    iconMap[key] = toCamelCase(rawIconMap[key]);
}

function getFiles(dir, files = []) {
    const fileList = fs.readdirSync(dir);
    for (const file of fileList) {
        const name = dir + '/' + file;
        if (fs.statSync(name).isDirectory()) {
            getFiles(name, files);
        } else if (name.endsWith('.dart')) {
            files.push(name);
        }
    }
    return files;
}

const files = getFiles('lib');
let modifiedCount = 0;

files.forEach(f => {
    let content = fs.readFileSync(f, 'utf8');
    let changed = false;

    // We only replace Icons.xyz if it is in our map.
    const newContent = content.replace(/Icons\.([a-zA-Z0-9_]+)/g, (match, p1) => {
        if (iconMap[p1]) {
            changed = true;
            return `LucideIcons.${iconMap[p1]}`;
        }
        return match;
    });

    if (changed) {
        // Add import if not present
        if (!newContent.includes("package:lucide_icons/lucide_icons.dart")) {
            const lines = newContent.split('\n');
            let lastImportIdx = -1;
            for (let i = 0; i < lines.length; i++) {
                if (lines[i].startsWith('import ')) {
                    lastImportIdx = i;
                }
            }
            if (lastImportIdx !== -1) {
                lines.splice(lastImportIdx + 1, 0, "import 'package:lucide_icons/lucide_icons.dart';");
            } else {
                lines.unshift("import 'package:lucide_icons/lucide_icons.dart';");
            }
            content = lines.join('\n');
        } else {
            content = newContent;
        }

        fs.writeFileSync(f, content, 'utf8');
        modifiedCount++;
    }
});

console.log(`Replaced icons in ${modifiedCount} files.`);
