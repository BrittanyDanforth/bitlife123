--[[
	Catalog Module
	Contains all game catalogs: Jobs, Education, Activities, Properties, Vehicles, Items, etc.
	
	This centralizes all catalog data so events, screens, and backend all use the same source.
]]

local Catalog = {}

-- Will be populated by sub-modules
Catalog.Jobs = {}
Catalog.Education = {}
Catalog.Activities = {}
Catalog.Properties = {}
Catalog.Vehicles = {}
Catalog.Items = {}
Catalog.Crimes = {}
Catalog.StoryPaths = {}

return Catalog
