#region Variables
$script:StartTime = Get-Date
$script:LogPath = 'C:\rs-pkgs\maktokms'
$script:LogFile = 'maktokms.txt'
$script:localOS = ""
$script:psVersion = ""
#endregion Variables


Function Write-Log {
	[CmdletBinding()]
	Param
	(
		[string]$Message,
		[ValidateSet('Info', 'Warn', 'Error')]
		[string]$EntryType,
		[string]$LogFilePath = $LogPath,
		[string]$LogFileName = $LogFile
	)
	begin {
		$LogPath = @($LogFilePath, $LogFileName -join '\')
	}
	process {
		try {
			# Create Log File
			if (-not (Test-Path $LogPath)) {
				$LogFilePathOut = New-Item -Path $LogFilePath -ItemType Directory -ErrorAction SilentlyContinue
				$LogPathOut = New-Item -Path $LogFileName -ItemType File -ErrorAction SilentlyContinue
				if ($LogPathOut.Exists) {
					Write-Verbose -Message "[$(Get-Date)] Info  :: $LogPath was created"
				}
			}
			$LogMessagePrefix = if ($EntryType -eq 'Error') {
				"[$(Get-Date)] $EntryType ::"
			}
			else {
				"[$(Get-Date)] $EntryType  ::"
			}
			Add-Content $LogPath -Value @("$LogMessagePrefix $Message")
			
			Write-Output -InputObject @("$LogMessagePrefix $Message")
		}
		catch [Exception]
		{
			Write-Output -InputObject "[$(Get-Date)] Info  :: $($MyInvocation.MyCommand)"
			Write-Output -InputObject "[$(Get-Date)] Error :: $_ "
		}
	}
}


function test-kmsconnection {
  	Write-Log -EntryType Info -Message 'Testing DNS to kms.domain.com'
  		try {
  			#test dns
  			$pingtest = ping kms.rackspace.com
  			if ($pingtest -like "*Reply from*") {
  				Write-Log -EntryType Info -Message 'KMS server resolves as expected'
  			}
    			else { 
        			Write-Log -EntryType Error -Message 'DNS DOES NOT RESOLVE'
    			}
  		}
  		catch {
  			Write-Log -EntryType Error -Message 'Error attempting to test connectivity'
  			Write-Log -EntryType Error -Message $_
  			exit
  		}
	
}

function set-clientkey {
    	Write-Log -EntryType Info -Message 'Installing KMS client key'
        try { 

    		$OSversion = (Get-WmiObject -class Win32_OperatingSystem).Caption
    		switch -Regex ($OSversion) {
		        'Windows Server 2008 Standard'           {$key = 'TM24T-X9RMF-VWXK6-X8JC9-BFGM2';break}
        		'Windows Server 2008 Enterprise'         {$key = 'YQGMW-MPWTJ-34KDK-48M3W-X4Q6V';break}
        		'Windows Server 2008 Datacenter'         {$key = '7M67G-PC374-GR742-YH8V4-TCBY3';break}
		        'Windows Web Server 2008'                {$key = 'WYR28-R7TFJ-3X2YQ-YCY4H-M249D';break}
        		'Windows Server 2008 R2 Web'             {$key = '6TPJF-RBVHG-WBW2R-86QPH-6RTM4';break}    
        		'Windows Server 2008 R2 Standard'        {$key = 'YC6KT-GKW9T-YTKYR-T4X34-R7VHC';break}
        		'Windows Server 2008 R2 Enterprise'      {$key = '489J6-VHDMP-X63PK-3K798-CPX3Y';break}
        		'Windows Server 2008 R2 Datacenter'      {$key = '74YFP-3QFB3-KQT8W-PMXWJ-7M648';break}
        		'Windows Server 2012 Server Standard'    {$key = 'XC9B7-NBPP2-83J2H-RHMBY-92BT4';break}
        		'Windows Server 2012 Standard'           {$key = 'XC9B7-NBPP2-83J2H-RHMBY-92BT4';break}
        		'Windows Server 2012 Datacenter'         {$key = '48HP8-DN98B-MYWDG-T2DCC-8W83P';break}
        		'Windows Server 2012 R2 Standard'        {$key = 'D2N9P-3P6X9-2R39C-7RTCD-MDVJX';break}
        		'Windows Server 2012 R2 Datacenter'      {$key = 'W3GGN-FT8W3-Y4M27-J84CP-Q3VJ9';break}
			      'Windows Server 2016 Datacenter'         {$key = 'CB7KF-BWN84-R7R2Y-793K2-8XDDG';break}
        		'Windows Server 2016 Standard'           {$key = 'WC2BQ-8NRM3-FDDYY-2BFGV-KHKQY';break}
        		'Windows Server 2016 Essentials'         {$key = 'JCKRF-N37P4-C2D82-9YXRT-4M63B';break}
    		}
    
    		$installclient = Invoke-Expression "cscript c:\windows\system32\slmgr.vbs /ipk $key"
    		if ($installclient -like "*installed successfully*" -or "*activated successfully*") {
		        Write-Log -EntryType Info -Message "Client key installed successfully."
        	}
    
    		else {
        		Write-Log -EntryType Error -Message "Client key not installed successfully."
        		Write-Log -EntryType Error -Message $_
        		exit
    		}
	}
    
	catch {
		Write-Log -EntryType Error -Message "ERROR encountered installing client license key."
		Write-Log -EntryType Error -Message "$_ "
		exit
	}
}
		
function set-rskmsserver {
    	Write-Log -EntryType Info -Message 'Pointing server to kms.domain.com'
    		try {
    			$skms = Invoke-Expression "cscript c:\windows\system32\slmgr.vbs /skms kms.domain.com"
    			if ($skms -like "*set to kms.domain.com successfully*") {
    				Write-Log -EntryType Info -Message 'Successfully set kms.domain.com as KMS server.'
    			}
    			else {
    				Write-Log -EntryType Error -Message 'Unable to set kms.domain.com as KMS server.'
    			}
    		}
    		catch {
    			Write-Log -EntryType Error -Message 'Error attempting to set kms.domain.com as KMS server.'
    			Write-Log -EntryType Error -Message $_
    			exit
    		}
    	}

function set-activation {
    	Write-Log -EntryType Info -Message 'Activating against kms.domain.com'
    		try {
    			$activate = Invoke-Expression "cscript c:\windows\system32\slmgr.vbs /ato"
    			if ($activate -like "*Product activated successfully*") {
    				Write-Log -EntryType Info -Message 'Successfully activated against kms.domain.com.'
    			}
    			else {
    				Write-Log -EntryType Error -Message 'Unable activate against kms.domain.com.'
    			}
    		}
    		catch {
    			Write-Log -EntryType Error -Message 'Error attempting to against Domain KMS server.'
    			Write-Log -EntryType Error -Message $_
    			exit
    		}
    	}

function get-kmsverification {
        Write-Log -EntryType Info -Message 'Verifying KMS'
               try {
                       $verifyKMS = Invoke-Expression "cscript c:\windows\system32\slmgr.vbs /dlv"
                        If (($verifyKMS -like "*Registered KMS machine name: kms.domain.com:1688*") -and ($verifyKMS -like "*License Status: Licensed*"))
                        {
                        	Write-Log -EntryType Info -Message 'KMS Activation Verified'
                        }
                        ElseIf ($verifyKMS -like "*MAK*")
                        {
                        	Write-Log -EntryType Error -Message 'Server is still utilizing MAK Key.'
                        	Write-Log -EntryType Error -Message $_
                        }
                        Else 
                        {
                        	Write-Log -EntryType Error -Message 'KMS Verification has failed'
                        	Write-Log -EntryType Error -Message $_
                        }
               }
                catch {
    			Write-Log -EntryType Error -Message 'Error attempting to against Domain KMS server.'
    			Write-Log -EntryType Error -Message $_
    			exit
    		}
}



test-kmsconnection
set-clientkey  
set-rskmsserver
set-activation
get-kmsverification
