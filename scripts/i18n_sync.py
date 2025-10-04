import json
import os

I18N_PATH = "i18n"
BASE_LANG = "en"
LANGS = ["es", "fr", "pt", "ja"]  # Add/remove as needed

def load_json(lang):
    with open(os.path.join(I18N_PATH, f"{lang}.json"), encoding="utf-8") as f:
        return json.load(f)

def save_json(lang, data):
    with open(os.path.join(I18N_PATH, f"{lang}.json"), "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

def sync_keys(ref, target, path=""):
    added = []
    removed = []

    # Add missing keys
    for key, value in ref.items():
        if key not in target:
            if isinstance(value, dict):
                target[key] = {}
                added.append(f"{path}{key}/")
                # Recursively add all subkeys as missing
                sub_added, _ = sync_keys(value, target[key], f"{path}{key}/")
                added.extend(sub_added)
            else:
                target[key] = "TODO_TRANSLATE"
                added.append(f"{path}{key}")
        elif isinstance(value, dict) and isinstance(target[key], dict):
            sub_added, sub_removed = sync_keys(value, target[key], f"{path}{key}/")
            added.extend(sub_added)
            removed.extend(sub_removed)

    # Remove extra keys
    for key in list(target.keys()):
        if key not in ref:
            removed.append(f"{path}{key}" + ("/" if isinstance(target[key], dict) else ""))
            del target[key]

    return added, removed

def main():
    base = load_json(BASE_LANG)
    summary = {}

    for lang in LANGS:
        print(f"\nChecking {lang}.json...")
        target = load_json(lang)
        added, removed = sync_keys(base, target)
        save_json(lang, target)
        summary[lang] = {"added": added, "removed": removed}
        print(f"✅ Synced {lang}.json")
        if added:
            print(f"  Added keys: {added}")
        if removed:
            print(f"  Removed keys: {removed}")

    # Final summary
    print("\n=== i18n Sync Summary ===")
    for lang, changes in summary.items():
        print(f"\nFile: {lang}.json")
        print(f"  Added keys: {changes['added'] or 'None'}")
        print(f"  Removed keys: {changes['removed'] or 'None'}")

if __name__ == "__main__":
    main()
