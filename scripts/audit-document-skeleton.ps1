# C:\Dev\Dejavara\scripts\audit-document-skeleton.ps1
# Document Skeleton Auditor v1.0
# Audits projects against the 68-item document skeleton
# READ-ONLY - does not modify any files

param(
    [string]$ProjectsRoot = "C:\Projects",
    [string]$FORoot = "C:\FO",
    [string]$OutputPath = "C:\Projects\_audit",
    [switch]$TestRun,
    [string]$TestProject = "",
    [int]$SampleSize = 0
)

$ErrorActionPreference = "Continue"
$timestamp = Get-Date -Format "yyyyMMdd"
$auditDate = Get-Date -Format "yyyy-MM-dd"

# ============================================================================
# SKELETON DEFINITION (68 items)
# ============================================================================

$skeleton = @(
    # Phase 0 - Contract Award
    @{ id = 1; name = "Signed agreement / LOI"; phase = 0; location = "00-contract/agreement"; patterns = @("agreement", "contract", "loi", "letter.*intent"); extensions = @("pdf"); required = "yes" }
    @{ id = 2; name = "Architectural drawing set"; phase = 0; location = "00-contract/drawings"; patterns = @(".*"); extensions = @("pdf", "dwg"); required = "yes" }
    @{ id = 3; name = "Division specifications"; phase = 0; location = "00-contract/specifications"; patterns = @("spec", "div.*\d+"); extensions = @("pdf"); required = "usually" }
    @{ id = 4; name = "Addenda"; phase = 0; location = "00-contract/addenda"; patterns = @("addend"); extensions = @("pdf"); required = "if_applicable" }
    @{ id = 5; name = "Insurance certificate / COI"; phase = 0; location = "00-contract/insurance"; patterns = @("insurance", "coi", "certificate"); extensions = @("pdf"); required = "usually" }
    @{ id = 6; name = "Initial estimate / bid"; phase = 0; location = "02-financial/budget"; patterns = @("estimate", "bid", "budget", "quote"); extensions = @("pdf", "xlsx", "xls"); required = "yes" }
    @{ id = 7; name = "Project schedule"; phase = 0; location = "01-admin/schedule"; patterns = @("schedule", "timeline", "gantt"); extensions = @("pdf", "xlsx", "xls", "mpp"); required = "usually" }

    # Phase 1 - Design & Pre-Production
    @{ id = 8; name = "Working DWG(s)"; phase = 1; location = "03-cad/working"; patterns = @(".*"); extensions = @("dwg"); required = "yes" }
    @{ id = 9; name = "Material spec sheets"; phase = 1; location = "05-materials"; patterns = @("spec", "sheet", "data"); extensions = @("pdf"); required = "per_scope"; scope = "materials" }
    @{ id = 10; name = "Hardware schedule"; phase = 1; location = "05-materials/hardware"; patterns = @("hardware", "schedule"); extensions = @("pdf", "xlsx"); required = "usually" }
    @{ id = 11; name = "Finish schedule"; phase = 1; location = "05-materials/finish"; patterns = @("finish", "schedule"); extensions = @("pdf", "xlsx"); required = "usually" }
    @{ id = 12; name = "Sample requests & approvals"; phase = 1; location = "06-samples"; patterns = @("sample", "approval"); extensions = @("pdf"); required = "per_scope"; scope = "samples" }
    @{ id = 13; name = "RFIs issued"; phase = 1; location = "01-admin/rfi"; patterns = @("^RFI", "rfi-\d+"); extensions = @("pdf"); required = "if_applicable" }
    @{ id = 14; name = "RFI responses"; phase = 1; location = "01-admin/rfi/_received"; patterns = @(".*"); extensions = @("pdf"); required = "if_applicable"; depends_on = 13 }
    @{ id = 15; name = "Submittal packages"; phase = 1; location = "01-admin/submittal"; patterns = @("^SUB", "submittal"); extensions = @("pdf"); required = "yes" }
    @{ id = 16; name = "Submittal source pieces"; phase = 1; location = "01-admin/submittal/_source"; patterns = @(".*"); extensions = @("pdf", "dwg"); required = "usually" }
    @{ id = 17; name = "Submittal returns (stamped)"; phase = 1; location = "01-admin/submittal/_received"; patterns = @(".*"); extensions = @("pdf"); required = "yes" }
    @{ id = 18; name = "CCNs / PCNs received"; phase = 1; location = "01-admin/ccn/_received"; patterns = @("ccn", "pcn", "change.*notice"); extensions = @("pdf"); required = "if_applicable" }
    @{ id = 19; name = "Change orders"; phase = 1; location = "01-admin/change-order"; patterns = @("^CO", "change.*order"); extensions = @("pdf"); required = "if_applicable" }
    @{ id = 20; name = "CO approvals/rejections"; phase = 1; location = "01-admin/change-order/_received"; patterns = @(".*"); extensions = @("pdf"); required = "if_applicable"; depends_on = 19 }
    @{ id = 21; name = "Vendor quotes (pre-decision)"; phase = 1; location = "08-buyout/quotes"; patterns = @("quote", "proposal"); extensions = @("pdf"); required = "if_applicable"; scope = "buyout" }
    @{ id = 22; name = "Vendor POs"; phase = 1; location = "08-buyout"; patterns = @("^PO", "purchase.*order"); extensions = @("pdf"); required = "if_applicable"; scope = "buyout"; sublocation = "*/po" }
    @{ id = 23; name = "Vendor quotes (awarded)"; phase = 1; location = "08-buyout"; patterns = @("quote"); extensions = @("pdf"); required = "if_applicable"; scope = "buyout"; sublocation = "*/quotes" }
    @{ id = 24; name = "Production material takeoff"; phase = 1; location = "05-materials/takeoff"; patterns = @("takeoff", "material.*list"); extensions = @("pdf", "xlsx"); required = "usually" }

    # Phase 2 - Production
    @{ id = 25; name = "Working cutlist (pre-FO#)"; phase = 2; location = "07-production"; patterns = @("cutlist", "parts"); extensions = @("xlsx", "xls"); required = "transitional" }
    @{ id = 26; name = "FO index"; phase = 2; location = "07-production"; patterns = @("_fo-index"); extensions = @("md"); required = "yes" }
    @{ id = 27; name = "Parts list (.xls)"; phase = 2; location = "07-production"; patterns = @("parts", "cutlist"); extensions = @("xlsx", "xls"); required = "per_scope"; scope = "fo"; sublocation = "*/parts-list" }
    @{ id = 28; name = "Clean CSV"; phase = 2; location = "C:\FO"; patterns = @("_clean|^(?!.*_dirty).*\.csv$"); extensions = @("csv"); required = "per_scope"; scope = "fo"; is_fo_file = $true }
    @{ id = 29; name = "Dirty CSV"; phase = 2; location = "C:\FO"; patterns = @("_dirty"); extensions = @("csv"); required = "per_scope"; scope = "fo"; is_fo_file = $true }
    @{ id = 30; name = "ARDIS project (.R41)"; phase = 2; location = "C:\FO"; patterns = @(".*"); extensions = @("r41"); required = "per_scope"; scope = "fo"; is_fo_file = $true }
    @{ id = 31; name = "Plywood cutlist PDF"; phase = 2; location = "C:\FO"; patterns = @("plywood", "ply"); extensions = @("pdf"); required = "per_scope"; scope = "fo"; is_fo_file = $true }
    @{ id = 32; name = "Solids cutlist PDF"; phase = 2; location = "C:\FO"; patterns = @("solid"); extensions = @("pdf"); required = "per_scope"; scope = "fo"; is_fo_file = $true }
    @{ id = 33; name = "Preglue optimization PDF"; phase = 2; location = "C:\FO"; patterns = @("preglue"); extensions = @("pdf"); required = "if_applicable"; scope = "fo"; is_fo_file = $true }
    @{ id = 34; name = "Panel layout PDF"; phase = 2; location = "C:\FO"; patterns = @("layout"); extensions = @("pdf"); required = "per_scope"; scope = "fo"; is_fo_file = $true }
    @{ id = 35; name = "Production drawings (PDFs)"; phase = 2; location = "04-drawings/production"; patterns = @(".*"); extensions = @("pdf"); required = "yes" }
    @{ id = 36; name = "Buyout drawings (to vendors)"; phase = 2; location = "04-drawings/buyout"; patterns = @(".*"); extensions = @("pdf"); required = "if_applicable"; scope = "buyout" }
    @{ id = 37; name = "Vendor work orders"; phase = 2; location = "08-buyout"; patterns = @("^WO", "work.*order"); extensions = @("pdf"); required = "if_applicable"; scope = "buyout"; sublocation = "*/wo" }
    @{ id = 38; name = "Vendor received docs"; phase = 2; location = "08-buyout"; patterns = @(".*"); extensions = @("pdf"); required = "if_applicable"; scope = "buyout"; sublocation = "*/_received" }

    # Phase 3 - Coordination & Install
    @{ id = 39; name = "Trade coordination drawings"; phase = 3; location = "09-coordination"; patterns = @("coord", "layout"); extensions = @("pdf"); required = "if_applicable" }
    @{ id = 40; name = "Door coordination + transmittal"; phase = 3; location = "09-coordination/doors"; patterns = @("door", "transmittal"); extensions = @("pdf"); required = "if_applicable"; scope = "doors" }
    @{ id = 41; name = "Hardware schedules received"; phase = 3; location = "09-coordination/doors/_received"; patterns = @("hardware", "schedule"); extensions = @("pdf"); required = "if_applicable"; scope = "doors" }
    @{ id = 42; name = "Installation drawings"; phase = 3; location = "04-drawings/install"; patterns = @("install"); extensions = @("pdf"); required = "if_applicable" }
    @{ id = 43; name = "Site measurements"; phase = 3; location = "10-site/measure"; patterns = @("measure", "dim"); extensions = @("pdf", "dwg"); required = "usually" }
    @{ id = 44; name = "Site photos"; phase = 3; location = "10-site/photo"; patterns = @(".*"); extensions = @("jpg", "jpeg", "png", "heic"); required = "usually" }
    @{ id = 45; name = "Site instructions"; phase = 3; location = "01-admin/site-instruction"; patterns = @("^SI", "site.*inst"); extensions = @("pdf"); required = "if_applicable" }
    @{ id = 46; name = "Field notices"; phase = 3; location = "01-admin/field-notice"; patterns = @("field", "notice"); extensions = @("pdf"); required = "if_applicable" }
    @{ id = 47; name = "Shipping/delivery docs"; phase = 3; location = "01-admin/shipping"; patterns = @("ship", "delivery", "bol"); extensions = @("pdf"); required = "usually" }
    @{ id = 48; name = "Meeting minutes"; phase = 3; location = "01-admin/meeting-minutes"; patterns = @("minute", "meeting"); extensions = @("pdf"); required = "usually" }

    # Phase 4 - QC & AWMAC
    @{ id = 49; name = "GIS submission"; phase = 4; location = "11-awmac/submissions"; patterns = @("^GIS", "gis"); extensions = @("pdf"); required = "if_applicable"; scope = "awmac" }
    @{ id = 50; name = "GIS source pieces"; phase = 4; location = "11-awmac/_source"; patterns = @(".*"); extensions = @("pdf", "dwg"); required = "if_applicable"; scope = "awmac" }
    @{ id = 51; name = "Initial inspection request"; phase = 4; location = "11-awmac/submissions"; patterns = @("insi", "initial.*insp"); extensions = @("pdf"); required = "if_applicable"; scope = "awmac" }
    @{ id = 52; name = "GIS report / inspection results"; phase = 4; location = "11-awmac/_received"; patterns = @("report", "result", "inspection"); extensions = @("pdf"); required = "if_applicable"; scope = "awmac" }
    @{ id = 53; name = "Humidity report"; phase = 4; location = "11-awmac/submissions"; patterns = @("humid", "moisture"); extensions = @("pdf"); required = "if_applicable"; scope = "awmac" }
    @{ id = 54; name = "Final inspection request"; phase = 4; location = "11-awmac/submissions"; patterns = @("insf", "final.*insp"); extensions = @("pdf"); required = "if_applicable"; scope = "awmac" }
    @{ id = 55; name = "Internal QC checklists"; phase = 4; location = "11-awmac/qc"; patterns = @("qc", "checklist", "quality"); extensions = @("pdf", "xlsx"); required = "if_applicable"; scope = "awmac" }
    @{ id = 56; name = "AWMAC MSE certificate"; phase = 4; location = "01-admin/certs"; patterns = @("awmac", "mse", "certificate"); extensions = @("pdf"); required = "if_applicable"; scope = "awmac" }

    # Phase 5 - Closeout
    @{ id = 57; name = "Deficiency / punchlist"; phase = 5; location = "01-admin/deficiencies"; patterns = @("deficien", "punch"); extensions = @("pdf", "xlsx"); required = "usually" }
    @{ id = 58; name = "As-built DWGs"; phase = 5; location = "03-cad/as-built"; patterns = @(".*"); extensions = @("dwg"); required = "usually" }
    @{ id = 59; name = "As-built PDFs (issued)"; phase = 5; location = "04-drawings/as-built"; patterns = @(".*"); extensions = @("pdf"); required = "usually" }
    @{ id = 60; name = "Approved drawings (stamped)"; phase = 5; location = "04-drawings/approved"; patterns = @(".*"); extensions = @("pdf"); required = "usually" }
    @{ id = 61; name = "Close-out package"; phase = 5; location = "01-admin/close-out"; patterns = @("close", "final"); extensions = @("pdf"); required = "yes" }
    @{ id = 62; name = "Warranty documents"; phase = 5; location = "01-admin/close-out"; patterns = @("warrant"); extensions = @("pdf"); required = "usually" }
    @{ id = 63; name = "Final invoicing"; phase = 5; location = "02-financial/invoices"; patterns = @("invoice", "inv-"); extensions = @("pdf"); required = "yes" }
    @{ id = 64; name = "Progress claims"; phase = 5; location = "02-financial/progress-claims"; patterns = @("claim", "progress"); extensions = @("pdf"); required = "usually" }
    @{ id = 65; name = "Revision snapshots"; phase = 5; location = "04-drawings/revision"; patterns = @(".*"); extensions = @("pdf"); required = "per_scope" }

    # Throughout
    @{ id = 66; name = "Correspondence / email disputes"; phase = -1; location = "01-admin/email-disputes"; patterns = @(".*"); extensions = @("pdf", "msg"); required = "if_applicable" }
    @{ id = 67; name = "Vendor correspondence"; phase = -1; location = "08-buyout"; patterns = @("email", "correspond"); extensions = @("pdf", "msg"); required = "if_applicable"; scope = "buyout"; sublocation = "*/correspondence" }
    @{ id = 68; name = "PO log / register"; phase = -1; location = "02-financial/po-log"; patterns = @("po.*log", "register"); extensions = @("xlsx", "xls"); required = "usually" }
)

# Known folder names (to detect anti-patterns)
$knownFolders = @(
    "00-contract", "01-admin", "02-financial", "03-cad", "04-drawings",
    "05-materials", "06-samples", "07-production", "08-buyout", "09-coordination",
    "10-site", "11-awmac", "_archive", "_cambium", "Shops", "shops"
)

# Anti-pattern folder names
$antiPatternFolders = @("PDFs", "MISC", "OTHER", "misc", "other", "pdfs", "Pdfs", "PDF", "Old", "old", "OLD", "Backup", "backup", "BACKUP", "temp", "Temp", "TEMP", "tmp", "Tmp", "TMP")

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

function Get-ProjectNamingFormat {
    param([string]$Name)

    if ($Name -match "^\d{4}-") {
        return "standard"  # YYMM-name format
    } elseif ($Name -match "^\d{2}-") {
        return "short"     # YY-name format
    } elseif ($Name -match "^\d+") {
        return "numeric"   # Starts with number
    } else {
        return "legacy"    # No number prefix
    }
}

function Get-JobNumber {
    param([string]$Name)

    if ($Name -match "^(\d+)-") {
        return $matches[1]
    }
    return $null
}

function Test-FolderHasFiles {
    param([string]$Path)

    if (-not (Test-Path $Path)) { return $false }
    $files = Get-ChildItem -Path $Path -File -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
    return $null -ne $files
}

function Test-FolderExists {
    param([string]$Path)
    return Test-Path $Path -PathType Container
}

function Get-ProjectScope {
    param([string]$ProjectPath)

    $scope = @{
        awmac = $false
        buyout = $false
        doors = $false
        fo = $false
        materials = $false
        samples = $false
    }

    # Check AWMAC scope
    $awmacPath = Join-Path $ProjectPath "11-awmac"
    if (Test-Path $awmacPath) {
        $awmacFiles = Get-ChildItem -Path $awmacPath -File -Recurse -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -notmatch "^_README" -and $_.Name -notmatch "^_template" }
        $scope.awmac = ($awmacFiles | Measure-Object).Count -gt 0
    }

    # Check buyout scope (has vendor subfolders)
    $buyoutPath = Join-Path $ProjectPath "08-buyout"
    if (Test-Path $buyoutPath) {
        $vendorFolders = Get-ChildItem -Path $buyoutPath -Directory -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -ne "quotes" }
        $scope.buyout = ($vendorFolders | Measure-Object).Count -gt 0
    }

    # Check doors scope
    $doorsPath = Join-Path $ProjectPath "09-coordination/doors"
    if (Test-Path $doorsPath) {
        $scope.doors = Test-FolderHasFiles $doorsPath
    }

    # Check FO scope (has FO references)
    $foIndexPath = Join-Path $ProjectPath "07-production/_fo-index.md"
    if (Test-Path $foIndexPath) {
        $content = Get-Content $foIndexPath -Raw -ErrorAction SilentlyContinue
        if ($content -match "\d{5}") {
            $scope.fo = $true
        }
    }

    # Check materials scope
    $materialsPath = Join-Path $ProjectPath "05-materials"
    $scope.materials = Test-FolderHasFiles $materialsPath

    # Check samples scope
    $samplesPath = Join-Path $ProjectPath "06-samples"
    $scope.samples = Test-FolderHasFiles $samplesPath

    return $scope
}

function Find-LinkedFOs {
    param([string]$ProjectPath, [string]$FORoot)

    $linkedFOs = @()

    # Check _fo-index.md
    $foIndexPath = Join-Path $ProjectPath "07-production/_fo-index.md"
    if (Test-Path $foIndexPath) {
        $content = Get-Content $foIndexPath -Raw -ErrorAction SilentlyContinue
        $foMatches = [regex]::Matches($content, "\b(\d{5})\b")
        foreach ($match in $foMatches) {
            $foNum = $match.Groups[1].Value
            if ($foNum -notin $linkedFOs) {
                $linkedFOs += $foNum
            }
        }
    }

    # Scan filenames for FO references
    $allFiles = Get-ChildItem -Path $ProjectPath -File -Recurse -ErrorAction SilentlyContinue
    foreach ($file in $allFiles) {
        $foMatches = [regex]::Matches($file.Name, "FO[_-]?(\d{5})")
        foreach ($match in $foMatches) {
            $foNum = $match.Groups[1].Value
            if ($foNum -notin $linkedFOs) {
                $linkedFOs += $foNum
            }
        }
    }

    return $linkedFOs
}

function Test-SkeletonItem {
    param(
        [hashtable]$Item,
        [string]$ProjectPath,
        [hashtable]$ProjectScope
    )

    # Skip FO-specific items (handled separately)
    if ($Item.is_fo_file) {
        return @{ status = "fo_item"; found_at = $null }
    }

    # Check scope applicability
    if ($Item.scope) {
        $scopeKey = $Item.scope
        if (-not $ProjectScope[$scopeKey]) {
            return @{ status = "not_applicable"; found_at = $null; reason = "no_$scopeKey`_scope" }
        }
    }

    # Build search path
    $searchPath = Join-Path $ProjectPath $Item.location

    # Handle sublocation patterns (e.g., "*/po" for vendor folders)
    if ($Item.sublocation) {
        $parentPath = Join-Path $ProjectPath $Item.location
        if (Test-Path $parentPath) {
            $subDirs = Get-ChildItem -Path $parentPath -Directory -ErrorAction SilentlyContinue
            foreach ($subDir in $subDirs) {
                $subPath = Join-Path $subDir.FullName ($Item.sublocation -replace "\*/", "")
                if (Test-Path $subPath) {
                    $searchPath = $subPath
                    break
                }
            }
        }
    }

    if (-not (Test-Path $searchPath)) {
        # Folder doesn't exist
        if ($Item.required -eq "if_applicable" -or $Item.required -eq "per_scope") {
            return @{ status = "not_applicable"; found_at = $null; reason = "folder_not_exists" }
        }
        return @{ status = "missing"; found_at = $null; expected_at = $Item.location }
    }

    # Search for matching files
    $files = Get-ChildItem -Path $searchPath -File -Recurse -ErrorAction SilentlyContinue

    foreach ($file in $files) {
        $ext = $file.Extension.TrimStart('.').ToLower()
        if ($ext -notin $Item.extensions) { continue }

        $nameMatch = $false
        foreach ($pattern in $Item.patterns) {
            if ($file.BaseName -match $pattern) {
                $nameMatch = $true
                break
            }
        }

        if ($nameMatch -or $Item.patterns -contains ".*") {
            $relativePath = $file.FullName.Replace($ProjectPath, "").TrimStart("\")
            return @{ status = "found"; found_at = $relativePath }
        }
    }

    # No matching file found
    if ($Item.required -eq "if_applicable") {
        return @{ status = "uncertain"; found_at = $null; expected_at = $Item.location }
    }

    return @{ status = "missing"; found_at = $null; expected_at = $Item.location }
}

function Get-AntiPatterns {
    param([string]$ProjectPath, [string]$ProjectName)

    $patterns = @{
        files_in_root = @()
        wrong_folder = @()
        status_in_filename = @()
        spaces_in_folder = @()
        person_folders = @()
        misc_folders = @()
        cnc_in_project = @()
        non_standard_folders = @()
    }

    # Files in root
    $rootFiles = Get-ChildItem -Path $ProjectPath -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -ne "_README.txt" }
    foreach ($f in $rootFiles) {
        $patterns.files_in_root += $f.Name
    }

    # Check all folders
    $allFolders = Get-ChildItem -Path $ProjectPath -Directory -Recurse -ErrorAction SilentlyContinue
    foreach ($folder in $allFolders) {
        $name = $folder.Name
        $relativePath = $folder.FullName.Replace($ProjectPath, "").TrimStart("\")

        # Spaces in folder names
        if ($name -match " ") {
            $patterns.spaces_in_folder += $relativePath
        }

        # Anti-pattern folder names
        if ($name -in $antiPatternFolders) {
            $patterns.misc_folders += $relativePath
        }

        # Person-named folders (single word, capitalized, only at project root level, not known)
        # Use -cmatch for case-sensitive matching
        if ($relativePath -notmatch "\\" -and $name -cmatch "^[A-Z][a-z]+$" -and $name -notin $knownFolders -and $name.Length -gt 3) {
            # Could be a person's name or misplaced folder at root level
            $patterns.person_folders += $relativePath
        }

        # Non-standard top-level folders
        if ($relativePath -notmatch "\\" -and $name -notmatch "^\d{2}-" -and $name -notin @("_archive", "_cambium")) {
            $patterns.non_standard_folders += $name
        }
    }

    # Status in filenames
    $allFiles = Get-ChildItem -Path $ProjectPath -File -Recurse -ErrorAction SilentlyContinue
    foreach ($f in $allFiles) {
        if ($f.Name -match "(APPROVED|PENDING|REJECTED|FINAL|DRAFT|APPROVED|REV\d+)") {
            # Only flag if it looks like embedded status, not legitimate naming
            if ($f.Name -match "[-_](APPROVED|PENDING|REJECTED)[-_\.]") {
                $relativePath = $f.FullName.Replace($ProjectPath, "").TrimStart("\")
                $patterns.status_in_filename += $relativePath
            }
        }

        # CNC files in project folder
        if ($f.Extension -in @(".R41", ".r41", ".csv") -and $f.DirectoryName -notmatch "\\FO\\") {
            $relativePath = $f.FullName.Replace($ProjectPath, "").TrimStart("\")
            $patterns.cnc_in_project += $relativePath
        }
    }

    return $patterns
}

function Test-FOFolder {
    param([string]$FOPath, [string]$FONumber)

    $result = @{
        fo_number = $FONumber
        path = $FOPath
        has_r41 = $false
        has_xls = $false
        has_csv = $false
        has_dirty_csv = $false
        has_plywoods_pdf = $false
        has_solids_pdf = $false
        has_preglue_pdf = $false
        has_layouts_pdf = $false
        has_shops_subfolder = $false
        extra_files = @()
        naming_compliant = $true
    }

    $files = Get-ChildItem -Path $FOPath -File -ErrorAction SilentlyContinue
    $dirs = Get-ChildItem -Path $FOPath -Directory -ErrorAction SilentlyContinue

    foreach ($file in $files) {
        $ext = $file.Extension.ToLower()
        $name = $file.Name.ToLower()

        switch ($ext) {
            ".r41" { $result.has_r41 = $true }
            ".xls" { $result.has_xls = $true }
            ".xlsx" { $result.has_xls = $true }
            ".csv" {
                $result.has_csv = $true
                if ($name -match "_dirty") {
                    $result.has_dirty_csv = $true
                }
            }
            ".pdf" {
                if ($name -match "plywood|ply") { $result.has_plywoods_pdf = $true }
                if ($name -match "solid") { $result.has_solids_pdf = $true }
                if ($name -match "preglue") { $result.has_preglue_pdf = $true }
                if ($name -match "layout") { $result.has_layouts_pdf = $true }
            }
        }

        # Check for unexpected files
        if ($ext -notin @(".r41", ".xls", ".xlsx", ".csv", ".pdf", ".edg", ".mch")) {
            $result.extra_files += $file.Name
        }
    }

    foreach ($dir in $dirs) {
        if ($dir.Name -match "^shops?$") {
            $result.has_shops_subfolder = $true
        }
    }

    return $result
}

# ============================================================================
# MAIN AUDIT LOGIC
# ============================================================================

function Invoke-ProjectAudit {
    param([string]$ProjectPath, [string]$FORoot)

    $projectName = Split-Path $ProjectPath -Leaf
    Write-Host "  Auditing: $projectName" -ForegroundColor White

    $result = @{
        path = $ProjectPath
        job_number = Get-JobNumber $projectName
        job_name = $projectName -replace "^\d+-", ""
        naming_format = Get-ProjectNamingFormat $projectName
        has_numbered_folders = $false
        folder_structure_match = "none"
        linked_fos = @()
        skeleton_audit = @{}
        anti_patterns = @{}
        file_count = 0
        total_size_mb = 0
    }

    # Check numbered folders
    $numberedFolders = Get-ChildItem -Path $ProjectPath -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -match "^\d{2}-" }
    $result.has_numbered_folders = ($numberedFolders | Measure-Object).Count -gt 0

    # Determine folder structure match
    $expectedFolders = @("00-contract", "01-admin", "02-financial", "03-cad", "04-drawings",
                         "05-materials", "06-samples", "07-production", "08-buyout",
                         "09-coordination", "10-site", "11-awmac")
    $foundCount = 0
    foreach ($folder in $expectedFolders) {
        if (Test-Path (Join-Path $ProjectPath $folder)) {
            $foundCount++
        }
    }

    if ($foundCount -eq $expectedFolders.Count) {
        $result.folder_structure_match = "full"
    } elseif ($foundCount -gt 6) {
        $result.folder_structure_match = "partial"
    } elseif ($foundCount -gt 0) {
        $result.folder_structure_match = "minimal"
    } else {
        $result.folder_structure_match = "none"
    }

    # Get project scope
    $scope = Get-ProjectScope $ProjectPath

    # Find linked FOs
    $result.linked_fos = Find-LinkedFOs $ProjectPath $FORoot

    # Audit skeleton items by phase
    $phaseResults = @{}
    foreach ($phase in @(0, 1, 2, 3, 4, 5, -1)) {
        $phaseItems = $skeleton | Where-Object { $_.phase -eq $phase }

        $phaseData = @{
            expected = ($phaseItems | Measure-Object).Count
            found = 0
            missing = @()
            documents = @()
        }

        foreach ($item in $phaseItems) {
            $itemResult = Test-SkeletonItem -Item $item -ProjectPath $ProjectPath -ProjectScope $scope

            $docEntry = @{
                skeleton_id = $item.id
                name = $item.name
                status = $itemResult.status
                found_at = $itemResult.found_at
                expected_at = $item.location
            }

            $phaseData.documents += $docEntry

            if ($itemResult.status -eq "found") {
                $phaseData.found++
            } elseif ($itemResult.status -eq "missing") {
                $phaseData.missing += $item.name
            }
        }

        $phaseKey = "phase_" + $(if ($phase -eq -1) { "throughout" } else { $phase.ToString() })
        $phaseResults[$phaseKey] = $phaseData
    }

    $result.skeleton_audit = $phaseResults

    # Get anti-patterns
    $result.anti_patterns = Get-AntiPatterns $ProjectPath $projectName

    # File stats
    $allFiles = Get-ChildItem -Path $ProjectPath -File -Recurse -ErrorAction SilentlyContinue
    $result.file_count = ($allFiles | Measure-Object).Count
    $result.total_size_mb = [math]::Round(($allFiles | Measure-Object -Property Length -Sum).Sum / 1MB, 2)

    return $result
}

# ============================================================================
# OUTPUT GENERATION
# ============================================================================

function Export-AuditJSON {
    param(
        [array]$ProjectResults,
        [array]$FOResults,
        [array]$OrphanedFOs,
        [string]$OutputPath
    )

    $summary = @{
        total_projects = $ProjectResults.Count
        total_fo_folders = $FOResults.Count
        orphaned_fos = $OrphanedFOs.Count
        projects_using_legacy_naming = ($ProjectResults | Where-Object { $_.naming_format -eq "legacy" }).Count
        projects_using_standard_naming = ($ProjectResults | Where-Object { $_.naming_format -eq "standard" }).Count
        projects_full_structure = ($ProjectResults | Where-Object { $_.folder_structure_match -eq "full" }).Count
        projects_partial_structure = ($ProjectResults | Where-Object { $_.folder_structure_match -eq "partial" }).Count
    }

    # Collect global anti-patterns
    $globalAntiPatterns = @{
        spaces_in_folder_names = @()
        status_in_filenames = @()
        person_named_folders = @()
        misc_other_folders = @()
        cnc_files_in_projects = @()
    }

    foreach ($project in $ProjectResults) {
        $pName = Split-Path $project.path -Leaf
        foreach ($item in $project.anti_patterns.spaces_in_folder) {
            $globalAntiPatterns.spaces_in_folder_names += "$pName\$item"
        }
        foreach ($item in $project.anti_patterns.status_in_filename) {
            $globalAntiPatterns.status_in_filenames += "$pName\$item"
        }
        foreach ($item in $project.anti_patterns.person_folders) {
            $globalAntiPatterns.person_named_folders += "$pName\$item"
        }
        foreach ($item in $project.anti_patterns.misc_folders) {
            $globalAntiPatterns.misc_other_folders += "$pName\$item"
        }
        foreach ($item in $project.anti_patterns.cnc_in_project) {
            $globalAntiPatterns.cnc_files_in_projects += "$pName\$item"
        }
    }

    $output = @{
        audit_date = $auditDate
        skeleton_version = "v1.0"
        doc_standards_version = "v5.5.5"
        summary = $summary
        projects = $ProjectResults
        factory_orders = $FOResults
        orphaned_fos = $OrphanedFOs
        global_anti_patterns = $globalAntiPatterns
    }

    $jsonPath = Join-Path $OutputPath "audit-$timestamp.json"
    $output | ConvertTo-Json -Depth 10 | Set-Content $jsonPath -Encoding UTF8

    return $jsonPath
}

function Export-AuditMarkdown {
    param(
        [array]$ProjectResults,
        [array]$FOResults,
        [array]$OrphanedFOs,
        [string]$OutputPath
    )

    $md = @()
    $md += "# Document Skeleton Audit Report"
    $md += ""
    $md += "**Date:** $auditDate"
    $md += "**Skeleton Version:** v1.0"
    $md += "**Doc Standards:** v5.5.5"
    $md += ""

    # Executive Summary
    $md += "## Executive Summary"
    $md += ""
    $md += "| Metric | Count |"
    $md += "|--------|-------|"
    $md += "| Total Projects | $($ProjectResults.Count) |"
    $md += "| Total FO Folders | $($FOResults.Count) |"
    $md += "| Orphaned FOs | $($OrphanedFOs.Count) |"
    $md += "| Standard Naming (YYMM-name) | $(($ProjectResults | Where-Object { $_.naming_format -eq 'standard' }).Count) |"
    $md += "| Legacy Naming | $(($ProjectResults | Where-Object { $_.naming_format -eq 'legacy' }).Count) |"
    $md += "| Full Folder Structure | $(($ProjectResults | Where-Object { $_.folder_structure_match -eq 'full' }).Count) |"
    $md += ""

    # Calculate overall health score
    $totalExpected = 0
    $totalFound = 0
    foreach ($project in $ProjectResults) {
        foreach ($phase in $project.skeleton_audit.Keys) {
            $totalExpected += $project.skeleton_audit[$phase].expected
            $totalFound += $project.skeleton_audit[$phase].found
        }
    }
    $healthScore = if ($totalExpected -gt 0) { [math]::Round(($totalFound / $totalExpected) * 100, 1) } else { 0 }
    $md += "**Overall Health Score:** $healthScore% ($totalFound / $totalExpected skeleton items found)"
    $md += ""

    # Per-Project Scorecards
    $md += "## Per-Project Scorecards"
    $md += ""

    foreach ($project in $ProjectResults | Sort-Object { $_.path }) {
        $projectName = Split-Path $project.path -Leaf
        $projectFound = 0
        $projectExpected = 0
        $projectMissing = @()

        foreach ($phase in $project.skeleton_audit.Keys) {
            $projectExpected += $project.skeleton_audit[$phase].expected
            $projectFound += $project.skeleton_audit[$phase].found
            $projectMissing += $project.skeleton_audit[$phase].missing
        }

        $projectScore = if ($projectExpected -gt 0) { [math]::Round(($projectFound / $projectExpected) * 100, 1) } else { 0 }
        $antiPatternCount = $project.anti_patterns.files_in_root.Count +
                           $project.anti_patterns.status_in_filename.Count +
                           $project.anti_patterns.misc_folders.Count +
                           $project.anti_patterns.cnc_in_project.Count

        $md += "### $projectName"
        $md += ""
        $md += "- **Score:** $projectScore% ($projectFound / $projectExpected)"
        $md += "- **Structure:** $($project.folder_structure_match)"
        $md += "- **Naming:** $($project.naming_format)"
        $md += "- **Files:** $($project.file_count) ($($project.total_size_mb) MB)"
        $md += "- **Anti-patterns:** $antiPatternCount"

        if ($project.linked_fos.Count -gt 0) {
            $md += "- **Linked FOs:** $($project.linked_fos -join ', ')"
        }

        if ($project.anti_patterns.files_in_root.Count -gt 0) {
            $md += "- **Inbox files:** $($project.anti_patterns.files_in_root.Count) files in project root"
        }

        if ($projectMissing.Count -gt 0 -and $projectMissing.Count -le 5) {
            $md += "- **Missing (critical):** $($projectMissing -join ', ')"
        } elseif ($projectMissing.Count -gt 5) {
            $md += "- **Missing:** $($projectMissing.Count) items"
        }

        $md += ""
    }

    # Orphaned FOs
    if ($OrphanedFOs.Count -gt 0) {
        $md += "## Orphaned FOs"
        $md += ""
        $md += "The following FO folders cannot be linked to any project:"
        $md += ""
        foreach ($fo in $OrphanedFOs) {
            $md += "- $fo"
        }
        $md += ""
    }

    # Top Anti-Patterns
    $md += "## Top Anti-Patterns"
    $md += ""

    $allAntiPatterns = @()
    foreach ($project in $ProjectResults) {
        $pName = Split-Path $project.path -Leaf
        if ($project.anti_patterns.files_in_root.Count -gt 0) {
            $allAntiPatterns += @{ type = "files_in_root"; project = $pName; count = $project.anti_patterns.files_in_root.Count }
        }
        if ($project.anti_patterns.status_in_filename.Count -gt 0) {
            $allAntiPatterns += @{ type = "status_in_filename"; project = $pName; count = $project.anti_patterns.status_in_filename.Count }
        }
        if ($project.anti_patterns.misc_folders.Count -gt 0) {
            $allAntiPatterns += @{ type = "misc_folders"; project = $pName; count = $project.anti_patterns.misc_folders.Count }
        }
        if ($project.anti_patterns.spaces_in_folder.Count -gt 0) {
            $allAntiPatterns += @{ type = "spaces_in_folder"; project = $pName; count = $project.anti_patterns.spaces_in_folder.Count }
        }
        if ($project.anti_patterns.cnc_in_project.Count -gt 0) {
            $allAntiPatterns += @{ type = "cnc_in_project"; project = $pName; count = $project.anti_patterns.cnc_in_project.Count }
        }
    }

    $sortedPatterns = $allAntiPatterns | Sort-Object { $_.count } -Descending | Select-Object -First 10

    if ($sortedPatterns.Count -gt 0) {
        $md += "| Rank | Project | Issue | Count |"
        $md += "|------|---------|-------|-------|"
        $rank = 1
        foreach ($pattern in $sortedPatterns) {
            $md += "| $rank | $($pattern.project) | $($pattern.type) | $($pattern.count) |"
            $rank++
        }
        $md += ""
    } else {
        $md += "No significant anti-patterns detected."
        $md += ""
    }

    # Projects Ranked by Completeness
    $md += "## Projects Ranked by Completeness"
    $md += ""

    $rankedProjects = @()
    foreach ($project in $ProjectResults) {
        $projectFound = 0
        $projectExpected = 0
        foreach ($phase in $project.skeleton_audit.Keys) {
            $projectExpected += $project.skeleton_audit[$phase].expected
            $projectFound += $project.skeleton_audit[$phase].found
        }
        $score = if ($projectExpected -gt 0) { [math]::Round(($projectFound / $projectExpected) * 100, 1) } else { 0 }
        $rankedProjects += @{ name = (Split-Path $project.path -Leaf); score = $score; found = $projectFound; expected = $projectExpected }
    }

    $rankedProjects = $rankedProjects | Sort-Object { $_.score } -Descending

    $md += "| Rank | Project | Score | Found/Expected |"
    $md += "|------|---------|-------|----------------|"
    $rank = 1
    foreach ($p in $rankedProjects) {
        $md += "| $rank | $($p.name) | $($p.score)% | $($p.found)/$($p.expected) |"
        $rank++
    }
    $md += ""

    $mdPath = Join-Path $OutputPath "audit-$timestamp.md"
    $md -join "`n" | Set-Content $mdPath -Encoding UTF8

    return $mdPath
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

Write-Host ""
Write-Host "=== Document Skeleton Audit ===" -ForegroundColor Cyan
Write-Host "Date: $auditDate" -ForegroundColor Gray
Write-Host ""

# Ensure output directory exists
if (-not (Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Force -Path $OutputPath | Out-Null
}

# Get projects
$allProjects = Get-ChildItem -Path $ProjectsRoot -Directory |
    Where-Object { $_.Name -notmatch "^_" } |
    Sort-Object LastWriteTime -Descending

if ($TestRun -or $TestProject) {
    if ($TestProject) {
        $allProjects = $allProjects | Where-Object { $_.Name -eq $TestProject }
    } else {
        # Pick a mid-size project for test run (skip first 5 most recent, take next one)
        $allProjects = $allProjects | Select-Object -Skip 5 -First 1
    }
    Write-Host "TEST RUN: Auditing $($allProjects.Count) project(s)" -ForegroundColor Yellow
} elseif ($SampleSize -gt 0) {
    $allProjects = $allProjects | Select-Object -First $SampleSize
    Write-Host "SAMPLE: Auditing $SampleSize most recent projects" -ForegroundColor Yellow
}

Write-Host "Projects to audit: $($allProjects.Count)" -ForegroundColor White
Write-Host ""

# Get FO folders
$foFolders = Get-ChildItem -Path $FORoot -Directory -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -match "^\d+$" }

Write-Host "FO folders found: $($foFolders.Count)" -ForegroundColor White
Write-Host ""

# Audit projects
$projectResults = @()
foreach ($project in $allProjects) {
    $result = Invoke-ProjectAudit -ProjectPath $project.FullName -FORoot $FORoot
    $projectResults += $result
}

# Audit FO folders
$foResults = @()
$allLinkedFOs = @()
foreach ($project in $projectResults) {
    $allLinkedFOs += $project.linked_fos
}

foreach ($fo in $foFolders) {
    $foResult = Test-FOFolder -FOPath $fo.FullName -FONumber $fo.Name

    # Try to find linked project
    if ($fo.Name -in $allLinkedFOs) {
        $linkedProject = $projectResults | Where-Object { $_.linked_fos -contains $fo.Name } | Select-Object -First 1
        $foResult.linked_project = if ($linkedProject) { Split-Path $linkedProject.path -Leaf } else { "unknown" }
    } else {
        $foResult.linked_project = "unknown"
    }

    $foResults += $foResult
}

# Find orphaned FOs
$orphanedFOs = @()
foreach ($fo in $foFolders) {
    if ($fo.Name -notin $allLinkedFOs) {
        $orphanedFOs += $fo.Name
    }
}

# Generate outputs
Write-Host ""
Write-Host "Generating reports..." -ForegroundColor Cyan

$jsonPath = Export-AuditJSON -ProjectResults $projectResults -FOResults $foResults -OrphanedFOs $orphanedFOs -OutputPath $OutputPath
Write-Host "  JSON: $jsonPath" -ForegroundColor Green

$mdPath = Export-AuditMarkdown -ProjectResults $projectResults -FOResults $foResults -OrphanedFOs $orphanedFOs -OutputPath $OutputPath
Write-Host "  Markdown: $mdPath" -ForegroundColor Green

Write-Host ""
Write-Host "=== Audit Complete ===" -ForegroundColor Cyan
Write-Host ""
