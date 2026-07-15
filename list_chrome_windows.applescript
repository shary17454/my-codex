set out to ""
tell application "System Events"
	tell process "Google Chrome"
		set i to 1
		repeat with w in (windows as list)
			try
				set out to out & i & ": " & (name of w) & " pos=" & (position of w as text) & " size=" & (size of w as text) & linefeed
			on error errMsg
				set out to out & i & ": error " & errMsg & linefeed
			end try
			set i to i + 1
		end repeat
	end tell
end tell
return out
