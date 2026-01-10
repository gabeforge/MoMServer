// MoM Server Bootstrap Script
// This script runs from /server/ and redirects to the game directory

// Get the game root from command line
$gameRoot = "minions.of.mirth";

// Set up the mod paths to point to the game directory
setModPaths($gameRoot);

// Load the actual server main script
echo("Bootstrap: Loading game from" SPC $gameRoot);
exec($gameRoot @ "/main.cs");
