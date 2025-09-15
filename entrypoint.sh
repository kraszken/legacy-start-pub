#!/bin/bash

# Base directories
GAME_BASE="/legacy/server"
SETTINGS_BASE="${GAME_BASE}/settings"
ETMAIN_DIR="${GAME_BASE}/etmain"
LEGACY_DIR="${GAME_BASE}/legacy"
HOMEPATH="/legacy/homepath"

mkdir -p /legacy/homepath/legacy
chown -R legacy:legacy /legacy/homepath

# Helper functions for common operations
log_info() {
    echo "$1"
}

log_warning() {
    echo "WARNING: $1"
}

ensure_directory() {
    mkdir -p "$1"
}

safe_copy() {
    local src="$1"
    local dest="$2"
    [ -f "$src" ] && cp -f "$src" "$dest"
}

# Config defaults
declare -A CONF=(
    # Server settings
    [HOSTNAME]="${HOSTNAME:-ETL Docker Server}"
    [MAP_PORT]="${MAP_PORT:-27960}"
    [REDIRECTURL]="${REDIRECTURL:-https://dl.etl.lol/maps/et}"
    [MAXCLIENTS]="${MAXCLIENTS:-32}"
    [STARTMAP]="${STARTMAP:-radar}"
    [TIMEOUTLIMIT]="${TIMEOUTLIMIT:-1}"
    [SERVERCONF]="${SERVERCONF:-legacy6}"
    [MOTD]="${CONF_MOTD:-}"

    # Passwords
    [PASSWORD]="${PASSWORD:-}"
    [RCONPASSWORD]="${RCONPASSWORD:-}"
    [REFPASSWORD]="${REFPASSWORD:-}"
    [SCPASSWORD]="${SCPASSWORD:-}"
    
    # ETLTV
    [SVAUTODEMO]="${SVAUTODEMO:-0}"
    [ETLTVMAXSLAVES]="${SVETLTVMAXSLAVES:-2}"
    [ETLTVPASSWORD]="${SVETLTVPASSWORD:-3tltv}"
    
    # Repository
    [SETTINGSURL]="${SETTINGSURL:-https://github.com/kraszken/legacy-config-pub.git}"
    [SETTINGSPAT]="${SETTINGSPAT:-}"
    [SETTINGSBRANCH]="${SETTINGSBRANCH:-main}"


    # extra assets settings
    [ASSETS]="${ASSETS:-false}"
    [ASSETS_URL]="${ASSETS_URL:-}"
)

# Fetch configs from repo
update_configs() {
    echo "Checking for configuration updates..."
    local auth_url="${CONF[SETTINGSURL]}"
    
    if [ -n "${CONF[SETTINGSPAT]}" ]; then
        auth_url="https://${CONF[SETTINGSPAT]}@$(echo "${CONF[SETTINGSURL]}" | sed 's~https://~~g')"
    fi

    if git clone --depth 1 --single-branch --branch "${CONF[SETTINGSBRANCH]}" "${auth_url}" "${SETTINGS_BASE}.new"; then
        rm -rf "${SETTINGS_BASE}"
        mv "${SETTINGS_BASE}.new" "${SETTINGS_BASE}"
    else
        echo "Configuration repo could not be pulled, using latest pulled version"
    fi
}

# Handle map downloads
download_maps() {
    IFS=':' read -ra MAP_ARRAY <<< "$MAPS"
    local maps_to_download=()
    
    # First pass - handle existing and local maps
    for map in "${MAP_ARRAY[@]}"; do
        # Skip if map already exists
        [ -f "${ETMAIN_DIR}/${map}.pk3" ] && continue

        log_info "Checking map ${map}"
        if [ -f "/maps/${map}.pk3" ]; then
            log_info "Map ${map} is sourcable locally, copying into place"
            cp "/maps/${map}.pk3" "${ETMAIN_DIR}/${map}.pk3"
        else
            maps_to_download+=("${map}")
        fi
    done
    
    # If we have maps to download, use parallel
    if [ ${#maps_to_download[@]} -gt 0 ]; then
        log_info "Attempting to download ${#maps_to_download[@]} maps in parallel"
        printf '%s\n' "${maps_to_download[@]}" | \
            parallel -j 30 \
            'wget -O "${ETMAIN_DIR}/{}.pk3" "${CONF[REDIRECTURL]}/etmain/{}.pk3" || { 
                log_warning "Failed to download {}"; 
                rm -f "${ETMAIN_DIR}/{}.pk3"; 
            }'
    fi
}

# Copy assets
copy_game_assets() {
    # Create required directories
    ensure_directory "${ETMAIN_DIR}/mapscripts/"
    ensure_directory "${LEGACY_DIR}/luascripts/"
    
    # Clean and copy mapscripts
    rm -f "${ETMAIN_DIR}/mapscripts/"*.script
    for mapscript in "${SETTINGS_BASE}/mapscripts/"*.script; do
        safe_copy "$mapscript" "${ETMAIN_DIR}/mapscripts/"
    done
    
    # Copy luascripts and command maps
    for luascript in "${SETTINGS_BASE}/luascripts/"*.lua; do
        safe_copy "$luascript" "${LEGACY_DIR}/luascripts/"
    done
    
    for tomlfile in "${SETTINGS_BASE}/luascripts/"*.toml; do
        safe_copy "$tomlfile" "${LEGACY_DIR}/luascripts/"
    done
    
    for campaignscript in "${SETTINGS_BASE}/scripts/"*.campaign; do
        safe_copy "$campaignscript" "${ETMAIN_DIR}/scripts/"
    done

    # Handle all .pk3 files
    if ls "${SETTINGS_BASE}"/*.pk3 >/dev/null 2>&1; then
        log_info "Copying all .pk3 files from ${SETTINGS_BASE}/ to ${ETMAIN_DIR}/ and ${LEGACY_DIR}/"
        cp "${SETTINGS_BASE}"/*.pk3 "${ETMAIN_DIR}/"
        cp "${SETTINGS_BASE}"/*.pk3 "${LEGACY_DIR}/"
    else
        log_info "ERROR: No .pk3 files found in ${SETTINGS_BASE}/!"
        exit 1
    fi

    # Handle configs
    if compgen -G "${SETTINGS_BASE}/configs/*.config" > /dev/null; then
        log_info "Copying config files to ${ETMAIN_DIR}/configs/"
        rm -rf "${ETMAIN_DIR}/configs/"
        ensure_directory "${ETMAIN_DIR}/configs/"
        cp "${SETTINGS_BASE}/configs/"*.config "${ETMAIN_DIR}/configs/"
    else
        log_info "WARNING: No config files found in ${SETTINGS_BASE}/configs/"
    fi

    if [ -f "${SETTINGS_BASE}/bots/omni-bot.cfg" ]; then
        log_info "Moving omni-bot.cfg to ${LEGACY_DIR}/omni-bot/et/user/"
        mkdir -p "${LEGACY_DIR}/omni-bot/et/user/"
        mv "${SETTINGS_BASE}/bots/omni-bot.cfg" "${LEGACY_DIR}/omni-bot/et/user/"
    else
        log_info "WARNING: omni-bot.cfg not found in ${SETTINGS_BASE}/bots/"
    fi

    if [ -f "${SETTINGS_BASE}/bots/et_botnames_ext.gm" ]; then
        log_info "Moving et_botnames_ext.gm to ${LEGACY_DIR}/omni-bot/et/scripts/"
        mkdir -p "${LEGACY_DIR}/omni-bot/et/scripts/"
        mv "${SETTINGS_BASE}/bots/et_botnames_ext.gm" "${LEGACY_DIR}/omni-bot/et/scripts/"
    else
        log_info "WARNING: et_botnames_ext.gm not found in ${SETTINGS_BASE}/bots/"
    fi

    # Handle waypoints directory
    if [ -d "${SETTINGS_BASE}/bots/waypoints" ]; then
        log_info "Copying waypoints to ${LEGACY_DIR}/omni-bot/et/nav/"
        mkdir -p "${LEGACY_DIR}/omni-bot/et/nav/"
        cp -r "${SETTINGS_BASE}/bots/waypoints/." "${LEGACY_DIR}/omni-bot/et/nav/"
    else
        log_info "WARNING: waypoints directory not found in ${SETTINGS_BASE}/bots/"
    fi

    # Handle all .toml files with verbose logging
    shopt -s nullglob  # Enable nullglob to handle empty cases
    toml_files=("${SETTINGS_BASE}/tomlfiles/"*.toml)

    if (( ${#toml_files[@]} )); then
        log_info "Found ${#toml_files[@]} .toml file(s) in ${SETTINGS_BASE}/:"
        for file in "${toml_files[@]}"; do
            filename=$(basename "$file")
            log_info " - ${filename}"
        done
        
        log_info "Copying to ${LEGACY_DIR}/"
        cp -v "${toml_files[@]}" "${LEGACY_DIR}/" | while read -r line; do
            log_info " ${line}"
        done
    else
        log_info "WARNING: No .toml files found in ${SETTINGS_BASE}/"
    fi
    shopt -u nullglob  # Disable nullglob

}

# Update server.cfg with CONF vars
update_server_config() {
    cp "${SETTINGS_BASE}/etl_server.cfg" "${ETMAIN_DIR}/etl_server.cfg"
    
    [ -n "${CONF[PASSWORD]}" ] && echo 'set g_needpass "1"' >> "${ETMAIN_DIR}/etl_server.cfg"

    # Replace all configuration placeholders
    for key in "${!CONF[@]}"; do
        value=$(echo "${CONF[$key]}" | sed 's/\//\\\//g')
        sed -i "s/%CONF_${key}%/${value}/g" "${ETMAIN_DIR}/etl_server.cfg"
        sed -i "s/%CONF_${key}%/${value}/g" "${LEGACY_DIR}/luascripts/config.toml"
    done
    
    sed -i 's/%CONF_[A-Z]*%//g' "${ETMAIN_DIR}/etl_server.cfg"
    
    # Handle MOTD configuration if set
    if [ -n "${CONF[MOTD]:-}" ]; then
        # Remove any existing server_motd lines to prevent duplicates
        sed -i '/^set server_motd[0-9]/d' "${ETMAIN_DIR}/etl_server.cfg"
        
        # Create a temporary file for MOTD lines
        local temp_motd=$(mktemp)
        
        # Convert the MOTD string into lines and write to temp file
        local line_num=0
        while IFS= read -r line || [ -n "$line" ]; do 
            echo "set server_motd${line_num}          \"${line}\"" >> "$temp_motd"
            ((line_num++))
        done < <(echo -e "${CONF[MOTD]}" | sed 's/\\n/\n/g')
        
        # Fill remaining slots with empty strings
        while [ $line_num -lt 6 ]; do
            echo "set server_motd${line_num}          \"\"" >> "$temp_motd"
            ((line_num++))
        done
        
        # Insert the MOTD lines after sv_hostname
        sed -i '/^set sv_hostname/r '"$temp_motd" "${ETMAIN_DIR}/etl_server.cfg"
        
        # Clean up
        rm "$temp_motd"
    fi
    
    [ -f "${GAME_BASE}/extra.cfg" ] && cat "${GAME_BASE}/extra.cfg" >> "${ETMAIN_DIR}/etl_server.cfg"
}

# Download extra assets if enabled
handle_extra_content() {
    [ "${CONF[ASSETS]}" = "true" ] || return 0
    
    log_info "Downloading assets..."
    wget -q --show-progress -P "${LEGACY_DIR}" "${CONF[ASSETS_URL]}" ||
        { log_warning "Failed to download assets"; return 1; }
}



# Parse additional CLI arguments
parse_cli_args() {
    local args=()
    local IFS=$' \t\n'
    
    # If ADDITIONAL_CLI_ARGS is empty, return empty array
    [ -z "${ADDITIONAL_CLI_ARGS:-}" ] && echo "${args[@]}" && return

    # Read the string into an array maintaining quotes
    eval "args=($ADDITIONAL_CLI_ARGS)"
    echo "${args[@]}"
}

# Main
[ "${AUTO_UPDATE:-true}" = "true" ] && update_configs
download_maps
copy_game_assets
update_server_config
handle_extra_content

ADDITIONAL_ARGS=($(parse_cli_args))

# Start the game server
exec "${GAME_BASE}/etlded" \
    +set sv_maxclients "${CONF[MAXCLIENTS]}" \
    +set net_port "${CONF[MAP_PORT]}" \
    +set fs_basepath "${GAME_BASE}" \
    +set fs_homepath "/legacy/homepath" \
    +exec "etl_server.cfg" \
    +map "${CONF[STARTMAP]}" \
    "${ADDITIONAL_ARGS[@]}" \
    "$@"