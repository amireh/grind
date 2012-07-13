-- grind.add_delimiter([==[(\d{2}:\d{2}:\d{2}):\s{1}]==])
grind.define_group("OGRE", 11145)
grind.define_delimiter("OGRE", [==[(\d{2}:\d{2}:\d{2}):\s{1}]==])
grind.define_format("OGRE", [==[(\w+:\s{1})?(.*)]==])
grind.define_extractor("OGRE", 
  function(module, content, timestamp)
    -- print("\tModule: " .. module)
    -- print("\tMessage: " .. content)

    return { 
      timestamp = timestamp,
      module = (module or "N/A")
    }, content
  end
)