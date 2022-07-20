local monsterSkill = {
	attack={
		info=' 1 點傷害',
		func=function( self,target,battle)
			_G.Event:Emit('GetHit',target,-1,false,true,battle)end--self.data.atk*-1
			--target.GetHit(target,self.data.atk*-1,false,true,battle) end,
		},
	attack2={
		info=' 2 點傷害',
		func=function (self,target,battle)
			_G.Event:Emit('GetHit',target,-2,false,true,battle)end
			--target.GetHit(target,-7,false,true,battle)end
		},
	attack3={
		info=' 5 點傷害',
		func=function (self,target,battle)
			_G.Event:Emit('GetHit',target,-5,false,true,battle)end
			--target.GetHit(target,-7,false,true,battle)end
		}
}
return monsterSkill