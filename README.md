# TetrisEffectArchipelago
Archipelago randomizer client mod for Tetris Effect: Connected.

If you're looking for releases and apworld/setup documentation, please visit the [AP World repository](https://github.com/ZatchyBeeps/Archipelago-TEC)

## Contributing
It is possible to contribute to this mod. To do so:
- Have UE4SS installed. Remember you still need the [experimental release](https://github.com/UE4SS-RE/RE-UE4SS/releases/tag/experimental-latest). It is recommend that you use the zDEV version to view logs during playtime easily apart of other tools.
- Create a new folder in ue4ss/Mods for the mod. You can call it whatever you want, I simply named mine TetrisEffectArchipelago
- Fork this repository.
- Clone the repository to the folder you created.
- Grab the .pak file on Scripts/BModManager and put it in `Tetris Effect Connected\TetrisEffect\Content\Paks\LogicMods` (if the LogicMods folder doesn't exist, create it).
- Enable both the mod and BPModLoaderMod in the ue4ss/Mods/mods.txt file
- Do all changes that you wanna do.
- If you wanna do changes to the UI, you will need to request for these changes as they are managed by the blueprint mod. See the files in the BModManager folder for things that said blueprint mod has.
- Once done, create a new pull request from your forked repository to this one and I will review it when possible.
If you would like to use annotations go to the ue4ss developer tools window while in-game, click Dumpers then click Generate Lua Types.
If you wanna test things without connecting to a server, use the previously mentioned window, go to Lua Debugger, click on `TetrisEffectArchipelago [main]` (name will change depending on how you called the folder), then go to REPL and type `debug_GiveAll()`

(AI usage is strictly prohibited. If found using it, your pull request will be declined and you'll be blacklisted from contributing)
