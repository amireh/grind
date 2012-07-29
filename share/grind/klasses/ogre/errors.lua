local error_matchers = {
  { rex = create_regex([[Compiler error: ]]), type = "compiler" },
  { rex = create_regex([[OGRE EXCEPTION]]), type = "exception" },
  { rex = create_regex([[Can't assign material]]), type = "material" },
  { rex = create_regex([[Bad element attribute]]), type = "bad_attribute" }
}
grind.define_klass("OGRE", { "default" }, "errors", function(fmt, entry, klass_ctx)
  for test in ilist(error_matchers) do
    if rex_pcre.match(entry.body, test.rex) ~= nil then
      klass_ctx.error_type = test.type
      return true
    end
  end

  return false
end)
