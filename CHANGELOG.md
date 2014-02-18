##0.1.5

Bugfixes
- Harvest/Provisioning data is now being collected when the player has Auto Loot enabled.

Features
- ``EH.lastTarget`` has been added to provide the name of the last NPC/Object the player had their reticle over _before_ any interaction commands are fired. This is useful, for example, in having the name of the harvest node available immediately after the harvest is complete (when EVENT_LOOT_RECEIVED is fired on auto-loot), even if the player's reticle wanders around and targets other things while they're harvesting.
- A new function ``EH.IsValidNode`` has been added to support an additional table of game data generated in our EsoheadConstants.lua file. This function can be used to pass the name of an interactable object and determine if it's a valid harvesting node (includes provisioning nodes).

##0.1.4

Bugfixes
- Added an additional check to ensure a material is a provisioning-type before logging it
- Unexpectedly empty fields should no longer be stored

Features
- Improved the reliability of the ``EH.currentTarget`` variable
- Narrowed the distance a player needs to be from a previously logged data point in order to log a nearby point from 1% map size to 0.5%

##0.1.3

Bugfixes
- Fixed a bug where looting a tradeskill material from an enemy counted as a harvest node

Features
- The addon is now called "Esohead" rather than "Esohead Looter"
- Saved variables for each data type are now independently versioned from eachother. This allows us to change the format data is collected and force the client to clear out the old version's obsolete data.
- Provisioning materials are now logged differently from materials of other tradeskills.

##0.1.2

Bugfixes
- Harvest data is no longer collected when a player opens a container in their inventory with tradeskill materials (such as from a hireling).

##0.1.1

Features
- Complete refactor of the addon, it is no longer a ZO_CallbackObject
- ``EH.ItemLinkParse`` has been added to parse in-game item links for ingesting key parts of the string.
- Harvesting data is now supported by ``EsoheadConstants.lua``, which helps associate a material gathered with a parent tradeskill as the in-game API does not provide that relationship.
- An additional ``/reload`` alias has been added to support the current alias of ``/rl`` for the in-game command ``/reloadui``