# 🚀 KillPort Benchmark Report

**Generato:** Dom  5 Ott 2025 21:49:13 CEST  
**File sorgente:** benchmark/benchmark_results_20251005_214636.txt

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


## TEST 1: Kill Singola Porta

```text
KillPort Advanced        [█████████████████████████] [27-27] 27ms ±0
killport (brew)          [███████████████████████░░] [25-25] 25ms ±0

Analisi Comparativa:
✓ Brew è più veloce di 2ms
```

## TEST 2: Kill 3 Porte Simultanee

```text
KillPort Advanced        [████████████████████████░] [31-31] 31ms ±0
killport (brew)          [█████████████████████████] [32-32] 32ms ±0

Analisi Comparativa:
✓ Advanced è più veloce di 1ms
```

## TEST 3: Kill Range Porte

```text
KillPort Advanced        [█████████████████████████] [20-20] 20ms ±0
killport (brew)          [█████████████████████████] [20-20] 20ms ±0

Analisi Comparativa:
⚖️ Performance identiche
```

## 🅰️ Funzionalità Esclusive KillPort Advanced

```text
Lista Porte (--list)     [█████████████████████████] 22ms
Statistiche (--stats)    [█████████████████████████] 22ms
```

## 🎯 Raccomandazioni

- ✅ **killport (brew)** generalmente più veloce
- 🔧 **KillPort Advanced**: Funzionalità complete (--list, --stats)
- ⚡ **killport (brew)**: Alternativa leggera e veloce

---
*Report generato da KillPort Benchmark Suite Enhanced v2.1*
