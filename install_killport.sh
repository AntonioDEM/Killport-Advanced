#!/bin/bash

# ========================================
# KillPort Advanced v2.0 - Installer Corretto
# ========================================

set -e

# Colori per output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

# Funzioni di logging
log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }

# PERCORSI
HOMEDIR="$HOME/cosmos-visualization/kill_port_script"
SCRIPT="$HOME/script"
MYSCRIPT="$HOME/myscript/killport"

echo -e "${CYAN}${BOLD}"
cat << 'EOF'
🚀 KillPort Advanced v2.0 Installer
====================================
Suite completa per gestione porte su macOS
✨ Con funzionalità multiple porte, range, watch mode e molto altro!
EOF
echo -e "${NC}"

# Verifica sistema
log_info "Verificando compatibilità sistema..."

if [[ "$OSTYPE" != "darwin"* ]]; then
    log_error "Questo installer è ottimizzato per macOS."
    exit 1
fi

# Verifica dipendenze
log_info "Verificando dipendenze..."

command -v lsof >/dev/null 2>&1 || {
    log_error "lsof non trovato. È richiesto per il funzionamento."
    exit 1
}

command -v netstat >/dev/null 2>&1 || {
    log_error "netstat non trovato. È richiesto per le statistiche."
    exit 1
}

# Verifica shell
CURRENT_SHELL=$(basename "$SHELL")
log_info "Shell corrente: $CURRENT_SHELL"

if [[ "$CURRENT_SHELL" != "zsh" ]] && [[ ! -f ~/.zshrc ]]; then
    log_warning "Zsh non rilevato. KillPort funziona meglio con Zsh."
    read -p "Continuare comunque? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

log_success "Sistema compatibile!"

# TROVA I FILE SORGENTE
find_source_files() {
    local current_dir=$(pwd)
    local home_dir="$HOME"
    
    local search_paths=(
        "$current_dir"
        "$HOMEDIR"  
        "$SCRIPT"
        "$MYSCRIPT"
        "$home_dir"
        "$home_dir/Downloads"
    )
    
    log_info "🔍 Ricerca file in corso..."
    for path in "${search_paths[@]}"; do
        path="${path/#\~/$HOME}"
        
        if [[ -f "$path/killport_zshrc_function.sh" ]]; then
            SOURCE_DIR="$path"
            log_success "Trovati file sorgente in: $path"
            return 0
        fi
    done
    
    return 1
}

# Cerca file sorgente
log_info "Ricerca file sorgente..."
if ! find_source_files; then
    log_warning "File sorgente non trovati automaticamente"
    echo ""
    log_info "Dove si trovano i file killport_zshrc_function.sh?"
    echo "Esempi: $MYSCRIPT, ./, $HOMEDIR"
    echo ""
    read -p "📂 Inserisci il percorso: " custom_source_dir
    
    if [[ "$custom_source_dir" == .* ]]; then
        custom_source_dir="$(pwd)/${custom_source_dir#./}"
    fi
    custom_source_dir="${custom_source_dir/#\~/$HOME}"
    
    if [[ ! -f "$custom_source_dir/killport_zshrc_function.sh" ]]; then
        log_error "File killport_zshrc_function.sh non trovato in: $custom_source_dir"
        exit 1
    fi
    
    SOURCE_DIR="$custom_source_dir"
fi

# Verifica versione
log_info "Verificando versione dello script..."
if grep -q "KillPort Advanced v2.0" "$SOURCE_DIR/killport_zshrc_function.sh"; then
    log_success "✅ Rilevata versione 2.0"
else
    log_warning "⚠️  Versione non riconosciuta"
    read -p "Continuare comunque? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Tipo di installazione
echo
log_info "Scegli il tipo di installazione:"
echo "1) 🌟 Completa (Raccomandato)"
echo "2) 💻 Solo funzione ZSH"
echo "3) 🔄 Aggiorna installazione esistente"
echo

read -p "Scelta [1-3]: " -n 1 -r choice
echo

case $choice in
    1|"") INSTALL_TYPE="full" ;;
    2) INSTALL_TYPE="zsh_only" ;;
    3) INSTALL_TYPE="update" ;;
    *) log_error "Scelta non valida"; exit 1 ;;
esac

# Directory di installazione (rimuovi doppi slash)
DEFAULT_DIR="$SCRIPT/.killport"
read -p "📂 Directory di installazione [$DEFAULT_DIR]: " INSTALL_DIR
INSTALL_DIR=${INSTALL_DIR:-$DEFAULT_DIR}

# Normalizza il percorso (rimuovi doppi slash)
INSTALL_DIR="${INSTALL_DIR//\/\//\/}"

log_info "Creando directory: $INSTALL_DIR"
mkdir -p "$INSTALL_DIR"

# RIMUOVI COMPLETAMENTE VECCHIA CONFIGURAZIONE
if [[ -f ~/.zshrc ]]; then
    if grep -q "killport" ~/.zshrc 2>/dev/null; then
        log_warning "Configurazione esistente rilevata"
        BACKUP_FILE="$HOME/.zshrc.backup.killport.$(date +%Y%m%d_%H%M%S)"
        cp ~/.zshrc "$BACKUP_FILE"
        log_info "Backup creato: $BACKUP_FILE"
        
        # Rimuovi TUTTE le righe relative a killport
        log_info "Rimozione configurazione esistente..."
        
        # Crea file temporaneo senza righe killport
        grep -v "KillPort" ~/.zshrc | \
        grep -v "killport" | \
        grep -v "alias kp=" | \
        grep -v "alias ports=" | \
        grep -v "alias netstats=" | \
        grep -v "alias kpi=" | \
        grep -v "alias kph=" > ~/.zshrc.tmp
        
        mv ~/.zshrc.tmp ~/.zshrc
        log_success "Vecchia configurazione rimossa"
    fi
fi

# Installa funzione
log_info "Installando funzione ZSH v2.0..."

if [[ -f "$SOURCE_DIR/killport_zshrc_function.sh" ]]; then
    cp "$SOURCE_DIR/killport_zshrc_function.sh" "$INSTALL_DIR/killport_function.sh"
    
    # Sostituisci placeholder (versione corretta per macOS e Linux)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s|__INSTALL_DIR__|$INSTALL_DIR|g" "$INSTALL_DIR/killport_function.sh"
    else
        sed -i "s|__INSTALL_DIR__|$INSTALL_DIR|g" "$INSTALL_DIR/killport_function.sh"
    fi
    
    log_success "Funzione configurata: $INSTALL_DIR/killport_function.sh"
else
    log_error "File sorgente non trovato!"
    exit 1
fi

# Copia documentazione
for doc_name in "Confronto_con_brew.md" "README.md" "readme.md"; do
    if [[ -f "$SOURCE_DIR/$doc_name" ]]; then
        cp "$SOURCE_DIR/$doc_name" "$INSTALL_DIR/" 2>/dev/null || true
        log_info "Documentazione copiata: $doc_name"
    fi
done

# CREA UNINSTALLER CORRETTO
cat > "$INSTALL_DIR/uninstall.sh" << 'UNINSTALL_EOF'
#!/bin/zsh

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }

echo -e "${RED}🗑️ Disinstallando KillPort Advanced v2.0...${NC}"
echo

INSTALL_DIR="__INSTALL_DIR_PLACEHOLDER__"

# Backup .zshrc
if [[ -f ~/.zshrc ]]; then
    BACKUP_FILE="$HOME/.zshrc.backup.uninstall.$(date +%Y%m%d_%H%M%S)"
    cp ~/.zshrc "$BACKUP_FILE"
    log_info "Backup creato: $BACKUP_FILE"
    
    # Rimuovi TUTTE le righe killport
    grep -v "KillPort" ~/.zshrc | \
    grep -v "killport" | \
    grep -v "alias kp=" | \
    grep -v "alias ports=" | \
    grep -v "alias netstats=" | \
    grep -v "alias kpi=" | \
    grep -v "alias kph=" > ~/.zshrc.tmp
    
    mv ~/.zshrc.tmp ~/.zshrc
    log_success "Configurazione rimossa da ~/.zshrc"
else
    log_warning "File ~/.zshrc non trovato"
fi

# Rimuovi directory
if [[ -d "$INSTALL_DIR" ]]; then
    rm -rf "$INSTALL_DIR"
    log_success "Directory rimossa: $INSTALL_DIR"
fi

# Rimuovi cronologia
if [[ -f "$HOME/.killport_history" ]]; then
    rm -f "$HOME/.killport_history"
    log_success "Cronologia rimossa"
fi

# Rimuovi alias dalla shell corrente
unalias kp kpi kph ports netstats killport-uninstall 2>/dev/null || true
unfunction killport 2>/dev/null || true

log_success "✨ Disinstallazione completata!"
echo
log_info "📋 Elementi rimossi:"
echo "   - Funzione killport"
echo "   - Tutti gli alias"
echo "   - Directory di installazione"
echo "   - File di cronologia"
echo

log_warning "💡 Riavvia il terminale o esegui: exec zsh"
UNINSTALL_EOF

# Sostituisci placeholder nell'uninstaller
if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' "s|__INSTALL_DIR_PLACEHOLDER__|$INSTALL_DIR|g" "$INSTALL_DIR/uninstall.sh"
else
    sed -i "s|__INSTALL_DIR_PLACEHOLDER__|$INSTALL_DIR|g" "$INSTALL_DIR/uninstall.sh"
fi

chmod +x "$INSTALL_DIR/uninstall.sh"
log_success "Script di disinstallazione creato"

# AGGIUNGI CONFIGURAZIONE AL .ZSHRC (UNA SOLA VOLTA)
log_info "Configurando .zshrc..."

cat >> ~/.zshrc << EOF

# === KillPort Advanced v2.0 - Installed $(date) ===
source "$INSTALL_DIR/killport_function.sh"

# KillPort v2.0 - Alias
alias kp='killport'
alias ports='killport --list'
alias netstats='killport --stats'
alias kpi='killport --interactive'
alias kph='killport --history'
alias killport-uninstall='$INSTALL_DIR/uninstall.sh'
EOF

log_success "Configurazione aggiunta a ~/.zshrc"

# Test installazione
echo
log_info "Testando installazione..."

# Source per test immediato
source "$INSTALL_DIR/killport_function.sh" 2>/dev/null || {
    log_warning "Impossibile caricare la funzione (normale durante l'installazione)"
}

# Riepilogo
echo
echo -e "${CYAN}${BOLD}🎉 INSTALLAZIONE COMPLETATA! 🎉${NC}"
echo
log_info "📂 Directory: $INSTALL_DIR"
log_info "🗑️ Disinstalla: killport-uninstall"
echo

# Comandi disponibili
echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
log_info "🚀 ${BOLD}COMANDI DISPONIBILI:${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo
echo -e "${YELLOW}📚 Base:${NC}"
echo -e "   ${GREEN}killport --help${NC}              # Guida completa"
echo -e "   ${GREEN}killport 3000${NC}                # Termina porta 3000"
echo -e "   ${GREEN}kp 8080 --force${NC}              # Force kill porta 8080"
echo
echo -e "${YELLOW}🎯 Multiple & Range:${NC}"
echo -e "   ${GREEN}killport 3000 4000 8080${NC}      # Termina 3 porte"
echo -e "   ${GREEN}killport 8000-8010${NC}           # Range di porte"
echo
echo -e "${YELLOW}🔍 Monitoraggio:${NC}"
echo -e "   ${GREEN}ports${NC}                        # Lista tutte le porte"
echo -e "   ${GREEN}netstats${NC}                     # Statistiche di rete"
echo
echo -e "${YELLOW}⚡ Modalità Avanzate:${NC}"
echo -e "   ${GREEN}kpi${NC}                          # Modalità interattiva"
echo -e "   ${GREEN}killport --watch 3000${NC}        # Watch mode auto-kill"
echo
echo -e "${YELLOW}📜 Utility:${NC}"
echo -e "   ${GREEN}kph${NC}                          # Cronologia"
echo -e "   ${GREEN}killport-uninstall${NC}           # Disinstalla"
echo
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo
log_success "✨ Installazione riuscita!"
log_warning "💡 IMPORTANTE: Esegui 'source ~/.zshrc' o 'exec zsh' per attivare"
echo