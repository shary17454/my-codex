on clickDeleteIn(elementRef)
	tell application "System Events"
		try
			set elementName to name of elementRef
		on error
			set elementName to ""
		end try
		try
			set elementRole to role of elementRef
		on error
			set elementRole to ""
		end try
		if elementName is "Delete" and elementRole is "AXButton" then
			click elementRef
			return true
		end if
		try
			set childElements to UI elements of elementRef
			repeat with childElement in childElements
				if my clickDeleteIn(childElement) then return true
			end repeat
		end try
	end tell
	return false
end clickDeleteIn

tell application "Google Chrome" to activate
tell application "System Events"
	tell process "Google Chrome"
		set frontmost to true
		if my clickDeleteIn(window 1) then
			return "clicked"
		else
			return "not found"
		end if
	end tell
end tell
