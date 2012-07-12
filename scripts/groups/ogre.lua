grind.define_group("OGRE", { exclusive = true })
grind.define_format("OGRE", [==[(\w+:\s{1})?(.*)]==])
grind.define_extractor("OGRE", 
  function(timestamp, module, content)
    -- print("\tModule: " .. module)
    -- print("\tMessage: " .. content)

    return { 
      module = (module or "N/A")
    }, content
  end
)