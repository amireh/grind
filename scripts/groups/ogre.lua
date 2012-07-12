-- grind.add_delimiter([==[(\d{2}:\d{2}:\d{2}):\s{1}]==])
grind.define_group("OGRE", { exclusive = false })
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