-- grind.add_delimiter([==[(\d{2}:\d{2}:\d{2})]==])

grind.define_group("elementum", 11144)
grind.define_delimiter("elementum", [==[(\d{2}:\d{2}:\d{2})]==])
grind.define_format("elementum", "default", [==[(\[[A-Z]\])\s{1}([A-Za-z]+):\s{1}(.*)]==])
grind.define_extractor("elementum", "default",
  function(context, module, content, timestamp)
    print("\tContext: " .. context)
    print("\tModule: " .. module)
    print("\tMessage: " .. content)

    return { 
      timestamp = timestamp,
      context = context,
      module = module
    }, content
  end
)