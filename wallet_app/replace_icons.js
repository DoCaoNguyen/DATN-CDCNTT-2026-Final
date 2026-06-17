const fs = require('fs');
const path = require('path');

const iconMap = {
    'account_balance': 'business_outline',
    'account_balance_outlined': 'business_outline',
    'account_balance_wallet': 'wallet_outline',
    'account_balance_wallet_outlined': 'wallet_outline',
    'add': 'add_outline',
    'add_circle_outline': 'add_circle_outline',
    'agriculture': 'leaf_outline',
    'apps': 'grid_outline',
    'arrow_back': 'arrow_back_outline',
    'arrow_back_ios': 'chevron_back_outline',
    'arrow_downward': 'arrow_down_outline',
    'arrow_drop_down': 'chevron_down_outline',
    'arrow_upward': 'arrow_up_outline',
    'assignment_outlined': 'clipboard_outline',
    'attach_money': 'cash_outline',
    'auto_awesome': 'sparkles_outline',
    'bar_chart': 'bar_chart_outline',
    'bookmark': 'bookmark_outline',
    'bookmark_border': 'bookmark_outline',
    'broken_image_outlined': 'image_outline',
    'business': 'business_outline',
    'calendar_today': 'calendar_outline',
    'call_received': 'call_outline',
    'call_received_outlined': 'call_outline',
    'camera_alt_outlined': 'camera_outline',
    'campaign': 'megaphone_outline',
    'cancel': 'close_circle_outline',
    'card_giftcard': 'gift_outline',
    'change_history': 'time_outline',
    'chat_bubble': 'chatbubble_outline',
    'chat_bubble_outline': 'chatbubble_outline',
    'check': 'checkmark_outline',
    'check_circle': 'checkmark_circle_outline',
    'check_circle_outline': 'checkmark_circle_outline',
    'check_circle_rounded': 'checkmark_circle_outline',
    'chevron_left': 'chevron_back_outline',
    'chevron_right': 'chevron_forward_outline',
    'close': 'close_outline',
    'computer': 'laptop_outline',
    'contact_phone_outlined': 'call_outline',
    'contactless_outlined': 'radio_outline',
    'content_copy': 'copy_outline',
    'copy': 'copy_outline',
    'credit_card': 'card_outline',
    'crisis_alert': 'warning_outline',
    'currency_exchange': 'swap_horizontal_outline',
    'description_outlined': 'document_text_outline',
    'devices': 'hardware_chip_outline',
    'directions_car_filled_outlined': 'car_outline',
    'download_outlined': 'download_outline',
    'electric_bolt': 'flash_outline',
    'email_outlined': 'mail_outline',
    'emoji_emotions_outlined': 'happy_outline',
    'error_outline': 'alert_circle_outline',
    'face': 'happy_outline',
    'face_retouching_natural': 'happy_outline',
    'face_retouching_natural_outlined': 'happy_outline',
    'favorite_border': 'heart_outline',
    'favorite_border_outlined': 'heart_outline',
    'fingerprint': 'finger_print_outline',
    'flash_off': 'flash_off_outline',
    'flash_on': 'flash_outline',
    'format_quote': 'chatbox_outline',
    'grid_view_outlined': 'grid_outline',
    'grid_view_rounded': 'grid_outline',
    'headset_mic_outlined': 'headset_outline',
    'health_and_safety_outlined': 'shield_checkmark_outline',
    'help_outline': 'help_circle_outline',
    'history': 'time_outline',
    'history_toggle_off': 'time_outline',
    'home': 'home_outline',
    'home_outlined': 'home_outline',
    'home_work_outlined': 'business_outline',
    'image_outlined': 'image_outline',
    'inbox_outlined': 'archive_outline',
    'info_outline': 'information_circle_outline',
    'input': 'log_in_outline',
    'keyboard_arrow_down': 'chevron_down_outline',
    'keyboard_arrow_up': 'chevron_up_outline',
    'local_offer_outlined': 'pricetag_outline',
    'lock': 'lock_closed_outline',
    'lock_outline': 'lock_closed_outline',
    'lock_outline_rounded': 'lock_closed_outline',
    'mail_outline': 'mail_outline',
    'monetization_on': 'cash_outline',
    'money': 'cash_outline',
    'more_horiz': 'ellipsis_horizontal_outline',
    'movie': 'film_outline',
    'movie_creation_outlined': 'film_outline',
    'nfc': 'radio_outline',
    'notifications_active_outlined': 'notifications_outline',
    'notifications_none': 'notifications_outline',
    'notifications_off_outlined': 'notifications_off_outline',
    'outbox': 'arrow_up_circle_outline',
    'output': 'log_out_outline',
    'palette_outlined': 'color_palette_outline',
    'paste': 'clipboard_outline',
    'payment': 'card_outline',
    'people_outline': 'people_outline',
    'person': 'person_outline',
    'person_add_alt_1': 'person_add_outline',
    'person_outline': 'person_outline',
    'phone': 'call_outline',
    'phone_android': 'phone_portrait_outline',
    'phone_android_outlined': 'phone_portrait_outline',
    'phone_in_talk_outlined': 'call_outline',
    'phonelink_lock_outlined': 'lock_closed_outline',
    'photo_library_outlined': 'images_outline',
    'policy_outlined': 'document_lock_outline',
    'qr_code': 'qr_code_outline',
    'qr_code_2': 'qr_code_outline',
    'qr_code_scanner': 'scan_outline',
    'radio_button_checked': 'radio_button_on_outline',
    'radio_button_off': 'radio_button_off_outline',
    'receipt_long': 'receipt_outline',
    'receipt_long_outlined': 'receipt_outline',
    'receipt_outlined': 'receipt_outline',
    'redeem': 'gift_outline',
    'restaurant_menu': 'restaurant_outline',
    'restaurant_outlined': 'restaurant_outline',
    'school_outlined': 'school_outline',
    'search': 'search_outline',
    'security': 'shield_checkmark_outline',
    'send': 'send_outline',
    'send_outlined': 'send_outline',
    'settings_applications_outlined': 'settings_outline',
    'share': 'share_social_outline',
    'shield': 'shield_outline',
    'shield_outlined': 'shield_outline',
    'shopping_bag_outlined': 'bag_outline',
    'shopping_basket': 'basket_outline',
    'shopping_basket_outlined': 'basket_outline',
    'sort': 'list_outline',
    'sports_esports': 'game_controller_outline',
    'star': 'star_outline',
    'star_border': 'star_outline',
    'support_agent': 'headset_outline',
    'support_agent_outlined': 'headset_outline',
    'swap_horiz': 'swap_horizontal_outline',
    'sync': 'sync_outline',
    'translate': 'language_outline',
    'tune': 'options_outline',
    'verified': 'checkmark_circle_outline',
    'verified_user': 'shield_checkmark_outline',
    'verified_user_outlined': 'shield_checkmark_outline',
    'video_library_outlined': 'videocam_outline',
    'visibility': 'eye_outline',
    'visibility_off': 'eye_off_outline',
    'visibility_off_outlined': 'eye_off_outline',
    'visibility_outlined': 'eye_outline',
    'wallet': 'wallet_outline',
    'warning_amber': 'warning_outline',
    'warning_amber_rounded': 'warning_outline',
    'wifi_off': 'wifi_outline',
    'wifi_off_rounded': 'wifi_outline'
};

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
            return `Ionicons.${iconMap[p1]}`;
        }
        return match;
    });

    if (changed) {
        // Add import if not present
        if (!newContent.includes("package:ionicons/ionicons.dart")) {
            // Find last import
            const lines = newContent.split('\n');
            let lastImportIdx = -1;
            for (let i = 0; i < lines.length; i++) {
                if (lines[i].startsWith('import ')) {
                    lastImportIdx = i;
                }
            }
            if (lastImportIdx !== -1) {
                lines.splice(lastImportIdx + 1, 0, "import 'package:ionicons/ionicons.dart';");
            } else {
                lines.unshift("import 'package:ionicons/ionicons.dart';");
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
