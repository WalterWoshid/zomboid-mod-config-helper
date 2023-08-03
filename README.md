# Easy Server Mod Configuration PowerShell Script

Hello fellow Zomboiders,

if you're like me and mod a lot, but also play with a friend / friends you probably know the pain about setting up the server mods.

I created an easy to use PowerShell script to make those steps easier.

First you need the `Mod Manager` Mod: https://steamcommunity.com/sharedfiles/filedetails/?id=2694448564

There is, of course, a `Mod Manager: Server` Mod, but I've read that sometimes it breaks the server and this is a pretty safe way to do it, if you're manually hosting a dedicated Zomboid server.

1. Create a Preset in the Mod Manager and remember the preset name:
![image](https://github.com/WalterWoshid/zomboid-mod-config-helper/assets/36635504/7db9c184-a926-4456-bcd8-e3626db7f789)

2. Download the script and place it anywhere: [ZomboidModConfigHelper.ps1](/ZomboidModConfigHelper.ps1)

If you don't trust the script, either check the code yourself or paste it into ChatGPT and ask him if it is safe :)

3. Run the script with `Right Click/Run with PowerShell`

4. Follow the instructions from the script

5. Once you entered all values, you should receive 3 lists in blue
![image](https://github.com/WalterWoshid/zomboid-mod-config-helper/assets/36635504/0774a6ac-c8a2-47de-bb43-4cdc7167f392)

6. Open your server ini configuration file in any text editor, e. g. `C:\Users\YOURNAME\Zomboid\Server\YOUR_CONFIGURATION.ini`

7. Add the mod IDs from the lists to the `Mods=` section

8. Add the workshop IDs from the lists to the `WorkshopItems=` section

9. Add the maps from the lists to the `Map=` section

10. Running the script again will remember your previous entered values


Have fun!
