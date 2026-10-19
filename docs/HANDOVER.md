# HANDOVER - Tomb Raider Underworld (Xbox 360) ricompilazione statica per PC

Ultimo aggiornamento: 2026-10-19, dopo le 12:57 (ora Roma). Milestone corrente: **1 di 6, in corso**.

## Obiettivo
Ricompilare staticamente la propria copia di Tomb Raider Underworld (Xbox 360) in modo che giri nativa su Windows. Base: SDK **ReXGlue v0.10.0** (kernel, GPU Direct3D 12 e audio gia' forniti). Non scrivere un renderer o un livello kernel propri. Le correzioni all'SDK sono patch piccole e documentate, in **un unico file diff** (`patches/rexglue-tru.diff` nel repo; oggi la bozza e' `V:\DeComp\work\rexglue-tru.diff`).

## Regole fondamentali (dell'utente)
1. Mai file di gioco nel repository (ISO, XEX, pk4, dati) ne' codice ricompilato generato. Il README dira' che ognuno deve procurarsi la propria copia.
2. Misurare prima di cambiare. Tenere una modifica solo se i numeri migliorano; togliere gli esperimenti senza miglioramento.
3. Chiedere prima di operazioni rischiose o con conferma esterna (eliminare, push, pubblicare, installare). Non avviare build di test mentre l'utente gioca.
4. Dire sempre cosa e' verificato e cosa solo ipotizzato.
5. Verificare con l'utente a ogni milestone e dare un breve riassunto.
6. **Comunicazione:** risposte brevi (20-30 parole di prosa), **tutti i comandi in un solo blocco** (se serve, uno script che cicla da solo). L'utente si irrita se i passi vengono spezzettati.

## Milestone
1. SDK compilato e installato; il gioco si avvia fino alla schermata del titolo. **(in corso)**
2. Correzioni di crash (limiti di funzioni mancanti, eccezioni in virgola mobile, funzioni non registrate).
3. Record/replay dell'input per guidare il gioco in autonomia.
4. 60 fps stabili senza scatti (misurare i tempi dei singoli fotogrammi, non la media).
5. QoL: menu impostazioni in-game, prompt "trova la tua ISO", collegamento desktop e icona.
6. Pubblicazione: repo GitHub (`<account>`, GPL-2.0-or-later, pubblico/privato da decidere), README, rilasci con solo codice sorgente.

## Stato del milestone 1

### Fatto e VERIFICATO (output reale sul PC dell'utente)
- SDK v0.10.0 (`f5337cdc...`) compilato (preset `win-amd64`, Clang VS Community 2026, CMake 4.3.1, Ninja) e installato in `V:\DeComp\work\rexglue-sdk\out\install\win-amd64`.
- ISO estratta in `V:\DeComp\work\game\Tomb Raider - Underworld\` (un solo `default.xex`, Title ID `534307EC`).
- Progetto `V:\DeComp\work\tru-project`, manifest `tru_manifest.toml`, config funzioni in `tru_functions.toml` (collegato con `includes`).
- Codegen completo e **build del gioco riuscita** (exit 0): `tru.exe` (42 MB) e `rexruntime.dll` in `tru-project\out\build\win-amd64-release\`.
- Comando di avvio: `.\tru.exe --game_data_root "V:\DeComp\work\game\Tomb Raider - Underworld"`. Log in `...\win-amd64-release\logs\tru_NNN.log`.
- Dopo la Patch 1 (sotto) il runtime parte, il gioco esegue codice guest, SDL input e audio si inizializzano.

### Patch SDK applicate (da riportare in `patches/rexglue-tru.diff`)
1. `src/system/runtime.cpp`: `rejected > 0` in `func_mappings` ora emette un warning e prosegue (prima: `Shutdown()` + `X_STATUS_UNSUCCESSFUL`, avvio impossibile con exit 1). Backup `runtime.cpp.bak`. **E' un workaround**: le 185 voci rifiutate sono stub di falso codice (vedi sotto). Va rivalutato; non e' dimostrato che sia la soluzione finale.

### Problema delle 185 voci (analisi, in gran parte verificata)
- Immagine runtime `82000000-83270000`, codice `820A0000-82730E74`. Le voci rifiutate (`0x83C29058`, `0x83E41A58`...`0x83E55184`, `0xFEEC2308`) sono fuori immagine.
- Nascono da `bl`/`bla` in funzioni tra `0x82727260` e `0x8272DE94`, il cui codice e' privo di senso: quasi certamente **dati/testo decodificati come PowerPC** (ipotesi forte; confine esatto non misurato).
- `[[invalid_instructions]]` e `[analysis].data_region_threshold` non risolvono (letti nel sorgente: il primo salta singoli siti nelle regioni pdata, il secondo conta parole `0`/`0xFFFFFFFF` consecutive).
- Strada aperta per una soluzione vera: trovare un modo di dire al codegen che la zona e' dati, oppure rimuovere quelle funzioni; poi rimisurare "185 rejected" (deve scendere a 0) e togliere la Patch 1.

### Funzioni non registrate (corretto un indirizzo alla volta)
Voce in `tru_functions.toml`: `[functions."0xADDR"] size = <prossima funzione - ADDR>`. Attuale contenuto verificato: `0x82506D98` (8), `0x8211D4C0` (64), `0x825003A0` (24).
- **FATAL attuale:** `0x8252A420` (non ancora corretto).
- Fatto proposto, output non ancora ricevuto: ciclo automatico che ripete avvio -> FATAL -> aggiunta -> rigenerazione (max 15 giri; si ferma su indirizzi fuori dal codice, gia' presenti, size sospetta).
- Attenzione PowerShell: i letterali hex > `0x7FFFFFFF` sono negativi; usare `[uint32]`/`[int64]`. Avvolgere gli script in `& { }` perche' `throw` fermi tutto.

### Aperto / non indagato
- **GPU plugin non impostato** (`no GPU emulation loaded (gpu_plugin not set)`, verificato). Il `CMakeLists.txt` del progetto chiama solo `rexglue_setup_target(tru)`; `rexglue_helpers.cmake` ha un argomento `GPU_PLUGINS`; il cvar `gpu_plugin` carica il plugin. Ipotesi: serve per arrivare al titolo. Prossimo passo: leggere `rexglue_helpers.cmake` (righe 70-170) e capire il valore da passare (non ancora verificato).
- `d:\layer2.dat` e `d:\tr8.arg`: `NtCreateFile FAILED 0xC000000F` (importanza ignota).
- `BaseHeap::Alloc failed to find contiguous range` / `PhysicalHeap::Alloc unable to alloc...`: molti, causa ignota.
- `gamecontrollerdb.txt` assente (probabilmente innocuo).

### Ancora da fare per chiudere il milestone 1
1. Esaurire le funzioni non registrate fino a un avvio stabile.
2. Collegare il GPU plugin (D3D12).
3. Arrivare alla schermata del titolo. Non ancora raggiunta.
4. Sostituire/chiudere il workaround della Patch 1 se possibile.

## Ambiente
- Windows, Visual Studio Community 2026 (Clang, MSVC, Windows SDK). Piano Claude gratuito: Claude **non** controlla il PC; l'utente esegue gli script e incolla gli output. Il sandbox di Claude non ha rete.
- Cartella di lavoro `V:\DeComp` (script `.ps1`; dati in `V:\DeComp\work`; ISO in `V:\DeComp`).
- Script in `scripts/` (con controllo exit code): `01-build-sdk.ps1`, `01b-fix-mspack-symlinks.ps1`, `02-install-sdk.ps1`, `03-init-codegen.ps1`. Da sbloccare: `Get-ChildItem .\*.ps1 | Unblock-File` e `Set-ExecutionPolicy -Scope Process -ExecutionPolicy RemoteSigned`.
- Log utili: `V:\DeComp\work\codegen-01.log`, `codegen-02.log`, `codegen-debug.log` (4,7 MB), `build-game-0N.log`, `run-02.log`, `callers-out-of-image.txt`, `unimpl-per-page.txt`.
- `.gitignore` scritto (esclude `work/`, `*.iso`, `*.xex`, `*.pk4`, `*.xbe`, `*.pak`, `*.bin`, `*generated*/`).

## Decisioni aperte per l'utente
- Repo GitHub: account, pubblico o privato (milestone 6).
- Repo in sottocartella separata (es. `V:\DeComp\repo`), perche' l'ISO sta in `V:\DeComp` con gli script.
- Licenza: SDK BSD a 3 clausole (derivata da Xenia); per GPL-2.0-or-later va conservata la nota di copyright originale.

## Prossimi passi concreti
1. Ricevere l'output del ciclo automatico delle funzioni non registrate e la lettura di `rexglue_helpers.cmake`.
2. Aggiungere `GPU_PLUGINS` a `rexglue_setup_target(tru ...)` con il valore corretto, ricompilare, avviare.
3. Spostare `rexglue-tru.diff` in `patches/` quando il repo esistera'; aggiornare questo file e `memory.md` a ogni passo.
