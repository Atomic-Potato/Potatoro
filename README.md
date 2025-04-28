<p align="center">
  <img src="https://github.com/user-attachments/assets/c8a9db4f-cb94-4d17-94e9-f3f8b6219374" alt="First" width="256" /><br>
  <b>pomodoro but we hatin' on them tomatoez<b><br>
</p>
<p>
made with<br>
<img src="https://github.com/user-attachments/assets/e5cc0bce-44f7-4ef4-92e3-458be8c4de86" alt="Second" width="256" />
</p>

# what is potatoro?
<table align="center" border="0" cellspacing="0" cellpadding="0">
  <tr>
    <td valign="top">
      <img
        src="https://github.com/user-attachments/assets/c31cdf16-cf1a-4f03-8600-de2c4e5e2926"
        alt="Left graphic"
        width="150"
      />
    </td>
    <td valign="top" width="500">
      The focus of potatoro is making a pomodoro timer that does not treat you like a child with ADHD (no offense to anyone). It allows you to be flexible with controlling your sessions. For example, need a couple more minutes? go ahead add some time. These last 2 minutes taking too long? skip it fam.  
      The theme is quite customizable, so if u wanna make it purely a solid color and u cant even read text anymore, u can and ain’t no one judgin’. And even if it wasn’t customizable enough, make it your problem and download the sauce code, …or send me some feet pics and i may consider adding what u want.  
      Of course there will be more features in the future… well just session tags and some juicy statistics, more on them in [FUTURE FEATURES](#features-to-come).  
      idk where to put this but i wanna brag, and u cant stop me, about the app calculating how much time has passed if a timer is running and the app was closed or crashed… because a lot of times i restart my computer and forget that i had a timer running.
    </td>
    <td valign="top">
      <img
        src="https://github.com/user-attachments/assets/2c3d6bed-0cf8-4f59-84b0-1099067e318a"
        alt="Right graphic"
        width="150"
      />
    </td>
  </tr>
</table>


# contents
- [installation](#installation)
  - [windows](#windows)
  - [linux](#linux)
- [manual](#how-to-use-manual)
  - [presets and timers](#presets-and-timers)
    - [creating a preset](#creating-a-preset)
    - [session setup](#session-setup)
    - [running session](#running-session)
    - [break setup](#break-setup)
    - [running break](#running-break)
  - [settings](#settings)
    - [default values](#default-values)
    - [timer settings](#timer-settings)
    - [sound settings](#sound-settings)
    - [theme](#theme)
    - [user interface](#user-interface)
- [querying statistics from database](#querying-statistics-from-database-and-other-queries)
- [changing the source code](#changing-the-source-code)
- [features to come](#features-to-come)
- [known issues](#known-issues)
- [contact me](#contact-me-for-help-feature-request-or-bug-report)

# installation
Head to the [releases](https://github.com/Atomic-Potato/Potatoro/releases) page and find the version u desire
## windows
You have 2 options:
- `potatoro_windows_setup.exe` setup file to automate the installation for you. Simply download and run the file
- `potatoro_windows_portable.zip` a portable file, you can simply extract this anywhere you like and run the `.exe`. NOTE: your data is not portable, it is found in the `appdata` (check app settings)
 
## linux
You have 2 options:
- `potatoro_linux_setup.run` setup file which can be run directly, if it is not installed, do `chmod +x` for the file in the terminal and try running it again
- `potatoro_linux_portable.zip` a portable file, you can simply extract this anywhere you like and run the `.x86_64`. NOTE: your data is not portable, it is found in the `.local/share/godot/app_userdata/Potatoro` (check app settings)

# how to use (manual)
im gonna pretend you know what is a pomodoro here and skip the obvious stuff

## presets and timers
Just some presets maybe for different days of the week or whatever you want. 
You can run different presets at the same time, and if a preset is already running you can restart it by clicking on the loop arrow at the top left the preset card in the presets page

### creating a preset
Clicking on "Create new preset" opens the form filled with the default values set in the [settings](#default-values).
- `[enter-preset-name]`: Theres no restrection on the preset name other than you have not created one with the same name
- `session count`: This is your sessions goal, it has no real effect, but u can set it to 0 so it would change to infinity icon 
- `session length`: in minutes
- `break length`: in minutes
- `Auto start break`: when the session ends, the break will start instead of being prompted to stop the notification
- `Auto start session`: when the break ends, the next session will start instead of being prompted to stop the notification
- `START button`: If editing an exisiting preset, it will start with the first session else it will save the preset first
- `SAVE button`: Updates / saves the preset
- `DELETE button`: Deletes exisiting presets / clears input to default 

### session setup
This page allows you to modify upcoming timers values before they start
- `current session length`: Changes the length just for this session and retunrs to default in the next session
- `next break length`: if "auto start next break" you can change the next break length since it will start automatically (returns to length set in preset for subsequent breaks) 
- `auto start next break`: starts break automatically after the current session, and enables `next break length` input
- `RESET button`: restores the values set in the preset for `current session length` and `next break length` 

### running session
- `restart button`: restarts the session ignoring all the time done before the restart
- `skip`: skips to the end session screen (even if `auto start next break` is enabled) and marks the end of the session in the database 
- `auto start next break`: if enabled, when the timer ends the next break automatically starts (no notification, i probably should but eh)
- The hour shown above the timer is when the timer will end in your local time

### break setup
This page allows you to modify upcoming timers values before they start
- `current break length`: Changes the length just for this break and retunrs to default in the next break
- `next session length`: if "auto start next session" you can change the next session length since it will start automatically (returns to length set in preset for subsequent sessions) 
- `auto start next session`: starts session automatically after the current break, and enables `next session length` input
- `RESET button`: restores the values set in the preset for `current break length` and `next session length` 

### running break
- `skip`: skips to the end break screen (even if `auto start next session` is enabled)
- `auto start next session`: if enabled, when the timer ends the next session automatically starts (no notification, i probably should but eh)
- The hour shown above the timer is when the timer will end in your local time

## settings
### default values
Changes the default values when creating a new preset. idk why i made it, but it is there

### timer settings
- `Use 12-hour format`: if an hour is indicated somewhere, it will be in a.m. p.m. format. Currently only found above timers to indicate the timer end time
- `Hide session time change controls:` simply hides the controls under the running session timer 
- `Hide break time change controls:` simply hides the controls under the running break timer

### sound settings
This section allows you to change the notification sound and its volume.
Just open the audio files directory using the button ive put there for you, and place your audio files there. (The only supported audio formats are .mp3, .wav, .ogg using anything else will use the default sound)
To use the default notification again just hit the `CLEAR` button

### theme
Here change the colors of the app to your liking.
Fingers crossed the app doesnt crash if you hit apply theme, i dont think it will but it takes some time to change it so the app freezes.
The experimental title bar doesnt work well on windows, and still misses loads of features like resizing the window.

### user interface
You can change the UI scale here (the UI gets a bit blurry if its not 1, idk why so [hit me up](#contact-me-for-help-feature-request-or-bug-report) if u know how to fix it) or change to a custom font file 

# querying statistics from database (and other queries)
Before querying your database you need an app to open the SQLite database first. I personally used [DB Browser](https://sqlitebrowser.org/) its simple and gets the job done.
Now go to the settings, in the info section, open the database directory to find your `potatoro.db` and open it with DB Browser.
if your at this point, i dont think you need me to tell you how DB Browser works. So here are some queries you can run to get some statistics, and the last query is for restoring your default settings from outside the app in case you need it:

```sql
-- These queries are basically 2, but you switch out the where statement depending on the date you want. 
-- (im assuming u know some SQL, plus SQL is quite easy to read so u should be fine big boy ;])
-- NOTE: some queries require a date and time input, so be sure to change that

-- QUERY FOR SUMMARY (total sessions, total minutes)
select count(*) as 'Total Sessions',
	sum(
		(select (unixepoch(s2.EndDateTime) - unixepoch(s2.StartDateTime)) as 'SessionLength'
			from Sessions s2 
			where ID = s.ID)
		- 
		coalesce((select sum(unixepoch(sp.EndDateTime) - unixepoch(sp.StartDateTime)) as 'BreaksSum'
			from SessionPauses as sp
			where SessionID = s.ID), 0)
	)/60 as 'Length (minutes)'
from Sessions s
-- [ADD WHERE STATEMENT HERE]


-- QUERY FOR DETAILS (ID, Start, End, Length in minutes)
select ID,
	StartDateTime as 'Start', 
	EndDateTime as 'End',
	(
		(select (unixepoch(s2.EndDateTime) - unixepoch(s2.StartDateTime)) as 'SessionLength'
			from Sessions s2 
			where ID = s.ID)
		- 
		coalesce((select sum(unixepoch(sp.EndDateTime) - unixepoch(sp.StartDateTime)) as 'BreaksSum'
			from SessionPauses as sp
			where SessionID = s.ID), 0)
	)/60 as 'Length (minutes)'
from Sessions s
-- [ADD WHERE STATEMENT HERE]

-- WHERE STATEMENTS:
-- for today
where date(s.StartDateTime) = date('now', 'localtime')

-- for a specific day
where date(s.StartDateTime) = date('yyyy-mm-dd')

-- for a specific month
where strftime('%Y-%m' s.StartDateTime) = 'yyyy-mm'

-- for a specific year
where strftime('%Y' s.StartDateTime) = 'yyyy'

-- between two days
where date(s.StartDateTime) between date('yyyy-mm-dd') and date('yyyy-mm-dd')

```

To restore the app default settings, run this query (set a smaller resolution if needed in the last row):
```sql
delete from Settings;
insert into Settings values
(0, 1, 'SessionsCount', '8'),
(1, , 'SessionLength', '50'),
(2, , 'BreakLength', '5'),
(3, , 'IsUse12HourFormat', '0'),
(4, , 'HideSessionTimerTimeChangeButtons', '0'),
(5, , 'HideBreakTimerTimeChangeButtons', '0'),
(6, , 'PathSessionEndNotification', ''),
(7, , 'PathBreakEndNotification', ''),
(8, , 'VolumeSessionEndNotification', '1.0'),
(9, , 'VolumeBreakEndNotification', '1.0'),
(10, , 'BackgroundPrimaryColor', '000000'),
(11, , 'PrimaryColor', 'ffffff'),
(12, , 'SecondaryColor', '000000'),
(13, , 'ThirdColor', '7f7f7f'),
(14, , 'DangerPrimaryColor', 'ff0000'),
(15, , 'DangerSecondaryColor', '000000'),
(16, , 'IsUseCustomTitleBar', '1'),
(17, , 'TitleBarPrimaryColor', 'ffffff'),
(18, , 'TitleBarSecondaryColor', '000000'),
(19, , 'UIScale', '1'),
(20, , 'PathFontFile', ''),
(21, , 'WindowResolution', '[800,820]');
```
# changing the source code
1. clone the repository to a folder on your computer or download it as a zip and extract it
2. Install the standard [Godot 4.2.1](https://godotengine.org/download/archive/4.2.1-stable/)
3. Open godot and add the colned folder to your godot projects
... the horros youre gonna witness

And to sorta help you out, i have made a diagram of how data is changing in the database from state to state  
<p align="center">
 <img src="https://github.com/user-attachments/assets/c3483fb5-9007-4485-829b-f4185124af19"/>
</p>

# features to come
- Android support
- Theme presets
- Tags and statistics. Heres some concept images of what they might look like 

![Drawing 2025-04-27 19 06 07 excalidraw](https://github.com/user-attachments/assets/9d975818-1bf2-4bb6-878b-cdad6772d7fc)

> [!Important]
> Just to note, i will be putting this project on hold for these big features
> 
> since i have put around 200 hours into this project
>
> and i wanna make some games WAAAA. 
>
> But of course if u still want some bugs fixed or other small things, u can contact me and ill do what i can

# known issues
- Desktop notifications, i could not find an OFFLINE way in godot to do this
- UI scaling other than default blurs the interface, havent looked into it much yet
- The slow ahh algorithm for changing the theme
- UI just sucks when resizing the window
- The experimental title bar on windows 

# contact me (for help, feature request, or bug report)
In case you need any of what is mentioned in the title. Heres some ways you could contact me:
- My discord username: atomic\_potato\_32
- My discrod server: [https://discord.gg/JUJKZxp](https://discord.gg/JUJKZxp)
- My email: atomicpotatogames32@gmail.com










