local matchers = {
  { rex = create_regex([[Added resource location]]), type = "rloc" },
  { rex = create_regex([[Parsing scripts for resource group]]), type = "group" },
  { rex = create_regex([[Parsing script]]), type = "script" },
  { rex = create_regex([[^Texture:]]), type = "texture" },
  { rex = create_regex([[^Font .*texture size]]), type = "font" },
  { rex = create_regex([[^Mesh: ]]), type = "mesh" }
}
grind.define_klass("OGRE", { "default" }, "resources", function(entry, klass_ctx)
  for test in ilist(matchers) do
    if rex_pcre.match(entry.body, test.rex) ~= nil then
      klass_ctx.resource_type = test.type
      return true
    end
  end

  return false
end)
