# navi-baseline

Baseline pessoal para configurar o [navi](https://github.com/denisidoro/navi) em qualquer máquina Linux: binário, cheat sheets próprias, notas e atalho `Ctrl+G`.

## Instalação numa máquina nova

```bash
git clone https://github.com/david-allsafe/navi-baseline.git
cd navi-baseline && bash install.sh
```

Abre um terminal novo e corre `navi` (ou `Ctrl+G`).

## O que o `install.sh` faz

| Passo | Detalhe |
|---|---|
| Dependências | `fzf` via apt; opcionais: `tldr`, `tree`, `exiftool`, `pdfinfo` |
| navi | Binário oficial v2.24.0 para `~/.local/bin`, **verificado por SHA-256** antes de instalar (x86_64, aarch64, armv7) |
| Cheats | `cheats/*.cheat` → `~/.local/share/navi/cheats/david/` |
| Notas | `notas/01.txt` → `~/notas/01.txt` (backup automático se a versão local for diferente) |
| Shell | Deteta bash/zsh e acrescenta PATH + widget ao `.bashrc`/`.zshrc` |

É idempotente: se o navi ou o widget já existirem, não duplica nada. Não precisa de Rust/cargo.

## Atualizar as cheats

Depois de editar cheats numa máquina:

```bash
bash recolher.sh          # copia as cheats locais para o repo
git add -A && git commit -m "Atualiza cheats" && git push
```

Nas outras máquinas: `git pull && bash install.sh`.

## Estrutura

```
cheats/      cheat sheets do navi (ubuntu.cheat, kali.cheat, ...)
notas/01.txt notas de uso (abríveis pelo próprio navi)
install.sh   instalação/atualização
recolher.sh  copia as cheats locais para o repo
```

## Notas de segurança

- Sem `curl | bash`: o binário é descarregado das releases oficiais e o hash é comparado com o valor fixado no script; se não corresponder, a instalação aborta.
- Não corre como root; só usa `sudo` para o apt.
- Para mudar de versão do navi, atualizar `NAVI_VERSION` e os hashes em `install.sh`.
