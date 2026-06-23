# Design — Marlin para Ender 5 + BTT SKR Mini E3 V1.2 + BL-Touch

**Data:** 2026-06-23
**Repositório:** https://github.com/Gianotto/marlin-ender5

## Objetivo

Manter, de forma versionada e com build automatizado (CI), o firmware Marlin
configurado para uma impressora **Creality Ender 5** equipada com:

- Placa **BigTreeTech SKR Mini E3 V1.2** (STM32F103RC, 256 KB flash, 4× TMC2209 UART integrados)
- Sensor de nivelamento **BL-Touch**
- Extrusora **direct drive** usando o extrusor Creality original realocado
- Demais componentes **de fábrica**: mesa 220×220, altura ~300 mm, hotend e termístores originais, single-Z, display 12864 stock

O resultado de cada build é um `firmware.bin` pronto para gravar na raiz do cartão SD.

## Abordagem: Config overlay

O repositório guarda **apenas** as customizações (arquivos de configuração editados),
o workflow de CI e a documentação. O CI baixa o código-fonte do Marlin no tag fixado,
aplica os configs por cima e compila. Vantagens: repositório leve, diff mostra
exatamente as customizações, atualizar a versão do Marlin é trivial.

### Estrutura

```
marlin-ender5/
├─ README.md                       # visão geral, como flashar, links
├─ marlin.version                  # tag do Marlin baixado pelo CI (ex.: "2.1.2.7")
├─ config/
│  ├─ Configuration.h              # Ender 5 + SKR Mini E3 V1.2 + BLTouch
│  └─ Configuration_adv.h          # TMC2209 UART, ABL, ajustes finos
├─ .github/workflows/build.yml     # CI PlatformIO → firmware.bin
├─ docs/
│  ├─ flashing.md                  # gravar via cartão SD
│  ├─ calibration.md               # e-steps, PID, Z-offset, probe offset
│  └─ superpowers/specs/2026-06-23-marlin-ender5-design.md
└─ .gitignore
```

## Versão base

- **Marlin estável `2.1.2.7`** (release oficial, jan/2024). Fixada em `marlin.version`.
- Configs partem do exemplo oficial **Creality/Ender-5** do repositório
  `MarlinFirmware/Configurations` no tag `release-2.1.2.7`, modificados conforme abaixo.
  (Se houver um exemplo Ender-5 + SKR Mini E3 pronto no repo Configurations, ele é
  usado como base preferencial.)

## Fluxo do CI (GitHub Actions)

Dispara em `push`, `pull_request` e `workflow_dispatch`. Passos:

1. Checkout do repositório
2. Instala Python + PlatformIO (com cache dos pacotes `~/.platformio`)
3. Clona o Marlin no tag de `marlin.version` (shallow)
4. Copia `config/Configuration.h` e `config/Configuration_adv.h` para `Marlin/Marlin/`
5. `platformio run -e STM32F103RC_btt_USB`
6. Renomeia `.pio/build/STM32F103RC_btt_USB/firmware.bin` →
   `firmware-ender5-skr-mini-e3-v1.2-<sha-curto>.bin`
7. Publica como **artifact** do build
8. Quando uma tag `v*` é criada, anexa o `.bin` a um **GitHub Release**

O job também reporta o tamanho do binário (a flash de 256 KB do STM32F103RC é
apertada — se o build estourar, o CI falha e revisamos o conjunto de features).

## Configuração — mudanças-chave sobre o exemplo Ender-5

| Área | Valor |
|------|-------|
| Placa | `BOARD_BTT_SKR_MINI_E3_V1_2` |
| Microcontrolador / env | STM32F103RC / `STM32F103RC_btt_USB` |
| Serial / host | `SERIAL_PORT -1` (USB-C nativo p/ PC/OctoPrint), secundária `-1` |
| Drivers | X/Y/Z/E0 = `TMC2209` (modo UART) |
| Correntes TMC | ~580 mA (motores stock Creality), StealthChop ligado |
| Homing X/Y | Endstops mecânicos stock (sem sensorless) |
| Z homing | Via BL-Touch (`USE_PROBE_FOR_Z_HOMING` + `Z_SAFE_HOMING`) |
| BL-Touch | `BLTOUCH` ligado; porta de probe dedicada da placa |
| Probe offset | `NOZZLE_TO_PROBE_OFFSET { -44, -9, 0 }` ⚠️ placeholder — medir e ajustar |
| Nivelamento | `AUTO_BED_LEVELING_BILINEAR`, grade 5×5, fade height ligado |
| Volume | 220 × 220 × 300 mm |
| Steps/mm | `{ 80, 80, 400, 93 }` (E recalibra após montar) |
| Termístores | Tipo 1 (hotend + mesa stock) |
| PID / EEPROM | Ligados (padrão do exemplo) |
| Retração (direct drive) | Padrões curtos (~1 mm); nota p/ inverter `INVERT_E0_DIR` se necessário |
| Display | `CR10_STOCKDISPLAY` (tela 12864 stock no header EXP) |

### Restrições da placa

- **Flash de 256 KB.** BL-Touch + ABL Bilinear cabem com folga, mas o conjunto de
  features deve ser mantido enxuto. O CI valida o tamanho a cada build.
- A SKR Mini E3 V1.2 tem **4 drivers** integrados (X/Y/Z/E). Sem 5º driver — dual-Z
  não é suportado (não necessário neste setup single-Z).

## Documentação de calibração (`docs/calibration.md`)

Passos obrigatórios após o primeiro flash (não dá para acertar 100% só no firmware):

1. Medir e setar o **probe offset** real (X/Y do suporte do BL-Touch)
2. Calibrar o **Z-offset** (papel / baby-stepping)
3. Calibrar **e-steps** do extrusor direct drive
4. **PID autotune** do hotend e da mesa (`M303`)
5. Conferir a **direção do motor E** (direct drive costuma inverter `INVERT_E0_DIR`)
6. Salvar na EEPROM (`M500`)

## Pontos que dependem do usuário (⚠️ marcados no firmware e nos docs)

1. **Probe offset** — depende do suporte físico do BL-Touch (parte de `{-44,-9,0}`).
2. **Z-offset** — sempre calibrado na máquina.
3. **E-steps / direção E** — direct drive, confirmado na primeira impressão.

## Critérios de sucesso

- CI verde produzindo `firmware-ender5-skr-mini-e3-v1.2-<sha>.bin` < 256 KB.
- Firmware grava pelo cartão SD e dá boot na Ender 5 com a SKR Mini E3 V1.2.
- BL-Touch faz deploy/stow no boot e o `G29` mapeia a mesa.
- Documentação cobre o flash e os passos de calibração pós-flash.

## Fora de escopo

- Calibração física da máquina (feita pelo usuário, documentada).
- Suporte a outras placas/impressoras.
- TFT touch screen (apenas o display stock 12864).
