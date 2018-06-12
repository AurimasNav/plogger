<#
.Synopsis
    Write message to log file
.DESCRIPTION
    Write message to log file in CMTRACE format, cpaturing some components from PSCallStack
.EXAMPLE
    Write-Log -EntryType Information -Message "Some custom message" -LogFile C:\temp\ouptut.log
.EXAMPLE
    Write-Log -EntryType Error -Message "This happened in a catch block" -Exception $_
.EXAMPLE
    Write-Log -EntryType Error -Message "Providing -Context parameter is useful within class methods, as module name is not available there" -Context "This was invoked within a class [CustomType]. Module - MyModule." -Exception $_
.NOTES
    Use cmtrace.exe to read logs (part of sccm toolkit https://www.microsoft.com/en-us/download/confirmation.aspx?id=50012)
.FUNCTIONALITY
   Writes custom message to a specified file, or in $Env:TEMP\Plogger direcotry if omitted, optionally writes additional message with -Exception parameter, which can take Error object as input.
   Logs messages in cmtrace parsable format, capturing source, function name, module name, method name, when able.
#>
Function Write-Plog
{
    param (
        #Path to logfile
        [string]$LogFile,
        [string]$Context,
        [Parameter(Mandatory = $true)]
        [ValidateSet("Warning", "Error", "Verbose", "Debug", "Information")]
        [string]$EntryType,
        #Message to log
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Message,
        $Exception
    )
    Begin
    {
        if ([string]::IsNullOrEmpty($LogFile))
        {
            #since no logfile path provided use default path for logfile
            $Timestamp = Get-Date -f "yyyy-MM-dd"
            $LogFile = "$Env:TEMP\Plogger\$Timestamp.log"
        }
    }
    Process
    {
        if ($Exception -is [System.Management.Automation.ErrorRecord])
        {
            $ExceptionMessage = $($Exception.Exception.Message)
        }
        elseif ($Exception -is [string])
        {
            $ExceptionMessage = $Exception
        }
        else
        {
            $ExceptionMessage = [string]::Empty
        }

        if ([string]::IsNullOrEmpty($ExceptionMessage))
        {
            $LogMessage = $Message
        }
        else
        {
            $LogMessage = $Message + " Exception Message: " + $ExceptionMessage
        }

        switch ($EntryType)
        {
            "Warning"
            {
                $TypeNumeric = 2
                $TypePlain = "Warning"
            }
            "Error"
            {
                $TypeNumeric = 3
                $TypePlain = "Error"
            }
            "Verbose"
            {
                $TypeNumeric = 4
                $TypePlain = "Verbose"
            }
            "Debug"
            {
                $TypeNumeric = 5
                $TypePlain = "Debug"
            }
            "Information"
            {
                $TypeNumeric = 6
                $TypePlain = "Info"
            }
            Default
            {
                $TypeNumeric = 6
                $TypePlain = "Info"
            }
        }

        $FunctionName = (Get-PSCallStack)[1].FunctionName
        $ModuleName = (Get-PSCallStack)[1].InvocationInfo.MyCommand.ModuleName
        #$CommandName=(Get-PSCallStack)[1].InvocationInfo.MyCommand.Name
        $Location = (Get-PSCallStack)[1].Location
        $TimeStamp = Get-Date
        $TimeCmtrace = $TimeStamp.ToString("HH:mm:ss.ffffff")
        $DateCmtrace = $TimeStamp.ToString("MM-dd-yyyy")
        #$TimePlain = $TimeStamp.ToString("HH:mm:ss")
        #$DatePlain = $TimeStamp.ToString("yyyy-MM-dd")

        try
        {
            $TypeName = (Get-Variable -Scope 1 this -ErrorAction Stop)
            $ModuleName = $TypeName.Value.GetType().Module.Name
            $Component = $ModuleName + ':' + $TypeName.Value.GetType().Name + '.' + $FunctionName
            #if it becomes possible to get module name from within class, need to add $context check here
        }
        catch
        {
            if ([string]::IsNullOrEmpty($ModuleName))
            {
                if ([string]::IsNullOrEmpty($Context))
                {
                    $Component = $FunctionName
                }
                else
                {
                    $Component = $Context + ':' + $FunctionName
                }
            }
            else
            {
                if ([string]::IsNullOrEmpty($Context))
                {
                    $Component = $ModuleName + ':' + $FunctionName
                }
                else
                {
                    $Component = $Context + ':' + $ModuleName + ':' + $FunctionName
                }
            }
        }
        Try
        {
            $LogFileInfo = [System.IO.FileInfo]::new($LogFile)
            if (-not (Test-Path ($LogFileInfo.Directory)))
            {
                New-Item -ItemType Directory -Path $LogFileInfo.Directory -Force
            }
        }
        catch
        {
            Write-Host "Could not create directory. Exception: $($_.Exception.Message)" -ForegroundColor Red
            Write-MetaPlog -Exception $_ -Message "Could not create directory."
        }
        Try
        {
            $CmtraceFormatLog = "<![LOG[{0}]LOG]!><time=`"{1}`" date=`"{2}`" component=`"{3}`" context=`"{4}`" type=`"{5}`" thread=`"{6}`" file=`"{7}`">" -f $LogMessage, $TimeCmtrace, $DateCmtrace, $Component, [string]::Empty, "$TypeNumeric", "$PID" , $Location
            #$PlainFormatLog = "{0} {1} {2} ♥ {3} ♥ {4} ▬ {5}" -f $DatePlain, $TimePlain, $TypePlain, $LogMessage, $Component, $Location
            $FileStream = [System.IO.FileStream]::new($LogFile, 'Append', 'Write', 'Read')
            $LogStream = [System.IO.StreamWriter]::new($FileStream)
            $LogStream.WriteLine($CmtraceFormatLog)
            $LogStream.Flush()
        }
        Catch
        {
            Write-Host "Could not write to log file. Exception: $($_.Exception.Message)" -ForegroundColor Red
            Write-MetaPlog -Exception $_ -Message "Could not write to log file."
        }
        Finally
        {
            $LogStream.Close()
        }
    }
    End {}
}
function Write-MetaPlog
{
    param(
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.ErrorRecord] $Exception,
        [string] $Message
    )
    $Filename = "$Env:TEMP\Plogger\PloggErr.log"
    $Timestamp = Get-Date -f "yyyy-MM-dd HH:mm:ss"
    if ([string]::IsNullOrEmpty($Message))
    {
        "{0} ♥ {1}" -f $Timestamp, $($Exception.Exception.Message) | Out-File $Filename -Encoding utf8 -Append
    }
    else
    {
        "{0} ♥ {1} ♥ {2}" -f $Timestamp, $Message, $($Exception.Exception.Message) | Out-File $Filename -Encoding utf8 -Append
    }
}