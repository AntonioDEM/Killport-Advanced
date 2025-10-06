<div align="center">

<img src="resources/icons/favicon/apple-touch-icon.png" alt="KillPort Logo" width="120"/>

# KillPort Advanced v2.0

**Suite completa per la gestione delle porte su macOS con monitoraggio avanzato, supporto range multipli e benchmark integrato.**

<div align="center">
<a href="https://github.com/AntonioDEM/killport-advanced/stargazers"><img src="https://img.shields.io/github/stars/AntonioDEM/killport-advanced" alt="Stars Badge"/></a>
<a href="https://github.com/AntonioDEM/killport-advanced/network/members"><img src="https://img.shields.io/github/forks/AntonioDEM/killport-advanced" alt="Forks Badge"/></a>
<a href="https://github.com/AntonioDEM/killport-advanced/pulls"><img src="https://img.shields.io/github/issues-pr/AntonioDEM/killport-advanced" alt="Pull Requests Badge"/></a>
<a href="https://github.com/AntonioDEM/killport-advanced/issues"><img src="https://img.shields.io/github/issues/AntonioDEM/killport-advanced" alt="Issues Badge"/></a>
<a href="https://github.com/AntonioDEM/killport-advanced/graphs/contributors"><img alt="GitHub contributors" src="https://img.shields.io/github/contributors/AntonioDEM/killport-advanced?color=2b9348"></a>
<a href="https://github.com/AntonioDEM/killport-advanced/blob/main/LICENSE"><img src="https://img.shields.io/github/license/AntonioDEM/killport-advanced?color=2b9348" alt="License Badge"/></a>
</div>

<br/>

![macOS](https://img.shields.io/badge/macOS-10.15+-green?style=flat-square&logo=apple)
![Shell](https://img.shields.io/badge/Shell-Zsh%20%7C%20Bash-blue?style=flat-square&logo=gnu-bash)
![Python](https://img.shields.io/badge/Python-3.10+-blue?style=flat-square&logo=python)

![Status](https://img.shields.io/badge/status-stable-brightgreen?style=flat-square)
![Last Commit](https://img.shields.io/badge/last%20commit-October%202025-orange?style=flat-square)
![License](https://img.shields.io/badge/License-MIT-yellow?style=flat-square)
![Version](https://img.shields.io/badge/version-2.0-red?style=flat-square)

</div>

---

## 📑 Indice

- [Caratteristiche](#-caratteristiche)
- [Installazione Rapida](#-installazione-rapida)
- [Utilizzo](#-utilizzo)
- [Benchmark Suite](#-benchmark-suite)
- [Documentazione](#-documentazione)
- [Troubleshooting](#-troubleshooting)
- [Contribuire](#-contribuire)
- [Licenza](#-licenza)

---

## ✨ Caratteristiche

- 🎯 **Kill singola porta o range multipli** - Gestione flessibile delle porte
- 🔍 **Monitoraggio avanzato** - Visualizzazione dettagliata dei processi in ascolto
- ⚡ **Performance ottimizzate** - Operazioni rapide ed efficienti
- 📊 **Benchmark integrato** - Suite completa per test di performance
- 🐍 **Integrazione Conda** - Supporto nativo per ambienti conda
- 🎨 **Output colorato** - Interfaccia terminale chiara e leggibile
- 🛡️ **Gestione errori robusta** - Controlli completi e messaggi informativi
- 📝 **Logging dettagliato** - Tracciamento completo delle operazioni

---

## 🚀 Installazione Rapida

### Prerequisiti

- macOS 10.15 o superiore
- Zsh o Bash
- Python 3.10+
- Conda/Miniconda (opzionale ma consigliato)

### Installazione Automatica

```bash
# Clone del repository
git clone https://github.com/AntonioDEM/killport-advanced.git
cd killport-advanced

# Esegui lo script di installazione
bash install_killport.sh

# Carica le funzioni nel tuo shell
source killport_zshrc_function.sh
```

### Installazione Manuale

Se preferisci installare manualmente, aggiungi al tuo `~/.zshrc` o `~/.bashrc`:

```bash
# Aggiungi il percorso alle funzioni
source /path/to/killport-advanced/killport_zshrc_function.sh
```

Poi ricarica la configurazione:

```bash
source ~/.zshrc  # per Zsh
# oppure
source ~/.bashrc # per Bash
```

---

## 💻 Utilizzo

### Comandi Base

```bash
# Kill di una singola porta
killport 8080

# Kill di range multipli
killport 3000-3005 8080-8085

# Monitoraggio porte in ascolto
monitor_ports

# Visualizza aiuto
killport --help
```

### Esempi Avanzati

```bash
# Kill di più porte specifiche
killport 3000 3001 8080 9000

# Combinazione di porte singole e range
killport 3000 5000-5005 8080-8090

# Monitoraggio con filtering
monitor_ports | grep python
```

### Integrazione con Conda

Il tool rileva automaticamente l'ambiente conda attivo e lo gestisce in modo ottimale:

```bash
# Attiva ambiente
conda activate myenv

# Usa killport normalmente
killport 8080

# L'ambiente conda viene preservato
```

---

## 📊 Benchmark Suite

La suite di benchmark integrata permette di testare le performance del sistema.

### Esecuzione Benchmark

```bash
# Vai nella cartella benchmark
cd benchmark

# Esegui il benchmark originale
bash benchmark_original.sh

# Visualizza i risultati
bash benchmark_visualizer_original.sh
```

### Report Generati

I benchmark generano automaticamente:
- 📈 File CSV con risultati dettagliati
- 📊 Grafici di performance
- 📝 Report markdown completi
- 📉 Analisi comparative

I risultati vengono salvati in:
```
benchmark/
├── benchmark_results_YYYYMMDD_HHMMSS.csv
├── benchmark_results_YYYYMMDD_HHMMSS.txt
├── benchmark_charts_YYYYMMDD_HHMMSS.txt
└── benchmark_report_YYYYMMDD_HHMMSS.md
```

---

## 📚 Documentazione

Per documentazione dettagliata, consulta:

- [BENCHMARK_GUIDE.md](benchmark/BENCHMARK_GUIDE.md) - Guida completa ai benchmark
- [CONTRIBUTING.md](CONTRIBUTING.md) - Come contribuire al progetto
- [LICENSE](LICENSE) - Licenza MIT

---

## 🔧 Troubleshooting

### Porta già in uso

```bash
Error: Port 8080 is already in use
```

**Soluzione**: Usa killport per terminare il processo:
```bash
killport 8080
```

### Permission denied

```bash
Error: Permission denied
```

**Soluzione**: Alcuni processi richiedono privilegi elevati:
```bash
sudo killport 8080
```

### Funzione non trovata

```bash
command not found: killport
```

**Soluzione**: Ricarica le funzioni shell:
```bash
source killport_zshrc_function.sh
```

### Problemi con Conda

Se l'ambiente conda non viene rilevato correttamente:

```bash
# Reinizializza conda
conda init zsh  # o bash

# Ricarica shell
source ~/.zshrc
```

---

## 🤝 Contribuire

Contributi, issues e feature requests sono benvenuti!

Consulta [CONTRIBUTING.md](CONTRIBUTING.md) per le linee guida.

### Come Contribuire

1. Fork del progetto
2. Crea il tuo feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit delle modifiche (`git commit -m 'Add some AmazingFeature'`)
4. Push al branch (`git push origin feature/AmazingFeature`)
5. Apri una Pull Request

---

## 📄 Licenza

Distribuito sotto licenza MIT. Vedi [LICENSE](LICENSE) per maggiori informazioni.

---

## 👨‍💻 Autore

**Antonio DeMarcus**

- GitHub: [@AntonioDEM](https://github.com/AntonioDEM)
- Repository: [killport-advanced](https://github.com/AntonioDEM/killport-advanced)

---

## 🙏 Ringraziamenti

- Ispirato dal progetto [killport](https://github.com/jkfran/killport) di jkfran
- Community open source per il supporto
- Tutti i contributori del progetto

---

<div align="center">

**⭐ Se questo progetto ti è utile, lascia una stella! ⭐**

Made with ❤️ by [Antonio DeMarcus](https://github.com/AntonioDEM)

</div>