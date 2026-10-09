import os
import re
import shutil

lib_dir = r"d:\ProjectQuiz\QuizMasterPro\lib"
package_name = "quizmaster_pro"

# Dictionary of old relative paths (from lib) to new relative paths (from lib)
moves = {
    # Auth
    r"screens\login_screen.dart": r"screens\auth\login_screen.dart",
    r"screens\nickname_screen.dart": r"screens\auth\nickname_screen.dart",
    r"screens\onboarding_screen.dart": r"screens\auth\onboarding_screen.dart",
    r"screens\splash_screen.dart": r"screens\auth\splash_screen.dart",
    
    # Home
    r"screens\home_screen.dart": r"screens\home\home_screen.dart",
    r"screens\menu_screen.dart": r"screens\home\menu_screen.dart",
    r"screens\settings_screen.dart": r"screens\home\settings_screen.dart",
    
    # Modes
    r"screens\online_modes_screen.dart": r"screens\modes\online_modes_screen.dart",
    r"screens\solo_modes_screen.dart": r"screens\modes\solo_modes_screen.dart",
    r"screens\study_modes_screen.dart": r"screens\modes\study_modes_screen.dart",
    r"screens\free_mode_menu_screen.dart": r"screens\modes\free_mode_menu_screen.dart",
    
    # Multiplayer
    r"screens\create_room_screen.dart": r"screens\multiplayer\create_room_screen.dart",
    r"screens\join_room_screen.dart": r"screens\multiplayer\join_room_screen.dart",
    r"screens\kahoot_game_screen.dart": r"screens\multiplayer\kahoot_game_screen.dart",
    r"screens\kahoot_lobby_screen.dart": r"screens\multiplayer\kahoot_lobby_screen.dart",
    r"screens\team_lobby_screen.dart": r"screens\multiplayer\team_lobby_screen.dart",
    r"screens\duel_lobby_screen.dart": r"screens\multiplayer\duel_lobby_screen.dart",
    r"screens\quiz_countdown_screen.dart": r"screens\multiplayer\quiz_countdown_screen.dart",
    r"screens\quiz_game_screen.dart": r"screens\multiplayer\quiz_game_screen.dart",
    r"screens\quiz_results_screen.dart": r"screens\multiplayer\quiz_results_screen.dart",
    r"screens\team_details_screen.dart": r"screens\multiplayer\team_details_screen.dart",
    
    # Solo
    r"screens\solo_map_screen.dart": r"screens\solo\solo_map_screen.dart",
    r"screens\solo_setup_screen.dart": r"screens\solo\solo_setup_screen.dart",
    r"screens\solo_quiz_game_screen.dart": r"screens\solo\solo_quiz_game_screen.dart",
    r"screens\boss_battle_screen.dart": r"screens\solo\boss_battle_screen.dart",
    r"screens\free_mode_results_screen.dart": r"screens\solo\free_mode_results_screen.dart",
    r"screens\survival_game_screen.dart": r"screens\solo\survival_game_screen.dart",
    r"screens\time_attack_game_screen.dart": r"screens\solo\time_attack_game_screen.dart",
    
    # Study
    r"screens\create_study_plan_screen.dart": r"screens\study\create_study_plan_screen.dart",
    r"screens\study_flashcards_screen.dart": r"screens\study\study_flashcards_screen.dart",
    r"screens\study_mode_screen.dart": r"screens\study\study_mode_screen.dart",
    r"screens\study_pdf_screen.dart": r"screens\study\study_pdf_screen.dart",
    r"screens\study_plan_details_screen.dart": r"screens\study\study_plan_details_screen.dart",
    r"screens\study_plans_list_screen.dart": r"screens\study\study_plans_list_screen.dart",
    r"screens\study_quiz_game_screen.dart": r"screens\study\study_quiz_game_screen.dart",
    
    # Economy
    r"screens\store_screen.dart": r"screens\economy\store_screen.dart",
    r"screens\season_map_screen.dart": r"screens\economy\season_map_screen.dart",
    r"screens\season_pass_screen.dart": r"screens\economy\season_pass_screen.dart",
    r"screens\quests_screen.dart": r"screens\economy\quests_screen.dart",
    r"screens\resource_download_screen.dart": r"screens\economy\resource_download_screen.dart",
    
    # Profile
    r"screens\profile_screen.dart": r"screens\profile\profile_screen.dart",
    r"screens\ranking_screen.dart": r"screens\profile\ranking_screen.dart",
}

# Resolve full paths
full_moves = {}
for old_rel, new_rel in moves.items():
    old_full = os.path.join(lib_dir, old_rel)
    new_full = os.path.join(lib_dir, new_rel)
    full_moves[old_full] = new_full

def get_new_path(filepath):
    return full_moves.get(filepath, filepath)

# Pre-compute all new paths for every file in the project (even unmoved ones)
all_files = []
for root, _, files in os.walk(lib_dir):
    for f in files:
        if f.endswith('.dart'):
            all_files.append(os.path.join(root, f))

# We will read all files, update their imports, then save them.
# Only then will we physically move the files.

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
            return match.group(0) # External package or dart core, skip
        
        # Resolve what file this import is pointing to
        if import_path.startswith(f'package:{package_name}/'):
            rel_to_lib = import_path.replace(f'package:{package_name}/', '').replace('/', os.sep)
            target_full = os.path.join(lib_dir, rel_to_lib)
        else:
            # Relative import
            target_full = os.path.normpath(os.path.join(os.path.dirname(filepath), import_path.replace('/', os.sep)))

        # Find new location of target file
        new_target_full = get_new_path(target_full)

        # Generate new import string
        if import_path.startswith('package:'):
            # Keep it package based
            rel_to_lib = os.path.relpath(new_target_full, lib_dir).replace(os.sep, '/')
            new_import_path = f"package:{package_name}/{rel_to_lib}"
        else:
            # Keep it relative
            new_rel = os.path.relpath(new_target_full, new_file_dir).replace(os.sep, '/')
            if not new_rel.startswith('.'):
                new_rel = './' + new_rel
            new_import_path = new_rel

        return f"{prefix}{new_import_path}{suffix}"

    new_content = import_pattern.sub(replacer, content)
    
    if new_content != content or filepath != new_filepath:
        modified_contents[filepath] = new_content

# Now apply changes
# First, create target directories
for new_full in full_moves.values():
    os.makedirs(os.path.dirname(new_full), exist_ok=True)

# Write contents (and move files)
for old_path, new_content in modified_contents.items():
    new_path = get_new_path(old_path)
    # Write to new path
    with open(new_path, 'w', encoding='utf-8') as f:
        f.write(new_content)
    
    # If moved, delete old path
    if old_path != new_path:
        os.remove(old_path)
        print(f"Moved and updated: {os.path.basename(old_path)} -> {new_path}")
    else:
        print(f"Updated imports: {old_path}")

print("Refactoring complete.")
