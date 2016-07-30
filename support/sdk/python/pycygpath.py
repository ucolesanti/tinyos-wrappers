import sys
import string
import re
import os
input_file = open(sys.argv[1])
prev_value = int(0)
true = 1
while true:
	input_line = input_file.readline()
	if input_line == "":
		break
	input_line = re.sub('"/','"c:/',input_line)
	input_line = re.sub('"([a-zA-Z]*).nc',r'"c:'+os.getcwd()+r'/\1.nc',input_line) 
	print input_line
