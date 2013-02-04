$newsoku="http://hayabusa3.2ch.net/news/"
$readall="http://hayabusa3.2ch.net/test/read.cgi/news/"

$personobjsrc=@"
        public class NiChPerson
        {            
            public string Name { get; private set; }
            public string Region { get; private set; }            
            public string ID { get; private set; }
            public string Be { get; private set; }            
            
            public NiChPerson(string name, string region, string id, string be)
            {
                Name = name;
                Region = region;
                ID = id;
                Be = be;
            }
        }

        public class NiChRes
        {
            public NiChPerson Person { get; private set; }
            public string Email { get; private set; }
            public string Content { get; private set; }
            public System.DateTime Time { get; private set; }
            public int ResNumber { get; private set; }

            
            public NiChRes(NiChPerson person, string email, string content, System.DateTime time, int resnumber)
            {
                Person = person;
                Email = email;
                Content = content;
                Time = time;
                ResNumber = resnumber;
            }
        }
"@

Add-Type -Language CSharp -TypeDefinition $personobjsrc



function ResponseParser($line){
    $splitter = "<dd>","</b>"
    $spline = $line.Split($splitter, [System.StringSplitOptions]::RemoveEmptyEntries)

    # number and e-mail (example: <dt>1 ：<a href="mailto:sage"><b>)
    $firstsp=$spline[0].TrimStart("<dt>").Split("：")
    $resnum = [System.Int32]::Parse($firstsp[0])
    $email = $null
    if($firstsp[1].StartsWith("<a")){
        $email = $firstsp[1].Split('"')[1].Substring(7)
    }

    # name (ex: イエネコ<b>)
    $name = $spline[1].TrimEnd("<b>")

    # region (ex: (チベット自治区)<b>)
    $region = $spline[2].Trim("()<b>")

    ### datetime ,ID and Be (ex: </a>：2013/02/04(月) 15:45:48.94 ID:op/3AUNfP <a href="javascript:be(1082344436);">?PLT(12001) ポイント特典</a>)
    $datelinesp = $spline[3].TrimStart("</a>：").Split()
    # date time
    $y, $m, $d = $datelinesp[0].Substring(0, $datelinesp[0].Length - 3).Split('/')
    $y=$y.TrimStart("font>：")
    $h, $min, $sec = $datelinesp[1].Split(':')
    $sec, $millisec = $sec.Split('.')
    $datetime = New-Object System.DateTime($y, $m, $d, $h, $min, $sec,$millisec)
    # id
    $id = $datelinesp[2].Substring(3)
    # be
    $be = $null
    $besplitter = ,"be"
    $besp = $spline[3].Split($besplitter, [System.StringSplitOptions]::RemoveEmptyEntries)
    if($besp.Length -eq 2){
        $be = $besp[1].TrimStart("(").Split(')')[0]
    }

    # content
    $content = $spline[4]
    $person = New-Object NiChPerson($name, $region, $id, $be)
    $return = New-Object NiChRes($person, $email, $content, $datetime, $resnum)
    return $return
}

function Get-ThreadContent($url){
    $wc = New-Object System.Net.WebClient
    $st = $wc.OpenRead($url)
    $enc = [System.Text.Encoding]::GetEncoding("Shift_JIS")
    $sr = New-Object System.IO.StreamReader($st, $enc)

    while(($line = $sr.ReadLine()) -ne $null){    
        if($line.StartsWith("<dl")){
            break
        }
    }

    $responses = New-Object System.Collections.ArrayList
    while(($line = $sr.ReadLine()) -ne $null){
        if($line.StartsWith("</dl")){
            break
        }
        try{
            $res = ResponseParser $line
        } catch {
            $line
        }
        $responses.Add($res) | Out-Null
    }
    $sr.Close()    
    $st.Close()
    $wc.Dispose()
    return $responses
}