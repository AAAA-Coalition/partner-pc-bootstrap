# partner-pc-bootstrap

One line to start the setup of a partner's Windows PC for the AAAA Coalition system.

```powershell
irm https://raw.githubusercontent.com/AAAA-Coalition/partner-pc-bootstrap/main/bootstrap.ps1 | iex
```

Run it in an **administrator** PowerShell window, during a setup session with the AAAA team.

## What it does

1. Installs GitHub CLI if it is missing (winget).
2. Opens your browser so that you sign in to **your own** GitHub account and click Authorize.
3. Clones **your private** exchange repository.
4. Runs the installer found in that repository (`setup/`), which prints GREEN or RED for each step.

## What it never does

- It holds no secret, no address, and no partner name. Everything specific to you stays in your private repository.
- It never sees or asks for a password. You sign in yourself, in your browser.
- It never deletes anything.

## Why a public file

A one-line command cannot read a private repository. This file is the only public piece; everything else is private.

Read it before running it: it is about 60 lines.
