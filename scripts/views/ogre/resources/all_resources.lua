local extractors = {
  group = create_regex([[Parsing scripts for resource group (.*)]]), 
  rloc = create_regex([[Added resource location '(.*)' of type '(.*)' to resource group '(.*)']]),
  script = create_regex([[Parsing script (.*)]]), 
  texture = create_regex([[^Texture: (.*): .*Internal format is (.*)]]), 
  font = create_regex([[^Font (.*)\s?using.* (\d+x\d+)]]), 
  mesh = create_regex([[^Mesh: Loading (.*)\.?]])
}

grind.define_view("OGRE", "resources", "all resources", 
  { "Resource Group", "Type", "Identifier", "Extra" },
  function(ctx, entry, kctx)

    local captures = { rex_pcre.find(entry.body, extractors[kctx.resource_type]) }

    if captures[1] == nil then
      return false
    end

    local out = {
      -- Timestamp = entry.meta.timestamp,
      ["Resource Group"] = kctx.rgroup,
      Type = nil,
      Identifier = nil,
      Extra = "N/A"
    }

    if kctx.resource_type == "group" then
      kctx.rgroup = captures[3]
      return false
    elseif kctx.resource_type == "rloc" then
      out["Identifier"] = captures[3]
      out["Type"] = captures[4]
      out["Resource Group"] = captures[5]
    elseif kctx.resource_type == "script" then
      out["Identifier"] = captures[3]
      out["Type"] = "Script"
    elseif kctx.resource_type == "texture" then
      out["Identifier"] = captures[3]
      out["Type"] = "Texture"
      out["Extra"] = "Internal format: " .. tostring(captures[4])
    elseif kctx.resource_type == "font" then
      out["Identifier"] = captures[3]
      out["Type"] = "Font"
      out["Extra"] = "Resolution: " .. tostring(captures[4])
    elseif kctx.resource_type == "mesh" then
      out["Identifier"] = captures[3]
      out["Type"] = "Mesh"
    end

    return true, out
  end)

--[[
-- Type: [ Script, Texture, Mesh, Font, FileSystem, Zip ]
-- Identifier: [ *.jpg|.pu|.mesh|...|/path/to/resource ]
-- Resource Group
-- Extra
Added resource location '../resources/media/models/gremlins/Max/Gremlin2/Mesh' of type 'FileSystem' to resource group 'Models'
Parsing scripts for resource group
Parsing script SuddenCraven.pu
Texture: sword_01.jpg: Loading 1 faces(PF_R8G8B8,512x1024x1) with 10 generated mipmaps from Image. Internal format is PF_X8R8G8B8,512x1024x1.
Font SdkTrays/Captionusing texture size 1024x512
Mesh: Loading arena_02.mesh.
]]