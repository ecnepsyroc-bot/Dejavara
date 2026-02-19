---
name: autocad-plugin-development
description: "AutoCAD .NET plugin development using C# for custom commands, block manipulation, and automation. Use when building AutoCAD extensions, creating custom commands, manipulating drawings programmatically, working with blocks/attributes, or integrating AutoCAD with external systems. Triggers include AutoCAD API, ObjectARX, transactions, block references, attribute manipulation, palette development, or drawing automation."
---

# AutoCAD Plugin Development

C# patterns for AutoCAD .NET API plugin development, based on Luxify (Feature Millwork's production plugin).

## Project Setup

### Target Framework

**AutoCAD 2022-2025 uses .NET Framework 4.8** (not .NET Core/.NET 8):

```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net48</TargetFramework>
    <PlatformTarget>x64</PlatformTarget>
    <UseWPF>true</UseWPF>
    <LangVersion>latest</LangVersion>
    <Nullable>enable</Nullable>
    <OutputPath>..\build_test\</OutputPath>
    <AppendTargetFrameworkToOutputPath>false</AppendTargetFrameworkToOutputPath>
  </PropertyGroup>

  <ItemGroup>
    <!-- AutoCAD 2022 SDK References -->
    <Reference Include="AcCoreMgd">
      <HintPath>C:\Program Files\Autodesk\AutoCAD 2022\AcCoreMgd.dll</HintPath>
      <Private>false</Private>
    </Reference>
    <Reference Include="AcDbMgd">
      <HintPath>C:\Program Files\Autodesk\AutoCAD 2022\AcDbMgd.dll</HintPath>
      <Private>false</Private>
    </Reference>
    <Reference Include="AcMgd">
      <HintPath>C:\Program Files\Autodesk\AutoCAD 2022\AcMgd.dll</HintPath>
      <Private>false</Private>
    </Reference>
    <Reference Include="AcCui">
      <HintPath>C:\Program Files\Autodesk\AutoCAD 2022\AcCui.dll</HintPath>
      <Private>false</Private>
    </Reference>
    <Reference Include="AdWindows">
      <HintPath>C:\Program Files\Autodesk\AutoCAD 2022\AdWindows.dll</HintPath>
      <Private>false</Private>
    </Reference>
  </ItemGroup>

  <ItemGroup>
    <PackageReference Include="System.Text.Json" Version="8.0.5" />
    <PackageReference Include="Newtonsoft.Json" Version="13.0.3" />
  </ItemGroup>
</Project>
```

**Critical:** Set `Private=false` for AutoCAD DLLs — they're provided by AutoCAD at runtime.

## Plugin Initialization (IExtensionApplication)

```csharp
using Autodesk.AutoCAD.ApplicationServices;
using Autodesk.AutoCAD.Runtime;
using System.IO;
using System.Reflection;

[assembly: ExtensionApplication(typeof(MyPlugin.PluginInitializer))]
[assembly: CommandClass(typeof(MyPlugin.Commands))]

namespace MyPlugin
{
    public class PluginInitializer : IExtensionApplication
    {
        private static bool _resolverRegistered = false;

        public void Initialize()
        {
            // 1. Register assembly resolver FIRST (for multi-DLL plugins)
            RegisterAssemblyResolver();

            // 2. Subscribe to events
            Application.DocumentManager.DocumentActivated += OnDocumentActivated;
            Application.Idle += OnFirstIdle;
        }

        private static void RegisterAssemblyResolver()
        {
            if (_resolverRegistered) return;
            _resolverRegistered = true;

            AppDomain.CurrentDomain.AssemblyResolve += (sender, args) =>
            {
                var assemblyName = new AssemblyName(args.Name);
                if (!assemblyName.Name.StartsWith("MyPlugin")) return null;

                var thisAssemblyPath = Assembly.GetExecutingAssembly().Location;
                var assemblyFolder = Path.GetDirectoryName(thisAssemblyPath);
                var assemblyPath = Path.Combine(assemblyFolder, assemblyName.Name + ".dll");

                return File.Exists(assemblyPath)
                    ? Assembly.LoadFrom(assemblyPath)
                    : null;
            };
        }

        private void OnDocumentActivated(object sender, DocumentCollectionEventArgs e)
        {
            // Handle document switch
        }

        private void OnFirstIdle(object sender, EventArgs e)
        {
            Application.Idle -= OnFirstIdle;
            // Show palette on first idle
        }

        public void Terminate()
        {
            Application.DocumentManager.DocumentActivated -= OnDocumentActivated;
        }
    }
}
```

## Command Registration

Commands are registered via assembly-level attributes:

```csharp
using Autodesk.AutoCAD.ApplicationServices;
using Autodesk.AutoCAD.DatabaseServices;
using Autodesk.AutoCAD.EditorInput;
using Autodesk.AutoCAD.Runtime;

// Register command class at assembly level
[assembly: CommandClass(typeof(MyPlugin.Commands))]

namespace MyPlugin
{
    public class Commands
    {
        [CommandMethod("MY_COMMAND")]
        public void MyCommand()
        {
            Document doc = Application.DocumentManager.MdiActiveDocument;
            Database db = doc.Database;
            Editor ed = doc.Editor;

            using (Transaction tr = db.TransactionManager.StartTransaction())
            {
                try
                {
                    // Command logic here
                    tr.Commit();
                }
                catch (System.Exception ex)
                {
                    ed.WriteMessage($"\nError: {ex.Message}");
                    tr.Abort();
                }
            }
        }

        [CommandMethod("MY_MODAL_COMMAND", CommandFlags.Modal)]
        public void MyModalCommand()
        {
            // Modal commands block other operations
        }
    }
}
```

**Command Naming Convention:** Use prefix for all commands (e.g., `LUX_`, `MY_`) to avoid conflicts.

## Transaction Pattern (Critical)

**ALWAYS use transactions for database operations:**

```csharp
using (Transaction tr = db.TransactionManager.StartTransaction())
{
    // Open objects for read
    BlockTable bt = (BlockTable)tr.GetObject(db.BlockTableId, OpenMode.ForRead);

    // Open objects for write (upgrade from read if needed)
    BlockTableRecord modelSpace = (BlockTableRecord)tr.GetObject(
        bt[BlockTableRecord.ModelSpace],
        OpenMode.ForWrite);

    // Create and add entities
    Circle circle = new Circle(Point3d.Origin, Vector3d.ZAxis, 10.0);
    circle.Layer = "0";
    circle.ColorIndex = 3; // Green

    modelSpace.AppendEntity(circle);
    tr.AddNewlyCreatedDBObject(circle, true);

    // MUST commit or transaction auto-aborts
    tr.Commit();
}
```

**Error Handling:**

```csharp
using (Transaction tr = db.TransactionManager.StartTransaction())
{
    BlockTable bt = (BlockTable)tr.GetObject(db.BlockTableId, OpenMode.ForRead);

    if (!bt.Has(blockName))
    {
        ed.WriteMessage($"\nError: Block '{blockName}' not found.\n");
        tr.Abort();  // Explicit abort on error
        return;
    }

    // Continue with operation...
    tr.Commit();
}
```

## Document Locking

When operations require exclusive access (especially from events or async contexts):

```csharp
Document doc = Application.DocumentManager.MdiActiveDocument;

using (doc.LockDocument())
{
    // Safe to modify document here
    EnsureBlocksExist();
}
```

## Block Creation

```csharp
public static void EnsureBlockExists(Database db, Transaction tr, string blockName)
{
    BlockTable bt = (BlockTable)tr.GetObject(db.BlockTableId, OpenMode.ForRead);

    if (bt.Has(blockName)) return;

    bt.UpgradeOpen();

    BlockTableRecord btr = new BlockTableRecord { Name = blockName };

    // Add geometry to block definition
    Circle circle = new Circle(Point3d.Origin, Vector3d.ZAxis, 1.0);
    circle.ColorIndex = 3;
    btr.AppendEntity(circle);

    // Add attribute definition
    AttributeDefinition attDef = new AttributeDefinition
    {
        Position = Point3d.Origin,
        Tag = "CODE",
        Prompt = "Enter code:",
        TextString = "",
        Height = 0.55,
        Justify = AttachmentPoint.MiddleCenter,
        ColorIndex = 7
    };
    btr.AppendEntity(attDef);

    bt.Add(btr);
    tr.AddNewlyCreatedDBObject(btr, true);
}
```

## Block Insertion with Attributes

```csharp
public ObjectId InsertBlock(string blockName, Point3d position, Dictionary<string, string> attValues)
{
    Document doc = Application.DocumentManager.MdiActiveDocument;
    Database db = doc.Database;

    using (Transaction tr = db.TransactionManager.StartTransaction())
    {
        BlockTable bt = (BlockTable)tr.GetObject(db.BlockTableId, OpenMode.ForRead);
        BlockTableRecord modelSpace = (BlockTableRecord)tr.GetObject(
            bt[BlockTableRecord.ModelSpace], OpenMode.ForWrite);

        ObjectId blockId = bt[blockName];
        BlockReference br = new BlockReference(position, blockId);

        ObjectId brId = modelSpace.AppendEntity(br);
        tr.AddNewlyCreatedDBObject(br, true);

        // Populate attributes
        BlockTableRecord blockDef = (BlockTableRecord)tr.GetObject(blockId, OpenMode.ForRead);
        foreach (ObjectId attDefId in blockDef)
        {
            DBObject obj = tr.GetObject(attDefId, OpenMode.ForRead);
            if (obj is AttributeDefinition attDef && !attDef.Constant)
            {
                AttributeReference attRef = new AttributeReference();
                attRef.SetAttributeFromBlock(attDef, br.BlockTransform);

                string tag = attDef.Tag.ToUpperInvariant();
                if (attValues.TryGetValue(tag, out string value))
                {
                    attRef.TextString = value;
                }

                br.AttributeCollection.AppendAttribute(attRef);
                tr.AddNewlyCreatedDBObject(attRef, true);
            }
        }

        tr.Commit();
        return brId;
    }
}
```

## Update Block Attributes

```csharp
public void UpdateAttributes(ObjectId blockRefId, Dictionary<string, string> values)
{
    Document doc = Application.DocumentManager.MdiActiveDocument;
    Database db = doc.Database;

    using (Transaction tr = db.TransactionManager.StartTransaction())
    {
        BlockReference br = (BlockReference)tr.GetObject(blockRefId, OpenMode.ForRead);

        foreach (ObjectId attId in br.AttributeCollection)
        {
            AttributeReference att = (AttributeReference)tr.GetObject(attId, OpenMode.ForWrite);

            if (values.TryGetValue(att.Tag.ToUpperInvariant(), out string newValue))
            {
                att.TextString = newValue;
            }
        }

        tr.Commit();
    }
}
```

## User Input

```csharp
Editor ed = doc.Editor;

// Get point
PromptPointResult ppr = ed.GetPoint("\nSelect insertion point: ");
if (ppr.Status != PromptStatus.OK) return;
Point3d point = ppr.Value;

// Get string
PromptStringOptions pso = new PromptStringOptions("\nEnter code: ")
{
    AllowSpaces = false,
    DefaultValue = "PL1"
};
PromptResult psr = ed.GetString(pso);
if (psr.Status != PromptStatus.OK) return;
string code = psr.StringResult;

// Get selection
PromptSelectionOptions selOpts = new PromptSelectionOptions
{
    MessageForAdding = "\nSelect objects: "
};
PromptSelectionResult selRes = ed.GetSelection(selOpts);
if (selRes.Status != PromptStatus.OK) return;
SelectionSet ss = selRes.Value;
```

## Layer Operations

```csharp
public void EnsureLayerExists(Database db, Transaction tr, string layerName, short colorIndex = 7)
{
    LayerTable lt = (LayerTable)tr.GetObject(db.LayerTableId, OpenMode.ForRead);

    if (lt.Has(layerName)) return;

    lt.UpgradeOpen();

    LayerTableRecord layer = new LayerTableRecord
    {
        Name = layerName,
        Color = Color.FromColorIndex(ColorMethod.ByAci, colorIndex)
    };

    lt.Add(layer);
    tr.AddNewlyCreatedDBObject(layer, true);
}
```

## Text Style Operations

```csharp
public void EnsureTextStyleExists(Database db, Transaction tr, string styleName)
{
    TextStyleTable tst = (TextStyleTable)tr.GetObject(db.TextStyleTableId, OpenMode.ForRead);

    if (tst.Has(styleName)) return;

    tst.UpgradeOpen();

    TextStyleTableRecord style = new TextStyleTableRecord
    {
        Name = styleName,
        Font = new FontDescriptor("Arial", false, false, 0, 0)
    };

    tst.Add(style);
    tr.AddNewlyCreatedDBObject(style, true);
}
```

## WPF Palette

```csharp
public class PaletteManager
{
    private static Autodesk.AutoCAD.Windows.PaletteSet _paletteSet;

    public static void Show()
    {
        if (_paletteSet == null)
        {
            _paletteSet = new Autodesk.AutoCAD.Windows.PaletteSet(
                "My Palette",
                new Guid("12345678-1234-1234-1234-123456789012"))
            {
                Size = new System.Drawing.Size(350, 500),
                DockEnabled = Autodesk.AutoCAD.Windows.DockSides.Left
                            | Autodesk.AutoCAD.Windows.DockSides.Right
            };

            // Add WPF UserControl
            MyPaletteControl control = new MyPaletteControl();
            _paletteSet.AddVisual("Main", control);
        }

        _paletteSet.Visible = true;
    }
}
```

**WPF UserControl with Theme Detection:**

```csharp
public partial class MyPaletteControl : UserControl
{
    private MyViewModel _viewModel;

    public MyPaletteControl()
    {
        InitializeComponent();
        _viewModel = new MyViewModel();
        DataContext = _viewModel;

        // Live theme change detection
        Application.SystemVariableChanged += OnSystemVariableChanged;
        this.Unloaded += OnUnloaded;
    }

    private void OnSystemVariableChanged(object sender, SystemVariableChangedEventArgs e)
    {
        if (e.Name.Equals("COLORTHEME", StringComparison.OrdinalIgnoreCase))
        {
            Dispatcher.Invoke(() =>
            {
                var colorTheme = Application.GetSystemVariable("COLORTHEME");
                _viewModel.IsDarkMode = colorTheme?.ToString() == "0";
            });
        }
    }

    private void OnUnloaded(object sender, RoutedEventArgs e)
    {
        Application.SystemVariableChanged -= OnSystemVariableChanged;
    }
}
```

## Bundle Deployment

### Folder Structure

```
C:\ProgramData\Autodesk\ApplicationPlugins\MyPlugin.bundle\
├── PackageContents.xml
└── Contents\
    ├── MyPlugin.dll
    ├── MyPlugin.Core.dll
    ├── MyPlugin.UI.dll
    └── [other dependencies]
```

### PackageContents.xml

```xml
<?xml version="1.0" encoding="utf-8"?>
<ApplicationPackage SchemaVersion="1.0" Name="MyPlugin" Version="1.0.0"
    ProductCode="{12345678-1234-1234-1234-123456789012}">
  <CompanyDetails Name="My Company" />
  <Components>
    <RuntimeRequirements OS="Win64" Platform="AutoCAD"
                         SeriesMin="R24.0" SeriesMax="R27.0"/>

    <ComponentEntry AppName="MyPlugin"
                    ModuleName=".\Contents\MyPlugin.dll"
                    LoadOnAutoCADStartup="True">
      <Commands>
        <Command Local="MY_COMMAND" Global="MY_COMMAND"/>
        <Command Local="MY_PALETTE" Global="MY_PALETTE"/>
      </Commands>
    </ComponentEntry>
  </Components>
</ApplicationPackage>
```

### Build & Deploy Script

```powershell
# BUILD_AND_DEPLOY.ps1

# Step 0: Check AutoCAD not running
$acadProcess = Get-Process -Name "acad" -ErrorAction SilentlyContinue
if ($acadProcess) {
    Write-Warning "AutoCAD is running! Close it before building."
    $response = Read-Host "Press Enter to kill AutoCAD, K to skip, Q to quit"
    if ($response -eq "Q") { exit 0 }
    if ($response -ne "K") {
        Stop-Process -Name "acad" -Force
        Start-Sleep -Seconds 2
    }
}

# Step 1: Build
$projectDir = $PSScriptRoot
Push-Location $projectDir
dotnet build MyPlugin -c Release --no-incremental
if ($LASTEXITCODE -ne 0) {
    Write-Error "Build failed!"
    Pop-Location
    exit 1
}
Pop-Location

# Step 2: Deploy to bundle
$bundleContents = "C:\ProgramData\Autodesk\ApplicationPlugins\MyPlugin.bundle\Contents"
if (-not (Test-Path $bundleContents)) {
    New-Item -ItemType Directory -Path $bundleContents -Force
}

# Clear old DLLs
Get-ChildItem $bundleContents -Filter "MyPlugin*.dll" | Remove-Item -Force

# Copy new files
$buildOutput = "$projectDir\build_test"
Copy-Item "$buildOutput\*.dll" $bundleContents -Force
Copy-Item "$buildOutput\*.pdb" $bundleContents -Force -ErrorAction SilentlyContinue

# Copy PackageContents.xml
Copy-Item "$projectDir\MyPlugin.bundle\PackageContents.xml" `
          "C:\ProgramData\Autodesk\ApplicationPlugins\MyPlugin.bundle\" -Force

Write-Host "Deployment complete!" -ForegroundColor Green
```

### Pre-Build Validation (.csproj)

```xml
<Target Name="PreBuildValidation" BeforeTargets="BeforeBuild"
        Condition="'$(SkipValidation)' != 'true'">
  <Exec Command="powershell -NoProfile -Command &quot;if (Get-Process -Name 'acad' -ErrorAction SilentlyContinue) { Write-Error 'AutoCAD is running! Close it first.'; exit 1 }&quot;" />
</Target>
```

Skip with: `dotnet build /p:SkipValidation=true`

## Memory Management Rules

1. **Always use transactions** — never modify objects outside transactions
2. **Commit or abort** — transactions auto-abort on dispose, but explicit is clearer
3. **Lock documents** — when modifying from events or async contexts
4. **Dispose resources** — use `using` statements for transactions
5. **Private=false** — for AutoCAD DLL references (they're loaded by AutoCAD)

## Common Patterns

### Check Active Transactions Before Block Creation

```csharp
int activeTransactions = doc.Database?.TransactionManager?.NumberOfActiveTransactions ?? 0;
if (activeTransactions == 0)
{
    using (doc.LockDocument())
    {
        EnsureBlocksExist();
    }
}
```

### Geometry Creation

```csharp
// Line
Line line = new Line(startPoint, endPoint);
line.ColorIndex = 3; // Green
line.Layer = "0";
modelSpace.AppendEntity(line);
tr.AddNewlyCreatedDBObject(line, true);

// Polyline
Polyline pline = new Polyline();
pline.AddVertexAt(0, new Point2d(0, 0), 0, 0, 0);
pline.AddVertexAt(1, new Point2d(10, 0), 0, 0, 0);
pline.AddVertexAt(2, new Point2d(10, 10), 0, 0, 0);
pline.Closed = true;
pline.ColorIndex = 1; // Red
modelSpace.AppendEntity(pline);
tr.AddNewlyCreatedDBObject(pline, true);

// MText
MText mtext = new MText();
mtext.Location = new Point3d(5, 5, 0);
mtext.Contents = "Hello World";
mtext.TextHeight = 0.55;
mtext.Attachment = AttachmentPoint.MiddleCenter;
modelSpace.AppendEntity(mtext);
tr.AddNewlyCreatedDBObject(mtext, true);
```

## Anti-Patterns to Avoid

| Bad | Why | Good |
|-----|-----|------|
| Modifying objects without transaction | Data corruption | Always use `StartTransaction()` |
| Forgetting `tr.AddNewlyCreatedDBObject()` | Entity not persisted | Add after `AppendEntity()` |
| `Private=true` for AutoCAD DLLs | DLL conflicts at runtime | `Private=false` |
| Building while AutoCAD running | DLLs locked | Close AutoCAD first |
| Hardcoded AutoCAD paths | Breaks on version change | Use environment variables |
| .NET 8 target framework | AutoCAD 2022-2025 = net48 | `<TargetFramework>net48</TargetFramework>` |

## Quick Reference

### AutoCAD Version → .NET Framework

| AutoCAD Version | .NET Framework |
|-----------------|----------------|
| 2022-2025 | .NET Framework 4.8 |
| 2025+ | .NET 8 (future) |

### Key Namespaces

```csharp
using Autodesk.AutoCAD.ApplicationServices;  // Application, Document
using Autodesk.AutoCAD.DatabaseServices;     // Database, Transaction, entities
using Autodesk.AutoCAD.EditorInput;          // Editor, prompts
using Autodesk.AutoCAD.Geometry;             // Point3d, Vector3d
using Autodesk.AutoCAD.Runtime;              // CommandMethod, IExtensionApplication
using Autodesk.AutoCAD.Colors;               // Color
```

### Build Commands

```powershell
# Build
dotnet build MyPlugin -c Release

# Build skipping validation
dotnet build MyPlugin -c Release /p:SkipValidation=true

# Clean build
dotnet build MyPlugin -c Release --no-incremental
```
