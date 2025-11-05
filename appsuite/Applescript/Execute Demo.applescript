-- 1) Choose Host
set d1 to display dialog "Enter Host address:" default answer "eu.appsuite.cloud" buttons {"Cancel", "Continue"} default button "Continue"
if button returned of d1 is "Cancel" then error number -128
set selectedHost to text returned of d1

-- 2) Enter Email
set d2 to display dialog "Enter Email address:" default answer "" buttons {"Cancel", "Continue"} default button "Continue"
if button returned of d2 is "Cancel" then error number -128
set email to text returned of d2

-- 3) Enter password
set d3 to display dialog "Enter password:" default answer "" buttons {"Cancel", "Start"} default button "Start"
if button returned of d3 is "Cancel" then error number -128
set selectedPassword to text returned of d3

-- 4) Execute CLI
set mePath to POSIX path of ((path to me) as text)
set baseDir to do shell script "/usr/bin/dirname " & quoted form of mePath

set home to POSIX path of (path to home folder)
set tool to home & ".local/bin/appsuite"


-- echo "Importing Emails"
set accountsPath to baseDir & "/GoldAccounts/chris.davis"
set importMails to quoted form of tool & " import mails --server " & quoted form of selectedHost & " --name " & quoted form of email & " --password " & quoted form of selectedPassword & " --importFolderTree --source " & quoted form of accountsPath & " --adjustRecipient true --stretchPeriod 180"

-- echo "Importing Taks"
set tasksPath to baseDir & "/tasks.json"
set importTasks to quoted form of tool & " import tasks --server " & quoted form of selectedHost & " --name " & quoted form of email & " --password " & quoted form of selectedPassword & " --source " & quoted form of tasksPath

-- echo "Importing Files"
set testFilesPath to baseDir & "/testfiles/"
set importFiles to quoted form of tool & " import files --server " & quoted form of selectedHost & " --name " & quoted form of email & " --password " & quoted form of selectedPassword & " --source " & quoted form of testFilesPath

-- echo "Generating Contacts"
set contactTemplatesPath to baseDir & "/contactTemplates.json"
set generateContacts to quoted form of tool & " generate contacts --server " & quoted form of selectedHost & " --name " & quoted form of email & " --password " & quoted form of selectedPassword & " --source " & quoted form of contactTemplatesPath & " --numberOfContacts 30"

-- echo "Generating Appointments"
set appointmentTemplatesPath to baseDir & "/appointmentTemplates.json"
set generateAppointments to quoted form of tool & " generate appointments --server " & quoted form of selectedHost & " --name " & quoted form of email & " --password " & quoted form of selectedPassword & " --source " & quoted form of appointmentTemplatesPath & " --days 180"

set jobs to {{name:"Import Mails", job:importMails}, {name:"Import Tasks", job:importTasks}, {name:"Import Files", job:importFiles}, {name:"Generate Contacts", job:generateContacts}, {name:"Generate Appointments", job:generateAppointments}}

set results to {}

set progressCompleted to 0
-- Execute
with timeout of 600 seconds
	delay 0.05 -- Unfortunately necessary for UI updates.
	set progress total steps to count of jobs
	set progress completed steps to progressCompleted
	set progress description to "Filling Demo Account"
	repeat with j in jobs
		try
			delay 0.05 -- Unfortunately necessary for UI updates.
			
			set progress additional description to (name of j)
			set progressCompleted to (progressCompleted + 1)
			set progress completed steps to progressCompleted
			
			delay 0.05 -- Unfortunately necessary for UI updates.
			
			set out to do shell script (job of j)
			set end of results to out
			
		on error errText number errNum
			-- Display error
			display dialog "Error (" & errNum & "): " & errText buttons {"OK"} default button "OK" with icon stop with title "Error"
			exit repeat
		end try
	end repeat
end timeout

set AppleScript's text item delimiters to linefeed
display dialog (results as text) buttons {"OK"} default button 1 with title "Result"
set AppleScript's text item delimiters to ""

