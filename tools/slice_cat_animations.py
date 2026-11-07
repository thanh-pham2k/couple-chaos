from pathlib import Path
from PIL import Image
import numpy as np
from scipy import ndimage as nd
base=Path('asset/archive/animation_sources'); out=Path('assets/pets/cat/animations')
sets=[('image.png','walk',6,3),('image copy.png','run',8,3),('image copy 2.png','panic',8,3),('image copy 5.png','idle',4,3),('image copy 7.png','reaction',4,3)]
for name,action,cols,rows in sets:
 source = Path('asset/inbox') / name if name == 'image copy 5.png' else base / name
 im=Image.open(source).convert('RGBA'); arr=np.array(im); mask=arr[:,:,3]>80
 lab,n=nd.label(nd.binary_dilation(mask,iterations=3)); items=[]
 for i,s in enumerate(nd.find_objects(lab),1):
  if s is None: continue
  area=np.count_nonzero(lab[s]==i)
  if area>1300:
   yy,xx=np.where((lab==i)&(arr[:,:,3]>0));
   if len(xx): items.append((float(np.mean(yy)),float(np.mean(xx)),i,(xx.min(),yy.min(),xx.max()+1,yy.max()+1)))
 items.sort(); items=items[:cols*rows]
 if len(items)!=cols*rows: raise ValueError((name,len(items)))
 for row in range(rows):
  group=sorted(items[row*cols:(row+1)*cols],key=lambda x:x[1])
  subname=({'reaction':['sleep','startled','hiss']}.get(action,['down','right','up']))[row]
  suffix=(subname if action=='reaction' else action+'_'+subname)
  bounds=[it[3] for it in group]; scale=min(56/max(b[2]-b[0] for b in bounds),54/max(b[3]-b[1] for b in bounds))
  sheet=Image.new('RGBA',(64*cols,64)); bottoms=[b[3] for b in bounds]; basebottom=np.median(bottoms)
  for j,(_,_,label,b) in enumerate(group):
   x0,y0,x1,y1=b; piece=arr[y0:y1,x0:x1].copy(); piece[:,:,3]=np.where(lab[y0:y1,x0:x1]==label,piece[:,:,3],0)
   pic=Image.fromarray(piece).resize((max(1,round((x1-x0)*scale)),max(1,round((y1-y0)*scale))),Image.Resampling.LANCZOS)
   lift=max(0,min(4,round((basebottom-b[3])*scale))) if action in ('walk','run','panic') else 0
   sheet.alpha_composite(pic,(j*64+(64-pic.width)//2,58-pic.height-lift))
  sheet.save(out/(suffix+'.png')); print(suffix, scale)
