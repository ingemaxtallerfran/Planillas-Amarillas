# Verificacion rapida sin abrir navegador (solo ASCII en este archivo: PowerShell 5 rompe los acentos sin BOM).
# Carga cada pagina en Chrome/Edge sin ventana, en modo solo lectura y contra el backend real,
# y devuelve UNA linea por pagina: errores de JS, cuanto texto pinto y, si se pide, el valor de una expresion.
#
#   powershell -ExecutionPolicy Bypass -File tools\verificar.ps1
#   powershell -ExecutionPolicy Bypass -File tools\verificar.ps1 -Paginas intervenciones.html -Js "S.equiposInfo.length"
#   powershell -ExecutionPolicy Bypass -File tools\verificar.ps1 -Paginas costos.html -Repetir 2   (2da pasada = con copia local)
param(
  [string[]]$Paginas = @("menu.html","index.html","intervenciones.html","costos.html","remitos.html","consultas.html"),
  [string]$Js = "",
  [int]$Espera = 30000,
  [int]$Repetir = 1
)
$Paginas = @($Paginas | ForEach-Object { $_ -split ',' } | Where-Object { $_ })
$repo = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$chrome = @("C:\Program Files\Google\Chrome\Application\chrome.exe",
            "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe",
            "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
            "C:\Program Files\Microsoft\Edge\Application\msedge.exe") | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $chrome) { Write-Output "No encontre Chrome ni Edge"; exit 1 }
$tmp = Join-Path $env:TEMP "ingemax-verif"
if (Test-Path $tmp) { Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue }
New-Item -ItemType Directory -Force $tmp | Out-Null
$enc = New-Object System.Text.UTF8Encoding($false)
$jsLit = if ($Js) { ($Js | ConvertTo-Json) } else { '""' }
$pre = '<script>window.__err=[];window.addEventListener("error",function(e){window.__err.push(String(e.message)+"@"+e.lineno)});window.addEventListener("unhandledrejection",function(e){window.__err.push("promesa: "+String(e.reason))});</script>'
$post = '<script>(function(){var t0=performance.now(),m={},expr=' + $jsLit + ';setInterval(function(){m.ms=Math.round(performance.now()-t0);m.errores=window.__err;m.texto=(document.body.innerText||"").length;m.actualizando=document.body.classList.contains("sync");if(expr){try{m.js=(0,eval)(expr)}catch(e){m.js="ERROR: "+e.message}}document.documentElement.setAttribute("data-verif",JSON.stringify(m));},100);})();</script>'
$fallas = 0
foreach ($pasada in 1..$Repetir) {
  foreach ($p in $Paginas) {
    $src = Join-Path $repo $p
    if (-not (Test-Path $src)) { Write-Output "$p : NO EXISTE"; $fallas++; continue }
    $t = [System.IO.File]::ReadAllText($src, $enc)
    $t = $t.Replace("<body>", "<body>" + $pre)
    $i = $t.LastIndexOf("</html>")
    if ($i -ge 0) { $t = $t.Insert($i, $post) } else { $t = $t + $post }
    $copia = Join-Path $tmp $p
    [System.IO.File]::WriteAllText($copia, $t, $enc)
    $uri = "file:///" + $copia.Replace('\','/') + "?modo=lectura"
    $dom = Join-Path $tmp "dom.txt"
    Start-Process -FilePath $chrome -ArgumentList @("--headless=new","--disable-gpu","--user-data-dir=`"$tmp\perfil`"","--virtual-time-budget=$Espera","--dump-dom","`"$uri`"") -RedirectStandardOutput $dom -RedirectStandardError (Join-Path $tmp "err.txt") -Wait -NoNewWindow
    $out = Get-Content $dom -Raw -Encoding UTF8
    $m = [regex]::Match([string]$out, 'data-verif="([^"]*)"')
    if ($m.Success) {
      $r = [System.Net.WebUtility]::HtmlDecode($m.Groups[1].Value)
      if ($r -notmatch '"errores":\[\]') { $fallas++ }
      Write-Output "$p (pasada $pasada): $r"
    } else { $fallas++; Write-Output "$p (pasada $pasada): NO CARGO (la pagina no llego a ejecutar el script final)" }
  }
}
if ($fallas) { Write-Output "RESULTADO: $fallas pagina(s) con problemas"; exit 1 } else { Write-Output "RESULTADO: todo OK" }
