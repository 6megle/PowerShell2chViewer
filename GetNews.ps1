$newsoku = "http://hayabusa3.2ch.net/news/"
$thredobjsrc=@"
        public class NewsThread
        {
            public string Content { get; private set; }
            public string Url { get; private set; }
            public int ThreadNumber { get; private set; }
            public int NumberOfRes { get; private set; }
            public NewsThread(string content, string url, int threadNumber, int numberOfRes)
            {
                Content = content;
                Url = url;
                ThreadNumber = threadNumber;
                NumberOfRes = numberOfRes;
            }
        }
"@

Add-Type -Language CSharp -TypeDefinition $thredobjsrc

function lineparser($line){
    $spline = $line.Split(':')
    $lastline = $line.TrimStart($spline[0] + ": ").TrimEnd("</a>")
    $lastsplit=$lastline.Split('(')
    $resnum = [System.Int32]::Parse($lastsplit[$lastsplit.Length-1].Split(')')[0])
    $fin = $lastline.Substring(0, $lastline.Length - $lastsplit[$lastsplit.Length -1].Length -3)
    $content=""
    for($i=1; $i -lt $spline.Length - 1; $i++){
        $content += $spline[$i]
    }
    $content+=$fin

    $retobj = New-Object NewsThread($content.TrimStart(), $spline[0].Split('"')[1].TrimEnd("l50").TrimEnd("/"), [System.Int32]::Parse($spline[0].Split('>')[1]), $resnum)
    return $retobj
}

$threads = New-Object System.Collections.ArrayList

function Get-News{
    $threads.Clear()
    $wc = New-Object System.Net.WebClient

    $st = $wc.OpenRead($newsoku+"subback.html")
    $enc = [System.Text.Encoding]::GetEncoding("Shift_JIS")
    $sr = New-Object System.IO.StreamReader($st, $enc)
    $sr.ReadLine() | Out-Null
    $sr.ReadLine() | Out-Null
    $sr.ReadLine() | Out-Null        
    while(($line = $sr.ReadLine()) -ne $null){
        if($line.StartsWith("</small>")){
            break
        }
    
        $thread = lineparser $line
        $threads.Add($thread) | Out-Null
    }
    return $threads
}