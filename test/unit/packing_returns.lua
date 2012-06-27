function foo()
  return 5,"a", { "d" }
end

local r = { foo() }
print(r[2])