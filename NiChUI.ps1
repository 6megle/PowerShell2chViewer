function View-ThreadList{    
    Get-News | Out-Null
    $windowWidth = $host.UI.RawUI.WindowSize.Width
    $columnWidth = @{
        number = $windowWidth*1/6;
        title = $windowWidth*2/3;
        resnum = $windowWidth*1/6
    }
    $columnName = @{
        number = "#";
        title = "Title";
        resnum = "Res"
    }

    function Normalize([string]$str, $w){
        $length = $str.Length * 2
        if($length -lt $w){
            $str + " "*($w - $length)
        } else {
            $str.SubString(0, $w/2)
        }
    }

    function ColString($v){
        return ($columnName[$v] + " "*($columnWidth[$v]- $columnName[$v].Length - 1))
    }

    $retstring = (ColString "number") + " " + (ColString "title") + " " + (ColString "resnum") + "`n"
    foreach($thread in $threads){
        $numstring = $thread.ThreadNumber.ToString()
        $rescstring = $thread.NumberOfRes.ToString()
        $retstring += (Normalize $numstring $columnWidth["number"]) + (Normalize $thread.Content $columnWidth["title"]) + (Normalize $rescstring $columnWidth["resnum"]) + "`n"
    }
    return $retstring
}

function ShowThread($num){
    $reslist = (Get-ThreadContent ($readall + $threads[$num].Url))
    function ResView($res){
        # head
        $str = ""
        $str += $res.ResNumber.ToString() + ": "
        $str += $res.Person.Name
        $str += "(" + $res.Person.Region + ")" + "`n"
        # content
        $str += $res.Content.Replace("<br>", "`n")
        return $str 
    }

    $returnstr = ""
    foreach($res in $reslist){
        $returnstr += (ResView $res)
    }

    return $returnstr
}