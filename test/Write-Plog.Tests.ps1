$ModuleName = 'Plogger'
Import-Module "$(Resolve-path "$PSScriptRoot\..\src")\$ModuleName.psd1" -Force
$PredeterminedLogPath = "$ENV:TEMP\Plogger\$(get-date -f 'yyyy-MM-dd').log"
Describe 'Write-Log' {
    It 'Given no LogFile parameter log file should be created at predetermined location' {
        Write-Plog -EntryType Information -Message "no log parameter"
        Test-Path $PredeterminedLogPath | Should -Be $true
    }
    It 'Given Exception parameter as a string, that string should be logged into file' {
        Write-Plog -EntryType Information -Message "no log parameter" -Exception "Exception as a string"
        $LastLineContent = Get-Content -Path $PredeterminedLogPath -Tail 1
        $LastLineContent | Should -Match "Exception as a string"
    }
    It "Given Exception parameter as an error object it's exception message should be logged into file" {
        $ErrorOjbect = try {1 / 0}catch {$_}
        Write-Plog -EntryType Error -Message "Testin error boject" -Exception $ErrorOjbect
        $LastLineContent = Get-Content -Path $PredeterminedLogPath -Tail 1
        $LastLineContent | Should -Match "Attempted to divide by zero."
    }
    It "Given parameter -LogFile was provided log file should be created at specified destination" {
        $LogFile = "$ENV:TEMP\Plogger\LogFileParam\$(get-date -f 'yyyy-MM-dd').log"
        Write-Plog -EntryType Error -LogFile $LogFile -Message "Log File at specified location"
        Test-Path $LogFile | Should -Be $true
    }
}