 -- syslog
-- grind.add_delimiter([[(?:<\d+>)([A-Z]{1}[a-z]{2}\s+[0-9]+\s+[0-9]{2}:[0-9]{2}:[0-9]{2}\s{1})]])
-- standalone log
-- grind.add_delimiter([[(\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2}:\d{2}\s{1})]])

grind.define_group("dakwak", 11153)
grind.define_delimiter("dakwak", [[([a-zA-Z]{3} \d{2} \d{2}:\d{2}:\d{2}) (\w+) (\w+): ]])

grind.define_format("dakwak", "requests", [[(\[\w{1}\])(?: )?\s+?(?:{([\w|-]+)}\s+)?(?|([\S]+):\s+((?sm).*)|()(.*))]])
grind.define_extractor("dakwak", "requests",
  { "context", "uuid", "module", "content", "timestamp", "fqdn", "app" })

grind.define_format("dakwak", "apache", [[([\w|.]+) ([\d|.]+) (\S+) \[\d{2}/\w{3}/\d{4}:\d{2}:\d{2}:\d{2} \+\d{4}\] (\d+) (\d+) (\d+) (\d+) (\d+) (\d+) "([A-Z]+) (.*) (?:HTTP/(\d\.\d))" "(.*)" "(.*)"]])
grind.define_extractor("dakwak", "apache",
  { "vhost", 
    "client_ip", 
    "uuid", 
    "rc", 
    "resp_size", 
    "tt", 
    "ka", 
    "recv", 
    "sent", 
    "method", 
    "uri", 
    "version", 
    "referer", 
    "agent",
    "timestamp",
    "fqdn",
    "app"
  })

