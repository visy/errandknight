pico-8 cartridge // http://www.pico-8.com
version 35
__lua__
-- errand knight
-- by visy & pumpuli

gravity=0.1
intro = 2
cheat = 0

enemylimit = 16

player = { x = 8*3, y = -512, walk = 0, dir = -1, attack = 0, atime = 0, 
weapon = 5, aspeed = 3, acooldown = 24, acooltimer = 0, hb_x = 9, hb_y = 1, hb_s = 11, hp = 100, maxhp = 100, w = 6, h = 17, xv=0,yv=0,jumpheight=2,speed=0.8,friction=0.5,iframes=0,
moveframes=0,totalsouls = 0,souls=0, level=1,dead = false,deathframes=0,keys=0,
onladder=false,prevladder=false,
jst = 10, ast = 20, st = 100, maxst = 100,streco=0.25,isjumping=false,
spelldur=100,spelltick=0,spelltime = -2,spelldmg=5,spell=false,spellx=0,spelly=0,spellactive=false
}

enemies = {}

item_heart = 1
item_key = 2

items = {}

-- debug
draw_hitbox = false

-- ai
-- behaviors
bh_idle = 0
bh_patrol = 1
bh_chase = 2
bh_wallhug = 3

-- enemy types
enemy_waller = 252
enemy_skelly = 253
enemy_slime = 254

-- special tiles
tile_bg = 255
tile_door = 248

function solid(x,y)
 if (x < 0) x = 0
 if (y < 0) y = 0
 val = mget(x/8,(y+8)/8)
 return fget(val,0) or fget(val,6)
end

function collidingsolid(x,y)
 return
 solid(x,y)or
 solid(x+7,y)or
 solid(x,y+7)or
 solid(x+7,y+7)
end


function btnf(n)return btn(n)and 1 or 0 end

function sfxi(i)
	sfx(8+i)
end

doors = {}

function initdoors()
	for my = 1,59 do
	for mx = 1,128 do
		mi = mget(mx,my)
		if (mi == tile_door) then
		
			door = { x=mx*8,y=my*8, mx = mx, my = my, openframes=-2,opened= false,opendir=0 }
			add(doors,door)
		end

	end
	end
end


function drawdoors()
	for i=1, #doors do
		door = doors[i]	
		if (door.far == false) then
			mx = door.mx
			my = door.my
			oo = 0
			dof = false
			if (door.openframes > 0) then
				oo = 32-door.openframes
			end

			if door.opendir == -1 then
			 dof = true
			end
			if (door.opened == true) return
			if (dof == false) then
				sspr(0,8,8,16,mx*8,my*8,8-oo/4,24)
			else
				sspr(0,8,8,16,oo/4+mx*8,my*8,8-oo/4,24)
			end
		end
	end
end

rndr = {}

mapp = { 0, 3, 3,1, 2, 1, 2, 3,
								14,14,14,8,25, 2, 3, 2,
								14,14,14,9,10,11,12,13,
								14,14,14,8, 1, 2, 3, 2
}

tilesets = { 0,1,2,3,0,0,0,0, 
														0,0,0,2,0,0,0,0,
														0,0,0,1,0,0,0,0,
														0,0,0,0,0,0,0,0
}

function initmap()
	-- copy map to 0x8000
	memcpy(0x8000,0x2000,8192)
	
	offs = 0
	xo=0
	yo=0

	for y=1,48 do
		for x=1,128 do
			mset(x,y,255)
		end
	end
	
	for y=1,3,1 do
		for x=1,8,1 do
			tile = mapp[offs+1]
			tileset = tilesets[offs+1]
			offs+=1
			for yy=0,16 do
				for xx=0,16 do
					xt = xx+((tile%8)*16)
					yt = yy+(flr(tile/8)*16)
				 t = peek(0x8000+(yt*128+xt))
				 if (t >= 240 and t <= 247) then
						if (tileset > 0) then
							t = t - 240
							t+=72+(tileset-1)*8
						end
				 end
				 
					mset(xx+xo*16,yy+yo*16,t)
				end
			end
			xo+=1
		end
		xo=0
		yo+=1
	end


end

function _init()
-- local clen = px9_comp(0,0,128,60, 0x8000, mget)
--	cstore(0x2000, 0x8000, clen, "kmap.p8")
 
	if (cheat == 1) then
--		player.keys = 99
--		player.maxhp = 1
--		player.hp = 39
	end
	
	
	for i=1,500 do
		rndr[i] = rnd()*32
	end

	initmap()

	initdoors()
	initenemies()
	inittab()

	music(0,500)

	
end

function collide_aabox(
  a,
  b)
  
  x1 = a.x
  y1 = a.y
  w1 = a.w
  h1 = a.h

  x2 = b.x
  y2 = b.y
  w2 = b.w
  h2 = b.h
  
  local hit=false
  local xd=abs((x1+(w1/2))-(x2+(w2/2)))
  local xs=w1*0.5+w2*0.5
  local yd=abs((y1+(h1/2))-(y2+(h2/2)))
  local ys=h1/2+h2/2
  if xd<xs and 
     yd<ys then 
    hit=true 
  end
  
  return hit
end


function physics(po,isplayer)

	onladder = false

	lx = flr((po.x+4)/8)
	ly = flr((po.y)/8)+2
	if (isplayer == true and mget(lx,ly) == 127) then

		onladder = true
	end

	if (isplayer == true) then
		player.onladder = onladder
	end

	if (player.onladder and isplayer) then
		delta = (btnf(2)-btnf(3))*po.speed/2
		if (solid(po.x,po.y-delta) == false) then 
		 po.y-=delta
			falling = false
			po.yv = 0
		end
 end

	ly = flr((po.y)/8)+2.2

	if (isplayer and mget(lx,ly) == 111 and onladder and falling == false) then
		if (delta > 0) then
			player.y-=8
			player.x+=1
			falling = false
			player.yv = 0
			player.xv = 0
			return
		end
	end


	if (isplayer == true and (player.y > 0 and intro < 2)) then
	 po.xv+=(btnf(1)-btnf(0))*po.speed
 end

 po.xv*=po.friction

	if (isplayer) then
		if (po.st == 0) then
			po.xv/=2
		end
	end

	if ((btn(0) == true or btn(1) == true) and isplayer and player.y > 0) then
		if (po.xv>=0) then po.dir = 1
		else po.dir = -1 end
	end
	
	if (isplayer) then
		pre = po.isjumping
		thebtn = btn(4)
		if (thebtn == true and pre == false) then

			if (po.st > 0) then
				po.isjumping = true
				po.jumpframes=16
			end

		end
		
	else
		if po.jumptrigger == true then
			po.isjumping = po.jumptrigger
			po.jumpframes = 16+flr(rnd(16))
			po.jumptrigger = false
		end
	end
	
	if po.jumpframes then
		po.isjumping = po.jumpframes > 0
		po.jumpframes-=1
	end

 if onladder == false or isplayer == false	then
	 if(collidingsolid(po.x,po.y+1))then
	     if(po.jumpframes == 15 and po.isjumping and not collidingsolid(po.x,po.y-1))then
						 if isplayer then
	      	sfxi(0)
								po.st-=po.jst

	      else
	       sfxi(6)
	      end
	      po.yv-=po.jumpheight
				   po.isjumping =false
	     end
	 else
	  po.yv+=gravity
	 end
 end

 --collisions and movement
 --horizontal
 if(collidingsolid(po.x+po.xv,po.y))then
  while not collidingsolid(po.x+sgn(po.xv),po.y)do
   po.x+=sgn(po.xv)
  end
  po.xv=0
  
  if not isplayer and po.dir and po.bh == bh_patrol then
	  po.dir = -po.dir
  end
 else
  po.x+=po.xv
 end
 --vertical

	if (onladder == false or isplayer == false) then
	 if(collidingsolid(po.x,po.y+po.yv))then
	  local falling=po.yv>0
	  while not collidingsolid(po.x,po.y+sgn(po.yv))do
	   po.y+=sgn(po.yv)
	  end
	  po.yv=0
	  if (isplayer) then
			sfx(27)
			end
	 else
	  po.y+=po.yv
	 end
 end



end

function humanlogic(po)

	po.walk = (po.xv and po.x) % 16

	if (po.attack > 0) then
		po.atime+=1
		if (po.atime >= po.aspeed-po.level) then 
			po.attack+=1 
			po.atime = 0 
		end
		
		if (po.attack == 6) then 
		 po.attack = 0 
		 po.acooltimer = po.acooldown-po.level
		end
	end

	if (po.acooltimer > 0) then
	 po.acooltimer-=1
	end		

	hasweapon = false
	if (po.type and po.type == enemy_skelly) then
	 hasweapon = true
	end
	
	isenemy = false
	if not po.type then hasweapon = true isenemy = true end

	if (hasweapon == true) then
	 -- update hitbox
	 if (po.dir == 1) weapoffs = 0
	 if (po.dir == -1) weapoffs = -22
	
	 po.hx1 = po.x+po.hb_x+weapoffs
	 po.hy1 = po.y+po.hb_y
	 po.hx2 = po.x+po.hb_x+po.hb_s+weapoffs
	 po.hy2 = po.y+po.hb_y+po.hb_s
	end

end

shopmode = 0

function dialog(text,text2,y,c)
	rectfill(0,y,128,y+18,0)
	printc4(text,y+2,c)
	printc4(text2,y+10,c)
end

function standin()
 local x = flr(player.x/8)+0
 local y = flr(player.y/8)+1
	local tt = mget(x,y)
	return tt
end

function standon()
 local x = flr(player.x/8)+0
 local y = flr(player.y/8)+2
	local tt = mget(x,y)
	return tt
end

function shoplogic()
 tt = standin()
	if tt == 250 and shopmode == 0 then
		shopitempos = {x=player.x-64,y=player.y-24}
		shopmode = 1
		sfxi(10)
	end

	if tt != 250 and shopmode > 0 then
		shopmode = 0
		sfxi(11)
	end
	
	if (shopmode == 1) then 
		if (btnp(2)) then 
			shopitem-=1
			if (shopitem < 0) then
				shopitem = shopitemmax
			end
		end
		if (btnp(3)) then 
			shopitem+=1
			if (shopitem > shopitemmax) then
				shopitem = 0
			end
		end
	end
	
	
end

price = 0
shopitem = 0
shopitemmax = 2

function trybuy()

	if (player.souls >= price) then
		player.souls-=price
		player.weapon=37
		sfxi(12)
		shopmode = 0
	else
		sfxi(11)
	end

end

gameover = 0

function spellchangelogic()
	local tt = standon()

	if (fget(tt,5) == true) then
		if (player.spell == false) then
			player.spell = true
			player.prevweapon = player.weapon
			attack_hitbox = {}
		end
		
		player.spelltime = 500
	end
end

function updateplayer()

	if (player.dead == true) then
		player.deathframes+=1
		return
	end

	if (player.st < player.maxst) then
		player.st+=(player.streco+(0.1*player.level))
	end

	if (player.iframes > 0) then
		player.iframes -= 1
	end

	physics(player,true)

	if (player.spell == true) then
		player.weapon = 6
	end

	stlimit = player.ast
	if (player.spell == true) then
	stlimit+=player.ast
	end

 if (btn(5) and player.attack == 0 and player.acooltimer == 0 and player.st >= stlimit) then 
		if (player.spell == false) then
  	player.attack = 1
	 	player.st-=player.ast
		end

		if (player.spell == true and player.spellactive == false) then
	 	player.attack = 1
	 	player.st-=player.ast*2
			player.spellx = player.x+player.dir*4
			player.spelly = player.y+8
			player.spelldir = player.dir
			player.spellspeed = 1
			player.spellactive=true
			sfxi(20)

			player.spelltick = 0
			
		end

 	if (shopmode == 0) then
 		sfxi(3)
 	else
 		trybuy()
 	end
 end

	humanlogic(player)

	shoplogic()

	spellchangelogic()

	if (player.spellactive == true) then
		player.spelltick+=1
		if (player.spelltick > player.spelldur) then
			player.spelltick = 0
			player.spellactive = false
			attack_hitbox = {}
		end
	end

	if (player.spelltime >= 0 and player.spell == true) then
		player.spelltime-=1
	end
	if (player.spelltime == -1 and player.spell == true) then
		player.spell = false
		player.spelltime = -2
		player.spellactive = false
		player.attack = 0
		player.acooltimer = 0
		attack_hitbox = false
		player.weapon = player.prevweapon	
	end

	if (player.spellactive == true) then
		player.spellx+=player.spelldir*player.spellspeed
		if (pd(abs(player.x),abs(player.y),abs(player.spellx),abs(player.spelly)) > 64) then
			player.spellactive = false
			player.spellx = -1000
			player.spelly = -1000
			attack_hitbox = {}
		end
	end

	if (player.spell == false) then
	-- player's attack
	attack_hitbox = { x = player.hx1, y = player.hy1, w = player.hb_s, h = player.hb_s }
	else
	if (player.spellactive == true) then
		attack_hitbox = { x = player.spellx, y = player.spelly, w = 16, h = 6 }
	else
			attack_hitbox = { x = player.spellx, y = player.spelly, w = 16, h = 6 }
	end
	end

	-- game exit
	if standin() == 48 then gameover = 2 end

	-- door
	tx = flr(player.x/8)+1
	ty = flr(player.y/8)
	if (mget(tx,ty) == 248 or mget(tx,ty) == 249) then opendoor(tx,ty) end
	tx = flr(player.x/8)-1
	ty = flr(player.y/8)
	if (mget(tx,ty) == 248 or mget(tx,ty) == 249) then opendoor(tx,ty) end

end

function ai(enemy)
	bh = enemy.bh

	if (bh == bh_idle) then
	elseif (bh == bh_patrol) then
		if not enemy.dir then
			enemy.dir = flr(rnd(2))-1
			if (enemy.dir == 0) enemy.dir = 1
		else
			enemy.xv+=enemy.dir*enemy.speed

			if (abs(enemy.y-player.y) < 8 and abs(enemy.x-player.x) < 32) enemy.bh = bh_chase
		end

		if (enemy.xv>=0) then enemy.dir = 1
		else enemy.dir = -1 end
	
	elseif (bh == bh_chase) then
		if (enemy.x < player.x and not player.dead) enemy.xv+=enemy.speed*1.5
  if (enemy.x > player.x and not player.dead) enemy.xv-=enemy.speed*1.5

		if (enemy.xv>=0) then enemy.dir = 1
		else enemy.dir = -1 end

		if (abs(enemy.x-player.x) < 30 and enemy.type != enemy_slime) enemy.attack = 1

		if (enemy.attack > 0) then
			enemy.attack+=1 
			if (enemy.attack > 6) then
				enemy.attack = 0
			end
		end

  
  if (rnd(255) < 1 and enemy.jumptrigger == false) then
  	enemy.jumptrigger = true
  end
	elseif(bh == bh_wallhug) then
		speedc = flr(rnd(256))
		if (speedc < 2) then
			enemy.speed = 0.2+rnd(0.5)
		end
		ox = 0
		oy = 0
		if (enemy.xdir > 0) then
			ox = 8
		end
		if (enemy.ydir > 0) then
			oy = 8
		end
		ex = flr((enemy.x+ox)/8)
		ey = flr((enemy.y+oy)/8)


		xs = enemy.xdir*enemy.speed
		ys = enemy.ydir*enemy.speed
	
		w = fget(mget(ex,ey),0) or fget(mget(ex,ey),6)

		if (w == true) then
			enemy.x-=enemy.xdir*enemy.speed
 		enemy.y-=enemy.ydir*enemy.speed

			pxd = enemy.xdir
			pyd = enemy.ydir
			if(enemy.xdir == -1) then
				enemy.xdir = 0
				enemy.ydir = -1
			elseif(enemy.xdir == 1) then
				enemy.xdir = 0
				enemy.ydir = 1
			elseif(enemy.ydir == -1) then
				enemy.xdir = 1
				enemy.ydir = 0
			elseif(enemy.ydir == 1) then
				enemy.xdir = -1
				enemy.ydir = 0
			end
	
			if (pxd != enemy.xdir or pyd != enemy.ydir) then
				enemy.x=flr(enemy.x)
				enemy.y=flr(enemy.y)
			end
			

		else

			enemy.x+=enemy.xdir*enemy.speed
			enemy.y+=enemy.ydir*enemy.speed
		end
		
	end
	
	

end

opening = {}

function doorat(x,y)
 for i=1,#doors do
  d = doors[i]
 	if (d.mx == x and d.my == y-1) then 
 		d.di = i
	 	return d 
 	end
 end
 return -1
end

function opendoor(tx,ty)
	dd = doorat(tx,ty)
	if (dd == -1) then
		return
	end
	if (dd.openframes == -2 and dd.opened == false and player.keys > 0) then
		player.keys-=1
	 dd.openframes=32
	 dd.opendir = player.dir
	 add(opening,dd)
 end
end

function maybespawnitem(x,y,tt)

	if tt == item_heart then
		c = rnd(256)
	end

	if tt == item_key then
		c = 1
	end
	
	if (c < 64) then
		item = {x = x, y = y, tt = tt}
		add(items,item)
	end

end


-- player's attack
attack_hitbox = { }

dmgs = {}
heals = {}
function damage(t,n)
	dmg = {x = t.x, y=t.y,n=n,frames=16}
	add(dmgs,dmg)
end

function healing(t,n,k)
	heal = {k=k, x = t.x, y=t.y,n=n,frames=16}
	add(heals,heal)
end

function getattackpower()
		dmg = 4
		extra = 0
		if (player.weapon == 37) then
			extra = 10
		end
		dmg+=(player.level-1)*2
		dmg+=extra
		if (player.spell == true) then
		dmg=player.spelldmg
		end
		return dmg
end


function updateenemies() 
	-- enemies
	hit = { }
	hitcount = 0
	
	dead = {}
	for i = 1,#enemies do
		enemy = enemies[i]
		if (enemy.dead == true) then
		 if (enemy.deathframes) then
			 if (enemy.deathframes <= 0) then
					add(dead,i)
				end
			end
		end
	end
	
	for i = 1,#dead do
		deli(enemies,dead[i])
	end

	for i = 1,#enemies do
		enemy = enemies[i]

		dd = abs(pd(enemy.x,enemy.y,player.x,player.y))
		dv = 90
		if dd >= dv then enemy.far = true
		else enemy.far = false
		end
		if (enemy.dead == false and dd < dv) then
			ai(enemy)

			if (enemy.type != enemy_waller) then
				physics(enemy,false)
				humanlogic(enemy)
			end

			if (enemy.iframes > 0) then
				enemy.iframes -= 1
			end

			if (enemy.animspeed) then
				enemy.atimer+=1
				if (enemy.atimer > enemy.animspeed) then
					enemy.atimer = 0
					enemy.aframe+=1
				end
			end
	
			cond = false
		 --collision with attack
			if (player.spell == false) then
				if (player.attack == 2) then
				cond = true
				end
			else
				if (player.spellactive == true) then
					cond = true
				end
			end

			if (cond and collide_aabox(enemy,attack_hitbox) and enemy.iframes == 0) then
				add(hit,i)
				hitcount+=1
		 	sfxi(2)

	 	end
			-- collision with player
			checkweapon = false
			if (enemy.type == enemy_skelly) then
				enemy_a_hitbox = { x = enemy.hx1, y = enemy.hy1, w = enemy.hb_s, h = enemy.hb_s }
				checkweapon = collide_aabox(enemy_a_hitbox,player)
			end
			if ((collide_aabox(enemy,player) or checkweapon) and enemy.iframes == 0 and player.iframes == 0) then
				player.hp-=enemy.dmg
				damage(player,enemy.dmg)

				player.iframes = 32
				sfxi(5)
				if (player.hp <= 0) then
					music(-1)
					player.dead = true
					gameover = 1
					player.deathframes = 0
				end
				pushtarget(enemy,player,false)
	 	end

  end
	end  

	for i=1,hitcount do
		enemy = enemies[hit[i]]
		if (player.xv > 0) then
		enemy.x+=player.xv*3
		else
		enemy.x-=enemy.dx*3
		end

		dmg = getattackpower()

		if (enemy.hp > 0 and enemy.dead == false) then
			enemy.hp-=dmg
			damage(enemy,dmg)
			pushtarget(player,enemy,true)
	
			enemy.iframes = 16
		else 
			sfxi(7)
			enemy.dead = true
			enemy.deathframes = 16
			maybespawnitem(enemy.x,enemy.y+8,item_heart)
		end
	end

end

function updatedoors()
	for i=1,#doors do
	 s = doors[i]
		dx = abs(s.x-player.x)
		dy = abs(s.y-player.y)
		dv = 60
		dd = (dx+dy)/2
		if (dd < dv) then s.far = false
		else s.far = true
		end

	end

	done = {}
	doneo = {}

	for i=1,#opening do 
		d = opening[i]
		
		if (d.openframes) then 
			if (d.openframes >= 0) then
				d.openframes-=1
				if (d.openframes == 15) then
					sfxi(18)
				end
			end
			if (d.openframes == 0) then
				mset(d.mx,d.my,255)
				mset(d.mx,d.my+1,255)
				mset(d.mx,d.my+2,255)
				d.opened = true
				add(done,d.di)
				add(doneo,i)
			end
		end
	end

	for i=1,#done do
		deli(opening,doneo[i])
		deli(doors,done[i])
	end
end

function drawspawners()
	for i=1,#spawners do
		s = spawners[i]
		if (s.far == false) then
			oo = cos(time()*0.2+i*0.3)*2
			oo2 = sin(time()*0.3+i*0.2)*2
	
			if (s.spawncount < s.spawnlimit) then
				sp = 64+((s.aframe+i)%2)*4
				sx, sy = (sp % 16) * 8, (sp \ 16) * 8
				ss = (s.spawncount-(s.spawnlimit-s.spawncount))*2
				sspr(sx,sy,32,8,ss+s.x-24+oo,s.y+4-oo2,32-oo-ss,8+oo2)
			end
			
			
		end
	end
end

function updatespawners()
	a = {}
	for i=1,#spawners do
		s = spawners[i]
		if (s.active == false) then
		add(a,i)
		end
	end

	for i=1,#a do
	 deli(spawners,a[i])
	end
	
	for i=1,#spawners do
		s = spawners[i]
		s.acount+=1
		if (s.acount > s.aspeed) then
		 s.aframe +=1
		 s.acount = 0
		 if (s.aframe >= 4) then s.aframe = 0 end
		end

		dx = abs(s.x-player.x)
		dy = abs(s.y-player.y)
		dv = 60
		dd = (dx+dy)/2
		if (dd < dv) then s.far = false
		else s.far = true
		end

		s.spawnlimit = 1+flr(player.level/2)
		if (s.spawnlimit > s.spawnlimitmax) then
			s.spawnlimit = s.spawnlimitmax
		end

		if (s.far == false) then 	
			s.spawnframes-=1
			if (s.spawncount < s.spawnlimit and s.spawnframes == 0) then
				s.spawnframes = s.spawntime
				if (#enemies >= enemylimit) then
					return
				end
				s.spawncount += 1
				sfxi(17)
				if (s.spawncount == s.spawnlimit) then
					maybespawnitem(s.x-8,s.y,item_key)
					s.active = false
				end
				if (s.enemytype == enemy_slime) then
					hpval = (player.level/2)*8+flr(rnd(4))
		 		enemy ={x = s.x - 14, 
		 		        y = s.y - 12, 
					 						animspeed = 4+rnd(12), 
						 					w = 12, h = 12, 
								 			hp = hpval, 
											 jumpheight=2+rnd(1),
											 speed=0.1+rnd(0.1),
											 friction=0.4,
											 bh=bh_patrol,
											 souls=flr(hpval*4),acooldown=4,
											 dmg = flr(hpval/2),										 }
										 
					enemy.type = enemy_slime
	
					addenemycommon(enemy)
			
					add(enemies,enemy)
			end	
		end
	 end
	end
end


function updateitems()
	rmd = {}
	for i = 1, #items do
		it = items[i]
		x = it.x
		y = it.y

		idd = pd(x+4,y,player.x+4,player.y+10)
		if (idd < 8) then
			rm = { i = i, tt = it.tt}
			add(rmd,rm)
		end
	end
	
	for i = 1, #rmd do
		tt = rmd[i].tt
		deli(items,rmd[i].i)
		if (tt == item_heart) then
			player.hp+=20
			healing(player,5)
			if (player.hp>player.maxhp) then player.hp = player.maxhp end
			sfxi(11)
		elseif (tt == item_key) then
			healing(player,1,1)
			player.keys+=1
			sfxi(9)
		end
	end

end


function _update60()
	updateplayer()
	updateshadow()
	updateenemies()	
	updateitems()
	updatespawners()
	updatedoors()
end

function addenemycommon(enemy, spawner)
	enemy.moveframes=0
	enemy.level = 0
	enemy.atimer = 0
	enemy.aframe = 0
	enemy.dx = 0
	enemy.dy = 0 
	enemy.iframes = 0
	enemy.jumptrigger = false
	enemy.dead = false
	enemy.xv=0
	enemy.yv=0
	enemy.acooltimer = 0
	enemy.attack=0
	enemy.atime=0
	enemy.deathframes=0
end

spawnerid = 1

function initspawner(mi,x,y)
	o = {}
	o.x = x*8
	o.y = y*8
	o.acount = 0
	o.aspeed = 4
	o.aframe = 0
	ww = flr(128+rnd(128))
	o.spawnframes = ww
	o.spawntime = ww
	o.spawnlimit = 1
	o.spawnlimitmax = 4
	o.spawncount = 0
	o.enemytype = mi
	o.spawner = spawnerid
	o.active = true
	return o
end

spawners = {}

function initenemies()
	for my = 1,59 do
	for mx = 1,128 do
		isspawner = false
		mi = mget(mx,my)
		if (mi >= enemy_waller and mi <= enemy_slime) then

		-- waller		
		if (mi == enemy_waller) then
			enemy = {x = mx*8,
												y = (my*8),
					 						animspeed = 5, 
												w = 6,
												h = 6,
												hp = 50,
												xdir = -1,
												ydir = 0,
												jumpheight=0,
												speed=0.8,
												friction=0.1,
												bh=bh_wallhug,
												souls=20,
												dmg = 5
												}

			enemy.type = enemy_waller

		end

		-- skelly
		if (mi == enemy_skelly) then
 		enemy ={x = mx*8, 
 		        y = (my*8) - 8, 
			 						aspeed = 8, 
				 					w = 9, h = 17, 
						 			hp = 80, 
									 jumpheight=0,
									 speed=0.2,
									 friction=0.4,
									 bh=bh_patrol,
									 souls=60, walk=0,
									 attack = 0,dir=-1,
									 weapon=37,acooldown=4,
									 spell = false,
										hb_x = 14, hb_y = 1, hb_s = 4,
										dmg = 25
								 }


			enemy.type = enemy_skelly
		
		end

		-- slime
		if (mi == enemy_slime) then
			add(spawners,initspawner(mi,mx,my))
			isspawner = true
		end
		
		if (isspawner == false) then
			addenemycommon(enemy)
	
			add(enemies,enemy)
		end

		end
	end
	end
end

function drawenemies()
	for i = 1,#enemies do
		enemy = enemies[i]
		if ((enemy.dead == false or enemy.deathframes > 0) and enemy.far == false) then

			if (enemy.deathframes > 0) then
				for i=1, 16 do
					pal(i,i+16-enemy.deathframes*0.8,0)
				end
			end
	
			if (enemy.type == enemy_waller) then
				if (enemy.iframes > 0 and enemy.deathframes == 0) then
					pal(9,16-enemy.iframes*2,0)
					pal(10,15-enemy.iframes*2,0)
				end
				if (enemy.xdir != -0) then
				a = 0
				if (enemy.xdir == 1) then
				a = 180
				end

				rspr(99+enemy.aframe%4,enemy.x,enemy.y,a,1,1)
				end
				if (enemy.ydir != -0) then
				a = 90
				if (enemy.ydir == 1) then
				a = 270
				end
				rspr(99+enemy.aframe%4,enemy.x,enemy.y,a,1,1)
				end
--				print(enemy.wall,enemy.x,enemy.y,7)
			pal()
			end

			if (enemy.type == enemy_skelly) then
				drawhumanoid(enemy,33)
			end

			if (enemy.type == enemy_slime) then
				if (enemy.iframes > 0 and enemy.deathframes == 0) then
					pal(11,16-enemy.iframes*2,0)
				end

				sn = 12+(enemy.aframe%2)*2	
				sx, sy = (sn % 16) * 8, (sn \ 16) * 8
				hi = flr(enemy.hp/10)
				if (hi <= 0) hi = 1
				ss = 11+hi*2
				xi = { 2,1,0,-1,-2 }
				yi = { 5,3,1,-1,-3 }
				sspr(sx,sy,16,16,enemy.x-2+xi[hi],enemy.y-2+yi[hi],ss,ss)
				pal()
			end

			if (enemy.deathframes > 0) then
				enemy.deathframes-=1
				enemy.y+=(8-enemy.deathframes)*0.05
				if (enemy.deathframes == 0) then
					sfxi(8)
					player.souls+=enemy.souls
					player.totalsouls+=enemy.souls
					if (player.totalsouls >= (player.level*1.3)*100) player.level+=1
				end
			end

			-- hitbox
			if (draw_hitbox == true) then
		  rect(enemy.x,enemy.y,enemy.x+enemy.w,enemy.y+enemy.h,8)
	  end

		--	print(enemy.bh,enemy.x+6,enemy.y-6,8)

  end
	end

	
end

function pushtarget(pusher,target,hit)
	force = 10
	if (hit == true) then 
		force = 20*player.dir
	end
	
	target.xv+=force
end


function rspr(s,x,y,a,w,h)
 sw=(w or 1)*8 --sprite width
 sh=(h or 1)*8 --sprite height

	sn = s
	sx, sy = (sn % 16) * 8, (sn \ 16) * 8
 x0=flr(0.5*sw)
 y0=flr(0.5*sh)
 a=a/360
 sa=sin(a)
 ca=cos(a)
 for ix=0,sw-1 do
  for iy=0,sh-1 do
   dx=ix-x0
   dy=iy-y0
   xx=flr(dx*ca-dy*sa+x0)
   yy=flr(dx*sa+dy*ca+y0)
   if (xx>=0 and xx<sw and yy>=0 and yy<=sh) then
   	c = sget(sx+xx,sy+yy)
   	if (c > 0) then
     pset(x+ix,y+iy,sget(sx+xx,sy+yy))
    end
   end
  end
 end
end


function drawhumanoid(actor,sprindex,ox,oy)
	ox = ox or 0
	oy = oy or 0
	if(actor.dead == true) then
		pal(0,8)
		rspr(1,actor.x-4+ox,actor.y+7+oy,-89,1,1)
		rspr(1,actor.x+4+ox,actor.y,-89+oy,1,3)
		pal()
		return
	end

	if (actor.iframes > 0 and ox == 0) then
		for i=1, 16 do
			pal(i,(i+actor.iframes)%16)
		end
	end


	if (actor.onladder == true) then
	-- head
	spr(108+sprindex+(actor.y/4 % 2),ox+actor.x+actor.dir*-1,oy+actor.y,1,1,actor.dir!=1)
	-- body
	spr(108+sprindex+16+(actor.y/4 % 2),ox+actor.x+actor.dir*-1,oy+actor.y+8,1,1,actor.dir!=1)
	else
	-- head
	spr(sprindex,ox+actor.x+actor.dir*-1,oy+actor.y,1,1,actor.dir!=1)
	-- body
	spr(sprindex+16+(actor.walk/4 % 3),ox+actor.x+actor.dir*-1,oy+actor.y+8,1,1,actor.dir!=1)
	end

	if (actor.iframes > 0 and ox == 0) then
		pal()
	end
	
 -- weapon
 if (actor.dir == 1) weapoffs = 8
 if (actor.dir == -1) weapoffs = 8

	-- weapon idle
	if (actor.attack == 0) then

		if actor.weapon > 0 then
			spr(actor.weapon,ox+actor.x+weapoffs*actor.dir+actor.dir*-1,oy+actor.y,1,2,actor.dir!=1)
		end
	else
	 -- weapon strike
		if (actor.attack > 0 and actor.attack < 3) then
			weapoffs-=3
			weapoffs+=actor.attack
		else
			weapoffs+=(3-actor.attack)
		end

	 if (actor.dir == -1) weapoffs += 8
		
		if actor.weapon > 0 and actor.spell == false then
			spr(actor.weapon+2,ox+actor.x+weapoffs*actor.dir+actor.dir*-1,oy+actor.y+cos(actor.attack/8+time())*2,2,2,actor.dir!=1)
		end

		if actor.spell == true then
		 ex = 0
			if (player.dir == -1) then
				ex = 8
			end
			spr(actor.weapon,ex+ox+actor.x+weapoffs*actor.dir+actor.dir*-1,oy+actor.y+cos(actor.attack/100+time()*0.01)*2,1,2,actor.dir!=1)
		end

	end

	if (ox == 0) then
		pal()
	end


	-- hitbox
	if (draw_hitbox == true) then
		rect(actor.x,actor.y, actor.x+actor.w, actor.y+actor.h,10)
		a = attack_hitbox
		if (a.x) then
		rect(a.x,a.y, a.x+a.w, a.y+a.h,15)
		end
	end

--	print(player.hp,player.x,player.y-6,2)

end



mx = 0

mapframe=0
mapspeed = 2
mapoffs = 0

function approx_dist(dx,dy)
 local maskx,masky=dx>>31,dy>>31
 local a0,b0=(dx+maskx)^^maskx,(dy+masky)^^masky
 if a0>b0 then
  return a0*0.9609+b0*0.3984
 end
 return b0*0.9609+a0*0.3984
end

function pd(x,y,x2,y2)
	return approx_dist(x-x2,y-y2)	
end

function drawlevel()
	mapframe+=1
	if (mapframe > mapspeed) then
		mapframe = 0
		mapoffs += 1
	end

	-- parallax pattern
	camera()

	for y=-2,14,2 do
	for x=-2,16,2 do 
 
 	sx = flr((player.x-64)/8)+x
 	sy = flr((player.y-64)/8)+y

 	xo = -player.x/4%16
 	yo = -player.y/32%16

		dx=flr(xo+x*8)
		dy=flr(yo+y*8)
		if (sx >= -2 and sy >= -2) then
		spr(46,dx,dy,2,2)
		end

		pal()
	end
	end
	pal()

	camera(player.x-64,player.y-64)

	drawspawners()
	--solid and stairs
	map(0,0,0,0,128,128,1)
	map(0,0,0,0,128,128,6)
end

function printc(s,y,c)
  x= 64-#s*2
  print("\^d2"..s,x,y,c)
end

function printc2(s,xx,y,c)
  x= 64-(#s*2)*2
  print("\^w\^t"..s,x+xx,y,c)
end

function printc3(s,y,c)
  x= 64-#s*2
  print(s,x-1,y,c)
end

function printc4(s,y,c)
  x= 64-#s*2
  print(s,x,y,c)
end

spelltime = 0
spellframe=0

function drawspell()
	if (player.spellactive == true) then
		spelltime+=1
		if (spelltime > 4) then
			spellframe+=1
			spelltime = 0
		end
		if (spellframe > 1) then spellframe = 0 end

		ofs = 0
		oo = 0
		if (player.spelldir == -1) then
			ofs = 8
			oo = 8
		else
			ofs = -8
		end

		spr(103,oo+player.spellx,player.spelly,1,1,player.spelldir == -1)
		spr(104+spellframe,oo+player.spellx-ofs,player.spelly,1,1,player.spelldir == -1)
	end
end

grad = { 10, 6, 9, 8, 4, 2,1,1,1,1,1,1,1,1,1,1,1,1,1} 

function drawtorch()
 if (player.dead == true) return

	for y=player.y-4*2,player.y+20*2,2 do
	for x=player.x-8*2,player.x+16*2,2 do
		dd = pd(x,y,player.x+4,player.y+8)/0.08
		cc = dd/(30+cos(time()*0.1+sin(time()*0.3)*0.5)*3)

		c = pget(x,y)
		if (c == 1 or c == 2) pset(x,y,grad[cc & -1])
		c = pget(x+1,y)
		if (c == 1 or c == 2) pset(x+1,y,grad[cc & -1])
		c = pget(x,y+1)
		if (c == 1 or c == 2) pset(x,y+1,grad[cc & -1])
		c = pget(x+1,y+1)
		if (c == 1 or c == 2) pset(x+1,y+1,grad[cc & -1])
	end
	end

end

function pad(string,length)
  if (#string==length) return string
  return "0"..pad(string, length-1)
end

function print_o(text,x,y,c)
		print(text,x,y-1,0)
		print(text,x,y+1,0)
		print(text,x-1,y,0)
		print(text,x+1,y,0)
		print(text,x,y,c)

end

function drawdmg()
	camera(player.x-64,player.y-64)
 r = {}
	for i=1,#dmgs do
		d = dmgs[i]
		if (d.frames >= 0) then
		oy = cos(i*0.1)*4
		print_o(flr(d.n),d.x+12,oy+-1+d.y-cos(d.frames*0.04)*4,8+(16-d.frames)*0.2)
		d.frames-=1
		if (d.frames == 0) then
			add(r,i)
		end
		end
	end
	
	for i=1,#r do
		deli(dmgs,r[i])
	end


end

function drawhealing()
	camera(player.x-64,player.y-64)
 r = {}
	for i=1,#heals do
		d = heals[i]
		if (d.frames >= 0) then
		oy = cos(i*0.1)*4
		co = 8
		if (d.k == 1) then
			co = 10
		end
		print_o("+"..flr(d.n),d.x+12,oy+-1+d.y-cos(d.frames*0.04)*4,co)
		d.frames-=1
		if (d.frames == 0) then
			add(r,i)
		end
		end
	end
	
	for i=1,#r do
		deli(heals,r[i])
	end


end

		names = { "red snapper", "brass cleaver", "golden long" }
		prices = { 100, 150, 500 }
		armor = {4,13,12,9,11,10,8,2,3,5,6,7,14,15,0}

function drawui()
	camera()
	rectfill(0,120,128,128,0)

	--stamina
	for i=player.maxst,1,-5 do

		
	 if (i > player.st) then
		pset(16+(i/10-1)*4,7,3)	
		pset(17+(i/10-1)*4,7,3)	
		else
		pset(16+(i/10-1)*4,7,11)	
		pset(17+(i/10-1)*4,7,11)	
		end
	end
	
	--hp
	for i=1,player.maxhp,5 do
		h = "█"
		e = "…"
	
	 if (i <= player.hp) then
			print(h,8+(i/10-1)*4,-4,8)
		else
			print(h,8+(i/10-1)*4,-4,2)
		end
	end

	spr(34,0,0,1,1)
	spr(35,50,0,1,1)

	xo = 0+cos(time()*0.1)+sin(time()*0.133)*3
	yo = 2+sin(time()*0.1)+cos(time()*0.15)*2
	yo2 = 2+sin(0.1+time()*0.1)+cos(time()*0.15)*2
	yo3 = 2+sin(0.2+time()*0.1)+cos(time()*0.15)*2

	spr(11,xo+127-42,yo+-1)
	spr(57,xo+127-40,yo2+0)
	spr(11,xo+127-32,yo3+-1)
	spr(11,xo+127-24,yo2+-2)
	spr(9,xo+127-16,yo+-2)
	spr(11,xo+127-8,yo2+-1)

	palt(0,false)
	spr(25,127-22,0,3,1)
		
	print("key:"..pad(""..player.keys,2),45,122,10)
	print("soul:"..pad(""..player.souls,3),71,122,12)
	print("     lvl:" ..pad(""..player.level,2),85,122,7)

	dmg = getattackpower()

	palt(0,true)
	for i=0,dmg-1,1 do
		spr(108,0,8+(i/2)*8)
	end


	for i=0,player.spelltime,20 do
		spr(54,120,8+(i/20)*4)
	end

	palt()
	pal()

	if shopmode == 1 then 
		--top
		dialog("[bunbun exports employee]","welcome to my shop",0,7)

		--item
		itemname = names[shopitem+1]
		price = prices[shopitem+1]		
		dialog(itemname,"only " .. price .. " souls for you my friend",20,8)
		camera(player.x-64,player.y-64)

		
		rectfill(shopitempos.x,shopitempos.y,shopitempos.x+16,shopitempos.y+64,0)
		
		pal(12,armor[1+flr(player.level/2)])
		yo = 16*shopitem
		sspr(9*8,16,8,8,shopitempos.x-16,yo+shopitempos.y+cos(time()*1)*2,16+cos(time()*1)*2,16+sin(time()*0.5)*2)

		for i=0,shopitemmax,1 do
			pal(10,i+8)
			if (i == shopitem) then
				sspr(10*8,0,8,8,shopitempos.x-cos(time()*1)*2,16*i+shopitempos.y-sin(time()*1)*2,16+cos(time()*1)*2,16+sin(time()*1)*2)
			else
				sspr(10*8,0,8,8,shopitempos.x,16*i+shopitempos.y,16,16)
			end
		end
		pal()
		camera()
	end
	
	--roomname
	--printc("in the court of crimson king",123,14)
	

end


itt = 0
ifr = 0
function drawitems()
	itt+=1
	if itt > 8 then
		itt = 0
		ifr +=1
	end
	for i = 1, #items do
		it = items[i]

		if (it.tt == item_heart) then
			spr(96+ifr%3,it.x,it.y)
		end
		if (it.tt == item_key) then
			spr(36,it.x,it.y-8,1,2)
		end
	end
end

sintab = {}
costab = {}

function inittab()
	for a=0,360,6 do

	 local ray={
	   angle=a/360,
	 }
	 -- rays
  local step_x = cos(ray.angle)
  local step_y = sin(ray.angle)
  costab[a+1] = step_x
  sintab[a+1] = step_y
	end
end

pchangex = -1
updateframes = 0

function updateshadow()
	plx = flr((player.x)/8)
	ply = flr((player.y)/8)

 px=plx
 py=ply

	if (pchangex == px and pchangey == py) then
		updateframes=0
	 return
	end 

	updateframes+=1

	pchangex = px
	pchangey = py

	ray_step=1
	memset(0x8000,112,512)

	for a=0,360,6 do
	
	 local ray={
	   x = px,
	   y = py,
	   angle=a/360,
	 }
	 -- rays
  local step_x = costab[a+1]*ray_step
  local step_y = sintab[a+1]*ray_step 

  local tile=0
  local distance=0

  -- reset ray start point
  ray.x = plx
  ray.y = ply

  local distance=0
  -- cast a ray across the
  -- world map
		local distbail = false
  repeat
   -- march the ray
   ray.x+=step_x       
   ray.y+=step_y
   distance+=ray_step
   if (distance > 8) then distbail = true end
   -- get tile at ray position
			tile = mget(flr(ray.x),flr(ray.y))
			flag = fget(tile,0)
	 until(flag==true or distbail==true)

		if(distbail == false and distance > 1) then
			 ray.x+=step_x
			 ray.y+=step_y

			for i=0,7 do
	   xi = flr(ray.x)-plx+8
	   yi = flr(ray.y)-ply+9
			 ray.x+=step_x
			 ray.y+=step_y

				dv = peek(0x8000+(yi*16)+xi)
				dv+=2
				if (dv > 124) then dv = 124 end
				poke(0x8000+(yi*16)+xi,dv)

			end
		end
 end
end

of = 0
function drawshadow()

	palt(1,true)
	palt(0,false)

	pdd = 0
	if (player.dir == -1) then
		pdd = 8
	end
	
	xo = (player.x%8)-pdd
	yo = player.y%8

 -- map to 0x80
	poke(0x5f56, 0x80)
	--alt map width
	poke(0x5f57, 16)

	-- draw shadowmap
	map(0,0,player.x-64-xo,player.y-64-yo,16,16)

	-- reset default map addr
	poke(0x5f56, 0x20)
	--default map width
	poke(0x5f57, 128)

	palt()
	camera()
end

fadepal={12,14,8,13,3,4,5,2,1,0}

function _draw()
	cls(0)
	if (intro == 2) then
		ff = 1+(8-abs(flr(player.y*0.02)))
		if (ff > 10) ff = 10
		if (ff < 1) ff = 1
		
		if (player.y < 0) rectfill(0,0,128,128,fadepal[ff])

		camera(player.x-64,player.y-64)		
		if (player.y > -256) then
		pal(7,flr(player.y*0.01))
		end
		for i=1,13,1 do
		spr(106, -time()*10+32+cos((i*32.0)*0.01)*32,-500+i*32+rndr[i],2,1)
		end
		pal()
		
		camera()		
	end
--	clip(player.x,player.y,player.x+32,player.y+32)
	camera(player.x-64,player.y-64)
	drawlevel()	
	drawdoors()

	-- shadow
	for i=1,16 do
		pal(i,0)
	end

	drawhumanoid(player,1,-1,-1)
	drawhumanoid(player,1,1,-1)
	drawhumanoid(player,1,0,1)
	
--	print(stat(0),player.x-32,player.y-8,0)
--	print(stat(0),player.x+1-32,player.y-7,7)
	pal()
	-- actual
	-- level armor colors
	armor = {4,13,12,9,11,10,8}
	pal(12,armor[1+flr(player.level/2)])
	drawhumanoid(player,1)

	if (intro == 0) then
	drawenemies()
	drawitems()
	drawtorch()
	drawspell()
	drawshadow()
	drawdmg()
	drawhealing()
	end
	camera()

	if (gameover == 1) then
		rectfill(0,120,128,128,0)
		printc("*** gam➡️ 🅾️ver ***",122,5)
		printc("*** gam➡️ 🅾️ver ***",123,8)
		stop()
	end

	if (gameover == 2) then
		rectfill(0,120,128,128,0)
		printc("success! found the exit!",122,5)
		printc("success! found the exit!",123,10)
		stop()
	end

		rectfill(0,0,128,8,0)
		rectfill(0,0,8,128,0)
		rectfill(120,0,128,128,0)
	
	if (intro == 1) then
		for y=15,22 do
			o = cos(y+time()*0.3)*2
			o2 = cos((y+0.05)+time()*0.3)*2			
			o3 = cos((y+0.1)+time()*0.3)*3			
			printc2("errand knight",flr(o),5,2)
			printc2("errand knight",flr(o2),5,9)
			printc2("errand knight",flr(o3),5,10)
			printc3("       a mini \^t\^wrpg\^-t\^-w by visy",18,5)
			printc3("       a mini \^t\^wrpg\^-t\^-w by visy",19,8)
			print  ("                      pumpuli",1,27,5)
			print  ("                      pumpuli",1,28,8)
		end
	end

	if (player.y >= 0 and intro == 2) then intro = 1 end
	if (player.y > 24 and intro == 1) then intro = 0 end
	
	if (intro == 0) then
		drawui()

	end

end
__gfx__
000000000006000055555550555555500006006000000000000000000000000000000000000000000000000a0000000000000000000000000000000000000000
00000000006600600500050005000500006606600000000000000000000000000000000000008000000000aa0000000000000003300000000000000000000000
0070070000660660555555555555555000660660000000000000000000000000000000000338a83000000aa003300b300000013bb31000000000000330000000
0007700005ccc66c66666666666666650c66ccc500000007000000000000000000007700393383330000aa0033333333000013bbbb3100000000013bb3100000
000770000c7ccccc333a2225333a22250ccccccc0000007700000889000000000077700097933003000aa0000b03300300013bbbbbb31000000013bbbb310000
007007000c7cfcfc33a9a22533a9a2250ccccccc00000770000008a800000000077000000900000000aa0000000000000013bbbbbbbb310000013bbbbbb31000
000000000ccc0c0c3a999a253a999a250ccccccc0000770000005e8800000007770000000000000005a0000000000000013bbbbbbbbbb3100013bbbbbbbb3100
000000000ccc0c0caaaaaaa5aaaaaaa50ccccccc000770000005e500000000770000000000000000550000000000000013bbbb3bb3bbbb31013bbbbbbbbbb310
1555551000cfffff00cfffff00cfffff00cffffc00770000005e500000005670000000009990dddddddddddddddddd9013bbbb3bb3bbbb3113bbbb3bb3bbbb31
56666650005555550055555500555555005555550560000005e500000ccf5000000000009440111111111111111111903bbbbb3bb3bbbbb33bbbbb3bb3bbbbb3
577777500ccccccc0ccccccc0ccccccc0cccccccf5000000fe500000cccff000000000009000dddddddddddddddddd903bbbbbbbbbbbbbb33bbbbb3bb3bbbbb3
555555500ccccccc0ccccccc0ccccccc0cccccccff000000ff000000cc000000000000009901909091901901901111903bbbbbbbbbbbbbb33bbbbbbbbbbbbbb3
aaaaaaa0ff44aa44ff44aa44ff44aa44ff44444400000000000000000000000000000000940d994099409490990ddd9003bbbbbbbbbbbb3003bbbbbbbbbbbb30
2a999a30ffdd55ddffdd55ddffdd55ddffdd55dd00000000000000000000000000000000900194019401999094901990003bbbbbbbbbb300003bbbbbbbbbb300
22a9a3300055005500cc0055005500cc0055005500000000000000000000000000000000900d90dd90dd9490909094900003bbbbbbbb30000003bbbbbbbb3000
222a333000cc00cc000000cc00cc000000cc00cc0000000000000000000000000000000099909011901191909090999000003333333300000000333333330000
22aaa3300008000082820000bbb3000009900990000000000c1c1c10000000000000000000000000555555555555555400005550550000001111101000110011
2aa9aa300066006082820000b300bbb39aa99aa9000000001aabb99c000000000000000011110000566666666666665400057775775000000111101000110000
22a9a3300086086082828882bbb30b309aaaaaa900000000caabb99c0000000000000000cccc1110564494949444965400057775775000001100001010000111
22aaa330005526658882808200b30b309aa00aa90000000918844eec000000000000a900ccccfff1564964949494965400057775775000000011110111110000
2aaaaa300522555582828882b3b30b309aa00aa9000000aac8844eec0000000000aaa000ccccff10564494449494965400057775775000001110010100001111
29a9a9300555757582828200bbb30b309aaaaaa900000aa01226633c000000000aa00000cccc1100566494949494965400005775775000000001110111111110
2aa9aa30022585858282820000000b3009aaaa900000aa00c226633c0000000aaa00000011110000564494949444965400005777777500000111110111110001
22aaa330055585850000820000000b30009aa900000aa0000cccccc0000000aa0000000000000000566666666666665400005771717500000000101111111011
77070707005177710051777100517771009a900000aa000000000000000059a00000000000000000566664449666665400005777777500000000001111110000
70007007005555550055555500555555009a990005900000000999000227500000000000000000005666649496565654000005777e5000000011001111100000
77070707022222220222222202222222009aaa907500000000988890222770000000000000000230566664449666665400000057750000000111101111000110
70000007022222220222222202222222009a99007700000009822289220000000000000000002823566664666656565400000577775000000111100000001111
77077707774499447744994477449944009aaa900000000008200028000000000000000000033203566664666665665400005775577500000011001100001111
0000700077dd55dd77dd55dd77dd55dd009a99000000000002000002000000000000000000033000566666666666665400057559955750000000101000000110
00007000005500550022005500550022000900000000000000000000000000000000000000bb3000555555555555555400005077770500001111000010010000
00007000002200220000002200220000000000000000000000000000000000000000000000bb0000444444444444444000000077770000000000111110111000
00000000333333333333333300000000000000003333333333333333000000000166ddd011111111016622200166111001664440618688800656655656656560
0000333333333333b333333333330000000033333333333b33b333333333000016dddddd11111111162222221611111116444444528888886212122122112126
0033333333333333333333333333330000333333333333333333333b333333006dd66ddd11111111622662226116611164466444528668885188888888888815
333333333b333b33333333333b3333333333333333b3333333333333333333336d66762111111111626676216166763164667691618676216287668612677826
33333b3333333333333333b33333333333333b333333333333333333333333b3dd67762111111111226776211167763144677691628776215187768812676816
3333333333333333333333333333b333333333333333b3333b333b333b333333d126621511111111212662121136631341966919518888886186688888866825
3333333b33b333333b3333333333333333333333333333333333333333333333dd12215511111111221221221113313344199199621211226282288888888825
05333333333333333333333333b3330005333b33b3333333333333b3333333000dd1155011111111022112200111133004411990065656655281188008886816
0166444011111111016699900166bbb00166eee06196999006566556566565600166ccc01111111101665550016688800166eee061b6bbb00656655656656560
16444444111111111699999916bbbbbb16eeeeee52999999621212212211212616cccccc11111111165555551688888816eeeeee52bbbbbb6212122122112126
6446644411111111699669996bb66bbb6ee66eee5296699951999999999999156cc66ccc1111111165566555688668886ee66eee52b66bbb51bbbbbbbbbbbb15
6466762111111111696676416b6676316e6676216196762162976696126779266c6676c11111111165667621686676216e66768161b6762162b766b612677b26
446776211111111199677641bb677631ee677621629776215197769912676916cc6776c1111111115567762188677621ee67768162b7762151b776bb12676b16
412662151111111191466414b1366313e1266212519999996196699999966925c1266212111111115126621481266212e186681251bbbbbb61b66bbbbbb66b25
441221551111111199144144bb133133ee122122621211226292299999999925cc122122111111115512214488122122ee1881226212112262b22bbbbbbbbb25
0441155011111111099114400bb113300ee112200656566552911990099969160cc112201111111105511440088112200ee112200656566552b11bb00bbb6b16
0288288008ee8ee00e22e22090009000090009000900000000090009000000000000aa0000000000000077777770000000000000000600600006006055555555
28ee8e288e22e28ee28828e209000009000000090000009009000090000000000aaa89a00aaaaaa00077777777777000000dd000006606600066066011111111
28eeee288e22228ee28888e20009900000099000900990000009900000022999988888aa988888a0077777777777770000dccd00006606600066066056100561
28eeee288e22228ee28888e2009aa900909aa900009aa909009aa900222298888888888a8888888a77777777777777000dc11cd00c66ccc50c66ccc556100561
28eeee288e22228ee28888e2909aa900009aa900009aa900009aa90900022999988888aa988888a07777777777777770dc1001cd0ccccccc0ccccccc56100561
028ee28008e228e00e288e2000099009000990000009900000099000000000000aaa89a00aaaaaa07777777777777700c100001c0ccccccc0ccccccc56666661
00282800008e8e0000e2e20009000000090000909000009090000000000000000000aa00000000000777777777777000100000010ccccccc0ccccccc56100561
000080000000e00000002000000000909000900000090009009000900000000000000000000000000007777777700000000000000cccccccffcccccc56100561
1111111111111111101110111011101101110111011101110101010101010101000100010001000100010001000100010000000000cffffcffcffffc56100561
11111111111111111110111011101110101010101010101010101010101010101010101010101010010001000100010000000000ff5555550055555556666661
11111111111111111011101110111011110111011101110101010101010101010100010001000100000100010001000100000000ffcccccc00cccccc56100561
1111111111111111111011101110111010101010101010101010101010101010101010101010101001000100010001000000000000cccccc00cccccc56100561
11111111111111111011101110111011011101010111010101010101010101010001000100010001000100010001000100000000004444440044444456100561
1111111111111111111011101110111010101110101011101010101010101010101010101010101001000100010001000000000000dd55dd00dd55dd56666661
1111111111111111101110111011101111010101110101010101010101010101010001000100010000010001000100010000000000cc0055005500cc56100561
11111111111111111110111011101110101010111010101110101010101010101010101010101010010001000100010000000000000000cc00cc000056100561
2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4fbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbf
0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f6f6f6f6f6f6f6f6f6f6f6f6f6f6f6f6f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f
2fffffffffffffffffffffffffffff2f3fffffffffffffffffffffffffffff3f4fffffffffffffffffffffffffffff4fbfffffffffffffffffffffffffffffbf
0fffffffffffffffffffffffffffff0f5fffffffffffffffffffffffffffff5f6fffffffffffffffffffffffffffff6f7fffffffffffffffffffffffffffff7f
2fffffffffffffffffffffffffffff2f3fffffffffffffffffffffffffffff3f4fffffffffffffffffffffffffffff4fbfffffffffffffffffffffffffffffbf
0fffffffffffffffffffffffffffff0f5fffffffffffffffffffffffffffff5f6fffffffffffffffffffffffffffff6f7fffffffffffffffffffffffffffff7f
2fffffffffffffffffffffffffffff2f3fffffffffffffffffffffffffffff3f4fffffffffffffffffffffffffffff4fbfffffffffffffffffffffffffffffbf
0fffffffffffffffffffffffffffff0f5fffffffffffffffffffffffffffff5f6fffffffffffffffffffffffffffff6f7fffffffffffffffffffffffffffff7f
2fffffffffffffffffffffffffffff2f3fffffffffffffffffffffffffffff3f4fffffffffffffffffffffffffffff4fbfffffffffffffffffffffffffffffbf
0fffffffffffffffffffffffffffff0f5fffffffffffffffffffffffffffff5f6fffffffffffffffffffffffffffff6f7fffffffffffffffffffffffffffff7f
2fffffffffffffffffffffffffffff2f3fffffffffffffffffffffffffffff3f4fffffffffffffffffffffffffffff4fbfffffffffffffffffffffffffffffbf
0fffffffffffffffffffffffffffff0f5fffffffffffffffffffffffffffff5f6fffffffffffffffffffffffffffff6f7fffffffffffffffffffffffffffff7f
2fffffffffffffffffffffffffffff2f3fffffffffffffffffffffffffffff3f4fffffffffffffffffffffffffffff4fbfffffffffffffffffffffffffffffbf
0fffffffffffffffffffffffffffff0f5fffffffffffffffffffffffffffff5f6fffffffffffffffffffffffffffff6f7fffffffffffffffffffffffffffff7f
2fffffffffffffffffffffffffffff2f3fffffffffffffffffffffffffffff3f4fffffffffffffffffffffffffffff4fbfffffffffffffffffffffffffffffbf
0fffffffffffffffffffffffffffff0f5fffffffffffffffffffffffffffff5f6fffffffffffffffffffffffffffff6f7fffffffffffffffffffffffffffff7f
2fffffffffffffffffffffffffffff2f3fffffffffffffffffffffffffffff3f4fffffffffffffffffffffffffffff4fbfffffffffffffffffffffffffffffbf
0fffffffffffffffffffffffffffff0f5fffffffffffffffffffffffffffff5f6fffffffffffffffffffffffffffff6f7fffffffffffffffffffffffffffff7f
2fffffffffffffffffffffffffffff2f3fffffffffffffffffffffffffffff3f4fffffffffffffffffffffffffffff4fbfffffffffffffffffffffffffffffbf
0fffffffffffffffffffffffffffff0f5fffffffffffffffffffffffffffff5f6fffffffffffffffffffffffffffff6f7fffffffffffffffffffffffffffff7f
2fffffffffffffffffffffffffffff2f3fffffffffffffffffffffffffffff3f4fffffffffffffffffffffffffffff4fbfffffffffffffffffffffffffffffbf
0fffffffffffffffffffffffffffff0f5fffffffffffffffffffffffffffff5f6fffffffffffffffffffffffffffff6f7fffffffffffffffffffffffffffff7f
2fffffffffffffffffffffffffffff2f3fffffffffffffffffffffffffffff3f4fffffffffffffffffffffffffffff4fbfffffffffffffffffffffffffffffbf
0fffffffffffffffffffffffffffff0f5fffffffffffffffffffffffffffff5f6fffffffffffffffffffffffffffff6f7fffffffffffffffffffffffffffff7f
2fffffffffffffffffffffffffffff2f3fffffffffffffffffffffffffffff3f4fffffffffffffffffffffffffffff4fbfffffffffffffffffffffffffffffbf
0fffffffffffffffffffffffffffff0f5fffffffffffffffffffffffffffff5f6fffffffffffffffffffffffffffff6f7fffffffffffffffffffffffffffff7f
2fffffffffffffffffffffffffffff2f3fffffffffffffffffffffffffffff3f4fffffffffffffffffffffffffffff4fbfffffffffffffffffffffffffffffbf
0fffffffffffffffffffffffffffff0f5fffffffffffffffffffffffffffff5f6fffffffffffffffffffffffffffff6f7fffffffffffffffffffffffffffff7f
2fffffffffffffffffffffffffffff2f3fffffffffffffffffffffffffffff3f4fffffffffffffffffffffffffffff4fbfffffffffffffffffffffffffffffbf
0fffffffffffffffffffffffffffff0f5fffffffffffffffffffffffffffff5f6fffffffffffffffffffffffffffff6f7fffffffffffffffffffffffffffff7f
2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4fbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbf
0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f6f6f6f6f6f6f6f6f6f6f6f6f6f6f6f6f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0166555011111111016688800166ccc00166aaa061565550065665565665656000999000009aa9000000000001663330a999999a007777000000000000000000
16555555111111111688888816cccccc16aaaaaa52555555621212212211212609aaa900009aa9000000000016333333990000990755557000bbbb0000000000
6556655511111111688668886cc66ccc6aa66aaa52566555515555555555551509a6a900009aa900000000006336633399000099007575000b3333b000000000
6566762111111111686676216c6676316a66769161567621625766561267752600666000009aa900000000006366765199000099075555700b0330b000000000
556776211111111188677621cc677631aa67769162577621515776551267651609666900009aa900000000003367765199000099007557000b3333b000000000
512662151111111181266212c1366313a196691951555555615665555556652509a6a900009aa9007070000031566515990000990005500000b33b0000000000
551221551111111188122122cc133133aa1991996212112262522555555555259aaaaa90009aa90007000000331551559900009900077000000bb00000000000
0551155011111111088112200cc113300aa1199006565665525115500555651699999990009aa9007070000003311550a999999a000000000000000000000000
__label__
20208888888888888888888822222222222222222222222220333000000000000000000000000000000000000000000000000009990dddddddddddddddddd900
202000000000000000000000000000000000000000000000003000333000000000000000000000000000003300b300003300b309440111111111111111111900
20202220000000000000000000000000000000000000000000333003000000000000000000000000000003333333230333333339000dddddddddddddddddd900
22202020000000000000000000000000000000000000000000003003000000000000000000000000000000b033028230b0330039901909091901901901111900
2020222000000000000000000000000000000000000000000030300300000000000000000000000000000000003320300000000940d994099409490990ddd900
20202000000000000000000000000000000000000000000000333003000000000000000000000000000000000033000000000009001940194019990949019900
20202000000000000000000000000000000000000000000000000003000000000000000000000000000000000bb300000000000900d90dd90dd9490909094900
00002000000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb03000000000000000000000000000000000bb0000000000009990901190119190909099900
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000001100000116cccccc11000001010000001100000101000000110000010100000011000001010000001100000116aaaaaa16aaaaaa1655500000000
00000000010000111106cc66ccc0001111000010010000111100001001000011110000100100001111000010010000111106aa66aaa6aa66aaa6556600000000
00000000011000000016c6676310000000111110111000000011111011100000001111101110000000111110111000000016a6676916a6676916566700000000
0000000001001111111cc677631011111110100011001111111010001100111111101000110011111110100011001111111aa677691aa6776915567700000000
0000000001000001111c1366313000011110100011000001111010001100000111101000110000011110100011000001111a1966919a19669195126600000000
0000000000011111000cc133133111110000101000011111000010100001111100001010000111110000101000011111000aa199199aa1991995512200000000
00000000010000001111cc113300000011110111110000001111011111000000111101111100000011110111110000001111aa119900aa119911551100000000
00000000051116655501166ccc11111110010100001111111001010000111111100101000011111110010100001111111001166aaa11166aaa01166500000000
000000000551655555516cccccc11000011101111111100001110111111110000111011111111000011101111111100001116aaaaaa16aaaaaa1655500000000
00000000055655665556cc66ccc0010111110111110001011111011111000101111101111100010111110111110001011116aa66aaa6aa66aaa6556600000000
00000000021656676216c6676310110000101111111011000010111111101100001011111110110000101111111011000016a6676916a6676916566700000000
0000000002155677621cc677631000000000111111000000000011111100000000001111110000000000111111000000000aa677691aa6776915567700000000
000dd00001551266215c1366313000001100111110000000110011111000000011001111100000001100111110000000110a1966919a19669195126600000000
00dccd0005555122155cc133133110011110111100011001111011110001100111101111000110011110111100011001111aa199199aa1991995512200000000
0dc11cd0051155115510cc113311110111100000001111011110000000111101111000000011110111100000001111011110aa119911aa119910551100000000
dc1001cd051116655500166ccc11110011001100001111001100110000111100110011000011110011001100001111001100166aaa11166aaa00166500000000
c10dd01c0551655555516cccccc11000001010000001100000101000000110000010100000011000001010000001100000116aaaaaa16aaaaaa1655500000000
10dccd01055655665556cc66ccc0001111000010010000111100001001000011110000100100001111000010010000111106aa66aaa6aa66aaa6556600000000
0dc11cd0021656676216c6676310000000111110111000000011111011100000001111101110000000111110111000000016a6676916a6676916566700000000
dc1001cd02155677621cc677631011111110100011001111111010001100111111101000110011111110100011001111111aa677691aa6776915567700000000
c100001c01551266215c1366313000011110100011000001111010001100000111101000110000011110100011000001111a1966919a19669195126600000000
1000000105555122155cc133133111110000101000011111000010100001111100001010000111110000101000011111000aa199199aa1991995512200000000
00000000050055115511cc113300000011110111110000001111011111000000111101111100000011110111110000001111aa119900aa119911551100000000
00000000051116655501166ccc11111110010100001111111001010000111111100101000011111110010100001111111001166aaa11166aaa01166500000000
000000000551655555516cccccc11000011101111111100001110111111110000111011111111000011101111111100001116aaaaaa16aaaaaa1655500000000
00000000055655665556cc66ccc0010111110111110001011111011111000101111101111100010111110111110001011116aa66aaa6aa66aaa6556600000000
00000000021656676216c6676310110000101111111011000010111111101100001011111110110000101111111011000016a6676916a6676916566700000000
0000000002155677621cc677631000000000111111000000000011111100000000001111110000000000111111000000000aa677691aa6776915567700000000
0000000001551266215c1366313000001100111110000000110011111000000011001111100000001100111110000000110a1966919a19669195126600000000
0000000005555122155cc133133110011110111100011001111011110001100111101111000110011110111100011001111aa199199aa1991995512200000000
00000000051155115510cc113311110111100000001111011110000000111101111000000011110111100000001111011110aa119911aa119910551100000000
00000000051116655500166ccc11110011001100001111001100110000111100110011000011110011001100001111001100166aaa11166aaa00166500000000
000000000551655555516cccccc11000001010000001100000101000000110000010100000011000001010000001100000116aaaaaa16aaaaaa1655500000000
00000000055655665556cc66ccc0001111000010010000111100001001000011110000100100001111000010010000111106aa66aaa6aa66aaa6556600000000
00000000021656676216c6676310000000111110111000000011111011100000001111101110000000111110111000000016a6676916a6676916566700000000
0000000002155677621cc677631011111110100011001111111010001100111111101000110011111110100011001111111aa677691aa6776915567700000000
0000000001551266215c1366313000011110100011000001111010001100000111101000110000011110100011000001111a1966919a19669195126600000000
0000000005555122155cc133133111110000101000011111000010100001111100001010000111110000101000011111000aa199199aa1991995512200000000
00000000050055115511cc113300000011110111110000001111011111000000111101111100000011110111110000001111aa119900aa119911551100000000
00000000051116655501166ccc11111110010100001111111001010000111111100101000011111110010100001111111001166aaa11166aaa01166500000000
000000000551655555516cccccc11000011101111111100001110111111110000111011111111000011101111111100001116aaaaaa16aaaaaa1655500000000
00000000055655665556cc66ccc0010111110111110001011111011111000101111101111100010111110111110001011116aa66aaa6aa66aaa6556600000000
00000000021656676216c6676310110000101111111011000010111111101100001011111110110000101111111011000016a6676916a6676916566700000000
0000000002155677621cc677631000000000111111000000000011111100000000001111110000000000111111000000000aa677691aa6776915567700000000
0000000001551266215c1366313000001100111110000000110011111000000011001111100000001100111110000000110a1966919a19669195126600000000
0000000005555122155cc133133110011110111100011001111011110001100111101111000110011110111100011001111aa199199aa1991995512200000000
00000000051155115510cc11331111011110000000111101111000000011110111100000001111011113b310001111011110aa119911aa119910551100000000
00000000051116655500110000111100110011000011656655606566556566565600656655621100113bbb310011110011001100001111001101555500000000
0000000005516555555010000001100000101000000621211116111111111122226644222222100013bbbbb31001100000101000000110000015666600000000
000000000556556655500010010000111100001001051555555515555555555554554555555000223bbbbbbb3100001111000010010000111105777700000000
00000000021656676211111011100000001111101116257665661576656226775466457665600002bbbbbbbbb110000000111110111000000015555500000000
0000000002155677621010001100111111101000110515776555157765544676586585776550443bbbb3b3bbbb3011111110100011001111111aaaaa00000000
0000000001551266215010001100000111101000110615665556156655555566585685665550003bbbb3b3bbbb30000111101000110000011112a99900000000
0000000005555122155010100001111100001010000625225556152255555555585695995558883bbbbbbbbbbb311111000010100001111100022a9a00000000
00000000050055115511011111000000111101111105251155151522550055565060959955000003bbbbbbbbb30000001111011111000000111222a300000000
000000000011111110010100001111111001010000116566556101000088889900600600009988883bbbbbbb30111111100101000011011100002aa000000000
000000000111100001110111111110000111011111162121111101224488800006600609999980000333333311111000011101111111100001020a0a00000000
00000000010001011111011111000101111101111105155555510222440009000660660066000000442202111100010111110111110001010112209a00000000
000000000110110000101111111011000010111111162576656022224480990054446640669000700020221111101100001011111110110000020a0a00000000
00000000010000000000111111000000000011111105157765502244880000004744444066000770000022111100000000001111110000000000aaa000000000
0000000000000000110011111000000011001111100615665550224480000000474f4f40600077008800221110000000110011111000000011020a0a00000000
00000000000110011110111100011001111011110006252255502244000990004440404000077009884022220001100111101111000100010112a09000000000
000000000011110111100000001111011110000000152511552000000099990644404040007709098840000000111101111000000011110111020a0a00000000
000000000010110011001100001010001000006000616566556044000099660004fffff00770660088004400001111001100110000110100010202a300000000
000000000001000000000000000100000006010102062121112040000009600005555550560660000040400000011000001010000001100000022a0a00000000
00000000000000111000001000000010100010005005155555500040080000604444444f50000099880000200100001111000010010000110102099900000000
00000000010000000001010001000000000605060506257665622240889000004444444ffa60000000442220111000000011111011100000000aaa0a00000000
000000000000111010101000100010101010007000551577655020008800990ff44aa44006009988884020001100111111101000110001110115055500000000
000000000100000111000000110000010106050605061566555020008800000ffdd55dd066000008884020001100000111101000110000011105770700000000
00000000000110100000101000001010000020005006252255502020000899900440055000099988000020100001111100001010000101110005066600000000
00000000010000000111010101000000010505010505251155110222440000006006044666000000442202111100000011110111110000001101550500000000
000000000a101660aa001660aa101060a0001060a011166aaa01166aaa88866aaa09600aaa99866aaa02166aaa11166aaa01166aaa11066a0a01066500000000
000000000a010a0a0a010a0a0a010a0a0a010a0a0a016aaaaaa16aaaaaa86aaaaaa96aaaaaa96aaaaaa26aaaaaa16aaaaaa16aaaaaa16a0aaa01650500000000
000000000aa6a066a0a6a066a0a0a060a0a0a060a0a6aa66aaa6aa66aaa6aa66aaa6aa66aaa6aa66aaa6aa66aaa6aa66aaa6aa66aaa60a660aa6056600000000
00000000090606070906060709060607090606070906a6676916a6676946a6676996a6676986a6676926a6676916a6676916a6676916a6076906560700000000
000000000910a6706010a6706010a0706010a070601aa677691aa677694aa677698aa677694aa677692aa677691aa677691aa677691a06770915067700000000
00000000010a0906910a0906910a0906010a0906010a1966919a1966929a4966989a8966989a4966929a1966919a1966919a1966919a19069105120600000000
00000000099aa090109aa0901090a0901090a090109aa199199aa199299aa299499aa499499aa299299aa199199aa199199aa199199a01990995012200000000
0000000009010a0109100a0109110a0109000a010901aa119910aa119922aa229940aa449922aa229910aa119911aa119910aa119911aa019900550100000000
000000000a101660aa001060a011066a0a0000600011066a0a00166aaa11166aaa00466aaa201660aa00166aaa11066a0a001660aa101660aa00166000000000
000000000a010a0a0a010a0a0a016a0aaa010a0a0a016a0aaa016aaaaaa16aaaaaa26aaaaaa20a0a0a016aaaaaa16a0aaa010a0a0a010a0a0a01050500000000
0000000000a6a066a0a0a060a0a60a660aa0a000a0060a660aa6aa66aaa6aa66aaa6aa66aaa6a066a0a6aa66aaa60a660aa6a066a0a6a066a0a6506600000000
0000000009060607090606070906a607690606070906a6076906a6676916a6676926a667691606070906a6676916a60769060607090606070906060700000000
000000000010a6706010a070601a067709100070001a0677091aa677691aa677691aa6776910a670601aa677691a06770910a6706010a6706010567000000000
00000000010a0906910a0906010a1906910a0906010a1906910a1966919a1966919a1966919a0906910a1966919a1906910a0906910a09069105020600000000
00000000009aa0901090a090109a01990990a000100a0199099aa199199aa199199aa199199aa090109aa199199a0199099aa090109aa0901095502000000000
0000000009000a0109110a010900aa0199010a010900aa019901aa119900aa119911aa1199000a010911aa119900aa0199010a0109000a010911050100000000
0000000000111111100101000010111010010100001010101000010000101010100000000011011100001660cc11066c0c01166ccc101060c000166000000000
0000000001011000011101011101000001010101110100000101010101010000010101010101100001010c0c0c016c0ccc016cccccc10c0c0c010c0c00000000
000000000000010111110111010000011011011101000000101100111000000010100010100001010116c066c0c60c660cc6cc66ccc0c060c0c6c06600000000
00000000010011000010110111000100000011011100010000000101010001000000010101001100000606070306c6076306c667631606070306060700000000
000000000000000000000111010000000000011101000000000011101000000000001010100000000000c670601c0677031cc6776310c0706010c67000000000
00000000000000001100110110000000110011011000000001000101100000000100010100000000110c0306310c1306310c1366313c0306010c030600000000
00000000000110011110011100011000101001110000100010101010000010001010101000010001011cc030103c0133033cc1331330c030103cc03000000000
0000000000111101111000000001010101100000000101010100000000110101010000000001110111000c010311cc013300cc1133110c0103000c0100000000
000000000010100010001000001101000100100000101100110001000010110011001100001010001000066c0c101660cc001660cc11066c0c00166000000000
0000000000010000000000000001100000000000000100000000100000010000000000000001000000016c0ccc010c0c0c010c0c0c016c0ccc010c0c00000000
0000000000000010100000100000001101000010000000111000001001000011100000100000001010060c660cc6c066c0c6c066c0c60c660cc6c06600000000
000000000100000000010100010000000001010001000000000111001100000000010100010000000006c60763060607030606070306c6076306060700000000
00000000000010101010100010000111011010001000111010100000010011101010100010001010101c06770310c6706010c670601c06770310c67000000000
00000000010000010100000001000001110000000100000111001000110000011100000011000001010c1306310c0306310c0306310c1306310c030600000000
00000000000010100000101000010111000010100001101000000010000110100000101000001010000c0133033cc030103cc030103c0133033cc03000000000
000000000100000001010101010000001101010101000000011101011100000001110101010000000101cc0133000c0103110c010300cc0133010c0100000000
00000000001000100000810000110111080000000010101010010100001011101000010000101110100101000810111010000100001111111001066c00000000
000000000101000001060106010110000601010101010000010101011101000001010101010100000101011166110000010101010101100001116c0c00000000
000000000100000010086086100001680680001010000000101101110100000110110011100000011011011186086001101100111000010111160c6600000000
00000000010001000005090601001506250001010100010000001101110001000000010101000100000011115526050000000901010011000016c60700000000
000000000100000000502aa05000055502201010100000000000011101000000000011101000000000001115225055000000aa1010000000000c067700000000
00000000000000000105070a500005057505010100000000010011011000000011000101100000001100111555750500110a010110000000110c130600000000
000000000000100010025050a0010585052010100000100010100111000110001010101000011000101011122585800010aa101000011001111c013300000000
0000000000010101010508080a11a50585050000000101010100000000010101011000000011010101100005558505010aa00000001111011110cc0100000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000a0a0aaa0a0a00000aaa0aa00000cc00cc0c0c0c0000000ccc0ccc0ccc00070007070700000007770770
000000000000000000000000000000000000000000000a0a0a000a0a00a00a0a00a0000c000c0c0c0c0c0000c00c0c0c0c0c0c00070007070700007007070070
000000000000000000000000000000000000000000000aa00aa00aaa00000a0a00a0000ccc0c0c0c0c0c0000000c0c0c0c0c0c00070007070700000007070070
000000000000000000000000000000000000000000000a0a0a00000a00a00a0a00a000000c0c0c0c0c0c0000c00c0c0c0c0c0c00070007770700007007070070
000000000000000000000000000000000000000000000a0a0aaa0aaa00000aaa0aaa000cc00cc000cc0ccc00000ccc0ccc0ccc00077700700777000007770777
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000210000000101010100000000000000000000000001010101000000000000000000000180010101010101018001010101010101800101010101010000000000000004040400000000000c00000000000000000000000000000002
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001800101010101014040000100008000
__map__
5b5bfffffffffff0f0fff0f0ffff5b5bf3f4f3f4f3f4f3f4f3f4f3f4f3f4f3f44b4bffff4b4bffff4b4bffff4b4b4b4b5b5bffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
5b5bfffffffffff0f0fff0f0ffff5b5bf3f5f6f7f3f5f6f7f3f5f6f7f3f5f6f74b4bffff4b4bffff4b4bffff4b4b4b4b5b5bffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
f2f2fffffffffff2f2f2f2f2f2f2f2f2f3f5f6f7f3f5f6f7f3f5f6f7f3f5f6f74b4bffff4b4bffff4b4bffff4b4b4b4bf2f2ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
f2f2fffffffffff2f2f2f2f2f2f2f2f2f3f5f6f7f3f5f6f7f3f5f6f7f3f5f6f74b4bffff4b4bffff4b4bffff4b4b4b4bf2f2fffffffffffffffffffffffff3f3ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
f2f2ff2626f2f2f2f2f2f2f2f2f2f2f2f3f4f3f4f3f4f3f4f3f4f3f4f3f4f3f44b4bffffffffffffffffffffffff4b4bf2f2fffffffffffffffffffffffff3f3ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
f2f2fff2f2f2f2f2f2f2f2f2f2f2f2f2f3f4f3f4f3f4f3f4f3f4f3f4f3f4f3f44b4bffffffffffffffffffffffff4b4bf2f2fffffffffffffffffffffffff3f3ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
f2ff6ff2f2f2f2f2f2f2f2f2f2f2f2f2f3f4f3f4f3f4ffffffffffffffffffffffffffffffffffffffffffffffffffffffff6ff3f3f3f3f3f3f3fffff3f3f3f3ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
f2ff7ff2f2f2f2f2f2f2f2f2f2f2f2f2f3f4f3f4f3fffffffffffffffffffffffffffffffffffffffffeffffffffffffffff7ff3f3f3f3f3f3f3fffff3f3f3f3ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
f2f27ff2f2f2f2f2f2f2f2f2f2f2f2f2f3f4f3f4fffffffffff6f3f4f3f4f3f44b4b4b4bffff4b4b4b4bffff4b4b4b4bf2f27ff3f3f3f3f3f3f3fffff3f3f3f3ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
f2f27ff2f2f2f2f2f2f2f2f2f2f2f2f2f3f4f3fffffffffff6fff3f4f3f4f3f44b4b4b4bffff4b54544bffff4b4b4b4bf2f27ff3f3f3f3f3f3f3fffff3f3f3f3ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
f2f27ff2f2f2f2f2f2f2f2f2f2f2f2f2f3f4f3fffffffff6f3f4f3f4f3f4f3f44b4b4b4bffff4b54544bffff4b4b4b4bf2f27ff3f3f3f3f3f3f3fffff3f3f3f3ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
f2f27ff2f2f2f2f2f2f2f2f2f2f2f2f2f8f4fffffffff6fff3f4f3f4f3f4f3f44b4b4b4bffff4b4b4b4bfffffffffffff2f27ff3f3f3f3f3f3f3fffff3f3f3f8ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
f2ff7ffffffffffffffffffffffffffff9ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff7ffffffffffffffffffffffffff9ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
f2fffffffffffffffefffffffffffffff9fffffff6fffffffffffffffffffffffffffffffffffdffffffffff4b4bfffffffffffffffffffffefffffffffffff9ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f5f6f7f5f6f7f5f6f7f5f6f7fffff5f64b4b4b4b4b4b4b4b4b4b4b4b4bffff4bf2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f5f6f7f5f6f7f5f6f7f5f6f7fffff5f64b4b4b4b4b4b4b4b4b4b4b4b4bffff4bf2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
f5f6f7f2f2f7f5f6f7f5f6f7fffff7f5f4f4f4f4f4f4f4fbfbfbfbfbfb6ffbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbf4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4fbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfb
f5f6f2f2f2f2f5f6f7f5f6f7fffff7f5fffffffffffff4fbfbfbfbfbfb7ffbfbf4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4fbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbf0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f6f6f6f6f6f6f6f6f6f6f6f6f6f6f6f6f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7
f5f2f2f2f2f2f2f6f7f5f6f7fffff7f5fffffffffffff4fbfbfbfbfbfb7ffbfbf4fffffffffffffffffffffffffffff4fbfffffffffffffffffffffffffffffbf0fffffffffffffffffffffffffffff0f5fffffffffffffffffffffffffffff5f6fffffffffffffffffffffffffffff6f7fffffffffffffffffffffffffffff7
f2f2f2f2f2f2f2f2f7f5f6f7fffff7f5fffffffffffff4fbfbfbfbfbfb7ffbfbf4fffffffffffffffffffffffffffff4fbfffffffffffffffffffffffffffffbf0fffffffffffffffffffffffffffff0f5fffffffffffffffffffffffffffff5f6fffffffffffffffffffffffffffff6f7fffffffffffffffffffffffffffff7
f2f2f2f2f2f2f2f2f7f5f6f7fffff7f5fffffffffffff4f3f4f4f4f4f47ff4f3f4fffffffffffffffffffffffffffff4fbfffffffffffffffffffffffffffffbf0fffffffffffffffffffffffffffff0f5fffffffffffffffffffffffffffff5f6fffffffffffffffffffffffffffff6f7fffffffffffffffffffffffffffff7
f5f6f7f2f2f7f5f6f7f5f6f7fffff7f5fffffffffffff4f3f4ffffffff7ff4f3f4fffffffffffffffffffffffffffff4fbfffffffffffffffffffffffffffffbf0fffffffffffffffffffffffffffff0f5fffffffffffffffffffffffffffff5f6fffffffffffffffffffffffffffff6f7fffffffffffffffffffffffffffff7
f5f6f7f2f2f7f5f6f7f5f6f7fffff7f5f4f4f4f4f46ff4f3f4ffffffff7ff4f3f4fffffffffffffffffffffffffffff4fbfffffffffffffffffffffffffffffbf0fffffffff2f2fffffffffffffffff0f5fffffffffffffffffffffffffffff5f6fffffffffffffffffffffffffffff6f7fffffffffffffffffffffffffffff7
f5f6f7f2f2f7f5f6f7f5f6f7fffff7f5f3f3f3f3f37ff3f3f4ffffffff7ff4f3f4fffffffffffffffffffffffffffff4fbfffffffffffffffffffffffffffff8fffffffff2f2f2f2fffffffffffffff0f5fffffffffffffffffffffffffffff5f6fffffffffffffffffffffffffffff6f7fffffffffffffffffffffffffffff7
f5f6f7f2f2f7f5f6f7f5f6f7fffff7f5f3f3f3f3f37ff3f3f4ffffffff7ff4f3f4fffffffffffffffffffffffffffff4fbfffffffffffffffffffffffffffff9fffffff2f2f2f2f2f2fffffffffffff0f5fffffffffffffffffffffffffffff5f6fffffffffffffffffffffffffffff6f7fffffffffffffffffffffffffffff7
f5f6f7f2f2f7f5f6fffffffffffff7f5f3f3f3f4f47fffffffffffffff7ff4f3f8fffffffffffffffffffffffffffff4fbfffffffffffffffffffffffffffdf9fffff2f2191a1bf2f2f2fffffffffff0f5fffffffffffffffffffffffffffff5f6fffffffffffffffffffffffffffff6f7fffffffffffffffffffffffffffff7
f5f6f7f2f2f7f5f6fffffffdfffff7f5f3f3f3f4fffffefffffffffffffffffff9fffffffffffffffffffffffffffff4fbfffffffffffffffffffff6f7f6f7fbf0f2f2f2f2f2f2f2f2f2f26ffffffff0f5fffffffffffffffffffffffffffff5f6fffffffffffffffffffffffffffff6f7fffffffffffffffffffffffffffff7
f5f6f7f2f2f7f5f6fffff6f7f5f6f7f5f3f3f3f4f4f4f4f3f4fffffff7fffffff9fffffffffffffffffffffffffffff4fbfffffffffffffffffff6f7f6f7f6fbf0f22c2dfffffffffff2f27ffffffff0f5fffffffffffffffffffffffffffff5f6fffffffffffffffffffffffffffff6f7fffffffffffffffffffffffffffff7
f5f6f7f2f2f7f5f6fffff6f7f5f6f7f5f3f3f3f3fffffffff426266ff4f4f4f3f46ffffffffffffffffffffffffffff8f8fffffffffffffffff6f6f7f6f7f6fbf0fb3c3dfffffffffff2f27ffffffff0f5fffffffffffffffffffffffffffff5f6fffffffffffffffffffffffffffff6f7fffffffffffffffffffffffffffff7
f5f6f7f2f2f7f5f6fffffffffff6f7f5f3f4f4f4f4f4f4f4f4f4f47ff4f3f3f3f47ffffffffffffffffffffffffffff9f9fffffffffffffff6f7f6f7f6f7f6fbf0fb2a2bfffffffffff2f27fffffffffffffffffffffffffffffffffff3030f5f6fffffffffffffffffffffffffffff6f7fffffffffffffffffffffffffffff7
f5f6f7f2f2f7f5f6f0f0f6f7fff6f7f5f3f4fffffffffffffffffffff4f3f3f3f4fffffffffffffffffefefefefefff9f9fffffffffffff6f7f6f6f7f6f7f6fbf0fb3a3bfaffffffffffff7fffffffffffffffffffffffffffffffffff3030f5f6fffffffffffffffffffffffffffff6f7fffffffffffffffffffffffffffff7
f5f6f7f2f2f7f5f6f0f0f6f7fffff7f5f3f4fffff4f4f4f4f4f4f4f4f4f3f3f3f42626f2f3f4f2f3f4f2f3f4f2f3f4f4fbf6f7f6f7f6f7f6f7f6f7f6f7f6f7fbf0fbf5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f6fffffffffffffffffffffffffffff6f7fffffffffffffffffffffffffffff7
__sfx__
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
910105061855018550185501855018550185501855000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010000003064030620306100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010402031c05300550005500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4d000000346101c120286101c61010610000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010000010055000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4d020001187561d700217002670000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00010000070400e0401a0201804011010100100e0500d0401f050130501d050250502805000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00030000051500813018330183301d3201c3101e3101b310193501632014320113300c3200c3200c3200932008320063300532003310023200132000300013000031000000000000000000000000000000000000
000200000c35013550165500865018650076400664005650056402633027320293100c050050400f1200a110061000410004100211001a1001810015100241000f1000a100071000510000000000000000000000
000200000b6103c6003a6101462014420124300e4300e410000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011100200c1100c11014110131200c1110c12014110131200c1200c11014110131200c1110c12012110131200c1100c12014110131200c1100c12014110131200c1200c12014110131200c1210c1201311014120
000400001c2501725015240102400e2300b2200921008220062100521000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200000c200090100a020090202821020210172000e200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00030000000001a0501f0501e75022750217501c7501875014750117500d75008750067500a7501575023750117500e7500005000000000000000000000000000000000000000000000000000000000000000000
0002000023050170201a0401c0401d0501f0502005020040170300a42009550085500455000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000400000965008640036300d4400f450114601b460144500a450044501645014550175301a5101c5001e50000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100001755019550275502755026550225500e5500a550000001655013550105500b5500000000000045500f5500f5500f5500f550000000000000000000000000000000000000000000000000000000000000
0002000000000111101212015130181401a1401c1401e130201200000000000211201e1201a140191400000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00020000253503432033330132402f340162402a3401b250243500c2501f350072601936013350333103535036350383500000000000000000000000000000000000000000000000000000000000000000000000
000100061a0101a03026040260502502021010185601a5602256023560235501e5401b53011520005200050000500005000050000500005000050000500005000050000500005000050000500005000050000500
000100010d1500e11010130121501415016150181501a1501c1501d1501d1501c1401b13019130161201311010110221002110000100001000010000100001000010000100001000010000100001000010000100
011100000c4212162714510000000c4260000000000000000c42600000000000c426000000c4260c4160c1260c4122162714510000000c4260000000000000000c4260000000000000000c422000170000000000
011100000c0330000000004000000c0330000000000000000c0330000000000000000c0330000500000000000c0330000000000000000c0330000000000000000c0330000000000000000c033000000000000000
00010000277002371024720287202a7302a73000730007000070000700197201472017730197301a7301d7101e750007000070000700007000070000700007000070000700007000070000700007000070000700
000200002e1502e1102b1402a130131702417024170261700b1600b1502e1500e1500010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
010200002a61403c5300c4300c0000c0000c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00030000241101c120111400d1400d6200a6100b6100c6200c62010610146101a61021610246100c6100b6000a600086000560004600056000260002600000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000201cf141cf101cf101cf101cf241cf201cf201cf201cf341cf301cf301cf301cf441cf401cf401cf401cf541cf501cf501cf501cf441cf401cf401cf401cf341cf301cf301cf301cf241cf201cf201cf20
0110002023f1423f1023f1023f1023f2423f2023f2023f2023f3423f3023f3023f3023f4423f4023f4023f4023f5423f5023f5023f5023f4423f4023f4023f4023f3423f3023f3023f3023f2423f2023f2023f20
0110002021f1021f1021f1021f1021f2021f2021f2021f2021f3021f3021f3021f3021f4021f4021f4021f4021f5021f5021f5021f5021f4021f4021f4021f4021f3021f3021f3021f3021f2021f2021f2021f20
011000201cf101cf101cf101cf101cf201cf201cf201cf201cf301cf301cf301cf301cf401cf401cf401cf401cf501cf501cf501cf501cf401cf401cf401cf401cf301cf301cf301cf301cf201cf201cf201cf20
0110002023f1023f1023f1023f1023f2023f2023f2023f2023f3023f3023f3023f3023f4023f4023f4023f4023f5023f5023f5023f5023f4023f4023f4023f4023f3023f3023f3023f3023f2023f2023f2023f20
0110002021f1021f1021f1021f1021f2021f2021f2021f2021f3021f3021f3021f3021f4021f4021f4021f4021f5021f5021f5021f5021f4021f4021f4021f4021f3021f3021f3021f3021f2021f2021f2021f20
011000001df101df101df101df101df201df201df201df201df301df301df301df301df401df401df401df401df501df501df501df501df401df401df401df401df301df301df301df301df201df201df201df20
011000001af101af101af101af101af201af201af201af201af301af301af301af301af401af401af401af401af501af501af501af501af401af401af401af401af301af301af301af301af201af201af201af20
0110002021f1421f1021f1021f1021f2421f2021f2021f2021f3421f3021f3021f3021f4421f4021f4021f4021f5421f5021f5021f5021f4421f4021f4021f4021f3421f3021f3021f3021f2421f2021f2021f20
011000001df141df101df101df101df241df201df201df201df341df301df301df301df441df401df401df401df541df501df501df501df441df401df401df401df341df301df301df301df241df201df201df20
0110002004e5004e5004e5004e5004e5004e5004e5004e5004e5004e5004e5004e5004e5004e5004e5004e5004e5004e5004e5004e5004e5004e5004e5004e5004e5004e5004e5004e5004e5004e5004e5004e50
0110002005e5005e5005e5005e5005e5005e5005e5005e5005e5005e5005e5005e5005e5005e5005e5005e5005e5005e5005e5005e5005e5005e5005e5005e5005e5005e5005e5005e5005e5005e5005e5005e50
0110002004e5004e5004e5004e5010e50000000000000000000000000004e5004e5010e500000000000000000000000000000000000010e500000000000000000000000000000000000010e500be500be500be50
0110002005e5005e5005e5005e5011e50000000000000000000000000005e5005e5011e500000000000000000000000000000000000011e500000000000000000000000000000000000011e5013e5013e5013e50
011000200455304e5004d5004e5010c5010c5004d5000000040530000004d5004e5010c5010c5004d5000000040530000004d500000010c5010c5004d5000000040530000004d500000010c5010c5004d500be50
011000200455305e5005d5005e5011c5011c5004d5000000040530000005d5005e5011c5011c5004d5000000040530000004d500000011c5011c5004d5000000040530000004d500000011c5011c5004d5013e50
0110002004110041100c1100b12004111041200c1100b12004120041100c1100b12004111041200c1100b12004110041200c1100b12004110041200c1100b12004120041200c1100b12004121041200b1100c120
0110002005110051100c1100b12005111051200c1100b12005120051100c1100b12005111051200c1100b12005110051200c1100b12005110051200c1100b12005120051200c1100b12005121051200b1100c120
0010000027d5300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
110800180da550da150ca550da1508a550ca1506a5508a1508a5506a150da5508a150fa550da1511a550fa1512a5511a1514a5512a1512a5514a150da5512a150c0050c0050c0050c00500005000050000000000
110800180fa550da150da550fa1508a550da1514a5508a150fa5514a150da550fa1514a550da150fa5514a150da550fa1512a550da1511a5512a150da5511a150ca050ca050c0050c00500005000050000500000
0010000027d5300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010800180dc500de5001f5001f500de500de500dc5001e500de500de5001f5001f500dc5001e5001f5001f500de500de500dc500de5001f5001f5001f5001f500000000000000000000000000000000000000000
010800180fc500fe5003f5003f500fe500fe500fc5003e500fe500fe5003f5003f500fc500fe5003f5003f500fe500fe500fc5003e500fe500fe5003f5003f500000000000000000000000000000000000000000
010600000cb10000000000000000000000cb1000000000000cd50000000000000000000000cb1000000000000cb10000000000000000000000cb1000000000000cd50000000000000000000000cb100000000000
__music__
01 41202122
00 41212324
00 41202122
00 41212324
01 41282122
00 41292324
00 41282122
02 41292324
01 412a2122
00 412b2324
00 412a2122
00 412b2324
01 412c1e1f
00 412d2726
00 412c1e1f
02 412d2726
01 412e2122
02 412f2324
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 413e3f37
00 413e3f37
00 413e3f37
06 413d3f36
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
03 4118170c

