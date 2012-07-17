-- grind.add_delimiter([==[(\d{2}:\d{2}:\d{2}):\s{1}]==])
grind.define_group("OGRE", 11145)
grind.define_delimiter("OGRE", [==[(\d{2}:\d{2}:\d{2}):\s{1}]==])
grind.define_format("OGRE", "default", [==[(\w+:\s{1})?(.*)]==])
grind.define_extractor("OGRE", "default",
  function(module, content, timestamp)
    -- print("\tModule: " .. module)
    -- print("\tMessage: " .. content)

    return { 
      timestamp = timestamp,
      module = module
    }, content
  end
)