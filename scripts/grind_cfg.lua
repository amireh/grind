grind = grind or {}

grind.config.delimiters = {
  [[(?:<\d+>)([A-Z]{1}[a-z]{2}\s+[0-9]+\s+[0-9]{2}:[0-9]{2}:[0-9]{2}\s{1})]] -- syslog
  , [[(\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2}:\d{2}\s{1})]] -- dakwak
  , [==[(\d{2}:\d{2}:\d{2}):\s{1}]==] -- OGRE
  , [==[(\d{2}:\d{2}:\d{2})]==] -- Elementum
}