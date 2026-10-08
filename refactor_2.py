import os
import re
import shutil

lib_dir = r"d:\ProjectQuiz\QuizMasterPro\lib"
package_name = "quizmaster_pro"

# Dictionary of old relative paths (from lib) to new relative paths (from lib)
moves = {
    # WIDGETS
    # Core Widgets
    r"widgets\animated_splash.dart": r"widgets\core\animated_splash.dart",
    r"widgets\app_logo_text.dart": r"widgets\core\app_logo_text.dart",
    r"widgets\custom_button.dart": r"widgets\core\custom_button.dart",
    r"widgets\custom_button_responsive.dart": r"widgets\core\custom_button_responsive.dart",
    r"widgets\exit_confirm_scope.dart": r"widgets\core\exit_confirm_scope.dart",
    r"widgets\loading_logo.dart": r"widgets\core\loading_logo.dart",
    r"widgets\local_asset_image.dart": r"widgets\core\local_asset_image.dart",
    r"widgets\meu_quiz_logo_text.dart": r"widgets\core\meu_quiz_logo_text.dart",
    r"widgets\offline_banner_wrapper.dart": r"widgets\core\offline_banner_wrapper.dart",
    r"widgets\processing_logo.dart": r"widgets\core\processing_logo.dart",
    r"widgets\responsive_chip.dart": r"widgets\core\responsive_chip.dart",

    # Game UI Widgets
    r"widgets\category_card.dart": r"widgets\game\category_card.dart",
    r"widgets\feature_card.dart": r"widgets\game\feature_card.dart",
    r"widgets\feature_card_responsive.dart": r"widgets\game\feature_card_responsive.dart",
    r"widgets\game_mode_card.dart": r"widgets\game\game_mode_card.dart",
    r"widgets\game_mode_card_responsive.dart": r"widgets\game\game_mode_card_responsive.dart",

    # Chat Widgets
    r"widgets\in_game_chat_bubble.dart": r"widgets\chat\in_game_chat_bubble.dart",
    r"widgets\in_game_chat_button.dart": r"widgets\chat\in_game_chat_button.dart",
    r"widgets\in_game_chat_sheet.dart": r"widgets\chat\in_game_chat_sheet.dart",
    r"widgets\in_game_quick_chat_bar.dart": r"widgets\chat\in_game_quick_chat_bar.dart",

    # Economy Widgets
    r"widgets\crystal_balance_chip.dart": r"widgets\economy\crystal_balance_chip.dart",
    r"widgets\reward_claim_dialog.dart": r"widgets\economy\reward_claim_dialog.dart",
    r"widgets\vip_badge_widget.dart": r"widgets\economy\vip_badge_widget.dart",

    # Profile Widgets
    r"widgets\cosmetic_avatar.dart": r"widgets\profile\cosmetic_avatar.dart",

    # PROVIDERS
    # Core Providers
    r"providers\auth_provider.dart": r"providers\core\auth_provider.dart",
    r"providers\network_provider.dart": r"providers\core\network_provider.dart",
    r"providers\websocket_provider.dart": r"providers\core\websocket_provider.dart",

    # Game Providers
    r"providers\category_provider.dart": r"providers\game\category_provider.dart",
    r"providers\game_provider.dart": r"providers\game\game_provider.dart",
    r"providers\question_provider.dart": r"providers\game\question_provider.dart",
    r"providers\room_provider.dart": r"providers\game\room_provider.dart",

    # Solo Providers
    r"providers\free_mode_provider.dart": r"providers\solo\free_mode_provider.dart",
    r"providers\solo_provider.dart": r"providers\solo\solo_provider.dart",

    # Economy Providers
    r"providers\mission_provider.dart": r"providers\economy\mission_provider.dart",
    r"providers\season_provider.dart": r"providers\economy\season_provider.dart",
    r"providers\store_provider.dart": r"providers\economy\store_provider.dart",

    # Study Providers
    r"providers\study_quiz_provider.dart": r"providers\study\study_quiz_provider.dart",

    # Social Providers
    r"providers\friendship_provider.dart": r"providers\social\friendship_provider.dart",
}

full_moves = {}
for old_rel, new_rel in moves.items():
    old_full = os.path.join(lib_dir, old_rel)
    new_full = os.path.join(lib_dir, new_rel)
    full_moves[old_full] = new_full

def get_new_path(filepath):
    return full_moves.get(filepath, filepath)

all_files = []
for root, _, files in os.walk(lib_dir):
    for f in files:
        if f.endswith('.dart'):
            all_files.append(os.path.join(root, f))

import_pattern = re.compile(r"(import\s+['\"])([^'\"]+)(['\"];?)")

modified_contents = {}

for filepath in all_files:
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
    except Exception as e:
        continue

    new_filepath = get_new_path(filepath)
    new_file_dir = os.path.dirname(new_filepath)

    def replacer(match):
        prefix = match.group(1)
        import_path = match.group(2)
        suffix = match.group(3)

        if import_path.startswith('dart:') or import_path.startswith('package:') and not import_path.startswith(f'package:{package_name}/'):
            return match.group(0) 
        
        if import_path.startswith(f'package:{package_name}/'):
            rel_to_lib = import_path.replace(f'package:{package_name}/', '').replace('/', os.sep)
            target_full = os.path.join(lib_dir, rel_to_lib)
        else:
            target_full = os.path.normpath(os.path.join(os.path.dirname(filepath), import_path.replace('/', os.sep)))

        new_target_full = get_new_path(target_full)

        if import_path.startswith('package:'):
            rel_to_lib = os.path.relpath(new_target_full, lib_dir).replace(os.sep, '/')
            new_import_path = f"package:{package_name}/{rel_to_lib}"
        else:
            new_rel = os.path.relpath(new_target_full, new_file_dir).replace(os.sep, '/')
            if not new_rel.startswith('.'):
                new_rel = './' + new_rel
            new_import_path = new_rel

        return f"{prefix}{new_import_path}{suffix}"

    new_content = import_pattern.sub(replacer, content)
    
    if new_content != content or filepath != new_filepath:
        modified_contents[filepath] = new_content

for new_full in full_moves.values():
    os.makedirs(os.path.dirname(new_full), exist_ok=True)

for old_path, new_content in modified_contents.items():
    new_path = get_new_path(old_path)
    with open(new_path, 'w', encoding='utf-8') as f:
        f.write(new_content)
    
    if old_path != new_path:
        os.remove(old_path)
        print(f"Moved and updated: {os.path.basename(old_path)} -> {new_path}")
    else:
        print(f"Updated imports: {old_path}")

print("Refactoring 2 complete.")
