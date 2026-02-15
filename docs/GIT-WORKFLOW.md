# Dejavara Monorepo - Git Workflow

## Structure
```
Dejavara/           # Master repo
├── AutoCAD-AHK/    # Submodule
├── Cambium/        # Submodule (auto-deploys to Railway)
├── FileOrganizer/  # Submodule
├── OpenClaw/       # Submodule
└── Phteah-pi/      # Submodule
```

## VS Code Source Control Icons
- **S** = Submodule has new commits (pointer changed)
- **M** = Modified file
- **U** = Untracked (new file)
- **+** in `git submodule status` = submodule ahead of recorded commit

## Daily Workflow

### Before Starting Work
```powershell
cd C:\Dev\Dejavara
git pull
git submodule update --init --recursive
```

### After Making Changes

**Rule: Commit inside-out (submodules first, then parent)**

1. **Commit in each submodule that has changes:**
   ```powershell
   cd Cambium
   git add -A
   git commit -m "feat: description"
   git push
   cd ..
   ```

2. **Then commit in Dejavara to update pointers:**
   ```powershell
   cd C:\Dev\Dejavara
   git add -A
   git commit -m "chore: update submodules"
   git push
   ```

### Quick Cleanup Script
```powershell
# From C:\Dev\Dejavara - commits all submodules then parent
$subs = @("AutoCAD-AHK", "Cambium", "FileOrganizer", "OpenClaw", "Phteah-pi")
foreach ($sub in $subs) {
    Push-Location $sub
    if (git status --porcelain) {
        git add -A
        git commit -m "chore: sync changes"
        git push
    }
    Pop-Location
}
git add -A
git commit -m "chore: update submodules"
git push
```

## What NOT to Do
- Don't commit in Dejavara without first committing submodule changes
- Don't ignore (S) markers in Source Control - they mean submodules drifted
- Don't work in standalone clones outside this monorepo

## Cambium Auto-Deploy
Pushing to `Cambium/main` triggers Railway deployment automatically.
No extra steps needed - just push.
