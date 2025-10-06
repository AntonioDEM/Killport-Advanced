# ===============================================
# KillPort Advanced v2.0 - Enhanced Edition
# Funzione ottimizzata per .zshrc con features avanzate
# ===============================================

killport() {
    # Colori per output
    local RED='\033[0;31m'
    local GREEN='\033[0;32m'
    local YELLOW='\033[1;33m'
    local BLUE='\033[0;34m'
    local PURPLE='\033[0;35m'
    local CYAN='\033[0;36m'
    local BOLD='\033[1m'
    local NC='\033[0m'
    
    # Configurazione
    local HISTORY_FILE="$HOME/.killport_history"
    local PROTECTED_PORTS=(22 80 443 3306 5432)
    local MAX_HISTORY=50
    
    # Funzioni di logging
    log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
    log_success() { echo -e "${GREEN}✅ $1${NC}"; }
    log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
    log_error() { echo -e "${RED}❌ $1${NC}"; }
    log_debug() { [[ "$DEBUG" == "1" ]] && echo -e "${PURPLE}🔍 $1${NC}"; }
    
    # Validazione porta
    validate_port() {
        local port=$1
        if ! [[ "$port" =~ ^[0-9]+$ ]] || [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
            log_error "Porta non valida: '$port'. Deve essere tra 1-65535."
            return 1
        fi
        return 0
    }
    
    # Controlla se porta è protetta
    is_protected() {
        local port=$1
        for protected in "${PROTECTED_PORTS[@]}"; do
            if [ "$port" -eq "$protected" ]; then
                return 0
            fi
        done
        return 1
    }
    
    # Aggiungi a history
    add_to_history() {
        local port=$1
        local action=$2
        local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
        echo "$timestamp|$action|$port" >> "$HISTORY_FILE"
        
        # Mantieni solo ultime MAX_HISTORY righe
        if [ -f "$HISTORY_FILE" ]; then
            tail -n $MAX_HISTORY "$HISTORY_FILE" > "${HISTORY_FILE}.tmp"
            mv "${HISTORY_FILE}.tmp" "$HISTORY_FILE"
        fi
    }
    
    # Mostra history
    show_history() {
        if [ ! -f "$HISTORY_FILE" ]; then
            log_warning "Nessuna cronologia disponibile"
            return
        fi
        
        echo -e "${CYAN}📜 Cronologia operazioni (ultime ${MAX_HISTORY}):${NC}"
        echo "================================================"
        printf "${YELLOW}%-20s %-15s %-10s${NC}\n" "TIMESTAMP" "AZIONE" "PORTA"
        printf "%-20s %-15s %-10s\n" "--------------------" "---------------" "----------"
        
        tail -n 20 "$HISTORY_FILE" | while IFS='|' read timestamp action port; do
            printf "%-20s %-15s %-10s\n" "$timestamp" "$action" "$port"
        done
        echo ""
    }
    
    # Espandi range di porte (es: 3000-3010)
    expand_range() {
        local range=$1
        if [[ "$range" =~ ^([0-9]+)-([0-9]+)$ ]]; then
            local start=${BASH_REMATCH[1]}
            local end=${BASH_REMATCH[2]}
            
            if [ "$start" -gt "$end" ]; then
                log_error "Range non valido: $start deve essere <= $end"
                return 1
            fi
            
            seq $start $end
        else
            echo "$range"
        fi
    }
    
    # Help avanzato
show_help() {
    # Color codes
    local RED='\033[0;31m'
    local GREEN='\033[0;32m'
    local YELLOW='\033[1;33m'
    local CYAN='\033[0;36m'
    local PURPLE='\033[0;35m'
    local BLUE='\033[0;34m'
    local BOLD='\033[1m'
    local NC='\033[0m'
    
    # Header pulito e moderno
    echo
    printf "${YELLOW}${BOLD}🚀 KILLPORT ADVANCED v2.0${NC}\n"
    printf "${NC}🔧 Gestione Porte Avanzata${NC}\n"
    echo
    printf "${YELLOW}${BOLD}═══════════════════════════════════════════════════════╗${NC}\n"
    echo
    
    # COMANDI PRINCIPALI
    printf "${BLUE}${BOLD}🎯 COMANDI PRINCIPALI${NC}\n"
    echo
    printf "${BOLD}📚 USO BASE:${NC}\n"
    printf "  ${GREEN}killport <porta>${NC} [opzioni]\n"
    printf "  ${GREEN}killport <p1> <p2> <p3>${NC}\n"
    printf "  ${GREEN}killport <inizio>-<fine>${NC}\n"
    echo
    printf "${BOLD}⚡ ALIAS RAPIDI:${NC}\n"
    printf "  ${GREEN}kp <porta>${NC}          # Alias per killport\n"
    printf "  ${GREEN}kpi${NC}                 # Modalità interattiva\n"
    printf "  ${GREEN}ports${NC}               # Lista porte attive\n"
    printf "  ${GREEN}netstats${NC}            # Statistiche rete\n"
    printf "  ${GREEN}kph${NC}                 # Cronologia\n"
    printf "  ${RED}killport-uninstall${NC}    # Disinstalla\n"
    echo
    printf "${YELLOW}${BOLD}────────────────────────────────────────────────────────╣${NC}\n"
    echo
    
    # OPZIONI AVANZATE
    printf "${PURPLE}${BOLD}🔧 OPZIONI AVANZATE${NC}\n"
    echo
    printf "${BOLD}🎮 MODALITÀ:${NC}\n"
    printf "  ${GREEN}-i, --interactive${NC}     # Selezione interattiva\n"
    printf "  ${GREEN}-f, --force${NC}           # Force kill (SIGKILL)\n"
    printf "  ${GREEN}-d, --dry-run${NC}         # Simula senza eseguire\n"
    printf "  ${GREEN}-w, --watch <porta>${NC}   # Monitora e auto-kill\n"
    echo
    printf "${BOLD}📊 INFORMAZIONI:${NC}\n"
    printf "  ${GREEN}-l, --list [porta]${NC}    # Lista processi\n"
    printf "  ${GREEN}-s, --stats${NC}           # Statistiche di rete\n"
    printf "  ${GREEN}-h, --history${NC}         # Cronologia operazioni\n"
    echo
    printf "${BOLD}🎯 FILTRI:${NC}\n"
    printf "  ${GREEN}--name <processo>${NC}     # Kill per nome\n"
    printf "  ${GREEN}--user <utente>${NC}       # Kill per utente\n"
    echo
    printf "${YELLOW}${BOLD}────────────────────────────────────────────────────────╣${NC}\n"
    echo
    
    # ESEMPI PRATICI
    printf "${GREEN}${BOLD}💡 ESEMPI PRATICI${NC}\n"
    echo
    printf "  ${CYAN}killport 3000${NC}                 # Termina porta 3000\n"
    printf "  ${CYAN}killport 3000 4000 8080${NC}       # Termina 3 porte\n"
    printf "  ${CYAN}killport 8000-8010${NC}            # Range porte\n"
    printf "  ${CYAN}killport 3000 --force${NC}         # Force kill\n"
    printf "  ${CYAN}killport --interactive${NC}        # Selezione interattiva\n"
    printf "  ${CYAN}killport --name node${NC}          # Kill processi node\n"
    printf "  ${CYAN}killport --watch 3000${NC}         # Monitora porta\n"
    echo
    printf "${YELLOW}${BOLD}────────────────────────────────────────────────────────╣${NC}\n"
    echo
    
    # PORTE PROTETTE
    printf "${RED}${BOLD}⚠️  PORTE PROTETTE${NC}\n"
    echo
    printf "  ${RED}22 80 443 3306 5432${NC}\n"
    printf "  ${YELLOW}(richiedono conferma esplicita)${NC}\n"
    echo
    printf "${YELLOW}${BOLD}═══════════════════════════════════════════════════════╝${NC}\n"
    echo
    
    # Footer
    printf "${CYAN}${BOLD}💡 Suggerimento: Usa 'kpi' per la modalità interattiva!${NC}\n"
    echo
    }
    
    # Lista porte avanzata
    list_ports() {
        local filter_port=$1
        
        if [ -n "$filter_port" ]; then
            if ! validate_port "$filter_port"; then
                return 1
            fi
            log_info "Processi sulla porta $filter_port:"
            echo ""
            local found=$(lsof -i :$filter_port -P 2>/dev/null)
            if [ -n "$found" ]; then
                echo "$found" | column -t
            else
                log_warning "Nessun processo trovato sulla porta $filter_port"
            fi
        else
            echo -e "${CYAN}🌐 Porte in ascolto sul sistema:${NC}"
            echo "=================================="
            echo ""
            
            # Crea output formattato
            {
                printf "PORTA\tPROCESSO\tPID\tSTATO\tINDIRIZZO\n"
                lsof -i TCP -P -n 2>/dev/null | grep LISTEN | awk '{
                    gsub(/.*:/, "", $9)
                    printf "%s\t%s\t%s\tLISTEN\t%s\n", $9, $1, $2, $(NF)
                }'
            } | column -t -s $'\t' | head -20
        fi
        echo ""
    }
    
    # Kill processo su porta singola
    kill_single_port() {
        local port=$1
        local force=$2
        local dry_run=$3
        
        if ! validate_port "$port"; then
            return 1
        fi
        
        # Controllo porta protetta
        if is_protected "$port"; then
            log_warning "⚠️  ATTENZIONE: Porta $port è protetta!"
            read -q "REPLY?Continuare comunque? [y/N] "
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                log_info "Operazione annullata"
                return 0
            fi
        fi
        
        # Trova processi
        log_debug "Cercando processi sulla porta $port..."
        local pids=$(lsof -ti :$port 2>/dev/null)
        
        if [ -z "$pids" ]; then
            log_warning "Nessun processo trovato sulla porta $port"
            return 1
        fi
        
        # Mostra processi
        echo -e "${YELLOW}Processi trovati sulla porta $port:${NC}"
        lsof -i :$port -P 2>/dev/null | column -t
        echo ""
        
        if [ "$dry_run" = true ]; then
            log_info "🔍 [DRY-RUN] Verrebbero terminati i PID: $pids"
            return 0
        fi
        
        # Kill processi
        local killed_count=0
        for pid in $pids; do
            local process_info=$(ps -p $pid -o comm= 2>/dev/null)
            
            if [ $? -eq 0 ]; then
                if [ "$force" = true ]; then
                    log_warning "Terminazione forzata: $pid ($process_info)"
                    kill -9 $pid 2>/dev/null
                else
                    log_info "Terminando: $pid ($process_info)"
                    kill $pid 2>/dev/null
                    
                    # Attesa con timeout
                    local attempts=0
                    while [ $attempts -lt 3 ] && kill -0 $pid 2>/dev/null; do
                        sleep 1
                        attempts=$((attempts + 1))
                    done
                    
                    # Force kill se necessario
                    if kill -0 $pid 2>/dev/null; then
                        log_warning "Forzando terminazione: $pid"
                        kill -9 $pid 2>/dev/null
                    fi
                fi
                
                sleep 0.3
                if ! kill -0 $pid 2>/dev/null; then
                    log_success "Terminato: $pid"
                    killed_count=$((killed_count + 1))
                fi
            fi
        done
        
        # Aggiungi a history
        add_to_history "$port" "KILLED"
        
        # Verifica finale
        if ! lsof -i :$port 2>/dev/null >/dev/null; then
            log_success "🎉 Porta $port liberata! ($killed_count processi terminati)"
            return 0
        else
            log_error "Alcuni processi sono ancora attivi sulla porta $port"
            return 1
        fi
    }
    
    # Kill per nome processo
    kill_by_name() {
        local name=$1
        local dry_run=$2
        
        log_info "Cercando processi con nome: $name"
        local pids=$(pgrep -f "$name")
        
        if [ -z "$pids" ]; then
            log_warning "Nessun processo trovato con nome: $name"
            return 1
        fi
        
        echo -e "${YELLOW}Processi trovati:${NC}"
        ps -p $pids -o pid,comm,args | column -t
        echo ""
        
        if [ "$dry_run" = true ]; then
            log_info "🔍 [DRY-RUN] Verrebbero terminati ${#pids[@]} processi"
            return 0
        fi
        
        read -q "REPLY?Terminare questi processi? [y/N] "
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Operazione annullata"
            return 0
        fi
        
        for pid in $pids; do
            kill $pid 2>/dev/null && log_success "Terminato: $pid"
        done
        
        add_to_history "N/A" "KILLED_BY_NAME:$name"
    }
    
    # Modalità interattiva
    interactive_mode() {
        log_info "📋 Modalità interattiva"
        echo ""
        
        # Lista processi con numerazione
        local -a ports_array
        local -a pids_array
        local index=1
        
        echo -e "${CYAN}Processi in ascolto:${NC}"
        printf "${YELLOW}%-5s %-8s %-20s %-8s${NC}\n" "#" "PORTA" "PROCESSO" "PID"
        
        while IFS= read -r line; do
            local port=$(echo "$line" | awk '{print $9}' | sed 's/.*://')
            local process=$(echo "$line" | awk '{print $1}')
            local pid=$(echo "$line" | awk '{print $2}')
            
            if [[ "$port" =~ ^[0-9]+$ ]]; then
                ports_array+=("$port")
                pids_array+=("$pid")
                printf "%-5s %-8s %-20s %-8s\n" "$index" "$port" "$process" "$pid"
                index=$((index + 1))
            fi
        done < <(lsof -i TCP -P -n 2>/dev/null | grep LISTEN)
        
        echo ""
        read "selection?Seleziona numero (o 'q' per uscire): "
        
        if [[ "$selection" == "q" ]]; then
            return 0
        fi
        
        if [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 1 ] && [ "$selection" -lt "$index" ]; then
            local selected_port=${ports_array[$selection]}
            log_info "Selezionata porta: $selected_port"
            kill_single_port "$selected_port" false false
        else
            log_error "Selezione non valida"
        fi
    }
    
    # Watch mode
    watch_mode() {
        local port=$1
        
        if ! validate_port "$port"; then
            return 1
        fi
        
        log_info "👁️  Modalità watch attivata per porta $port"
        log_info "Premi Ctrl+C per interrompere"
        echo ""
        
        local check_count=0
        while true; do
            if lsof -i :$port 2>/dev/null >/dev/null; then
                local pids=$(lsof -ti :$port 2>/dev/null)
                log_warning "Processo rilevato sulla porta $port (Check #$check_count)"
                lsof -i :$port -P 2>/dev/null
                
                log_info "Auto-killing processi: $pids"
                kill_single_port "$port" false false
                echo ""
            fi
            
            check_count=$((check_count + 1))
            sleep 2
        done
    }
    
    # Statistiche avanzate
    show_stats() {
        log_info "Statistiche di rete dettagliate:"
        echo "===================================="
        echo ""
        
        echo -e "${YELLOW}📊 Connessioni TCP per stato:${NC}"
        netstat -an -p tcp 2>/dev/null | awk 'NR>2 && NF>5 {print $6}' | sort | uniq -c | sort -rn | while read count state; do
            printf "  %-15s: %d\n" "$state" "$count"
        done
        echo ""
        
        echo -e "${YELLOW}🔥 Top 5 processi per connessioni:${NC}"
        lsof -i -P 2>/dev/null | awk 'NR>1 {print $1}' | sort | uniq -c | sort -rn | head -5 | while read count process; do
            printf "  %-20s: %d connessioni\n" "$process" "$count"
        done
        echo ""
        
        echo -e "${YELLOW}🎯 Top 5 porte più utilizzate:${NC}"
        lsof -i -P 2>/dev/null | awk 'NR>1 && $9 ~ /:/ {gsub(/.*:/, "", $9); print $9}' | grep '^[0-9]*$' | sort -n | uniq -c | sort -rn | head -5 | while read count port; do
            printf "  Porta %-10s: %d connessioni\n" "$port" "$count"
        done
        echo ""
        
        echo -e "${YELLOW}💾 Totale porte in LISTEN:${NC}"
        local total=$(lsof -i TCP -P 2>/dev/null | grep LISTEN | wc -l | tr -d ' ')
        echo "  $total porte"
        echo ""
    }
    
    # === PARSING ARGOMENTI ===
    local force_kill=false
    local dry_run=false
    local interactive=false
    local watch_port=""
    local filter_name=""
    local filter_user=""
    local -a ports_to_kill
    local action="kill"
    
    # Parse argomenti
    while [[ $# -gt 0 ]]; do
        case $1 in
            --help)
                show_help
                return 0
                ;;
            -i|--interactive)
                interactive=true
                ;;
            -f|--force)
                force_kill=true
                ;;
            -d|--dry-run)
                dry_run=true
                ;;
            -l|--list)
                action="list"
                if [[ "$2" =~ ^[0-9]+$ ]]; then
                    ports_to_kill+=("$2")
                    shift
                fi
                ;;
            -s|--stats)
                show_stats
                return 0
                ;;
            -h|--history)
                show_history
                return 0
                ;;
            -w|--watch)
                if [[ -z "$2" ]] || [[ ! "$2" =~ ^[0-9]+$ ]]; then
                    log_error "--watch richiede una porta"
                    return 1
                fi
                watch_port="$2"
                shift
                ;;
            --name)
                if [[ -z "$2" ]]; then
                    log_error "--name richiede un nome processo"
                    return 1
                fi
                filter_name="$2"
                shift
                ;;
            --user)
                if [[ -z "$2" ]]; then
                    log_error "--user richiede un username"
                    return 1
                fi
                filter_user="$2"
                shift
                ;;
            -*) 
                log_error "Opzione sconosciuta: $1"
                show_help
                return 1
                ;;
            *-*)
                # Range di porte
                for port in $(expand_range "$1"); do
                    ports_to_kill+=("$port")
                done
                ;;
            *)
                # Porta singola o multipla
                if [[ "$1" =~ ^[0-9]+$ ]]; then
                    ports_to_kill+=("$1")
                else
                    log_error "'$1' non è una porta valida"
                    return 1
                fi
                ;;
        esac
        shift
    done
    
    # === ESECUZIONE AZIONI ===
    
    # Watch mode
    if [ -n "$watch_port" ]; then
        watch_mode "$watch_port"
        return 0
    fi
    
    # Interactive mode
    if [ "$interactive" = true ]; then
        interactive_mode
        return 0
    fi
    
    # Kill by name
    if [ -n "$filter_name" ]; then
        kill_by_name "$filter_name" "$dry_run"
        return 0
    fi
    
    # List mode
    if [ "$action" = "list" ]; then
        if [ ${#ports_to_kill[@]} -gt 0 ]; then
            list_ports "${ports_to_kill[1]}"
        else
            list_ports
        fi
        return 0
    fi
    
    # Nessuna porta specificata
    if [ ${#ports_to_kill[@]} -eq 0 ]; then
        show_help
        return 1
    fi
    
    # Kill porte multiple
    if [ ${#ports_to_kill[@]} -gt 1 ]; then
        log_info "🎯 Terminando ${#ports_to_kill[@]} porte: ${ports_to_kill[*]}"
        echo ""
        
        local success_count=0
        local total=${#ports_to_kill[@]}
        
        for port in "${ports_to_kill[@]}"; do
            echo -e "${CYAN}┌── Porta $port ───┐${NC}"
            if kill_single_port "$port" "$force_kill" "$dry_run"; then
                success_count=$((success_count + 1))
            fi
            echo ""
        done
        
        log_info "📊 Risultati: $success_count/$total porte liberate"
        return 0
    fi
    
    # Kill porta singola
    kill_single_port "${ports_to_kill[1]}" "$force_kill" "$dry_run"
}

# Completamento ZSH (solo se compdef disponibile e ZSH attivo)
if [[ -n "$ZSH_VERSION" ]]; then
    if command -v compdef >/dev/null 2>&1; then
        _killport() {
            local -a opts
            opts=(
                '--help:Mostra aiuto'
                '--list:Lista porte'
                '--stats:Statistiche'
                '--history:Cronologia'
                '--interactive:Modalità interattiva'
                '--force:Force kill'
                '--dry-run:Simula operazione'
                '--watch:Modalità watch'
                '--name:Kill per nome'
            )
            _describe 'command' opts
        }
        compdef _killport killport
    fi
fi