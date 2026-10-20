# memory.md - appunti di progetto TRU recomp

Diario tecnico del progetto, aggiornato a ogni passo. Cio' che non e' marcato "verificato" va considerato ipotesi.

## Decisioni dell'utente (fisse, non rivalutare)
- SDK ReXGlue **v0.10.0** come base; niente renderer o kernel propri.
- Ordine: compilare SDK -> `rexglue init` -> `rexglue codegen` -> avvio fino al titolo; solo dopo le funzionalita'.
- Fix SDK come patch piccole e documentate in un unico file diff.
- Mai file di gioco ne' codice generato nel repo. README: ognuno porta la propria copia.
- Misurare prima di cambiare; tenere solo cio' che migliora i numeri.
- Chiedere prima di eliminare, push, pubblicare, installare. Niente build di test mentre l'utente gioca. (2026-10-19: l'utente ha chiesto esplicitamente auto commit/push dei piccoli fix.)
- Lavoro sul PC: lo fa l'utente eseguendo gli script e incollando gli output (scelta "opzione 1").
- **Stile di comunicazione (2026-10-19/20, l'utente si e' arrabbiato piu' volte):** risposte brevi (max 30 parole di prosa). Non cambiare domanda a meta', non dimenticare risultati gia' riportati, niente test di controllo giudicati inutili, niente programmi da installare (RenderDoc/PIX rifiutati). Chiedere **tutto in un solo blocco** di comandi, mai un comando per volta. Meno ricerche a pezzi, piu' blocchi autonomi (cicli che si fermano da soli).

## Cronologia (2026-10-19)
- Verifica preliminare: ReXGlue esiste, v0.10.0 usato da altri progetti; tag = commit `f5337cdc...` (**verificato**).
- Prima build SDK **fallita** su `lzxd.c`: symlink di `libmspack` diventati file di testo su Windows. Soluzione: `01b-fix-mspack-symlinks.ps1` (copie, solo in `work\`). Seconda build ok.
- Lezione: PowerShell non ferma lo script su errore di programma esterno; controllare `$LASTEXITCODE` ovunque.
- Lezione: output SDK in `<radice SDK>\out\<piattaforma>\<config>` (**verificato**).
- SDK installato dopo ok esplicito. ISO estratta con XGDTool (Extract) in `V:\DeComp\work\game`.
- Lezione: `rexglue init` genera `<nome>_manifest.toml`; `codegen` prende il manifest.
- Codegen #1: 1 errore, `b 0x82506D98` da `0x82507A44`. Voce `[functions."0x82506D98"] size = 8` in `tru_functions.toml`; codegen a fine e build del gioco riuscita (**verificato**).
- **Build del gioco riuscita** (exit 0, 105 s): `tru.exe` 42.030.080 byte, `rexruntime.dll` 9.853.440 byte, in `V:\DeComp\work\tru-project\out\build\win-amd64-release\`.
- Primo avvio senza argomenti: finestra "`--game_data_root was not provided.`". Serve `--game_data_root "<cartella>"` (**verificato**).
- Avvio con argomento: exit code 1. Log in `out\build\win-amd64-release\logs\tru_NNN.log` (**verificato**). Causa: `185 func_mappings entries rejected` e poi `Runtime setup failed: C0000001`.

## Analisi delle 185 voci rifiutate (verificato salvo dove indicato)
- Runtime: `code=820A0000-82730E74`, `image=82000000-83270000`.
- Le voci rifiutate stanno oltre l'immagine (`0x83C29058`, `0x83E41A58`...`0x83E55184`, e `0xFEEC2308`). Non e' un offset costante.
- Origine: chiamate `bl`/`bla` in funzioni tra `0x82727260` e `0x8272DE94`; il codegen ha emesso uno stub vuoto per ogni target.
- Il codice chiamante e' privo di senso: **quasi certamente dati o testo decodificati come istruzioni**. Dove inizia la zona dati: **non misurato**. Il conteggio di `REX_UNIMPLEMENTED` per pagina NON la distingue (scartato).
- Sorgente SDK: `[[invalid_instructions]]` (`phase_discover.cpp`) e `data_region_threshold` (`phase_scan.cpp`) **non risolvono** questo caso.
- Sorgente del rifiuto: `function_dispatcher.cpp:256` (SetFunction) e `runtime.cpp:238-241`.

## Patch SDK 1 (workaround, da rivalutare)
- `src/system/runtime.cpp`: se `rejected > 0` ora `REXSYS_WARN(... (continuing))` invece di `Shutdown()` + errore. Backup `runtime.cpp.bak`; diff in `V:\DeComp\work\rexglue-tru.diff`. SDK ricompilato e reinstallato.
- Verificato: dopo la patch il log mostra `185 ... rejected (continuing)` e il gioco esegue codice guest.
- Workaround: nasconde la causa. Rivalutare a milestone 1 chiusa; da tenere solo se non peggiora i numeri.

## GPU plugin (verificato 2026-10-19)
- `rexglue_helpers.cmake`: `rexglue_configure_target` accetta `GPU_PLUGINS <nome>`; il target installato e' `rex::gpu-xenos` (`rexgpu-xenos.dll`). Il cvar `gpu_plugin` (in `rex_app.cpp`) carica il plugin.
- Fatto: `rexglue_setup_target(tru GPU_PLUGINS xenos)` in `CMakeLists.txt` (backup `.bak`) e avvio con `--gpu_plugin xenos`. Il log mostra `[gpu] SetInterruptCallback(...)`.
- **Risultato: menu principale raggiunto, con audio.** Premendo START: `FATAL ... 0x8225C440` (funzione non registrata).

## Funzioni non registrate a runtime
Schema (verificato): l'indirizzo e' l'inizio della funzione successiva a una gia' scoperta (chiamata presumibilmente indiretta). Correzione: `[functions."0xADDR"] size = <prossima funzione - ADDR>`.
- Voci attuali (verificate nel toml): `0x82506D98`(8), `0x8211D4C0`(64), `0x825003A0`(24), `0x8252A420`(24), `0x821F5010`(24), `0x821F4A88`(16), `0x82128CE0`(8), `0x82253DA0`(16), `0x82253DB0`(16), `0x82253DC0`(40), `0x824C9CA8`(16), `0x824C92F8`(32), `0x82153460`(24).
- **FATAL attuale:** `0x8225C440` (dopo START). Esito del ciclo successivo non ancora visto.
- Lezione: in PowerShell `0x8211D4C0` e' un int32 **negativo**; usare `[uint32]`/`[int64]`. Anche i limiti del controllo "fuori dal codice" avevano questo bug (corretto con `[uint32]'0x...'`).
- Lezione: `throw` nel paste a righe non ferma le righe successive: avvolgere tutto in `& { }`.
- Lezione: il codegen **rifiuta voci sovrapposte** (`[config] Overlapping boundaries: 0x82253DA0+0x48 overlaps 0x82253DB0+0x38`, verificato). Fix: accorciare la voce precedente (`size = prossimo - indirizzo`); il ciclo lo fa da solo (`Fix-Overlaps`).
- Lezione: se la build fallisce o viene interrotta, `tru.exe` resta vecchio e il FATAL si ripete anche con la voce nel toml. Controllare timestamp di `tru_init.cpp`/`tru.exe`.
- Lezione: avviare con `Start-Process` e `WaitForExit(ms)` + `Kill()` evita che una finestra nera blocchi il ciclo.

## Altre osservazioni dal log (non indagate)
- `NtCreateFile FAILED` (0xC000000F, file non trovato): `d:\layer2.dat`, `d:\tr8.arg`, `game:\movies\english\medsea_loop.wmv`, `game:\movies\medsea_loop.sch`. Se i filmati mancano nell'estrazione: **non verificato**.
- Molti `BaseHeap::Alloc failed to find contiguous range` / `PhysicalHeap::Alloc unable to alloc physical memory in parent heap`: causa ignota; il gioco prosegue.
- `gamecontrollerdb.txt` assente (warning innocuo, ipotesi). Controller Xbox Series X riconosciuto da SDL (verificato).
- Audio: endpoint inizializzato correttamente (verificato).

## Repository GitHub
- `https://github.com/ZenigataBloch/tr-underworld-recomp`; cartella locale `V:\DeComp\repo` con `patches/`, `project/`, `scripts/`, `docs/`, README, LICENSE GPL-2.0, `NOTICE-ReXGlue-SDK.txt`.
- Esito del primo push: non ancora riportato.
- Auto commit/push: watcher in seconda finestra PowerShell (poll ogni 30 s), blocca file vietati (`*.iso`, `*.xex`, `generated/`...).

## Fatti verificati sull'SDK v0.10.0 (dal sorgente)
- CLI: solo `init`, `codegen` (e uno interno di test). Opzioni globali: `--log-level`, `--log-file`, `-v/--verbose`, `-f/--force`.
- Nessun estrattore ISO integrato. `disc_image_device` esiste nel runtime; se permetta l'avvio da ISO e' ipotesi.
- Config per binario: `[functions."0xADDR"]` (`size`/`end`, `name`, `parent`, `share_registers`), `[[switch_tables]]`, `[[invalid_instructions]]`, `[[midasm_hook]]`, `[analysis]` (`max_jump_extension`, `data_region_threshold`, `large_function_threshold`, `exception_handler_funcs`), `setjmp_address`, `longjmp_address`.
- Licenza SDK: BSD a 3 clausole con avviso Xenia.

## Metodo per i prossimi errori
1. Rilanciare con `--log-level debug --log-file <file>` e cercare per indirizzo esatto e funzioni vicine.
2. Una ipotesi, una voce in `tru_functions.toml`, rigenerare, confrontare.
3. Tenere ogni voce solo se l'errore sparisce senza crearne altri. Annotare il perche'.
4. Mai `--force` per nascondere errori.


## Grafica, sessione 2026-10-19 sera / 2026-10-20 (dettagli in HANDOVER.md)
Verificato:
- Script 01/02 puntavano a `V:\work` (copia non patchata, DLL 2,7 MB); corretti in `$PSScriptRoot\work` (backup `.bak`). Build patchata in `V:\DeComp\work\rexglue-sdk`. `V:\work` da cancellare solo con ok esplicito.
- `git checkout` scrive "HEAD is now at..." su stderr: in PowerShell 5.1 con `*>&1` e `ErrorActionPreference=Stop` e' scambiato per errore. Usare `--quiet` o `cmd /c "... > log 2>&1"`.
- Patch di log `TRUDBG` (e esperimenti `TRU_EXP_SWDXT/ENDIAN/SKIP`) in `src/graphics/vulkan/texture_cache.cpp`; log `tru_114.log`: 11.576 load, 67 combinazioni uniche (formati e pitch in HANDOVER).
- Titolo/menu non usano texture `packed=1` con mip; la cutscene si'. Il pitch e' sempre ceil(w/32): nessun bug di stride dai dati.
- `Run-Tru` (funzione di sessione) passa sempre `--execute_unclipped_draw_vs_on_cpu=true`. `tru.toml` accanto all'exe sembra ignorato: i cvar vanno passati come `--nome=valore`. I test cvar via toml sono nulli.
- `04-build-game.ps1` non ricopia `rexgpu-xenos.dll`: la copia del gioco era ferma alle 21:48, la patchata alle 23:40. I primi test SKIP erano quindi nulli (nessuna riga `TRUEXP skip` nei log).
- Dopo la copia: SKIP 23/18/20/49/packed6 nessuna differenza; SKIP packed molto peggio; SKIP 2 tutto verde; SKIP 6 tutto nero; SWDXT artefatti.
- Cvar (CLI): `depth_float24_convert_in_pixel_shader=true` da' Lara giusta e muri neri; `fsi` stutter e muri neri; `native_2x_msaa=false` e `vulkan_dynamic_rendering=false` crash; `gamma_render_target_as_unorm16=false` e `gpu_allow_invalid_fetch_constants=true` peggio. Gli altri 8 cvar: identici al downgrade precedente.
Ipotesi (non verificate): la puntinatura e' un problema di precisione/confronto depth (float24); muri neri con G non spiegati; il "downgrade" potrebbe essere rimasto appiccicato dopo `gpu_allow_invalid_fetch_constants`.
Lezioni:
- Misurare il percorso reale degli script prima di fidarsi (`..\work` da `V:\DeComp` e' `V:\work`).
- Dopo ogni build controllare la stringa dell'esperimento nei binari E nella DLL che il gioco carica (timestamp delle 5 copie di `rexgpu-xenos.dll`); un esperimento vale solo se il log mostra la riga `TRUEXP`/`TRUDBG`.
- Un risultato nullo vale solo se l'esperimento ha dimostrato di avere effetto; ricavare il controllo dai log, non da test inutili.
- Non mescolare ipotesi e fatti; numerare gli esperimenti con il nome esatto della variabile (`TRU_EXP_*`) o del cvar.
- Confronti visivi su scene in movimento: annotare che non sono pixel-a-pixel.
- Prima di ogni nuovo esperimento sul sorgente: generare il diff (le modifiche stanno solo nell'albero).

## Stato
- (2026-10-20) Grafica: vedi sezione sopra e HANDOVER.md; prossimo passo: diff di sicurezza, baseline pulito, lettura del percorso fmt 23 in `texture_cache.cpp`.
- Milestone 1 in corso: menu principale raggiunto; crash dopo START su funzioni non registrate (ultimo noto `0x8225C440`). Prossimo dato atteso: output del ciclo con START e stato del primo push su GitHub.


## 2026-10-20 (2): G e skip formati (validi)
Verificato: G (`depth_float24_convert_in_pixel_shader=true`) corregge il volto. Con G, SKIP 23/18/49/packed6 non sistemano i muri; SKIP 20 fa sparire il volto (DXT5 contiene il volto). 12 cvar testati con G (`cli3`): tutti uguali (riferito). In Vulkan G entra in `command_processor.cpp:3932` (stato viewport), non nella luce.
Ipotesi: muri neri = ombra/illuminazione (confronto Dref o ALU), non decodifica texture. Da verificare nel traduttore SPIR-V.
Lezione: prima di chiedere a un test "e' cambiato?", leggere l'output gia' disponibile nei log e negli esiti; non ripetere test gia' fatti.
