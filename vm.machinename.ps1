//*
//
//
//
*//


# Env Variable
$VM = "Merlin"
$SLEEP = 5

function UpdateHosts {
    param (
        [String]$VIRTUALMACHINE
    )

    if ($IsLinux) {
        # "Linux"
        # $hostsPath = "/etc/hosts"
        $hostsPath = "/home/peter/hosts"
    }
    elseif ($IsMacOS) {
        # "macOS"
        $hostsPath = "/private/etc/hosts"
    }
    else {
        # "Windows"
        $hostsPath = "$env:windir\System32\drivers\etc\hosts"
    }

    # Get ip of VM
    $IP = VBoxManage guestproperty get "$VIRTUALMACHINE" "/VirtualBox/GuestInfo/Net/0/V4/IP"
    $IP = $IP.substring(7).trim()
    # Get file contents
    [string[]]$hosts = Get-Content $hostsPath
    [string[]]$domains=Get-Content "$VIRTUALMACHINE.txt"
    $hostText=""
    ForEach ($ahost in $hosts) {
        $thehost=$ahost.split(" ")[1]
        if (!($domains -like "*$thehost*")) {
            "Add -> $ahost"
            $hostText=$hostText+$ahost+"`n"
        }
        else {
            "Domains contains $thehost"
       }
    }
    $hostlines=$hostText.Substring(0,$hostText.Length-1)
    Get-Content "$VIRTUALMACHINE.txt"| ForEach-Object {
        $hostlines =$hostlines+"`n$IP $_"
    }
    "Host File"
    "$hostlines"
    $hostlines|Out-File $hostsPath 
}


if ($IsLinux) {
    # "Linux"
    $SharedPath = "$HOME/vm/$VM"
    $Started = "${SharedPath}/Started"
}
elseif ($IsMacOS) {
    # "macOS"
    $SharedPath = "$HOME/vm/$VM"
    $Started = "${SharedPath}/Started"
}
else {
    # "Windows"
    $SharedPath = "$HOME\vm\$VM"
    $Started = "${SharedPath}\Started"
}

"SharedPath: $Sharedpath"
"Started   : $Started"


# start virtual machine
if (VBoxManage list runningvms | Select-String -Pattern "$VM" -quiet) {
    "$VM Running"
}
else {
    try {
        Remove-Item -Path "$Started" -Force -ErrorAction SilentlyContinue
        "Removed Old Start file"
    }
    catch {
        "No Start file present"
    }
     "Starting $VM"
    VBoxManage startvm "$VM" --type headless
    Write-Host -NoNewline "Waiting for boot to complete."
    while (!([System.IO.File]::Exists("$Started"))) {
        Start-Sleep -Seconds $SLEEP
        Write-Host -NoNewline  "."
    }
 }
"`n"
UpdateHosts -VIRTUALMACHINE $VM
"Waiting for network"
$ping = test-connection -ComputerName "$VM" -Quiet
do { $ping = test-connection -ComputerName "$VM" -Quiet }
until ($ping -contains "True") 
"Network to $VM detected"
"$VM Ready!"