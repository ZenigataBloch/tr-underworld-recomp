# HANDOVER - Tomb Raider Underworld (Xbox 360) ricompilazione statica per PC

Ultimo aggiornamento: 2026-10-20, dopo le 00:30 (ora Roma). Milestone corrente: **1 di 6, quasi chiusa**; aperto un problema grafico (muri sporchi/neri).

## Obiettivo
Ricompilare staticamente la propria copia di Tomb Raider Underworld (Xbox 360) in modo che giri nativa su Windows. Base: SDK **ReXGlue v0.10.0** (kernel, GPU e audio gia' forniti; il plugin GPU `xenos` contiene sia il backend Direct3D 12 sia quello Vulkan). Non scrivere un renderer o un livello kernel propri. Le correzioni all'SDK sono patch piccole e documentate, in **un unico file diff** (`patches/rexglue-tru.diff` nel repo; bozza di lavoro `V:\DeComp\work\rexglue-tru.diff`).

## Regole fondamentali (dell'utente)
1. Mai file di gioco nel repository (ISO, XEX, pk4, dati) ne' codice ricompilato generato. Il README dice che ognuno deve procurarsi la propria copia.
2. Misurare prima di cambiare. Tenere una modifica solo se i numeri migliorano; togliere gli esperimenti senza miglioramento.
3. Chiedere prima di operazioni rischiose o con conferma esterna (eliminare, push, pubblicare, installare). Non avviare build di test mentre l'utente gioca. (Eccezione esplicita 2026-10-19: l'utente ha chiesto auto commit/push dei piccoli fix.)
4. Dire sempre cosa e' verificato e cosa solo ipotizzato.
5. Verificare con l'utente a ogni milestone e dare un breve riassunto.
6. **Comunicazione:** risposte brevi (max 30 parole di prosa), **tutti i comandi in un solo blocco** (se serve, uno script che cicla da solo e logga su file). L'utente si irrita se i passi vengono spezzettati, se si cambia idea/domanda a meta' o se si dimentica un risultato gia' riportato: tenere il registro esiti di questo file e rileggerlo prima di rispondere. Non proporre di installare altri programmi (RenderDoc/PIX rifiutati esplicitamente il 2026-10-19: "sto riempiendo il PC"); lavorare con log, codice e PowerShell/Python. Niente test "di controllo" che l'utente giudica inutili: se serve un controllo positivo, ricavarlo dai log.

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

### Modifiche SOLO nell'albero (NON ancora in `patches/rexglue-tru.diff`) - FARE IL DIFF PRIMA di altri esperimenti
- `src/system/runtime.cpp`: e' la Patch 1 qui sopra (warning invece di Shutdown per le 185 voci rifiutate). Scopo: far proseguire il gioco; workaround.
- `src/graphics/vulkan/texture_cache.cpp`, funzione `VulkanTextureCache::LoadTextureDataFromResidentMemoryImpl`: log `TRUDBG` (REXGPU_INFO per ogni caricamento texture: fmt, dim, w, h, tiled, packed, pitch, mips, endian, sgn, scaled, host, ls) e blocchi sperimentali con variabili d'ambiente `TRU_EXP_SWDXT`, `TRU_EXP_ENDIAN`, `TRU_EXP_SKIP` (valori: `packed`, `packed6`, oppure numero formato; `return false` prima del log). All'avvio l'esperimento attivo stampa `TRUEXP ...` nel log. Backup: `texture_cache.cpp.exp.bak`, `.exp2.bak`, `.exp3.bak`. Da togliere gli esperimenti inutili prima del diff finale.

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

## Problema grafico: muri sporchi/neri, volto con puntinatura (aperto, 2026-10-19/20)

### Sintomo
- Baseline senza cvar: muri sporchi, cutscene non renderizzata.
- Con `execute_unclipped_draw_vs_on_cpu=true` la cutscene iniziale si vede: quasi tutta la scena (volto di Lara, muri, sfondo) ha una puntinatura fitta di trattini diagonali arancioni; occhi e rocce ok. Titolo e menu con configurazione di default sono puliti. Screenshot dei 4 run SKIP (invalidi, vedi sotto) ricevuti: stesso difetto identico in tutti.
- Confronti visivi fatti a occhio su frame diversi di una scena in movimento, NON pixel-a-pixel.

### Come si testa (corretto 2026-10-20: leggere con attenzione)
- `Run-Tru '<etichetta>'` e' una funzione della sessione PowerShell (non e' in `V:\DeComp`). Fa: `DISABLE_VULKAN_OBS_CAPTURE=1`, poi `tru.exe --game_data_root "..." --gpu_plugin xenos --execute_unclipped_draw_vs_on_cpu=true`, aspetta la chiusura, stampa il log piu' recente e le righe `TRUEXP`. **Tutti i test fatti con Run-Tru hanno quindi `unclipped=true`.**
- **`tru.toml` accanto all'exe sembra IGNORATO** (aggiungendo `window_width/height` la finestra non e' cambiata; probabile, non dimostrato al 100%). Contiene solo `game_data_root`, `gpu_plugin`, `depth_transfer_not_equal_test = false`. Di conseguenza i test cvar fatti via toml (`cvar-tests-*` e `cvar-tests2-*` in `V:\DeComp\work\cvar-tests`) sono **NON VALIDI**. I cvar vanno passati solo come `--nome=valore`.
- Script ciclici (output in `V:\DeComp\work\cvar-tests`): `tru-cvar-cli.ps1` (14 test, esiti `cli-*-esiti.txt`) e `tru-cvar-cli2.ps1` (6 combinazioni con G, esiti `cli2-*-esiti.txt`). Dopo ogni test l'utente chiude il gioco e scrive l'esito (Invio = nessuna differenza).
- **Catena della DLL (verificato):** `rexgpu-xenos.dll` esiste in 5 copie. Patchate: `...\rexglue-sdk\out\install\win-amd64\bin\` e `...\rexglue-sdk\out\win-amd64\Release\`. Del gioco: `...\tru-project\out\build\win-amd64-release\`. Copia non patchata (2,7 MB): `V:\work\rexglue-sdk\...`. Dopo 01 -> 02 -> 04 la DLL nella cartella del gioco era ancora vecchia (21:48 contro 23:40): **va copiata a mano** dopo ogni modifica all'SDK: `Copy-Item V:\DeComp\work\rexglue-sdk\out\install\win-amd64\bin\rexgpu-xenos.dll V:\DeComp\work\tru-project\out\build\win-amd64-release\ -Force`. Un esperimento e' valido solo se nel log compare la riga `TRUEXP ...` (o `TRUDBG`).
- Legenda esiti dei primi giri (Chat GPT): muri `p`=puliti, `s`=sporchi, `n`=neri; cutscene `c`=non renderizzata, `o`=ok; `x`=non so.

### Risultati cvar, prima fase (riferiti dall'utente, eseguiti da riga di comando)
- Baseline senza cvar: `s c`.
- `depth_float24_round=true`, `depth_transfer_not_equal_test=false`, da soli o insieme: come baseline. Scartati.
- `execute_unclipped_draw_vs_on_cpu=true`: sblocca la cutscene (`s o`); muri sporchi, Lara con modello sbagliato. Base per tutti i test successivi.
- Sopra `unclipped`: `gpu_allow_invalid_fetch_constants=true`, `use_fuzzy_alpha_epsilon=true` nessun cambiamento (`s o`).
- `depth_float24_convert_in_pixel_shader=true` ("G"): **modello di Lara perfetto** (mani luccicanti in alcune varianti), **muri neri** (`n o`).
- Sopra `unclipped` + G: `render_target_path_vulkan=fbo`, `native_stencil_value_output=false` non cambiano i muri.
- D3D12 e Vulkan: stessi risultati (riferito).
- Altre combinazioni con G (`gamma_render_target_as_unorm16=false`, `mrt_edram_used_range_clamp_to_min`, `native_2x_msaa=false`, `direct_host_resolve`, `edram_rt_clamp`): nessun miglioramento.

### Risultati cvar, seconda fase (2026-10-20, `tru-cvar-cli.ps1`, base unclipped, validi)
- `render_target_path_vulkan=fsi`: stutter, muri neri, Lara con mani luminose. Da scartare.
- `gamma_render_target_as_unorm16=false`: peggiore di prima.
- `native_2x_msaa=false`: crash. `vulkan_dynamic_rendering=false`: crash.
- `depth_float24_convert_in_pixel_shader=true`: muri neri, niente stutter, Lara con mani luminose (conferma G).
- `gpu_allow_invalid_fetch_constants=true`: peggio di prima ("downgrade").
- Da `readback_resolve_half_pixel_offset=true` in poi l'utente ha scritto "come test precedente", cioe' **identico al test precedente, che era il downgrade**: `readback_resolve_half_pixel_offset`, `vulkan_sparse_shared_memory=false`, `native_stencil_value_output=false`, `vulkan_readback_resolve=true`, `non_seamless_cube_map=true`, `depth_float24_round=true`, `vulkan_force_expand_point_sprites_in_vs=true`, `vulkan_prefer_geometry_shader=false`. **Dubbio aperto:** il downgrade potrebbe essere rimasto "appiccicato" (cache o stato) per tutti i test successivi, rendendoli non informativi. Non verificato: serve un baseline pulito (`Run-Tru` senza altro) e confronto. L'utente ha respinto un ragionamento confuso su questo punto, quindi riproporlo in modo semplice.

### Combinazioni con G (`tru-cvar-cli2.ps1`, validi)
- G + `depth_float24_round=true`: niente stutter, Lara giusta con mani luccicanti, muri neri.
- G + `render_target_path_vulkan=fsi`: stutter, per il resto uguale.
- G + `depth_transfer_not_equal_test=false`, G + `native_stencil_value_output=false`, G + `vulkan_readback_resolve=true`, G + `gamma...=true` + round + `depth_transfer_not_equal_test=true`: uguale al primo (muri neri, Lara giusta).

### Esperimenti texture sulla cutscene (variabili `TRU_EXP_*`, via Run-Tru, validi solo dopo la copia della DLL; il log mostra `TRUEXP skip=<v>`)
- `TRU_EXP_SKIP=23`: nessuna differenza visibile. `=18`: nessuna. `=20`: nessuna. `=49`: nessuna. `=packed6` (fmt 6 con packed): nessuna.
- `TRU_EXP_SKIP=packed`: immagine molto peggiore ("orrendo") -> le texture packed sono usate in scena.
- `TRU_EXP_SKIP=2`: tutto verde, anche il menu principale (ipotesi: fmt 2 a 8 bit usato anche dal video/menu; non verificato).
- `TRU_EXP_SKIP=6`: tutto nero, anche il menu.
- `TRU_EXP_SWDXT=1` (decodifica DXT software): titolo con frange magenta/verdi, peggiore del BC nativo; cutscene: menu visibile, intro carica, gioco con artefatti.
- `TRU_EXP_ENDIAN=0` sui compressi: titolo e menu peggiorano, cutscene sporca come prima. endian=1 e' giusto; endian=2 non testato.
- **NON validi** (DLL del gioco vecchia, variabile mai arrivata, nessuna riga `TRUEXP skip`): i primi giri SKIP packed/18/20/49 e 23/2/6. Ignorarli.

### Dati dal log texture (`tru_114.log`, 11.576 load, 67 combinazioni; verificato)
- Formati: fmt 6 = 8888 (ls=2), fmt 2 = 8 bit (ls=0), fmt 23 = 24_8_FLOAT convertito in R32 (host=100, ls=36), fmt 18 = DXT1 (BC1), fmt 20 = DXT4/5 (BC3), fmt 49 = DXN (BC5). Compressi sempre `endian=1`; nessun load shader sconosciuto, nessun `sgn=1`; presente un cubemap/3D (`dim=3`).
- Titolo e menu (fino a 20:47:30): nessuna texture `packed=1` con `mips>0`; DXT solo `packed=0 mips=0`. Dal 20:47:36.132 (inizio cutscene) compaiono insieme: DXT1/DXT5/DXN `packed=1` con 5-10 mip, render target fmt 6 e depth/shadow fmt 23 (1024x576, 2048x1024, 2048x2048).
- Il `pitch` e' sempre ceil(w/32): coerente, nessuna anomalia di stride. fmt 6 1280x720 e' quasi sempre `endian=0` (1607 volte contro 1).
- In gioco ~510 load/s di fmt 6 e ~60/s di fmt 23 (render target e shadow map ricaricati ogni frame): da misurare per il milestone 4.

### Interpretazione (ipotesi, NON verificate)
- Saltare DXT1/DXT5/DXN, fmt 23 o fmt 6 packed non cambia il difetto; G corregge il volto. Ipotesi: la puntinatura e' un problema di precisione/confronto di profondita' (tipo shadow acne) con il float24, non di decodifica texture. Muri neri con G (e con fsi) non spiegati: forse ombra/luce sbagliata, non misurato.
- Codice letto: la conversione D24FS8 in pixel shader esiste in `vulkan/pipeline_cache.cpp` (~riga 992, `DepthStencilMode::kFloat24Truncating/kFloat24Rounding`) e nel traduttore SPIR-V (`kSysFlag_DepthFloat24`, `vulkan/command_processor.cpp` ~6006). Il percorso di caricamento di fmt 23 come R32 (host=100, load shader 36) in `texture_cache.cpp` **non e' ancora stato letto**.
- Cvar non ancora provati: `gpu_debug_markers`, `dump_shaders`, `vulkan_force_convert_quad_lists_to_triangle_lists`, `execute_unclipped_draw_vs_on_cpu_with_scissor`, `half_pixel_offset`, `resolve_resolution_scale_fill_half_pixel_offset`, `vulkan_prefer_*`/`vulkan_require_*` (tutti da passare da riga di comando).

### In sospeso
- Dump degli shader (`--dump_shaders "V:\DeComp\work\shaders"`): primo tentativo 0 file (cache shader gia' presente); script con cache rinominata preparato, esito non riportato.

### Risultati 2026-10-20 (2): G + skip formati e cvar (validi: DLL patchata alle 23:52, log con `TRUEXP skip`)
- Con G, `TRU_EXP_SKIP=23`: nessun cambiamento (tru_188). `=20`: il volto sparisce, "Lara non ha un viso" (tru_189): DXT5 contiene il volto; il menu si rompe. `=18`: tutto nero tranne le esplosioni (tru_190). `=49`: muri ancora neri, lievi bug sul modello (tru_191). `=packed6`: stutter, muri neri (tru_192).
- Verificato dai test: nessun formato corregge i muri con G. Il difetto sta dopo il caricamento texture.
- `tru-cvar-cli3.ps1` (12 test con G: occlusion, scissor, convert quad/fan/line, half pixel, memexport, clear memory page, fuzzy alpha, prefer vertex pipeline, fake sample count): tutti uguali, muri neri. Riferito dall'utente; esito per singolo test non registrato.
- Volto: G lo corregge. Vulkan: G entra in `vulkan/command_processor.cpp:3932` (stato viewport/depth), non nel calcolo della luce.
- Ipotesi NON verificate: i muri neri vengono da ombra o illuminazione, non da decodifica texture. Candidati: confronto shadow (Dref) nel traduttore SPIR-V, operazioni ALU della luce.
- Il diff SDK committato e' WIP: contiene TRUDBG e TRU_EXP_*. Da ripulire prima del diff finale.

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
- Variabile usata nei test: `DISABLE_VULKAN_OBS_CAPTURE=1`. Script di build: `04-build-game.ps1` (non ricopia `rexgpu-xenos.dll`, vedi sezione grafica). `V:\work` e' una copia NON patchata dell'SDK (script 01/02 prima puntavano li', corretti con backup `.bak`): cancellarla solo con ok esplicito. L'opzione `--log-file` non ha prodotto il file atteso; usare i `tru_NNN.log` nella cartella `logs`. `tru.exe --help` da' un errore di parsing CLI11.
- `.gitignore` del repo esclude `out/`, `work/`, `*.iso`, `*.xex`, `*.pk4`, `*.xbe`, `*.pak`, `*.bin`, `*.exe`, `*.dll`, `*generated*/`.

## Decisioni aperte per l'utente
- Repo pubblico o privato (stato attuale su GitHub non verificato).
- Licenza: SDK BSD a 3 clausole (derivata da Xenia); per GPL-2.0-or-later va conservata la nota di copyright originale (`NOTICE-ReXGlue-SDK.txt`).

## Prossimi passi concreti
1. Verificare il commit docs + diff WIP (`git log` nel repo).
2. Leggere l'output del grep su Dref nel traduttore SPIR-V e cercare le operazioni di luce.
3. Se un punto e' confermato: una sola modifica alla volta, misurata nei log.
4. Ripulire TRUDBG e TRU_EXP_* dal diff; rifare il diff finale.
5. Controllare `tru_functions.toml` e l'avvio dopo START; rivalutare la Patch 1. Aggiornare questo file e `memory.md` a ogni passo.
