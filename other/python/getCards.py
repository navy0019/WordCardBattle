import os 	
from PIL import Image

file=open("/Users/up/Downloads/coding/Lua/love2dDungeon/other/python/onlyCopy.lua","w")
file.write("local Cards={\n")

count=1

imgPath ="/Users/up/Downloads/coding/Lua/love2dDungeon/assets/cards/"
imgFiles=os.listdir(imgPath)
imgNewp=imgPath.replace("/Users/up/Downloads/coding/Lua/love2dDungeon/","")		
		
for f in imgFiles:
	if f[-3:len(f)] == "png" :
		img= Image.open(imgPath+f)
		w,h=img.size
		key = f.replace(".png","")

		if count < len(imgFiles):
			file.write(key+"={\nquad={ 0 , 0 , "+str(w)+" , "+str(h)+" },\n" + "img = '"+imgNewp+f+"'\n},\n")
		else:
			file.write(key+"={\nquad={ 0 , 0 , "+str(w)+" , "+str(h)+" },\n" + "img = '"+imgNewp+f+"'\n}\n")

	count += 1

file.write("}")
file.close()