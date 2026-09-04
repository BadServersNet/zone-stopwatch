# Zone Stopwatch

Zone Stopwatch is a SourceMod plugin for Counter-Strike: Global Offensive that lets a player create temporary start and end zones and time movement between them.

## Features

- Defines personal start and end zones from two corners selected in-game.
- Starts on zone entry or on jump and stops on end-zone entry or landing.
- Draws the configured zones in the world.
- Avoids running while a GOKZ or KZTimer timer is active.

## Installation

Download the latest release archive and extract it into the game server's `csgo` directory. The archive places the compiled plugin in `addons/sourcemod/plugins` and the source and bundled includes in `addons/sourcemod/scripting`.

GOKZ and KZTimer are optional. When either timer is installed and active for a player, Zone Stopwatch stays out of its way.

## Usage

Run `sm_ztopwatch` while alive to open the Zone Stopwatch menu. Use the menu to set both corners of the start zone and end zone, reset the zones, and choose whether timing starts on jump or stops on landing.

## Building

Compile `ztopwatch.sp` with SourceMod 1.10 and add `include` plus the GOKZ v3.6.4 include directory to the compiler's include search path. The release workflow retrieves the pinned GOKZ build dependencies automatically.

## Releases

Version tags follow Semantic Versioning. See [CHANGELOG.md](CHANGELOG.md) for the release history reconstructed from the original commit messages.

## License

This project is licensed under the GNU General Public License v3.0. See [LICENSE](LICENSE).
