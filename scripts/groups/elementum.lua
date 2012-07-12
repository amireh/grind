grind.define_group("elementum", { exclusive = true })
grind.define_format("elementum", [==[(\[[A-Z]\])\s{1}([A-Za-z]+):\s{1}(.*)]==])
grind.define_extractor("elementum", 
  function(timestamp, context, module, content)
    print("\tContext: " .. context)
    print("\tModule: " .. module)
    print("\tMessage: " .. content)

    return { 
      context = context,
      module = module
    }, content
  end
)