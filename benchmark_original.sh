#!/bin/zsh

# ========================================
# KillPort Benchmark Test Suite
# Confronta killport (brew) vs KillPort Advanced v2.0
# ========================================

set -e

# Trap per pulizia in caso di interruzione
trap cleanup_and_exit INT TERM

cleanup_and_exit() {
    echo ""
    log_warning "Interruzione rilevata. Pulizia in corso..."
    cleanup_ports
    log_info "Pulizia completata"
    exit 130
}

# Colori
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Configurazione migliorata
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
# Crea cartella benchmark se non esiste
BENCHMARK_DIR="benchmark"
mkdir -p "$BENCHMARK_DIR"
# File di output nella cartella benchmark
RESULTS_FILE="${BENCHMARK_DIR}/benchmark_results_${TIMESTAMP}.txt"
CSV_FILE="${BENCHMARK_DIR}/benchmark_results_${TIMESTAMP}.csv"
# range porte
TEST_PORTS=(9001 9002 9003 9004 9005 9006 9007 9008 9009 9010 9011 9012 9013 9014 9015)
RANGE_START=${RANGE_START:-9100}
RANGE_END=${RANGE_END:-9120}  # Aumentato da 9109 a 9120 (21 porte)

# Funzioni helper
log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }
log_title() { echo -e "\n${CYAN}${BOLD}╭─── $1 ───╮${NC}\n"; }

# Verifica dipendenze
check_dependencies() {
    log_info "Verificando dipendenze..."
    
    if ! command -v python3 >/dev/null 2>&1; then
        log_error "python3 non trovato. È richiesto per aprire le porte di test."
        exit 1
    fi
    
    if ! type killport >/dev/null 2>&1 && ! command -v killport >/dev/null 2>&1; then
        log_error "Funzione killport non trovata. Assicurati di aver eseguito: source ~/.zshrc"
        log_info "Tentativo di caricamento automatico..."
        source ~/.zshrc 2>/dev/null || true
        
        if ! type killport >/dev/null 2>&1 && ! command -v killport >/dev/null 2>&1; then
            log_error "Impossibile caricare killport. Verifica l'installazione."
            exit 1
        fi
    fi
    
    BREW_KILLPORT_AVAILABLE=false
    if command -v /opt/homebrew/bin/killport >/dev/null 2>&1 || command -v /usr/local/bin/killport >/dev/null 2>&1; then
        BREW_KILLPORT_AVAILABLE=true
        log_success "killport (brew) trovato"
    else
        log_warning "killport (brew) non trovato. Solo KillPort Advanced v2.0 sarà testato."
        log_info "Per installare: brew install killport"
    fi
    
    log_success "Dipendenze verificate"
}

# Apri porta con Python
open_port() {
    local port=$1
    
    python3 -c "
import socket
import sys
import time

try:
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    s.bind(('127.0.0.1', $port))
    s.listen(1)
    print($port, flush=True)
    sys.stdout.flush()
    time.sleep(300)
except Exception as e:
    sys.exit(1)
" >/dev/null 2>&1 &
    
    local pid=$!
    sleep 0.5
    
    if lsof -i :$port >/dev/null 2>&1; then
        return 0
    else
        kill -9 $pid 2>/dev/null || true
        return 1
    fi
}

# Chiudi tutte le porte di test
cleanup_ports() {
    local all_pids=$(lsof -ti :9001-9010,9100-9109 2>/dev/null)
    if [ -n "$all_pids" ]; then
        echo $all_pids | xargs kill -9 2>/dev/null || true
    fi
    sleep 0.3
}

# Calcola statistiche avanzate con gestione valori zero
calc_enhanced_stats() {
    local values=()
    # Filtra solo i valori validi (> 0)
    for val in "$@"; do
        if [[ "$val" =~ ^[0-9]+$ ]] && [ "$val" -gt 0 ]; then
            values+=($val)
        fi
    done
    
    local count=${#values[@]}
    if [ $count -eq 0 ]; then
        echo "0:0:0:0" # min:max:avg:stddev
        return
    fi
    
    local sum=0
    local min=${values[0]}
    local max=${values[0]}
    
    # Calcola somma, min, max
    for val in "${values[@]}"; do
        sum=$((sum + val))
        (( val < min )) && min=$val
        (( val > max )) && max=$val
    done
    
    local avg=$((sum / count))
    
    # Calcola deviazione standard
    local var_sum=0
    for val in "${values[@]}"; do
        local diff=$((val - avg))
        var_sum=$((var_sum + diff * diff))
    done
    
    local variance=$((var_sum / count))
    local stddev=$(awk "BEGIN { printf \"%.0f\", sqrt($variance) }" 2>/dev/null || echo "0")
    
    echo "$min:$max:$avg:$stddev"
}

# Misura tempo di esecuzione - CORRETTO
measure_time() {
    local cmd="$1"
    
    local start=$(perl -MTime::HiRes=time -e 'printf "%.0f\n", time * 1000')
    
    # Esegui comando catturando stderr per diagnostica
    local output=$(eval "$cmd" 2>&1)
    local exit_code=$?
    
    local end=$(perl -MTime::HiRes=time -e 'printf "%.0f\n", time * 1000')
    local elapsed=$((end - start))
    
    # Se fallisce o tempo = 0, restituisci -1
    if [ $exit_code -ne 0 ] || [ $elapsed -eq 0 ]; then
        echo "-1"
    else
        echo "$elapsed"
    fi
}

# Test 1: Kill singola porta - MIGLIORATO
test_single_port() {
    log_title "TEST 1: Kill Singola Porta"
    
    local results=()
    local advanced_times=()
    local brew_times=()
    
    for i in {1..5}; do
        log_info "Iterazione $i/5..."
        
        cleanup_ports
        open_port 9001 >/dev/null
        sleep 0.3
        
        local time_advanced=$(measure_time "killport 9001")
        if [ "$time_advanced" != "-1" ]; then
            results+=("advanced:$time_advanced")
            advanced_times+=($time_advanced)
        fi
        
        sleep 0.5
        
        if [ "$BREW_KILLPORT_AVAILABLE" = true ]; then
            cleanup_ports
            open_port 9001 >/dev/null
            sleep 0.3
            
            local time_brew=$(measure_time "/opt/homebrew/bin/killport 9001 2>/dev/null || /usr/local/bin/killport 9001 2>/dev/null")
            if [ "$time_brew" != "-1" ]; then
                results+=("brew:$time_brew")
                brew_times+=($time_brew)
            fi
        fi
        
        sleep 0.5
    done
    
    local sum_advanced=0
    local count_advanced=0
    local sum_brew=0
    local count_brew=0
    
    for result in "${results[@]}"; do
        if [[ $result == advanced:* ]]; then
            time=${result#advanced:}
            sum_advanced=$((sum_advanced + time))
            count_advanced=$((count_advanced + 1))
        elif [[ $result == brew:* ]]; then
            time=${result#brew:}
            sum_brew=$((sum_brew + time))
            count_brew=$((count_brew + 1))
        fi
    done
    
    echo "TEST 1: Singola Porta" >> "$RESULTS_FILE"
    
    # Calcola statistiche avanzate
    local advanced_stats=$(calc_enhanced_stats "${advanced_times[@]}")
    local brew_stats=$(calc_enhanced_stats "${brew_times[@]}")
    
    if [ $count_advanced -gt 0 ]; then
        local avg_advanced=$((sum_advanced / count_advanced))
        IFS=':' read -r min_a max_a avg_a stddev_a <<< "$advanced_stats"
        echo "  KillPort Advanced v2.0: avg=${avg_a}ms, min=${min_a}ms, max=${max_a}ms, σ=±${stddev_a}ms ($count_advanced test)"
        echo "  KillPort Advanced v2.0: avg=${avg_a}ms, min=${min_a}ms, max=${max_a}ms, stddev=${stddev_a}ms" >> "$RESULTS_FILE"
    else
        echo "  KillPort Advanced v2.0: N/A"
        echo "  KillPort Advanced v2.0: N/A" >> "$RESULTS_FILE"
    fi
    
    if [ $count_brew -gt 0 ]; then
        local avg_brew=$((sum_brew / count_brew))
        IFS=':' read -r min_b max_b avg_b stddev_b <<< "$brew_stats"
        echo "  killport (brew):        avg=${avg_b}ms, min=${min_b}ms, max=${max_b}ms, σ=±${stddev_b}ms ($count_brew test)"
        echo "  killport (brew):        avg=${avg_b}ms, min=${min_b}ms, max=${max_b}ms, stddev=${stddev_b}ms" >> "$RESULTS_FILE"
        
        if [ $count_advanced -gt 0 ] && [ "$avg_b" -gt 0 ]; then
            local diff=$((avg_a - avg_b))
            local percent=$(( (diff * 100) / avg_b ))
            echo "  Differenza (avg):       ${diff}ms (${percent}%)"
            echo "  Differenza (avg):       ${diff}ms (${percent}%)" >> "$RESULTS_FILE"
        fi
    fi
    
    echo "" >> "$RESULTS_FILE"
}

# Test 2: Kill multiple porte (3)
test_multiple_ports_3() {
    log_title "TEST 2: Kill 3 Porte Simultanee"
    
    local results=()
    
    for i in {1..5}; do
        log_info "Iterazione $i/5..."
        
        cleanup_ports
        open_port 9001 >/dev/null
        open_port 9002 >/dev/null
        open_port 9003 >/dev/null
        sleep 0.5
        
        local time_advanced=$(measure_time "killport 9001 9002 9003")
        if [ "$time_advanced" != "-1" ]; then
            results+=("advanced:$time_advanced")
        fi
        
        sleep 0.5
        
        if [ "$BREW_KILLPORT_AVAILABLE" = true ]; then
            cleanup_ports
            open_port 9001 >/dev/null
            open_port 9002 >/dev/null
            open_port 9003 >/dev/null
            sleep 0.5
            
            local time_brew=$(measure_time "/opt/homebrew/bin/killport 9001 9002 9003 2>/dev/null || /usr/local/bin/killport 9001 9002 9003 2>/dev/null")
            if [ "$time_brew" != "-1" ]; then
                results+=("brew:$time_brew")
            fi
        fi
        
        sleep 0.5
    done
    
    local sum_advanced=0
    local count_advanced=0
    local sum_brew=0
    local count_brew=0
    
    for result in "${results[@]}"; do
        if [[ $result == advanced:* ]]; then
            time=${result#advanced:}
            sum_advanced=$((sum_advanced + time))
            count_advanced=$((count_advanced + 1))
        elif [[ $result == brew:* ]]; then
            time=${result#brew:}
            sum_brew=$((sum_brew + time))
            count_brew=$((count_brew + 1))
        fi
    done
    
    echo "TEST 2: 3 Porte Simultanee" >> "$RESULTS_FILE"
    
    if [ $count_advanced -gt 0 ]; then
        local avg_advanced=$((sum_advanced / count_advanced))
        echo "  KillPort Advanced v2.0: ${avg_advanced}ms (media su $count_advanced test)"
        echo "  KillPort Advanced v2.0: ${avg_advanced}ms" >> "$RESULTS_FILE"
    else
        echo "  KillPort Advanced v2.0: N/A"
        echo "  KillPort Advanced v2.0: N/A" >> "$RESULTS_FILE"
    fi
    
    if [ $count_brew -gt 0 ]; then
        local avg_brew=$((sum_brew / count_brew))
        echo "  killport (brew):        ${avg_brew}ms (media su $count_brew test)"
        echo "  killport (brew):        ${avg_brew}ms" >> "$RESULTS_FILE"
        
        if [ $count_advanced -gt 0 ]; then
            local avg_advanced=$((sum_advanced / count_advanced))
            local diff=$((avg_advanced - avg_brew))
            local percent=$(( (diff * 100) / avg_brew ))
            echo "  Differenza:             ${diff}ms (${percent}%)"
            echo "  Differenza:             ${diff}ms (${percent}%)" >> "$RESULTS_FILE"
        fi
    fi
    
    echo "" >> "$RESULTS_FILE"
}

# Test 3: Kill range porte - MIGLIORATO
test_port_range() {
    local port_count=$((RANGE_END - RANGE_START + 1))
    log_title "TEST 3: Kill Range Porte ($port_count porte: $RANGE_START-$RANGE_END)"
    
    local results=()
    local advanced_times=()
    local brew_times=()
    
    for i in {1..3}; do
        log_info "Iterazione $i/3..."
        
        cleanup_ports
        sleep 0.5
        
        log_info "Aprendo $port_count porte..."
        for port in $(seq $RANGE_START $RANGE_END); do
            open_port $port >/dev/null &
        done
        sleep 3  # Più tempo per porte multiple
        
        local open_count=$(lsof -i :$RANGE_START-$RANGE_END 2>/dev/null | grep LISTEN | wc -l | tr -d ' ')
        log_info "Porte aperte: $open_count/$port_count"
        
        # Soglia adattiva: almeno 70% delle porte
        local min_ports=$(( port_count * 7 / 10 ))
        if [ "$open_count" -lt "$min_ports" ]; then
            log_warning "Poche porte aperte ($open_count < $min_ports), salto iterazione"
            continue
        fi
        
        # Test con OUTPUT VISIBILE per debug
        log_info "Testing KillPort Advanced con range ${RANGE_START}-${RANGE_END}..."
        local time_advanced=$(measure_time "killport ${RANGE_START}-${RANGE_END}")
        
        if [ "$time_advanced" != "-1" ]; then
            results+=("advanced:$time_advanced")
            advanced_times+=($time_advanced)
            log_success "Advanced: ${time_advanced}ms"
        else
            log_error "Test Advanced fallito - comando non eseguito correttamente"
        fi
        
        sleep 0.5
        
        if [ "$BREW_KILLPORT_AVAILABLE" = true ]; then
            cleanup_ports
            sleep 0.5
            
            log_info "Aprendo 10 porte per brew..."
            for port in $(seq $RANGE_START $RANGE_END); do
                open_port $port >/dev/null &
            done
            sleep 2
            
            open_count=$(lsof -i :$RANGE_START-$RANGE_END 2>/dev/null | grep LISTEN | wc -l | tr -d ' ')
            
            if [ "$open_count" -ge "$min_ports" ]; then
                local time_brew=$(measure_time "/opt/homebrew/bin/killport ${RANGE_START}-${RANGE_END} 2>/dev/null || /usr/local/bin/killport ${RANGE_START}-${RANGE_END} 2>/dev/null")
                if [ "$time_brew" != "-1" ]; then
                    results+=("brew:$time_brew")
                    brew_times+=($time_brew)
                    log_success "Brew: ${time_brew}ms"
                fi
            fi
        fi
        
        sleep 0.5
    done
    
    local sum_advanced=0
    local count_advanced=0
    local sum_brew=0
    local count_brew=0
    
    for result in "${results[@]}"; do
        if [[ $result == advanced:* ]]; then
            time=${result#advanced:}
            sum_advanced=$((sum_advanced + time))
            count_advanced=$((count_advanced + 1))
        elif [[ $result == brew:* ]]; then
            time=${result#brew:}
            sum_brew=$((sum_brew + time))
            count_brew=$((count_brew + 1))
        fi
    done
    
    echo "TEST 3: Range 10 Porte (9100-9109)" >> "$RESULTS_FILE"
    
    if [ $count_advanced -gt 0 ]; then
        local avg_advanced=$((sum_advanced / count_advanced))
        echo "  KillPort Advanced v2.0: ${avg_advanced}ms (media su $count_advanced test)"
        echo "  KillPort Advanced v2.0: ${avg_advanced}ms" >> "$RESULTS_FILE"
    else
        echo "  KillPort Advanced v2.0: N/A"
        echo "  KillPort Advanced v2.0: N/A" >> "$RESULTS_FILE"
    fi
    
    if [ $count_brew -gt 0 ]; then
        local avg_brew=$((sum_brew / count_brew))
        echo "  killport (brew):        ${avg_brew}ms (media su $count_brew test)"
        echo "  killport (brew):        ${avg_brew}ms" >> "$RESULTS_FILE"
        
        if [ $count_advanced -gt 0 ] && [ $avg_brew -gt 0 ]; then
            local avg_advanced=$((sum_advanced / count_advanced))
            local diff=$((avg_advanced - avg_brew))
            local percent=$(( (diff * 100) / avg_brew ))
            echo "  Differenza:             ${diff}ms (${percent}%)"
            echo "  Differenza:             ${diff}ms (${percent}%)" >> "$RESULTS_FILE"
        fi
    fi
    
    echo "" >> "$RESULTS_FILE"
}

# Test 4: Lista porte
test_list_ports() {
    log_title "TEST 4: Lista Porte (solo KillPort Advanced)"
    
    cleanup_ports
    sleep 0.5
    for port in {9001..9005}; do
        open_port $port >/dev/null &
    done
    sleep 1
    
    local time_list=$(measure_time "killport --list")
    
    if [ "$time_list" != "-1" ]; then
        echo "  killport --list:        ${time_list}ms"
        echo "TEST 4: Lista Porte" >> "$RESULTS_FILE"
        echo "  killport --list:        ${time_list}ms" >> "$RESULTS_FILE"
    else
        echo "  killport --list:        N/A"
        echo "TEST 4: Lista Porte" >> "$RESULTS_FILE"
        echo "  killport --list:        N/A" >> "$RESULTS_FILE"
    fi
    
    echo "" >> "$RESULTS_FILE"
}

# Test 5: Statistiche
test_stats() {
    log_title "TEST 5: Statistiche di Rete (solo KillPort Advanced)"
    
    cleanup_ports
    for port in {9001..9003}; do
        open_port $port >/dev/null &
    done
    sleep 0.5
    
    local time_stats=$(measure_time "killport --stats")
    
    if [ "$time_stats" != "-1" ]; then
        echo "  killport --stats:       ${time_stats}ms"
        echo "TEST 5: Statistiche di Rete" >> "$RESULTS_FILE"
        echo "  killport --stats:       ${time_stats}ms" >> "$RESULTS_FILE"
    else
        echo "  killport --stats:       N/A"
        echo "TEST 5: Statistiche di Rete" >> "$RESULTS_FILE"
        echo "  killport --stats:       N/A" >> "$RESULTS_FILE"
    fi
    
    echo "" >> "$RESULTS_FILE"
}

# Export CSV
export_csv() {
    echo "test_name,tool,min_ms,max_ms,avg_ms,stddev_ms,samples" > "$CSV_FILE"
    
    # Estrai dati dal file risultati usando parsing semplice
    local test_num=1
    while IFS= read -r line; do
        if [[ $line =~ "TEST $test_num:" ]]; then
            local test_name=$(echo "$line" | sed 's/TEST [0-9]*: //')
            test_num=$((test_num + 1))
        elif [[ $line =~ "KillPort Advanced.*: avg=([0-9]+)ms, min=([0-9]+)ms, max=([0-9]+)ms, stddev=([0-9]+)ms" ]]; then
            local avg="${BASH_REMATCH[1]}"
            local min="${BASH_REMATCH[2]}"
            local max="${BASH_REMATCH[3]}"
            local stddev="${BASH_REMATCH[4]}"
            echo "$test_name,Advanced,$min,$max,$avg,$stddev,5" >> "$CSV_FILE"
        elif [[ $line =~ "killport \(brew\).*: avg=([0-9]+)ms, min=([0-9]+)ms, max=([0-9]+)ms, stddev=([0-9]+)ms" ]]; then
            local avg="${BASH_REMATCH[1]}"
            local min="${BASH_REMATCH[2]}"
            local max="${BASH_REMATCH[3]}"
            local stddev="${BASH_REMATCH[4]}"
            echo "$test_name,Brew,$min,$max,$avg,$stddev,5" >> "$CSV_FILE"
        fi
    done < "$RESULTS_FILE"
}

# Genera report finale migliorato
generate_report() {
    log_title "REPORT COMPLETO"
    cat "$RESULTS_FILE"
    
    # Export CSV
    export_csv
    
    echo ""
    log_success "📊 Report testuale: $RESULTS_FILE"
    log_success "📈 Dati CSV:       $CSV_FILE"
    
    # Mostra info riassuntive
    echo ""
    log_info "📋 Riassunto configurazione:"
    echo "  • Iterazioni per test: 5 (test 1-2), 3 (test 3)"
    echo "  • Range porte testato: $RANGE_START-$RANGE_END ($((RANGE_END - RANGE_START + 1)) porte)"
    echo "  • Statistiche: Min/Max/Media/DevStd per ogni test"
}

# Banner
echo -e "${CYAN}${BOLD}"
cat << 'EOF'
╔═══════════════════════════════════════════════╗
║     KillPort Benchmark Test Suite v1.0       ║
║   Confronto Performance killport vs v2.0     ║
╚═══════════════════════════════════════════════╝
EOF
echo -e "${NC}"

echo "KillPort Benchmark Results - $(date)" > "$RESULTS_FILE"
echo "==========================================" >> "$RESULTS_FILE"
echo "" >> "$RESULTS_FILE"

check_dependencies
echo ""

test_single_port
test_multiple_ports_3
test_port_range
test_list_ports
test_stats

cleanup_ports
generate_report

echo ""
log_success "Benchmark completato!"
log_info "Tutti i risultati sono disponibili in: $RESULTS_FILE"