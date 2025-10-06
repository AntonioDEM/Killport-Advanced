#!/bin/bash

# ========================================
# Visualizzatore Risultati Benchmark
# Crea grafici ASCII dai risultati
# ========================================

# Colori
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Trova ultimo file risultati nella cartella benchmark
BENCHMARK_DIR="benchmark"

if [ ! -d "$BENCHMARK_DIR" ]; then
    echo -e "${RED}❌ Cartella benchmark/ non trovata${NC}"
    echo "Esegui prima: ./benchmark_original.sh"
    exit 1
fi

RESULTS_FILE=$(ls -t ${BENCHMARK_DIR}/benchmark_results_*.txt 2>/dev/null | head -1)

if [ -z "$RESULTS_FILE" ]; then
    echo -e "${RED}❌ Nessun file di risultati trovato in ${BENCHMARK_DIR}/${NC}"
    echo "Esegui prima: ./benchmark_original.sh"
    exit 1
fi

# Mostra legenda e istruzioni
show_legend() {
    echo -e "${YELLOW}${BOLD}┌─── LEGENDA GRAFICI ───┐${NC}"
    echo -e "${YELLOW}│${NC} ${GREEN}█${NC} - Barra performance        ${YELLOW}│${NC}"
    echo -e "${YELLOW}│${NC} ${CYAN}[min-max]${NC} - Range valori      ${YELLOW}│${NC}"
    echo -e "${YELLOW}│${NC} ${WHITE}σ=±N${NC} - Deviazione standard  ${YELLOW}│${NC}"
    echo -e "${YELLOW}└────────────────────────┘${NC}\n"
    
    echo -e "${MAGENTA}${BOLD}INTERPRETAZIONE RISULTATI:${NC}"
    echo -e "  ${GREEN}• < 30ms${NC}   - Eccellente"
    echo -e "  ${YELLOW}• 30-60ms${NC}  - Buono"
    echo -e "  ${RED}• > 60ms${NC}   - Lento"
    echo -e "  ${BLUE}• σ < 5ms${NC}   - Molto consistente"
    echo -e "  ${YELLOW}• σ 5-15ms${NC} - Accettabile"
    echo -e "  ${RED}• σ > 15ms${NC}  - Inconsistente\n"
}

echo -e "${CYAN}${BOLD}"
cat << 'EOF'
╔══════════════════════════════════════════════════╗
║    Visualizzatore Benchmark Results Enhanced     ║
║         Con Legenda e Interpretazione            ║
╚══════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

echo -e "${BLUE}📊 Analizzando: $RESULTS_FILE${NC}\n"

show_legend

# Estrai dati - MIGLIORATO per formati multipli
extract_value() {
    local test_name="$1"
    local tool="$2"
    
    # Cerca la riga che contiene il tool name
    local line=$(grep -A 5 "$test_name" "$RESULTS_FILE" | grep "$tool" | head -1)
    
    # Se la riga contiene "N/A", ritorna vuoto
    if echo "$line" | grep -q "N/A"; then
        echo ""
        return
    fi
    
    # Prova formato nuovo: avg=XXms
    local value=$(echo "$line" | grep -oE 'avg=([0-9]+)ms' | head -1 | sed 's/avg=//' | sed 's/ms//')
    
    # Se non trovato, prova formato legacy: XXms
    if [ -z "$value" ]; then
        value=$(echo "$line" | sed 's/.*: *//' | grep -oE '[0-9]+ms' | head -1 | sed 's/ms//')
    fi
    
    echo "$value"
}

# Estrai statistiche avanzate (se disponibili)
extract_advanced_stats() {
    local test_name="$1"
    local tool="$2"
    
    local line=$(grep -A 5 "$test_name" "$RESULTS_FILE" | grep "$tool" | head -1)
    
    # Cerca formato: avg=XXms, min=YYms, max=ZZms, stddev=WWms
    if [[ $line =~ avg=([0-9]+)ms,\ min=([0-9]+)ms,\ max=([0-9]+)ms,\ stddev=([0-9]+)ms ]]; then
        local avg="${BASH_REMATCH[1]}"
        local min="${BASH_REMATCH[2]}"
        local max="${BASH_REMATCH[3]}"
        local stddev="${BASH_REMATCH[4]}"
        echo "$min:$max:$avg:$stddev"
    else
        # Formato legacy - solo media
        local avg=$(extract_value "$test_name" "$tool")
        if [ -n "$avg" ]; then
            echo "$avg:$avg:$avg:0"
        else
            echo ""
        fi
    fi
}

# Estrai valori per compatibilità (solo media)
t1_advanced=$(extract_value "TEST 1" "KillPort Advanced")
t1_brew=$(extract_value "TEST 1" "killport (brew)")
t2_advanced=$(extract_value "TEST 2" "KillPort Advanced")
t2_brew=$(extract_value "TEST 2" "killport (brew)")
t3_advanced=$(extract_value "TEST 3" "KillPort Advanced")
t3_brew=$(extract_value "TEST 3" "killport (brew)")
t4_list=$(extract_value "TEST 4" "killport --list")
t5_stats=$(extract_value "TEST 5" "killport --stats")

# Estrai statistiche avanzate
t1_advanced_stats=$(extract_advanced_stats "TEST 1" "KillPort Advanced")
t1_brew_stats=$(extract_advanced_stats "TEST 1" "killport (brew)")
t2_advanced_stats=$(extract_advanced_stats "TEST 2" "KillPort Advanced")
t2_brew_stats=$(extract_advanced_stats "TEST 2" "killport (brew)")
t3_advanced_stats=$(extract_advanced_stats "TEST 3" "KillPort Advanced")
t3_brew_stats=$(extract_advanced_stats "TEST 3" "killport (brew)")

# Funzione per mostrare statistiche se disponibili
show_enhanced_stats() {
    local stats="$1"
    local value="$2"  # fallback value
    
    if [ -n "$stats" ] && [[ $stats =~ ^[0-9]+:[0-9]+:[0-9]+:[0-9]+$ ]]; then
        IFS=':' read -r min max avg stddev <<< "$stats"
        printf "  ${avg}ms ${CYAN}[${min}-${max}]${NC}"
        if [ "$stddev" -gt 0 ]; then
            
            # Colore per deviazione standard
            if [ "$stddev" -lt 5 ]; then
                printf " ${GREEN}σ=±${stddev}${NC}"
            elif [ "$stddev" -le 15 ]; then
                printf " ${YELLOW}σ=±${stddev}${NC}"
            else
                printf " ${RED}σ=±${stddev}${NC}"
            fi
        fi
        echo "ms"
        return 0
    else
        # Fallback al formato semplice
        printf "  ${value}ms"
        echo
        return 1
    fi
}

# Funzione per creare barra grafica - MIGLIORATA
create_bar() {
    local value=$1
    local max_value=$2
    local width=40
    
    # Gestisci casi speciali
    if [ -z "$value" ] || [ "$value" -eq 0 ] || [ "$max_value" -eq 0 ]; then
        printf "[%-${width}s]" ""
        return
    fi
    
    # Calcola quanti caratteri riempire
    local filled=$(( (value * width) / max_value ))
    
    # Proteggi contro overflow
    if [ $filled -gt $width ]; then
        filled=$width
    fi
    
    printf "["
    for ((i=0; i<filled; i++)); do
        printf "█"
    done
    for ((i=filled; i<width; i++)); do
        printf " "
    done
    printf "]"
}

# Funzione per calcolare differenza in modo sicuro
calc_diff() {
    local val1=$1
    local val2=$2
    
    if [ -z "$val1" ] || [ -z "$val2" ] || [ "$val2" -eq 0 ]; then
        echo ""
    else
        local diff=$((val1 - val2))
        local percent=$(( (diff * 100) / val2 ))
        echo "$diff:$percent"
    fi
}

# Trova valore massimo per ogni test per scalare le barre
find_max() {
    local v1=$1
    local v2=$2
    
    local max=0
    
    if [ -n "$v1" ] && [ "$v1" -gt "$max" ]; then
        max=$v1
    fi
    
    if [ -n "$v2" ] && [ "$v2" -gt "$max" ]; then
        max=$v2
    fi
    
    # Se max è 0, usa 100 come default
    if [ "$max" -eq 0 ]; then
        max=100
    fi
    
    echo $max
}

# TEST 1
echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}TEST 1: Kill Singola Porta${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

max_t1=$(find_max "$t1_advanced" "$t1_brew")

if [ -n "$t1_advanced" ]; then
    echo -e "${GREEN}KillPort Advanced v2.0${NC}"
    show_enhanced_stats "$t1_advanced_stats" "$t1_advanced"
    create_bar $t1_advanced $max_t1
    echo ""
else
    echo -e "${YELLOW}KillPort Advanced v2.0: N/A${NC}"
fi

if [ -n "$t1_brew" ]; then
    echo -e "${BLUE}killport (brew)${NC}"
    show_enhanced_stats "$t1_brew_stats" "$t1_brew"
    create_bar $t1_brew $max_t1
    echo ""
    
    if [ -n "$t1_advanced" ]; then
        diff_data=$(calc_diff $t1_advanced $t1_brew)
        if [ -n "$diff_data" ]; then
            diff=$(echo $diff_data | cut -d: -f1)
            percent=$(echo $diff_data | cut -d: -f2)
            
            if [ $diff -gt 0 ]; then
                echo -e "  ${YELLOW}⚡ brew è più veloce di ${diff}ms (${percent}%)${NC}"
            elif [ $diff -lt 0 ]; then
                echo -e "  ${GREEN}⚡ Advanced è più veloce di ${diff#-}ms${NC}"
            else
                echo -e "  ${CYAN}⚖️  Stessa velocità${NC}"
            fi
        fi
    fi
else
    echo -e "${YELLOW}killport (brew): N/A${NC}"
fi

echo ""

# TEST 2
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}TEST 2: Kill 3 Porte Simultanee${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

max_t2=$(find_max "$t2_advanced" "$t2_brew")

if [ -n "$t2_advanced" ]; then
    echo -e "${GREEN}KillPort Advanced v2.0${NC}"
    printf "  %4sms " "$t2_advanced"
    create_bar $t2_advanced $max_t2
    echo ""
else
    echo -e "${YELLOW}KillPort Advanced v2.0: N/A${NC}"
fi

if [ -n "$t2_brew" ]; then
    echo -e "${BLUE}killport (brew)${NC}"
    printf "  %4sms " "$t2_brew"
    create_bar $t2_brew $max_t2
    echo ""
    
    if [ -n "$t2_advanced" ]; then
        diff_data=$(calc_diff $t2_advanced $t2_brew)
        if [ -n "$diff_data" ]; then
            diff=$(echo $diff_data | cut -d: -f1)
            percent=$(echo $diff_data | cut -d: -f2)
            
            if [ $diff -gt 0 ]; then
                echo -e "  ${YELLOW}⚡ brew è più veloce di ${diff}ms (${percent}%)${NC}"
            elif [ $diff -lt 0 ]; then
                echo -e "  ${GREEN}⚡ Advanced è più veloce di ${diff#-}ms${NC}"
            else
                echo -e "  ${CYAN}⚖️  Stessa velocità${NC}"
            fi
        fi
    fi
else
    echo -e "${YELLOW}killport (brew): N/A${NC}"
fi

echo ""

# TEST 3
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}TEST 3: Kill Range 10 Porte (9100-9109)${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

max_t3=$(find_max "$t3_advanced" "$t3_brew")

if [ -n "$t3_advanced" ] && [ "$t3_advanced" -gt 0 ]; then
    echo -e "${GREEN}KillPort Advanced v2.0${NC}"
    printf "  %4sms " "$t3_advanced"
    create_bar $t3_advanced $max_t3
    echo ""
else
    echo -e "${YELLOW}KillPort Advanced v2.0: N/A o 0ms (test fallito)${NC}"
fi

if [ -n "$t3_brew" ] && [ "$t3_brew" -gt 0 ]; then
    echo -e "${BLUE}killport (brew)${NC}"
    printf "  %4sms " "$t3_brew"
    create_bar $t3_brew $max_t3
    echo ""
    
    if [ -n "$t3_advanced" ] && [ "$t3_advanced" -gt 0 ]; then
        diff_data=$(calc_diff $t3_advanced $t3_brew)
        if [ -n "$diff_data" ]; then
            diff=$(echo $diff_data | cut -d: -f1)
            percent=$(echo $diff_data | cut -d: -f2)
            
            if [ $diff -gt 0 ]; then
                echo -e "  ${YELLOW}⚡ brew è più veloce di ${diff}ms (${percent}%)${NC}"
            elif [ $diff -lt 0 ]; then
                echo -e "  ${GREEN}⚡ Advanced è più veloce di ${diff#-}ms${NC}"
            else
                echo -e "  ${CYAN}⚖️  Stessa velocità${NC}"
            fi
        fi
    fi
else
    echo -e "${YELLOW}killport (brew): N/A o 0ms (test fallito)${NC}"
fi

echo ""

# TEST 4 & 5 (solo Advanced)
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}Funzionalità Esclusive KillPort Advanced v2.0${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

max_t45=$(find_max "$t4_list" "$t5_stats")

if [ -n "$t4_list" ]; then
    echo -e "${GREEN}Lista Porte (--list)${NC}"
    printf "  %4sms " "$t4_list"
    create_bar $t4_list $max_t45
    echo ""
else
    echo -e "${YELLOW}Lista Porte (--list): N/A${NC}"
fi

if [ -n "$t5_stats" ]; then
    echo -e "${GREEN}Statistiche di Rete (--stats)${NC}"
    printf "  %4sms " "$t5_stats"
    create_bar $t5_stats $max_t45
    echo ""
else
    echo -e "${YELLOW}Statistiche di Rete (--stats): N/A${NC}"
fi

echo ""

# RIEPILOGO
echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}${BOLD}RIEPILOGO${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Verifica se abbiamo dati per confronto
has_comparison=false
if [ -n "$t1_brew" ] || [ -n "$t2_brew" ] || [ -n "$t3_brew" ]; then
    has_comparison=true
fi

if [ "$has_comparison" = true ]; then
    echo -e "${BOLD}Performance (Velocità Pura):${NC}"
    
    # Conta quale tool è più veloce
    faster_brew=0
    faster_advanced=0
    
    if [ -n "$t1_advanced" ] && [ -n "$t1_brew" ]; then
        if [ $t1_brew -lt $t1_advanced ]; then
            faster_brew=$((faster_brew + 1))
        elif [ $t1_advanced -lt $t1_brew ]; then
            faster_advanced=$((faster_advanced + 1))
        fi
    fi
    
    if [ -n "$t2_advanced" ] && [ -n "$t2_brew" ]; then
        if [ $t2_brew -lt $t2_advanced ]; then
            faster_brew=$((faster_brew + 1))
        elif [ $t2_advanced -lt $t2_brew ]; then
            faster_advanced=$((faster_advanced + 1))
        fi
    fi
    
    if [ -n "$t3_advanced" ] && [ -n "$t3_brew" ] && [ "$t3_advanced" -gt 0 ] && [ "$t3_brew" -gt 0 ]; then
        if [ $t3_brew -lt $t3_advanced ]; then
            faster_brew=$((faster_brew + 1))
        elif [ $t3_advanced -lt $t3_brew ]; then
            faster_advanced=$((faster_advanced + 1))
        fi
    fi
    
    if [ $faster_brew -gt $faster_advanced ]; then
        echo -e "  ${BLUE}→ killport (brew) è generalmente più veloce${NC}"
    elif [ $faster_advanced -gt $faster_brew ]; then
        echo -e "  ${GREEN}→ KillPort Advanced è generalmente più veloce${NC}"
    else
        echo -e "  ${CYAN}→ Performance simili tra i due tool${NC}"
    fi
    echo ""
    
    echo -e "${BOLD}Funzionalità:${NC}"
    echo -e "  ${GREEN}✓${NC} KillPort Advanced: monitoraggio (--list, --stats)"
    echo -e "  ${GREEN}✓${NC} KillPort Advanced: modalità avanzate"
    echo -e "  ${GREEN}✓${NC} Entrambi: supporto multiple porte e range"
    echo ""
    
    echo -e "${BOLD}Conclusione:${NC}"
    if [ $faster_brew -gt $faster_advanced ]; then
        echo -e "  ${BLUE}Operazioni rapide quotidiane${NC} → killport (brew)"
        echo -e "  ${GREEN}Workflow completo + monitoring${NC} → KillPort Advanced v2.0"
    else
        echo -e "  ${GREEN}Best choice${NC} → KillPort Advanced v2.0 (veloce + funzionalità)"
        echo -e "  ${BLUE}Alternativa leggera${NC} → killport (brew)"
    fi
else
    echo -e "${YELLOW}Solo KillPort Advanced v2.0 testato${NC}"
    echo ""
    echo -e "${BOLD}Risultati KillPort Advanced:${NC}"
    
    tests_passed=0
    tests_total=5
    
    [ -n "$t1_advanced" ] && tests_passed=$((tests_passed + 1))
    [ -n "$t2_advanced" ] && tests_passed=$((tests_passed + 1))
    [ -n "$t3_advanced" ] && [ "$t3_advanced" -gt 0 ] && tests_passed=$((tests_passed + 1))
    [ -n "$t4_list" ] && tests_passed=$((tests_passed + 1))
    [ -n "$t5_stats" ] && tests_passed=$((tests_passed + 1))
    
    echo -e "  Test completati: ${tests_passed}/${tests_total}"
    
    if [ $tests_passed -lt 3 ]; then
        echo -e "  ${RED}⚠️  Molti test falliti - verifica la configurazione${NC}"
    fi
    
    echo ""
    echo -e "${BOLD}Per confronto completo:${NC}"
    echo -e "  Installa: ${CYAN}brew install killport${NC}"
fi

echo ""

# Note sui test falliti
failed_tests=""
if [ -z "$t3_advanced" ] || [ "$t3_advanced" -eq 0 ]; then
    failed_tests="${failed_tests}TEST 3 (Range), "
fi
if [ -z "$t4_list" ]; then
    failed_tests="${failed_tests}TEST 4 (--list), "
fi
if [ -z "$t5_stats" ]; then
    failed_tests="${failed_tests}TEST 5 (--stats), "
fi

if [ -n "$failed_tests" ]; then
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}⚠️  Test falliti: ${failed_tests%??}${NC}"
    echo -e "${CYAN}Possibili cause:${NC}"
    echo -e "  • TEST 3: funzione killport non supporta range (usa singole porte)"
    echo -e "  • TEST 4/5: opzioni --list/--stats non implementate"
    echo ""
fi

# Export grafici ASCII
export_ascii_charts() {
    local export_file="${BENCHMARK_DIR}/benchmark_charts_$(date +%Y%m%d_%H%M%S).txt"
    
    echo "KillPort Benchmark - Grafici ASCII" > "$export_file"
    echo "Generato: $(date)" >> "$export_file"
    echo "==========================================" >> "$export_file"
    echo "" >> "$export_file"
    
    # Copia tutti i grafici dal display corrente (approssimazione)
    echo "LEGENDA:" >> "$export_file"
    echo "  █ = Barra performance" >> "$export_file"
    echo "  [min-max] = Range valori" >> "$export_file"
    echo "  σ=±N = Deviazione standard" >> "$export_file"
    echo "" >> "$export_file"
    echo "INTERPRETAZIONE:" >> "$export_file"
    echo "  < 30ms = Eccellente, 30-60ms = Buono, > 60ms = Lento" >> "$export_file"
    echo "  σ < 5ms = Molto consistente, 5-15ms = Accettabile, > 15ms = Inconsistente" >> "$export_file"
    echo "" >> "$export_file"
    
    # Aggiungi note sui risultati
    if [ -n "$t1_advanced" ] && [ -n "$t1_brew" ]; then
        if [ $t1_advanced -lt $t1_brew ]; then
            echo "RACCOMANDAZIONE: KillPort Advanced è più veloce per singole porte" >> "$export_file"
        else
            echo "RACCOMANDAZIONE: killport (brew) è più veloce per singole porte" >> "$export_file"
        fi
    fi
    
    echo "$export_file"
}

# Export Markdown con grafici ASCII
export_markdown_report() {
    local md_file="${BENCHMARK_DIR}/benchmark_report_$(date +%Y%m%d_%H%M%S).md"
    
    cat > "$md_file" << EOF
# 🚀 KillPort Benchmark Report

**Generato:** $(date)  
**File sorgente:** $RESULTS_FILE

## 📊 Legenda

| Simbolo | Significato |
|---------|-------------|
| █ | Barra performance |
| [min-max] | Range valori misurati |
| σ=±N | Deviazione standard |

## 📈 Interpretazione

- **🟢 < 30ms** = Eccellente
- **🟡 30-60ms** = Buono  
- **🔴 > 60ms** = Lento
- **🟢 σ < 5ms** = Molto consistente
- **🟡 σ 5-15ms** = Accettabile
- **🔴 σ > 15ms** = Inconsistente

---

EOF

    # Genera grafici per ogni test
    generate_md_test "TEST 1: Kill Singola Porta" "$t1_advanced" "$t1_brew" "$t1_advanced_stats" "$t1_brew_stats" >> "$md_file"
    generate_md_test "TEST 2: Kill 3 Porte Simultanee" "$t2_advanced" "$t2_brew" "$t2_advanced_stats" "$t2_brew_stats" >> "$md_file"
    generate_md_test "TEST 3: Kill Range Porte" "$t3_advanced" "$t3_brew" "$t3_advanced_stats" "$t3_brew_stats" >> "$md_file"
    
    # Aggiungi funzionalità esclusive
    if [ -n "$t4_list" ] || [ -n "$t5_stats" ]; then
        cat >> "$md_file" << EOF

## 🅰️ Funzionalità Esclusive KillPort Advanced

\`\`\`text
EOF
        
        if [ -n "$t4_list" ]; then
            local bar4=$(create_md_bar $t4_list $t4_list)
            echo "Lista Porte (--list)     $bar4 ${t4_list}ms" >> "$md_file"
        fi
        
        if [ -n "$t5_stats" ]; then
            local bar5=$(create_md_bar $t5_stats $t5_stats)
            echo "Statistiche (--stats)    $bar5 ${t5_stats}ms" >> "$md_file"
        fi
        
        echo '```' >> "$md_file"
    fi
    
    # Raccomandazioni finali
    cat >> "$md_file" << EOF

## 🎯 Raccomandazioni

EOF
    
    if [ -n "$t1_advanced" ] && [ -n "$t1_brew" ]; then
        if [ $t1_advanced -lt $t1_brew ]; then
            echo "- ✅ **KillPort Advanced** generalmente più veloce" >> "$md_file"
        else
            echo "- ✅ **killport (brew)** generalmente più veloce" >> "$md_file"
        fi
    fi
    
    echo "- 🔧 **KillPort Advanced**: Funzionalità complete (--list, --stats)" >> "$md_file"
    echo "- ⚡ **killport (brew)**: Alternativa leggera e veloce" >> "$md_file"
    
    echo "" >> "$md_file"
    echo "---" >> "$md_file"
    echo "*Report generato da KillPort Benchmark Suite Enhanced v2.1*" >> "$md_file"
    
    echo "$md_file"
}

# Genera sezione MD per un singolo test
generate_md_test() {
    local test_title="$1"
    local adv_time="$2"
    local brew_time="$3"
    local adv_stats="$4"
    local brew_stats="$5"
    
    if [ -z "$adv_time" ] && [ -z "$brew_time" ]; then
        return
    fi
    
    echo
    echo "## $test_title"
    echo
    echo '```text'
    
    if [ -n "$adv_time" ]; then
        local max_val=$adv_time
        [ -n "$brew_time" ] && [ $brew_time -gt $max_val ] && max_val=$brew_time
        
        local bar_adv=$(create_md_bar $adv_time $max_val)
        if [ -n "$adv_stats" ] && [[ $adv_stats =~ ^[0-9]+:[0-9]+:[0-9]+:[0-9]+$ ]]; then
            IFS=':' read -r min max avg stddev <<< "$adv_stats"
            echo "KillPort Advanced        $bar_adv [${min}-${max}] ${avg}ms ±${stddev}"
        else
            echo "KillPort Advanced        $bar_adv ${adv_time}ms"
        fi
    fi
    
    if [ -n "$brew_time" ]; then
        local max_val=$brew_time
        [ -n "$adv_time" ] && [ $adv_time -gt $max_val ] && max_val=$adv_time
        
        local bar_brew=$(create_md_bar $brew_time $max_val)
        if [ -n "$brew_stats" ] && [[ $brew_stats =~ ^[0-9]+:[0-9]+:[0-9]+:[0-9]+$ ]]; then
            IFS=':' read -r min max avg stddev <<< "$brew_stats"
            echo "killport (brew)          $bar_brew [${min}-${max}] ${avg}ms ±${stddev}"
        else
            echo "killport (brew)          $bar_brew ${brew_time}ms"
        fi
    fi
    
    # Analisi comparativa
    if [ -n "$adv_time" ] && [ -n "$brew_time" ]; then
        echo
        echo "Analisi Comparativa:"
        local diff=$((adv_time - brew_time))
        if [ $diff -lt 0 ]; then
            echo "✓ Advanced è più veloce di ${diff#-}ms"
        elif [ $diff -gt 0 ]; then
            echo "✓ Brew è più veloce di ${diff}ms"
        else
            echo "⚖️ Performance identiche"
        fi
        
        # Analisi consistenza se disponibile
        if [ -n "$adv_stats" ] && [ -n "$brew_stats" ]; then
            IFS=':' read -r _ _ _ stddev_a <<< "$adv_stats"
            IFS=':' read -r _ _ _ stddev_b <<< "$brew_stats"
            if [ "$stddev_a" -lt "$stddev_b" ]; then
                echo "✓ Advanced più consistente (±${stddev_a}ms vs ±${stddev_b}ms)"
            elif [ "$stddev_b" -lt "$stddev_a" ]; then
                echo "✓ Brew più consistente (±${stddev_b}ms vs ±${stddev_a}ms)"
            fi
        fi
    fi
    
    echo '```'
}

# Crea barra ASCII per Markdown
create_md_bar() {
    local value=$1
    local max_value=$2
    local width=25
    
    if [ -z "$value" ] || [ "$value" -eq 0 ] || [ "$max_value" -eq 0 ]; then
        printf "[%-${width}s]" ""
        return
    fi
    
    local filled=$(( (value * width) / max_value ))
    [ $filled -gt $width ] && filled=$width
    
    printf "["
    for ((i=0; i<filled; i++)); do
        printf "█"
    done
    for ((i=filled; i<width; i++)); do
        printf "░"  # Carattere più leggero per il resto
    done
    printf "]"
}

# Analisi performance avanzata
analyze_performance() {
    echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}${BOLD}ANALISI PERFORMANCE DETTAGLIATA${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    # Analizza i tempi
    local total_tests=0
    local excellent_tests=0
    local good_tests=0
    local slow_tests=0
    
    for time in "$t1_advanced" "$t1_brew" "$t2_advanced" "$t2_brew" "$t3_advanced" "$t3_brew"; do
        if [ -n "$time" ] && [ "$time" -gt 0 ]; then
            total_tests=$((total_tests + 1))
            if [ "$time" -lt 30 ]; then
                excellent_tests=$((excellent_tests + 1))
            elif [ "$time" -le 60 ]; then
                good_tests=$((good_tests + 1))
            else
                slow_tests=$((slow_tests + 1))
            fi
        fi
    done
    
    if [ $total_tests -gt 0 ]; then
        echo -e "${BOLD}Distribuzione Performance:${NC}"
        echo "  • Eccellente (< 30ms): $excellent_tests/$total_tests test ($(( excellent_tests * 100 / total_tests ))%)"
        echo "  • Buono (30-60ms):     $good_tests/$total_tests test ($(( good_tests * 100 / total_tests ))%)"
        echo "  • Lento (> 60ms):      $slow_tests/$total_tests test ($(( slow_tests * 100 / total_tests ))%)"
        echo ""
    fi
    
    # Raccomandazioni finali
    echo -e "${BOLD}Raccomandazioni d'uso:${NC}"
    if [ $excellent_tests -ge $(( total_tests * 7 / 10 )) ]; then
        echo -e "  ${GREEN}✓ Sistema molto performante - ideale per uso intensivo${NC}"
    elif [ $good_tests -ge $(( total_tests / 2 )) ]; then
        echo -e "  ${YELLOW}→ Performance buone - adatto per uso normale${NC}"
    else
        echo -e "  ${RED}⚠ Performance da migliorare - verifica carico sistema${NC}"
    fi
}

analyze_performance
echo ""

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ Visualizzazione completata${NC}"
echo -e "${BLUE}📄 Dati completi: $RESULTS_FILE${NC}"

# Offri export grafici
echo ""
read -p "Vuoi esportare i grafici ASCII in un file? (y/n): " export_choice
if [ "$export_choice" = "y" ] || [ "$export_choice" = "Y" ]; then
    chart_file=$(export_ascii_charts)
    echo -e "${GREEN}✓ Grafici esportati in: $chart_file${NC}"
fi
echo ""

echo ""
read -p "Vuoi esportare in Markdown? (y/n): " export_md_choice
if [ "$export_md_choice" = "y" ] || [ "$export_md_choice" = "Y" ]; then
    md_file=$(export_markdown_report)
    echo -e "${GREEN}✓ Report Markdown esportato in: $md_file${NC}"
fi
echo ""
