on appIsRunning(appName)
    tell application "System Events" to (name of processes) contains appName
end appIsRunning

" https://gist.github.com/rpapallas/31dfdf0626d078a357fccd46cdf6eafd

on run {input, parameters}
	set myPath to POSIX path of input
	set q to "nvim " & quote & myPath & quote

	if appIsRunning("iTerm") or appIsRunning("iTerm2") then
		run script "
			on run {q}
				tell application \":Applications:iTerm.app\"
					activate
					try
						select first window
						set onlywindow to false
					on error
						create window with default profile
						select first window
						set onlywindow to true
					end try
					tell the first window
						if onlywindow is false then
							create tab with default profile
						end if
						tell current session to write text q
					end tell
				end tell
			end run
		" with parameters {q}
	else
		run script "
			on run {q}
				tell application \":Applications:iTerm.app\"
					activate
					try
						select first window
					on error
						create window with default profile
						select first window
					end try
					tell the first window
						tell current session to write text q
					end tell
				end tell
			end run
		" with parameters {q}
	end if

end run