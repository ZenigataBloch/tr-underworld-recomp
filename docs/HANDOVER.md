# HANDOVER - Tomb Raider Underworld (Xbox 360) ricompilazione statica per PC

Ultimo aggiornamento: 2026-10-19, dopo le 16:10 (ora Roma). Milestone corrente: **1 di 6, quasi chiusa**; aperto un problema grafico (muri sporchi/neri).

## Obiettivo
Ricompilare staticamente la propria copia di Tomb Raider Underworld (Xbox 360) in modo che giri nativa su Windows. Base: SDK **ReXGlue v0.10.0** (kernel, GPU e audio gia' forniti; il plugin GPU `xenos` contiene sia il backend Direct3D 12 sia quello Vulkan). Non scrivere un renderer o un livello kernel propri. Le correzioni all'SDK sono patch piccole e documentate, in **un unico file diff** (`patches/rexglue-tru.diff` nel repo; bozza di lavoro `V:\DeComp\work\rexglue-tru.diff`).

## Regole fondamentali (dell'utente)
1. Mai file di gioco nel repository (ISO, XEX, pk4, dati) ne' codice ricompilato generato. Il README dice che ognuno deve procurarsi la propria copia.
2. Misurare prima di cambiare. Tenere una modifica solo se i numeri migliorano; togliere gli esperimenti senza miglioramento.
3. Chiedere prima di operazioni rischiose o con conferma esterna (eliminare, push, pubblicare, installare). Non avviare build di test mentre l'utente gioca. (Eccezione esplicita 2026-10-19: l'utente ha chiesto auto commit/push dei piccoli fix.)
4. Dire sempre cosa e' verificato e cosa solo ipotizzato.
5. Verificare con l'utente a ogni milestone e dare un breve riassunto.
6. **Comunicazione:** risposte brevi (20-30 parole di prosa), **tutti i comandi in un solo blocco** (se serve, uno script che cicla da solo). L'utente si irrita se i passi vengono spezzettati.

## Milestone
1. SDK compilato e installato; il gioco si avvia fino alla schermata del titolo. **(quasi chiusa: menu principale raggiunto, dopo START parte la cutscene iniziale)**
2. Correzioni di crash (limiti di funzioni mancanti, eccezioni in virgola mobile, funzioni non registrate).
3. Record/replay dell'input per guidare il gioco in autonomia.
4. 60 fps stabili senza scatti (misurare i tempi dei singoli fotogrammi, non la media).
5. QoL: menu impostazioni in-game, prompt "trova la tua ISO", collegamento desktop e icona.
6. Pubblicazione: repo GitHub (GPL-2.0-or-later), README, rilasci con solo codice sorgente.

## Stato del milestone 1

### Fatto e VERIFICATO (output reale sul PC dell'utente)
- SDK v0.10.0 (`f5337cdc...`) compilato (preset `win-amd64`, Clang VS Community 2026, CMake 4.3.1, Ninja) e installato in `V:\DeComp\work\rexglue-sdk\out\install\win-amd64`.
- ISO estratta in `V:\DeComp\work\game\Tomb Raider - Underworld\` (un solo `default.xex`, Title ID `534307EC`).
- Progetto `V:\DeComp\work\tru-project`, manifest `tru_manifest.toml`, config funzioni `tru_functions.toml` (collegato con `includes`).
- Codegen completo e build del gioco riuscita: `tru.exe` e `rexruntime.dll` in `tru-project\out\build\win-amd64-release\`.
- **GPU plugin collegato**: `rexglue_setup_target(tru GPU_PLUGINS xenos)` nel `CMakeLists.txt` del progetto (backup `.bak`) + argomento di avvio `--gpu_plugin xenos`. Viene copiata `rexgpu-xenos.dll`.
- Il gioco arriva al menu principale, con audio. **Dopo START parte la cutscene iniziale** (riferito dall'utente durante i test grafici del 2026-10-19; non ricontrollato sul log). Il FATAL `0x8225C440` visto in `tru_021.log` risulta quindi superato; **non e' stato riverificato il contenuto attuale di `tru_functions.toml`** (l'ultimo contenuto verificato e' quello delle 13:08, vedi sotto).
- Comando di avvio base: `.\tru.exe --game_data_root "V:\DeComp\work\game\Tomb Raider - Underworld" --gpu_plugin xenos`. Log in `...\win-amd64-release\logs\tru_NNN.log`.
- Dal log (`tru_094.log`, verificato): backend in uso **Vulkan** su GPU AMD (driver 25.6.1), swapchain 1920 px; nessun errore GPU rilevante (solo fallback di formato per texture YUV `k_Y1_Cr_Y0_Cb_REP` / `k_Cr_Y1_Cb_Y0_REP` e un warning del loader Vulkan su `amdvlk`).

### Patch SDK applicate (in `patches/rexglue-tru.diff`)
1. `src/system/runtime.cpp`: `rejected > 0` in `func_mappings` ora emette un warning e prosegue (prima: `Shutdown()` + `X_STATUS_UNSUCCESSFUL`). Backup `runtime.cpp.bak`. **E' un workaround**: le 185 voci rifiutate sono stub di falso codice (vedi sotto). Da rivalutare; non e' dimostrato che sia la soluzione finale.

### Problema delle 185 voci (analisi, in gran parte verificata)
- Immagine runtime `82000000-83270000`, codice `820A0000-82730E74`. Le voci rifiutate (`0x83C29058`, `0x83E41A58`...`0x83E55184`, `0xFEEC2308`) sono fuori immagine.
- Nascono da `bl`/`bla` in funzioni tra `0x82727260` e `0x8272DE94`, il cui codice e' privo di senso: quasi certamente **dati/testo decodificati come PowerPC** (ipotesi forte; confine esatto non misurato).
- `[[invalid_instructions]]` e `[analysis].data_region_threshold` non risolvono (letti nel sorgente).
- Strada aperta: dire al codegen che la zona e' dati, oppure rimuovere quelle funzioni; poi rimisurare "185 rejected" (deve scendere a 0) e togliere la Patch 1.

### Funzioni non registrate (voci in `tru_functions.toml`)
Formato: `[functions."0xADDR"] size = <prossima funzione - ADDR>`. Ultimo contenuto verificato (2026-10-19, 13:08):
`0x82506D98` (8), `0x8211D4C0` (64), `0x825003A0` (24), `0x8252A420` (24), `0x821F5010` (24), `0x821F4A88` (16), `0x82128CE0` (8), `0x82253DA0` (16), `0x82253DB0` (16), `0x82253DC0` (40), `0x824C9CA8` (16), `0x824C92F8` (32), `0x82153460` (24). Il ciclo automatico successivo ha probabilmente aggiunto altre voci: da controllare nel file.
- Lezione: il codegen rifiuta voci sovrapposte (`[config] Overlapping boundaries`, verificato con `0x82253DA0`+72 vs `0x82253DB0`). Il ciclo accorcia da solo la voce precedente.
- Lezione: se la build viene interrotta, `tru.exe` resta vecchio e lo stesso FATAL si ripete anche con la voce nel toml; controllare sempre i timestamp.
- Attenzione PowerShell: i letterali hex > `0x7FFFFFFF` sono int32 negativi; usare `[uint32]`/`[int64]`. Avvolgere gli script in `& { }`.

## Problema grafico: muri sporchi/neri (aperto, 2026-10-19)

### Sintomo
Nel gioco i muri sono sporchi (parzialmente neri) o neri; il modello di Lara e' sbagliato o corretto a seconda dei cvar. La cutscene dopo START a volte non viene renderizzata.

### Come si testa
Script PowerShell che lancia `tru.exe` con `--nome_cvar=valore` (sintassi verificata), aspetta la chiusura e chiede l'esito. **Legenda esiti dell'utente:** muri `p`=puliti, `s`=sporchi, `n`=neri; cutscene `c`=non renderizzata, `o`=ok; `x`=non so. La colonna "Sec" dei primi giri era solo la durata del test, senza valore diagnostico.

### Risultati (riferiti dall'utente)
- **Baseline senza cvar:** muri sporchi, cutscene non renderizzata (`s c`).
- `depth_float24_round=true`, `depth_transfer_not_equal_test=false`, da soli o insieme: identici alla baseline (`s c`). **Scartati.**
- `execute_unclipped_draw_vs_on_cpu=true`: **sblocca la cutscene** (`s o`); i muri restano sporchi, Lara con modello sbagliato. E' l'unico cvar che cambia la cutscene. Base per tutti i test successivi.
- Sopra la base `unclipped`: `gpu_allow_invalid_fetch_constants=true` e `use_fuzzy_alpha_epsilon=true` non cambiano nulla (`s o`). **Scartati.**
- `depth_float24_convert_in_pixel_shader=true` ("G"): **modello di Lara perfetto** (mani luccicanti/glowy in alcune varianti), ma **muri neri** (`n o`).
- Sopra `unclipped` + G: `render_target_path_vulkan=fbo` e `native_stencil_value_output=false` non cambiano i muri (`n o`).
- `render_target_path_vulkan=fsi`: con G il test e' finito senza muri visibili/da ripetere (il log mostra chiusura normale dopo ~17 s, nessun crash registrato); senza G muri neri, stutter immensi, mani glowy. **Da scartare** (stutter).
- Combinazioni con `depth_convert` (primo giro) con `gamma_render_target_as_unorm16=false`, `mrt_edram_used_range_clamp_to_min=false`, `native_2x_msaa=false` (il gioco non si avviava), e con `direct_host_resolve`, `edram_rt_clamp`, `mrt_edram_used_range_clamp_to_min=true`: nessun miglioramento, a volte cutscene non renderizzata. **Scartati.**
- D3D12 e Vulkan: risultati uguali (riferito dall'utente).
- **Nessuna combinazione finora ha dato muri puliti.**

### Ipotesi (NON verificate)
- Essendo D3D12 e Vulkan uguali, il difetto sta probabilmente sopra il backend: codice GPU condiviso (texture, shader, formati) oppure dati prodotti dal codice ricompilato. Muri sporchi senza G e neri con G (o con fsi) suggeriscono che i muri dipendano da un percorso depth/render target che nessun cvar corregge.
- Cvar non ancora provati (definiti in `src/graphics/flags.cpp`): `gpu_debug_markers`, `dump_shaders`; `native_stencil_value_output_d3d12_intel` e `render_target_path_d3d12` solo per D3D12.

### In sospeso
- Dump degli shader (`--dump_shaders "V:\DeComp\work\shaders"`): il primo tentativo ha prodotto 0 file, probabilmente per la cache shader gia' presente (`Initializing shader storage for title 534307EC`). E' stato preparato uno script che rinomina in `.bak` la cache trovata e rifa' il dump; **l'esito non e' ancora stato riportato**.
- Screenshot dei muri sporchi (base `unclipped`) e neri (con G): richiesti, non ricevuti.

## Aperto / non indagato
- `d:\layer2.dat`, `d:\tr8.arg`, `game:\movies\english\medsea_loop.wmv`, `game:\movies\medsea_loop.sch`: `NtCreateFile FAILED 0xC000000F` (non trovati; confermato ancora in `tru_094.log` per `layer2.dat`, `tr8.arg`, `medsea_loop.sch`). Se i filmati manchino nell'estrazione o siano solo opzionali: **non verificato**.
- `BaseHeap::Alloc failed to find contiguous range` / `PhysicalHeap::Alloc unable to alloc...`: molti, causa ignota; il gioco prosegue.
- `gamecontrollerdb.txt` assente (probabilmente innocuo). Controller Xbox Series X rilevato da SDL (verificato).

## Ancora da fare per chiudere il milestone 1
1. Verificare che l'avvio dopo START sia stabile (nessun nuovo FATAL) e controllare `tru_functions.toml`.
2. Sostituire/chiudere il workaround della Patch 1 se possibile.
3. Decidere come trattare il problema grafico (puo' diventare parte del milestone 2 o 4).

## Repository
- Remote: `https://github.com/ZenigataBloch/tr-underworld-recomp`. Cartella locale `V:\DeComp\repo` (config progetto, patch, script, docs; niente gioco ne' codice generato).
- Auto commit/push dei piccoli fix tramite un watcher in una seconda finestra PowerShell (controlla ogni 30 s `tru_functions.toml`, `CMakeLists.txt`, manifest, diff SDK, HANDOVER.md). Esito del primo push: non ancora riportato.

## Ambiente
- Windows, Visual Studio Community 2026 (Clang, MSVC, Windows SDK). Piano Claude gratuito: Claude **non** controlla il PC; l'utente esegue gli script e incolla gli output. Il sandbox di Claude non ha rete.
- Cartella di lavoro `V:\DeComp` (script `.ps1`; dati in `V:\DeComp\work`; ISO in `V:\DeComp`).
- Script (con controllo exit code): `01-build-sdk.ps1`, `01b-fix-mspack-symlinks.ps1`, `02-install-sdk.ps1`, `03-init-codegen.ps1`. Da sbloccare: `Get-ChildItem .\*.ps1 | Unblock-File` e `Set-ExecutionPolicy -Scope Process -ExecutionPolicy RemoteSigned`.
- Log utili: `V:\DeComp\work\codegen-01.log`, `codegen-02.log`, `codegen-debug.log`, `build-game-loop.log`, `build-game-gpu.log`, `run-02.log`.
- Variabile usata nei test: `DISABLE_VULKAN_OBS_CAPTURE=1`. L'opzione `--log-file` non ha prodotto il file atteso; usare i `tru_NNN.log` nella cartella `logs`. `tru.exe --help` da' un errore di parsing CLI11.
- `.gitignore` del repo esclude `out/`, `work/`, `*.iso`, `*.xex`, `*.pk4`, `*.xbe`, `*.pak`, `*.bin`, `*.exe`, `*.dll`, `*generated*/`.

## Decisioni aperte per l'utente
- Repo pubblico o privato (stato attuale su GitHub non verificato).
- Licenza: SDK BSD a 3 clausole (derivata da Xenia); per GPL-2.0-or-later va conservata la nota di copyright originale (`NOTICE-ReXGlue-SDK.txt`).

## Prossimi passi concreti
1. Ricevere l'esito del dump shader (cache rinominata + `--dump_shaders`) e gli screenshot dei muri.
2. Controllare `tru_functions.toml` e confermare l'avvio stabile dopo START.
3. Se il problema grafico resta, indagare il codice GPU condiviso (texture/shader dei muri) invece di altri cvar.
4. Rivalutare la Patch 1 (185 voci) a milestone 1 chiusa; aggiornare questo file e `memory.md` a ogni passo.
