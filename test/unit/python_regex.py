import re
rex = re.compile('([A-Z]{1}[a-z]{2} [0-9]+ [0-9]{2}:[0-9]{2}:[0-9]{2} )+')
txt = """Jun 25 12:31:44 cornholio dakapi: [I] Channel[translations]: closing1
Jun 25 12:31:46 cornholio dakapi: [I] Channel[translations]: closing2
Jun 25 12:31:48 cornholio dakapi: [I] Channel[translations]: closing3
Jun 25 12:31:50 cornholio dakapi: [I] Channel[translations]: closing4
Jun 25 12:31:52 cornholio dakapi: [I] Channel[translations]: closing5"""

# print txt
i = 0
while i < 1000000:
  rex.match(txt)
  rex.match(txt)
  i += 1
