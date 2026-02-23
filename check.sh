#!/bin/bash

TARGET="/var/www"

PHP_CODE='
$data = [
    "url"     => get_option("siteurl"),
    "name"    => get_option("blogname"),
    "version" => $GLOBALS["wp_version"],
    "admin"   => get_option("admin_email"),
    "theme"   => wp_get_theme()->get("Name"),
    "plugins" => implode(",", (array) get_option("active_plugins", [])),
];
$admin_user = get_users(["role" => "Administrator", "number" => 1]);
$data["admin_user"] = !empty($admin_user) ? $admin_user[0]->user_login : "N/A";
echo json_encode($data);
'

echo "=== WordPress Site Inspection ==="
echo "Search Path: $TARGET"
echo "---------------------------------------------"

find "$TARGET" -name "wp-config.php" -print0 2>/dev/null | while IFS= read -r -d '' wpconfig_path; do
    dir=$(dirname "$wpconfig_path")
    owner=$(stat -c '%U' "$dir" 2>/dev/null)

    json_output=$(sudo -u "$owner" -- wp --path="$dir" eval "$PHP_CODE" --allow-root 2>/dev/null)

    if [[ -z "$json_output" ]]; then continue; fi

    # 各項目を抽出
    url=$(echo "$json_output" | jq -r '.url')
    name=$(echo "$json_output" | jq -r '.name')
    version=$(echo "$json_output" | jq -r '.version')
    admin_user=$(echo "$json_output" | jq -r '.admin_user')
    admin_email=$(echo "$json_output" | jq -r '.admin')
    theme=$(echo "$json_output" | jq -r '.theme')
    plugins=$(echo "$json_output" | jq -r '.plugins')

    echo "Site: $name"
    printf "  %-18s : %s\n" "URL" "$url"
    printf "  %-18s : %s (%s)\n" "Path (Owner)" "$dir" "$owner"
    printf "  %-18s : %s\n" "WP Version" "$version"
    printf "  %-18s : %s (%s)\n" "Admin" "$admin_user" "$admin_email"
    printf "  %-18s : %s\n" "Active Theme" "$theme"
    printf "  %-18s : %s\n" "Active Plugins" "$plugins"
    echo "---------------------------------------------"
done

echo "Done"
