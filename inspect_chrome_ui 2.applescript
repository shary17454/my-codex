property outputText : ""

on walkElement(e, p, depth)
	if depth > 12 then return
	tell application "System Events"
		try
			set r to role of e
		on error
			set r to "?"
		end try
		try
			set n to name of e
		on error
			set n to ""
		end try
		try
			set v to value of e
		on error
			set v to ""
		end try
		if depth < 6 or r contains "Radio" or r contains "Button" then
			set outputText to outputText & p & " role=" & r & " name=" & n & " value=" & v & linefeed
		end if
		try
			set kids to UI elements of e
			set i to 1
			repeat with kid in kids
				my walkElement(kid, p & "." & i, depth + 1)
				set i to i + 1
			end repeat
		end try
	end tell
end walkElement

tell application "System Events"
	tell process "Google Chrome"
		set w to item 4 of (windows as list)
		my walkElement(w, "window1", 0)
	end tell
end tell

return outputText
