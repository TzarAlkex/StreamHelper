# StreamHelper

![Screenshot #1](https://raw.githubusercontent.com/TzarAlkex/StreamHelper/master/Screenshot1.png "Screenshot #1")
![Screenshot #2](https://raw.githubusercontent.com/TzarAlkex/StreamHelper/master/Screenshot2.png "Screenshot #2")
![Screenshot #3](https://raw.githubusercontent.com/TzarAlkex/StreamHelper/master/Screenshot3.png "Screenshot #3")
![Screenshot #4](https://raw.githubusercontent.com/TzarAlkex/StreamHelper/master/Screenshot4.png "Screenshot #4")

A desktop notifier for Twitch, Mixer and Smashcast.

Simply add your username in the settings for the respective service, click "Get ID", and it will start looking for streams from the people you follow (also followed games on Twitch).

All functionality is by the tray icon.
* Click a stream to play.
* Ctrl+click a stream to mark as favorite (plays extra "alarm" sound so it's harder to miss), click again to mark as ignore (no notification), click again to go back to normal.
* Shift+click a stream in the list to open it in the "Play from clipboard" window.

I highly recommend installing [Streamlink](https://streamlink.github.io/) to get the most use of Streamhelper. Description from their website:
> Streamlink is a command-line utility that pipes video streams from various services into a video player, such as VLC. The main purpose of Streamlink is to allow the user to avoid buggy and CPU heavy flash plugins but still be able to enjoy various streamed content.

Look at their [Streamlink - User guide](https://streamlink.github.io/#user-guide) for install help and how to configure it to use your video player. If using with Twitch, you may want to [authenticate Streamlink](https://streamlink.github.io/cli.html#authenticating-with-twitch).

If Streamlink is found on your computer, it will be used for playing and downloading streams. Using the "Play from clipboard" functionality, you can use Streamhelper to launch streams or download from any sites supported by Streamlink (YMMV, I have only tested a few of the ~180 or so sites listed by [Streamlink - Plugins](https://streamlink.github.io/plugin_matrix.html) as supported).

If Streamlink is not found streams will open in your browser. Downloading is not available without Streamlink.

Needless to say, I highly recommend installing Streamlink so you get the best usage from this.

Twitch and Hitbox (now Smashcast) API's were largely implemented by glancing at the python-twitch and Hitboxy python libs.