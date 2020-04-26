# StreamHelper

### A desktop notifier for Twitch and Mixer

![Screenshot #3](./Screenshot3.png?raw=true "Screenshot #3")
![Screenshot #4](./Screenshot4.png?raw=true "Screenshot #4")
![Screenshot #1](./Screenshot1.png?raw=true "Screenshot #1")
![Screenshot #5](./Screenshot5.png?raw=true "Screenshot #5")
![Screenshot #2](./Screenshot2.png?raw=true "Screenshot #2")

## Install

Download StreamHelper from the [Microsoft Store](https://www.microsoft.com/store/apps/9P776V8N7B5B) or [GitHub](https://github.com/TzarAlkex/StreamHelper/releases/latest)

## Description

Start the application then open the settings from the tray icon and login to the respective service from the tab with it's name.

All functionality is by the tray icon.
* Click a stream to play.
* Ctrl+click a stream to mark as favorite (shows notification when they go online or change game), Ctrl+click again to go back to normal.
* Shift+click a stream in the list to open it in the "Play from clipboard" window.

I highly recommend installing [Streamlink](https://streamlink.github.io/) to get the most use of StreamHelper. Description from their website:
> Streamlink is a command-line utility that pipes video streams from various services into a video player, such as VLC. The main purpose of Streamlink is to allow the user to avoid buggy and CPU heavy flash plugins but still be able to enjoy various streamed content.

Look at their [Streamlink - User guide](https://streamlink.github.io/#user-guide) for install help and how to configure it to use your video player. If using with Twitch, you may want to [authenticate Streamlink](https://streamlink.github.io/cli.html#authenticating-with-twitch).

If Streamlink is found on your computer, it will be used for playing and downloading streams. Using the "Play from clipboard" functionality, you can use StreamHelper to launch streams or download from sites supported by Streamlink (YMMV, see [Streamlink - Plugins](https://streamlink.github.io/plugin_matrix.html)).

If Streamlink is not found streams will open in your browser. Downloading is not available without Streamlink.

Twitch and Hitbox (now Smashcast) API's were largely implemented by glancing at the python-twitch and Hitboxy python libs.

## Compile or Run from source

1. Install AutoIt v3 (and optionally SciTE4AutoIt3 for the best experience) from http://autoitscript.com/
2. Set your own client-ids and redirect-uri in APIStuff.au3 and /docs/login/index.html
3. Open "StreamHelper.au3" in SciTE and click Tools > Compile or Go

## Credits

Made by Alexander Samuelsson

### Uses code from

Ward - https://www.autoitscript.com/forum/topic/148114-jsmn-a-non-strict-json-udf/

trancexx - https://www.autoitscript.com/forum/topic/84133-winhttp-functions/

KaFu - https://www.autoitscript.com/forum/topic/95850-url-encoding/?do=findComment&comment=689045

Mat - https://www.autoitscript.com/forum/topic/115222-set-the-tray-icon-as-a-hicon/

SmOke_N - https://www.autoitscript.com/forum/topic/95383-sorting-numbers/?do=findComment&comment=685701

jchd - https://www.autoitscript.com/forum/topic/195291-datetime-conversion-issue/?do=findComment&comment=1400353