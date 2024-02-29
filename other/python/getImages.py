import os 	
from PIL import Image

file=open("/Users/up/Downloads/coding/Lua/love2dDungeon/other/python/onlyCopy.lua","w")
file.write("local Resource={\n")

count=1

#################  UI  ####################################
imgPath ="/Users/up/Downloads/coding/Lua/love2dDungeon/assets/UI/"
imgFiles=os.listdir(imgPath)
imgNewp=imgPath.replace("/Users/up/Downloads/coding/Lua/love2dDungeon/","")

for f in imgFiles:
	if f[-3:len(f)] == "png" :
		img= Image.open(imgPath+f)
		w,h=img.size
		key = f.replace(".png","")
		file.write(key+"={\nquad={ 0 , 0 , "+str(w)+" , "+str(h)+" },\n" + "img = '"+imgNewp+f+"'\n},\n")



#################  BG  ####################################
imgPath ="/Users/up/Downloads/coding/Lua/love2dDungeon/assets/BG/"
imgFiles=os.listdir(imgPath)
imgNewp=imgPath.replace("/Users/up/Downloads/coding/Lua/love2dDungeon/","")		

for f in imgFiles:
	if f[-3:len(f)] == "png" :
		img= Image.open(imgPath+f)
		w,h=img.size
		key = f.replace(".png","")
		file.write(key+"={\nquad={ 0 , 0 , "+str(w)+" , "+str(h)+" },\n" + "img = '"+imgNewp+f+"'\n},\n")

#################  button  ####################################
imgPath ="/Users/up/Downloads/coding/Lua/love2dDungeon/assets/buttons/"
imgFiles=os.listdir(imgPath)
imgNewp=imgPath.replace("/Users/up/Downloads/coding/Lua/love2dDungeon/","")		

for f in imgFiles:
	if f[-3:len(f)] == "png" :
		img= Image.open(imgPath+f)
		w,h=img.size
		key = f.replace(".png","")
		file.write(key+"={\nquad={ 0 , 0 , "+str(w)+" , "+str(h)+" },\n" + "img = '"+imgNewp+f+"'\n},\n")

#################  card  ####################################
imgPath ="/Users/up/Downloads/coding/Lua/love2dDungeon/assets/cards/"
imgFiles=os.listdir(imgPath)
imgNewp=imgPath.replace("/Users/up/Downloads/coding/Lua/love2dDungeon/","")		

for f in imgFiles:
	if f[-3:len(f)] == "png" :
		img= Image.open(imgPath+f)
		w,h=img.size
		key = f.replace(".png","")
		file.write(key+"={\nquad={ 0 , 0 , "+str(w)+" , "+str(h)+" },\n" + "img = '"+imgNewp+f+"'\n},\n")

#################  character  ####################################
imgPath ="/Users/up/Downloads/coding/Lua/love2dDungeon/assets/character/"
imgFiles=os.listdir(imgPath)
imgNewp=imgPath.replace("/Users/up/Downloads/coding/Lua/love2dDungeon/","")		

for f in imgFiles:
	if f[-3:len(f)] == "png" :
		img= Image.open(imgPath+f)
		w,h=img.size
		key = f.replace(".png","")
		file.write(key+"={\nquad={ 0 , 0 , "+str(w)+" , "+str(h)+" },\n" + "img = '"+imgNewp+f+"'\n},\n")

#################  equipment  ####################################
imgPath ="/Users/up/Downloads/coding/Lua/love2dDungeon/assets/equipment/"
imgFiles=os.listdir(imgPath)
imgNewp=imgPath.replace("/Users/up/Downloads/coding/Lua/love2dDungeon/","")		

for f in imgFiles:
	if f[-3:len(f)] == "png" :
		img= Image.open(imgPath+f)
		w,h=img.size
		key = f.replace(".png","")
		file.write(key+"={\nquad={ 0 , 0 , "+str(w)+" , "+str(h)+" },\n" + "img = '"+imgNewp+f+"'\n},\n")

#################  interactive  ####################################
imgPath ="/Users/up/Downloads/coding/Lua/love2dDungeon/assets/interactive/"
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


file.write("}\n")
file.write("return Resource")
file.close()