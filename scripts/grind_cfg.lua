grind = grind or {}

grind.config.delimiters = {
  [[(?:<\d+>)([A-Z]{1}[a-z]{2}\s+[0-9]+\s+[0-9]{2}:[0-9]{2}:[0-9]{2}\s{1})]] -- syslog
  , [==[(\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2}:\d{2}\s{1})]==] -- dakwak
  , [==[([\w|\.|-]+):(\d+)\s([\d|\.]+,\s[\d|\.]+)\s([A-Z]{1}-\w+)\s-\s-\s\[(\d{1,2}/\w{3}/\d{4}:\d{2}:\d{2}:\d{2}\s\+\d{4})\]]==] -- dakwak apache
  , [==[([\w\.]+)\s-\s-\s\[(.*)\]\s]==] -- apache with ip prefix
  -- , [==[\[(\w{3}\s\w{3}\s\d+\s\d{2}:\d{2}:\d{2}\s\d+)\]\s]==] -- apache error log
  , [==[(\d{2}:\d{2}:\d{2}):\s{1}]==] -- OGRE
  -- , [==[(\d{2}:\d{2}:\d{2})]==] -- Elementum
}