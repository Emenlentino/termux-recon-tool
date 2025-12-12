#!/bin/bash

# 🎨 Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m' # No Color

# 📓 Log file
log_file="$HOME/finder_log.txt"

# 🕒 Timestamp
timestamp() {
    date "+%Y-%m-%d %H:%M:%S"
}

# 📝 Log function
log_action() {
    echo "[$(timestamp)] $1" >> "$log_file"
}

# ⏳ Progress Bar
progress_bar(){
    echo -ne "${YELLOW}Scanning"
    for i in {1..10}; do echo -ne "."; sleep 0.1; done
    echo -e "${NC}"
}

# 🔍 Local File Recon
hood_recon(){
    echo -e "${GREEN}\n🔎 What file you tryna locate? (name, *.ext, or partial):${NC}"
    read -r query
    folder="$HOME"
    echo -e "${YELLOW}📁 Scanning in: $folder${NC}"
    log_action "Started local directory for '$query' in $folder"

    echo -e "${YELLOW}\n⏳ Starting scan for '$query'...${NC}"
    progress_bar

    [[ "$query" != *'*'* ]] && query="*$query*"
    mapfile -t results < <(find "$folder" -type f -name "$query" 2>/dev/null)

    if [[ ${#results[@]} -eq 0 ]]; then
        echo -e "${RED}❌ No sign of '$query'. Might be ghostin'.${NC}\n"
        log_action "No results found for '$query'"
        return
    fi

    echo -e "${GREEN}✅ Found ${#results[@]} file(s):${NC}\n"
    log_action "Found ${#results[@]} result(s) for '$query'"

    for path in "${results[@]}"; do
        size=$(du -h "$path" | cut -f1)
        type=$(file "$path" | cut -d: -f2)
        mod=$(date -r "$path")
        hash=$(md5sum "$path" | cut -d ' ' -f1)

        echo -e "${BLUE}📍 Location: $path${NC}"
        echo -e "${YELLOW}📦 Size: $size${NC}"
        echo -e "${YELLOW}🧬 Type:$type${NC}"
        echo -e "${YELLOW}📅 Modified: $mod${NC}"
        echo -e "${YELLOW}🔐 MD5: $hash${NC}"
        echo -e "${NC}----------------------------------------\n"

        log_action "File: $path | Size: $size | Type:$type | Modified: $mod | MD5: $hash"
    done

    echo -e "${GREEN}🎯 Recon complete. You got the goods.${NC}\n"
}

# 🌐 Remote File Scan (SSH)
remote_scan(){
    echo -e "${BLUE}Enter remote host (user@ip):${NC}"
    read -r remote_host
    echo -e "${BLUE}Enter remote file name to search:${NC}"
    read -r remote_file
    log_action "Remote scan initiated on $remote_host for '$remote_file'"
    ssh "$remote_host" "find / -type f -name '*$remote_file*' 2>/dev/null"
}

# 🗑️ Delete a File
delete_file(){
    echo -e "${RED}Enter full path of file to delete:${NC}"
    read -r del_path
    if [[ -f "$del_path" ]]; then
        echo -e "${YELLOW}Are you sure you want to delete '$del_path'? (y/n):${NC}"
        read -r confirm
        if [[ "$confirm" == "y" ]]; then
            rm "$del_path" && {
                echo -e "${GREEN}✅ File deleted.${NC}"
                log_action "Deleted file: $del_path"
            } || {
                echo -e "${RED}❌ Failed to delete.${NC}"
                log_action "Failed to delete file: $del_path"
            }
        else
            echo -e "${BLUE}🛑 Deletion canceled.${NC}"
            log_action "Deletion canceled for: $del_path"
        fi
    else
        echo -e "${RED}❌ File not found.${NC}"
        log_action "File not found for deletion: $del_path"
    fi
}

# 📸 Preview File Contents
preview_file(){
    echo -e "${BLUE}Enter full path of file to preview:${NC}"
    read -r file
    if [[ -f "$file" ]]; then
        mime=$(file --mime-type -b "$file")
        log_action "Previewing file: $file | MIME: $mime"
        case $mime in
            text/*) head -n 20 "$file" ;;
            image/*) exiftool "$file" ;;
            *) echo -e "${YELLOW}Unsupported preview type: $mime${NC}" ;;
        esac
    else
        echo -e "${RED}❌ File not found.${NC}"
        log_action "Preview failed — file not found: $file"
    fi
}

# 🧹 Auto-Clean Junk Files
clean_junk(){
    echo -e "${YELLOW}🧹 Cleaning junk files in $HOME...${NC}"
    log_action "Started junk file cleanup in $HOME"
    find "$HOME" \( -name "*.log" -o -name "*.tmp" -o -name "*.bak" -o -empty \) -type f -print -delete >> "$log_file"
    echo -e "${GREEN}✅ Junk files removed.${NC}"
    log_action "Junk cleanup complete"
}

# 🧪 Regex File Search
regex_search(){
    echo -e "${GREEN}Enter regex pattern to search filenames:${NC}"
    read -r pattern
    echo -e "${YELLOW}Searching in $HOME...${NC}"
    log_action "Regex search for pattern: $pattern"
    find "$HOME" -type f | grep -E "$pattern" | tee -a "$log_file"
}

# 🔒 Permission Audit
permission_audit(){
    echo -e "${BLUE}Enter full path of file to audit:${NC}"
    read -r file
    if [[ -e "$file" ]]; then
        perms=$(stat -c "%A %U %G" "$file")
        echo -e "${YELLOW}🔒 Permissions: $perms${NC}"
        log_action "Permission audit for $file: $perms"
    else
        echo -e "${RED}❌ File not found.${NC}"
        log_action "Permission audit failed — file not found: $file"
    fi
}

# 📤 Export Log to Cloud
export_to_cloud(){
    echo -e "${BLUE}Choose cloud target (dropbox, gdrive):${NC}"
    read -r remote
    if [[ -f "$log_file" ]]; then
        rclone copy "$log_file" "$remote:hoodfinder_logs" && {
            echo -e "${GREEN}✅ Log exported to '$remote'.${NC}"
            log_action "Log exported to $remote"
        } || {
            echo -e "${RED}❌ Export failed. Check rclone config.${NC}"
            log_action "Log export failed to $remote"
        }
    else
        echo -e "${RED}❌ No log file found to export.${NC}"
        log_action "Export failed — no log file found"
    fi
}

# 🧩 Main Menu
hood_menu(){
    while true; do
        echo -e "${BLUE}===== HoodFinder Menu =====${NC}"
        echo -e "${YELLOW}1) 🔍 Local File Recon"
        echo -e "2) 🌐 Remote File Scan (SSH)"
        echo -e "3) 🗑️  Delete a File"
        echo -e "4) 📸 Preview File Contents"
        echo -e "5) 🧹 Auto-Clean Junk Files"
        echo -e "6) 🧪 Regex File Search"
        echo -e "7) 🔒 Permission Audit"
        echo -e "8) 📤 Export Log to Cloud"
        echo -e "9) ❌ Exit${NC}"
        echo -ne "${GREEN}Choose your hustle: ${NC}"
        read -r choice

        case $choice in
            1) hood_recon ;;
            2) remote_scan ;;
            3) delete_file ;;
            4) preview_file ;;
            5) clean_junk ;;
            6) regex_search ;;
            7) permission_audit ;;
            8) export_to_cloud ;;
            9) echo -e "${RED}👋 Peace out, hacker.${NC}"; log_action "Exited HoodFinder"; break ;;
            *) echo -e "${RED}❌ Invalid choice. Try again.${NC}" ;;
        esac
    done
}

# 🚀 Launch
hood_menu
