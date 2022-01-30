pico-8 cartridge // http://www.pico-8.com
version 35
__lua__
gravity=0.1
intro = 1

player = { x = 8*2.5, y = 8*3, walk = 0, dir = 1, attack = 0, atime = 0, 
weapon = 5, aspeed = 3, acooldown = 24, acooltimer = 0, hb_x = 9, hb_y = 1, hb_s = 11, hp = 10, maxhp = 10, w = 9, h = 17, xv=0,yv=0,jumpheight=2,speed=0.8,friction=0.5,iframes=0,
moveframes=0,totalsouls = 0,souls=0, level=1,dead = false,deathframes=0,keys=0
}

enemies = {}
enemycount = 0

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

-- enemy types
enemy_skelly = 253
enemy_slime = 254

-- special tiles
tile_bg = 255
tile_door = 248

function solid(x,y)
 val = mget(x/8,(y+8)/8)
 return val>=240 and val < 250
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
		
			door = { x=mx*8,y=my*8, mx = mx, my = my, openframes=0,opened= false }
			add(doors,door)
		end

	end
	end
end


function drawdoors()
	for i=1, #doors do
		door = doors[i]	
		mx = door.mx
		my = door.my
		oo = 0
		if (door.openframes > 0) then
			oo = 32-door.openframes
		end
		if (door.openframes == -1 or door.opened == true) return
		sspr(0,8,8,24,mx*8,my*8,8-oo/4,24)
		end
end


function _init()
	music(0,500)
	initdoors()
	initenemies()
	
end

function collide_aabox(a,b)
    -- a is left most
    if(a.x>b.x) a,b=b,a
    -- screen coords
    local ax,ay,bx,by=flr(a.x),flr(a.y),flr(b.x),flr(b.y)
    ax+=1
    ay+=1
    bx-=1
    by-=1
    local xmax,ymax=bx+b.w,by+b.h
    if ax<xmax and 
     ax+a.w>bx and
     ay<ymax and
     ay+a.w>by then
     -- collision coords in a space
     return true,a,b,bx-ax,max(by-ay),min(by+b.h,ay+a.h)-ay
    end
end

function physics(po,isplayer)
	if (isplayer == true) then
	 po.xv+=(btnf(1)-btnf(0))*po.speed
 end

 po.xv*=po.friction

	if ((btn(0) == true or btn(1) == true) and isplayer) then
		if (po.xv>=0) then po.dir = 1
		else po.dir = -1 end
	end
	
	if (isplayer) then
		po.isjumping = btn(4)
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
	
 if(collidingsolid(po.x,po.y+1))then
     if(po.isjumping and not collidingsolid(po.x,po.y-1))then
					 if isplayer then
      	sfxi(0)
      else
       sfxi(6)
      end
      po.yv-=po.jumpheight
     end
 else
  po.yv+=gravity
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

 if(collidingsolid(po.x,po.y+po.yv))then
  local falling=po.yv>0
  while not collidingsolid(po.x,po.y+sgn(po.yv))do
   po.y+=sgn(po.yv)
  end
  po.yv=0
 else
  po.y+=po.yv
 end

end

function humanlogic(po)
	if (po.iframes > 0) then
		po.iframes -= 1
	end

	po.walk = (po.xv and po.x) % 16

	if (po.attack > 0) then
		po.atime+=1
		if (po.atime >= po.aspeed-po.level) then 
			po.attack+=1 
			po.atime = 0 
		end
		
		if (po.attack == 6) then 
		 po.attack = 0 
		 po.acooltimer = po.acooldown-((po.level-1)*2)
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

function shoplogic()
 x = flr(player.x/8)+0
 y = flr(player.y/8)+1
	tt = mget(x,y)
	if tt == 250 and shopmode == 0 then
		shopitempos = {x=x*8-48,y=y*8-20}
		shopmode = 1
		sfxi(10)
	end

	if tt != 250 and shopmode > 0 then
		shopitempos = {x=x*8-8,y=y*8-20}
		shopmode = 0
		sfxi(11)
	end
	
end

price = 0

function trybuy()

	if (player.souls >= price) then
		player.souls-=price
		player.weapon=37
		sfxi(12)
		shopmode = 0
	end

end

gameover = 0

function updateplayer()
	if (player.dead == true) then
		player.deathframes+=1
		return
	end

	physics(player,true)

 if (btn(5) and player.attack == 0 and player.acooltimer == 0) then 
 	player.attack = 1
 	if (shopmode == 0) then
 		sfxi(3)
 	else
 		trybuy()
 	end
 end

	humanlogic(player)

	shoplogic()

	-- player's attack
	attack_hitbox = { x = player.hx1, y = player.hy1, w = player.hb_s, h = player.hb_s }

	-- game exit
	if mget(1+flr(player.x/8),flr(player.y/8)) == 252 then gameover = 2 end

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
	end
	

end

opening = {}

function doorat(x,y)
 for i=1,#doors do
  d = doors[i]
 	if (d.mx == x) then return d end
 end
end

function opendoor(tx,ty)
	dd = doorat(tx)
	if (dd.openframes == 0 and dd.opened == false) then
		player.keys-=1
	 dd.openframes=32
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

function damage(t,n)
	dmg = {x = t.x, y=t.y,n=n,frames=16}
	add(dmgs,dmg)
end

function updateenemies() 
	-- enemies
	hit = { }
	hitcount = 0
	
	if (enemycount <= 0) then
		return
	end


	for i = 1,enemycount do
		enemy = enemies[i]

		dd = abs(pd(enemy.x,enemy.y,player.x,player.y))
		dv = 90
		if dd >= dv then enemy.far = true
		else enemy.far = false
		end
		if (enemy.dead == false and dd < dv) then
			ai(enemy)

			physics(enemy,false)

			humanlogic(enemy)

			if (enemy.animspeed) then
				enemy.atimer+=1
				if (enemy.atimer > enemy.animspeed) then
					enemy.atimer = 0
					enemy.aframe+=1
				end
			end
	
		 --collision with weapon
			if (player.attack == 2 and collide_aabox(enemy,attack_hitbox) and enemy.iframes == 0) then
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
				player.hp-=1
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

		if (player.yv > 0) then
		enemy.y+=player.yv*3
		else
		enemy.y-=enemy.dy*3
		end

		dmg = 10
		extra = 0
		if (player.weapon == 37) then
			extra = 10
		end
		dmg+=(player.level-1)*5
		dmg+=extra
		enemy.hp-=dmg
		damage(enemy,dmg)
		pushtarget(player,enemy,true)

		enemy.iframes = 16
		if (enemy.hp <= 0) then
			sfxi(7)
			enemy.dead = true
			enemy.deathframes = 16
			maybespawnitem(enemy.x,enemy.y+8,item_heart)
		end
	end

end

function updatedoors()
	done = {}

	for i=1,#opening do 
		d = opening[i]
		
		if (d.openframes) then 
			if (d.openframes >= 0) then
				d.openframes-=1
				if (d.openframes == 15) then
					sfxi(18)
				end
				if (d.openframes == 0) then
					d.opened = true
				end
			end
			if (d.openframes == -1) then
				mset(d.mx,d.my,255)
				mset(d.mx,d.my+1,255)
				mset(d.mx,d.my+2,255)
				d.openframes=-1
				add(done,i)
			end
		end
	end

	for i=1,#done do
		deli(opening,done[i])
	end
end

function drawspawners()
	for i=1,#spawners do
		s = spawners[i]
		if (s.far == false) then
			oo = cos(time()*0.2+i*0.3)*2
			oo2 = sin(time()*0.3+i*0.2)*2
			
			if (s.spawncount < s.spawnlimit) then
				sp = 64+((s.aframe+i)%4)*4
				sx, sy = (sp % 16) * 8, (sp \ 16) * 8
				ss = (s.spawncount-(s.spawnlimit-s.spawncount))*2
				sspr(sx,sy,32,16,ss+s.x-24+oo,s.y+4-oo2,32-oo-ss,16+oo2)
			end
			
			
		end
	end
end

function updatespawners()
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
	
		if (s.far == false) then 	
			s.spawnframes-=1
			if (s.spawncount < s.spawnlimit and s.spawnframes == 0) then
				s.spawnframes = s.spawntime
				s.spawncount += 1
				sfxi(17)
				if (s.spawncount == s.spawnlimit) then
					maybespawnitem(s.x-8,s.y,item_key)
				end
				if (s.enemytype == enemy_slime) then
					hpval = 20+flr(rnd(20))
		 		enemy ={x = s.x - 8, 
		 		        y = s.y - 8, 
					 						animspeed = 4+rnd(12), 
						 					w = 12, h = 12, 
								 			hp = hpval, 
											 jumpheight=2+rnd(1),
											 speed=0.1+rnd(0.1),
											 friction=0.4,
											 bh=bh_patrol,
											 souls=flr(hpval*1.25),acooldown=4
										 }
										 
					enemy.type = enemy_slime
	
					addenemycommon(enemy)
			
					add(enemies,enemy)
					enemycount+=1
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

		idd = dist(x+4,y,player.x+4,player.y+10)
		if (idd < 8) then
			rm = { i = i, tt = it.tt}
			add(rmd,rm)
		end
	end
	
	for i = 1, #rmd do
		tt = rmd[i].tt
		deli(items,rmd[i].i)
		if (tt == item_heart) then
			player.hp+=2
			if (player.hp>player.maxhp) then player.hp = player.maxhp end
			sfxi(11)
		elseif (tt == item_key) then
			player.keys+=1
			sfxi(9)
		end
	end

end

function _update()
end

function _update60()
	updateplayer()
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
	o.spawnlimit = 3
	o.spawncount = 0
	o.enemytype = mi
	o.spawner = spawnerid
	return o
end

spawners = {}

function initenemies()
	for my = 1,59 do
	for mx = 1,128 do
		isspawner = false
		mi = mget(mx,my)
		if (mi >= 251 and mi <= enemy_slime) then

		-- skelly
		if (mi == enemy_skelly) then
 		enemy ={x = mx*8, 
 		        y = my*8 - 8, 
			 						aspeed = 8, 
				 					w = 9, h = 17, 
						 			hp = 80, 
									 jumpheight=0,
									 speed=0.2,
									 friction=0.4,
									 bh=bh_patrol,
									 souls=20, walk=0,
									 attack = 0,dir=-1,
									 weapon=37,acooldown=4,
										hb_x = 14, hb_y = 1, hb_s = 4
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
			enemycount+=1
		end

		end
	end
	end
end

function drawenemies()
	for i = 1,enemycount do
		enemy = enemies[i]
		if ((enemy.dead == false or enemy.deathframes > 0) and enemy.far == false) then

			if (enemy.deathframes > 0) then
				for i=1, 16 do
					pal(i,i+16-enemy.deathframes*0.8,0)
				end
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
					if (player.totalsouls >= (player.level+player.level*1.33)*60) player.level+=1
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
	force = pusher.xv*100
	if (hit == true) then 
		force = 20*player.dir
	end
	
	target.xv+=force
end


function rspr(s,x,y,a,w,h)
 sw=(w or 1)*8 --sprite width
 sh=(h or 1)*8 --sprite height
 sx=(s%8)*8
 sy=flr(s/8)*8
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


	-- head
	spr(sprindex,ox+actor.x+actor.dir*-1,oy+actor.y,1,1,actor.dir!=1)
	-- body
	spr(sprindex+16+(actor.walk/4 % 3),ox+actor.x+actor.dir*-1,oy+actor.y+8,1,1,actor.dir!=1)

 -- weapon
 if (actor.dir == 1) weapoffs = 8
 if (actor.dir == -1) weapoffs = 16
	-- weapon idle
	if (actor.attack == 0) then

		if actor.weapon > 0 then
			spr(actor.weapon,ox+actor.x+weapoffs*actor.dir+actor.dir*-1,oy+actor.y,2,2,actor.dir!=1)
		end
	else
	 -- weapon strike
		if (actor.attack > 0 and actor.attack < 3) then
			weapoffs-=3
			weapoffs+=actor.attack
		else
			weapoffs+=(3-actor.attack)
		end
		
		if actor.weapon > 0 then
			spr(actor.weapon+2,ox+actor.x+weapoffs*actor.dir+actor.dir*-1,oy+actor.y+cos(actor.attack/8+time())*2,2,2,actor.dir!=1)
		end
	end

	if (ox == 0) then
		pal()
	end

	-- hitbox
	if (draw_hitbox == true) then
		rect(actor.x,actor.y, actor.x+actor.w, actor.y+actor.h,10)
		rect(actor.hx1,actor.hy1, actor.hx2, actor.hy2,8)
	end

--	print(player.hp,player.x,player.y-6,2)

end



mx = 0

mapframe=0
mapspeed = 2
mapoffs = 0

function pythag(a,b)
  return sqrt(a^2+b^2)
end

function dist( x1, y1, x2, y2 )
	return abs(pythag(x1-x2,y1-y2))
end

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

	for y=-1,14,2 do
	for x=-1,16,2 do 
 
 	sx = flr((player.x-64)/8)+x
 	sy = flr((player.y-64)/8)+y

 	xo = -player.x/4%16
 	yo = -player.y/32%16


 

		if(mget(sx,sy) == tile_bg) then 
			dx=flr(xo+x*8)
			dy=flr(yo+y*8)
			spr(46,-8+dx,dy,2,2)
			spr(46,-8+dx-16,dy,2,2)
			spr(46,-8+dx,dy-16,2,2)
			spr(46,-8+dx,dy+16,2,2)
		end

		pal()
	end
	end
	pal()

	camera(player.x-64,player.y-64)

	drawspawners()
	map(0,0,0,0,128,128,1)
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

function drawtorch()
 if (player.dead == true) return
	grad = { 10, 6, 9, 8, 4, 2,1,1,1,1,1,1,1,1,1,1,1,1,1} 

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

function drawdmg()
 r = {}
	for i=1,#dmgs do
		d = dmgs[i]
		if (d.frames >= 0) then
		print(flr(d.n),d.x+4,-1+d.y-cos(d.frames*0.04)*4,0)
		print(flr(d.n),d.x+4,1+d.y-cos(d.frames*0.04)*4,0)
		print(flr(d.n),d.x+4-1,d.y-cos(d.frames*0.04)*4,0)
		print(flr(d.n),d.x+4+1,d.y-cos(d.frames*0.04)*4,0)
		print(flr(d.n),d.x+4,d.y-cos(d.frames*0.04)*4,8+(16-d.frames)*0.2)
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

function drawui()
	camera()
	rectfill(0,120,128,128,0)
	
	--hp
	for i=1,player.maxhp do
		h = "█"
		e = "…"
	
	 if (i <= player.hp) then
			print(h,-2+(i-1)*4,122,8)
		else
			print(e,-2+(i-1)*4,122,8)
		end
	end
		
	print("key:"..pad(""..player.keys,2),45,122,10)
	print("soul:"..pad(""..player.souls,3),71,122,12)
	print("     lvl:" ..pad(""..player.level,2),85,122,7)

	if shopmode == 1 then 
		--top
		dialog("[bunbun exports employee]","welcome to my shop",0,7)

		--item
		dialog("golden long sword","only 140 souls for you my friend",20,8)
		price = 140
		camera(player.x-64,player.y-64)

		armor = {4,13,12,9,11,10,8}
		
		rectfill(shopitempos.x,shopitempos.y,shopitempos.x+16,shopitempos.y+64,0)
		
		pal(12,armor[player.level])
		sspr(9*8,16,8,8,shopitempos.x-16,shopitempos.y+cos(time()*1)*2,16+cos(time()*1)*2,16+sin(time()*0.5)*2)
		
		sspr(10*8,0,8,8,shopitempos.x-cos(time()*1)*2,shopitempos.y-sin(time()*1)*2,16+cos(time()*1)*2,16+sin(time()*1)*2)
		camera()
	end
	
	--roomname
	--printc("in the court of crimson king",123,14)
	

end

function enemycounter()
 c = 0
	for i=1,enemycount do
		e = enemies[i]
		if (e.dead == false) then c+=1 end
	end
	
	return c
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

function drawshadow()
	camera(player.x-64,player.y-64)

	ray_step=8
	palt(0,false)
	palt(1,true)

	for a=1,360,16 do
	
	 local ray={
	   x=player.x,
	   y=player.y,
	   angle=a/360,
	   angle_step=1
	 }
	 -- rays
  local step_x = cos(ray.angle)*ray_step
  local step_y = sin(ray.angle)*ray_step 

	 for x=0,1 do
	  local tile=0
	  local distance=0
	
	
	  -- reset ray start point
	  ray.x = player.x+4
	  ray.y = player.y+8
	
	  local distance=0
	  -- cast a ray across the
	  -- world map
			local distbail = false
	  repeat
	   -- march the ray
	   ray.x+=step_x       
	   ray.y+=step_y
	   distance+=ray_step
	   if (distance > 64) then distbail = true end
	   -- get tile at ray position
	   tile=mget(flr(ray.x/8),flr(ray.y/8))
				flag=fget(tile,0)
		 until(flag==true or distbail==true)
			if(distbail == false) then

		   ray.x+=step_x
		   ray.y+=step_y
				for i=0, 4 do
		   ray.x+=step_x
		   ray.y+=step_y
					spr(34,flr(ray.x),flr(ray.y))
				end
			end
		end 
	end
	palt()

end

function _draw()
	cls(0)

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
	
--	print(stat(1),player.x,player.y-8)
	pal()
	-- actual
	-- level armor colors
	armor = {4,13,12,9,11,10,8}
	pal(12,armor[player.level])
	drawhumanoid(player,1)

	drawenemies()
	drawitems()
	drawtorch()
	drawshadow()
	drawdmg()
	drawui()

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
		if (player.y > 32) then intro = 0 end
	end
	
end
__gfx__
00000000000600005555555055555550000000000000000000000000000000000000000000000000000000090000000000000000000000000000000000000000
00000000006600600500050005000500000000000000000000000000000000000000000000000000000000aa0000000000000003300000000000000000000000
0070070000660660555555555555555000000000000000000000000000000000000000000000000000000aa0000000000000013bb31000000000000330000000
0007700005ccc66c66666666666666650000000000000007000000000000000000007700000000000000aa0000000000000013bbbb3100000000013bb3100000
000770000c7ccccc333a2225333a2225000000000000007700000000000000000077700000000000000aa0000000000000013bbbbbb31000000013bbbb310000
007007000c7cfcfc33a9a22533a9a22500000000000007700000000000000000077000000000000000aa0000000000000013bbbbbbbb310000013bbbbbb31000
000000000ccc0c0c3a999a253a999a250000000000007700000000000000000777000000000000000590000000000000013bbbbbbbbbb3100013bbbbbbbb3100
000000000ccc0c0caaaaaaa5aaaaaaa5000000000007700000000000000000770000000000000000550000000000000013bbbb3bb3bbbb31013bbbbbbbbbb310
1555551000cfffff00cfffff00cfffff000000000077000000000000000056700000000000000000000000000000000013bbbb3bb3bbbb3113bbbb3bb3bbbb31
566666500055555500555555005555550000000005600000000000000ccf5000000000000000000000000000000000003bbbbb3bb3bbbbb33bbbbb3bb3bbbbb3
577777500ccccccc0ccccccc0ccccccc00000000f500000000000000cccff000000000000000000000000000000000003bbbbbbbbbbbbbb33bbbbb3bb3bbbbb3
555555500ccccccc0ccccccc0ccccccc00000000ff00000000000000cc000000000000000000000000000000000000003bbbbbbbbbbbbbb33bbbbbbbbbbbbbb3
aaaaaaa0ff44aa44ff44aa44ff44aa44000000000000000000000000000000000000000000000000000000000000000003bbbbbbbbbbbb3003bbbbbbbbbbbb30
2a999a30ffdd55ddffdd55ddffdd55dd0000000000000000000000000000000000000000000000000000000000000000003bbbbbbbbbb300003bbbbbbbbbb300
22a9a3300055005500cc0055005500cc00000000000000000000000000000000000000000000000000000000000000000003bbbbbbbb30000003bbbbbbbb3000
222a333000cc00cc000000cc00cc0000000000000000000000000000000000000000000000000000000000000000000000003333333300000000333333330000
22aaa330000800001111111100000000099009900000000000000000000000000000000000000000555555555555555400005550550000001111101000110011
2aa9aa300066006000000000000000009aa99aa90000000000000000000000000000000011110000566666666666665400057775775000000111101000110000
22a9a3300086086011111111000000009aaaaaa900000000000000000000000000000000cccc1110564494949444965400057775775000001100001010000111
22aaa3300055266500000000000000009aa00aa90000000900000000000000000000a900ccccfff1564964949494965400057775775000000011110111110000
2aaaaa300522555511111111000000009aa00aa9000000aa000000000000000000aaa000ccccff10564494449494965400057775775000001110010100001111
29a9a9300555757500000000000000009aaaaaa900000aa000000000000000000aa00000cccc1100566494949494965400005775775000000001110111111110
2aa9aa3002258585111111110000000009aaaa900000aa00000000000000000aaa00000011110000564494949444965400005777777500000111110111110001
22aaa330055585850000000000000000009aa900000aa00000000000000000aa0000000000000000566666666666665400005771717500000000101111111011
222a3330005177710051777100517771009a900000aa000000000000000059a00000000000000000566664449666665400005777777500000000001111110000
22a9a330005555550055555500555555009a990005900000000000000227500000000000000000005666649496565654000005777e5000000011001111100000
2a999a30022222220222222202222222009aaa907500000000000000222770000000000000000000566664449666665400000057750000000111101111000110
aaaaaaa0022222220222222202222222009a99007700000000000000220000000000000000000000566664666656565400000577775000000111100000001111
55555550774499447744994477449944009aaa900000000000000000000000000000000000000000566664666665665400005775577500000011001100001111
5777775077dd55dd77dd55dd77dd55dd009a99000000000000000000000000000000000000000000566666666666665400057559955750000000101000000110
56666650005500550022005500550022000900000000000000000000000000000000000000000000555555555555555400005077770500001111000010010000
15555510002200220000002200220000000000000000000000000000000000000000000000000000444444444444444000000077770000000000111110111000
00000000333333333333333300000000000000003333333333333333000000000000000033333333333333330000000000000000333333333333333b00000000
0000333333333333b333333333330000000033333333333b33b3333333330000000033333b33333b33333333333300000000333333b33333b333333333330000
0033333333333333333333333333330000333333333333333333333b333333000033333333333333333333b33333330000333333333bb3333333333333333300
333333333b333b33333333333b3333333333333333b333333333333333333333333b33333b333333b33333333333333333333b333333333333333b3333333333
33333b3333333333333333b33333333333333b333333333333333333333333b333333333333333333333b33333333b333333333b333333333333333333b33333
3333333333333333333333333333b333333333333333b3333b333b333b33333333333b3333333b33333333333b333333333b333333b33b3333333b3333b33333
3333333b33b333333b33333333333333333333333333333333333333333333333333333b33b3333333333333333b333333333333333333333b333333333333b3
05333333333333333333333333b3330005333b33b3333333333333b33333330005333333333333333b3333b33333330005333333333333333333333b33333300
0055333333333333333b3333333355000055333333333b333333333333335500005533333333b333333333333333550000553333b33333b33333333333335500
00005555333333333333333355550000000055553333333333333333555500000000555533333333333333335555000000005555333333333333333355550000
00000000555555555555555500000000000000005555555555555555000000000000000055555555555555550000000000000000555555555555555500000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0288288008ee8ee00e22e22000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
28ee8e288e22e28ee28828e200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
28eeee288e22228ee28888e200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
28eeee288e22228ee28888e200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
28eeee288e22228ee28888e200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
028ee28008e228e00e288e2000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00282800008e8e0000e2e20000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000080000000e0000000200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ffffffffffffffffffffffffffffffffffffffffffffffffffffff0f0fffffffffffffffffffffffffffffff0f0f1f1f1f0f0f0fffffff6f0f0f0f0f0f0f0f0f
0f0f0f0f0f0f0f7fffff0fffffffffffffffffffff0f0fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffff0f0fffffffffffffffffffffffffffffff0f0f1f1f1f0f0f0fffffff0f0f0f0f0f0f0f0f0f
0f0f0f0f0f0f0fffffff0fffffffffffff0fffffff0f0fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffff0f0fffffffffffffffffffffffffffffff0f0f1f1f1f0f0f0fffffffffffffffffffffffff
ffffffffffffffffff0f0f0f7fffffffff0fffffff0f0fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffff0f0fffffefffffffffffffffffffffefff0f0f0f0f0f0f0f0fffffffffffffffffffffffff
ffffffffffffffffffff0f0f0fffffff0f0fffff0f0f0fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffff0f0f3f3f3f3fffffff4fffffff3f3f3f3f0f0f0f0f0f0f0f0fffffffffffffffffffffffff
ffffffffffffffff0f0fffffffffff0f0f0fffffff0f0fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffcfcfffffffffffff4fffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffff0f0fffff0f0fffffffffffff0f0f0f0f0fffff0f0fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffcfcfffffffffff4f4f4f4f4f4f4f4fffffffffffffffffffffffffffffefffffffffffffff
ffffffffffffffffffffffffef0f0f0fffffffff0f0f0fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffcfcfffffffffffff4fffffffffffffffffffffffffffff0f0f0f0f0f0f0f0f0f0f0f0f0f0f
0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0fffffefffff0f0fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffcfcfffffffffffffff4fffffffffffffffffffffff0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f
0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffcfcfffffffefffffffffffffffffffefffffff0f0f0f0f0fffffffffffffffffffffffffff
ffffffffffffffffffffffffffff0f0f0f0f0f0f0f0f0fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffff0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0fffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffff0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0fffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
0166555011111111016688800166ccc00166aaa061565550065665565665656000999000009aa9000000000000000000ffffffff007777000000000000000000
16555555111111111688888816cccccc16aaaaaa52555555621212212211212609aaa900009aa9000000000000000000ffccccff0755557000bbbb0000000000
6556655511111111688668886cc66ccc6aa66aaa52566555515555555555551509a6a900009aa9000000000000000000ffccccff007575000b3333b000000000
6566762111111111686676216c6676316a66769161567621625766561267752600666000009aa9000000000000000000ffccccff075555700b0330b000000000
556776211111111188677621cc677631aa67769162577621515776551267651609666900009aa9000000000000000000ffccccff007557000b3333b000000000
512662151111111181266212c1366313a196691951555555615665555556652509a6a900009aa9007070000000000000ffccccff0005500000b33b0000000000
551221551111111188122122cc133133aa1991996212112262522555555555259aaaaa90009aa9000700000000000000ffccccff00077000000bb00000000000
0551155011111111088112200cc113300aa1199006565665525115500555651699999990009aa9007070000000000000ffffffff000000000000000000000000
__label__
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
00000000000000000000000000000000000000000166555001665550016655500166555001665550016655500166555001665550016655500166555001665550
00000000000000000000000000000000000000001655555516555555165555551655555516555555165555551655555516555555165555551655555516555555
00000000000000000000000000000000000000006556655565566555655665556556655565566555655665556556655565566555655665556556655565566555
00000000000000000000000000000000000000006566762165667621656676216566762165667621656676216566762165667621656676216566762165667621
00000000000000000000000000000000000000005567762155677621556776215567762155677621556776215567762155677621556776215567762155677621
00000000000000000000000000000000000000005126621551266215512662155126621551266215512662155126621551266215512662155126621551266215
00000000000000000000000000000000000000005512215555122155551221555512215555122155551221555512215555122155551221555512215555122155
00000000000000000000000000000000000000000551155005511550055115500551155005511550055115500551155005511550055115500551155005511550
00000000000000000000000000000000000000000166555001665550016655500166555001665550016655500166555001665550016655500166555001665550
00000000000000000000000000000000000000001655555516555555165555551655555516555555165555551655555516555555165555551655555516555555
00000000000000000000000000000000000000006556655565566555655665556556655565566555655665556556655565566555655665556556655565566555
00000000000000000000000000000000000000006566762165667621656676216566762165667621656676216566762165667621656676216566762165667621
00000000000000000000000000000000000000005567762155677621556776215567762155677621556776215567762155677621556776215567762155677621
00000000000000000000000000000000000000005126621551266215512662155126621551266215512662155126621551266215512662155126621551266215
00000000000000000000000000000000000000005512215555122155551221555512215555122155551221555512215555122155551221555512215555122155
00000000000000000000000000000000000000000551155005511550055115500551155005511550055115500551155005511550055115500551155005511550
00000000000000000000000000000000000000000166555001665550000101000001010000010100000101000001010000010100000101001555551000010100
00000000000000000000000000000000000000001655555516555555110111011101110111011101110111011101110111011101110111015666665111011101
00000000000000000000000000000000000000006556655565566555010100010101000101010001010100010101000101010001010100015777775101010001
00000000000000000000000000000000000000006566762165667621111100011111000111110001111100011111000111110001111100015555555111110001
0000000000000000000000000000000000000000556776215567762101011111010121110101111101011111010111110101111101011111aaaaaaa101011111
00000000000000000000000000000000000000005126621551266215011101010224040201110101011101010111010101110101011101012a999a3101110101
000000000000000000000000000000000000000055122155551221550000012200000844000001110000011100000111000001110000011122a9a33100000111
0000000000000000000000000000000000000000055115500551155000011200000099000002110000011100000111000001110000011100222a333000011100
000000000000000000000000000000000000000001665550016655500001040000600900000401000001010000010100000101000001010022aaa33000010100
00000000000000000000000000000000000000001655555516555555110248090660060699084201110111011101110111011101110111012aa9aa3111011101
000000000000000000000000000000000000000065566555655665550104000006606600060800000101000101010001010100310101000122a9a33101010001
0000000000000000000000000000000000000000656676216566762111240000cccc66c0a66900701111000111110001111113b31111000122aaa33111110001
0000000000000000000000000000000000000000556776215567762102089960c7ccccc00a000772010111110101111101013bbb310111112aaaaa3101011111
0000000000000000000000000000000000000000512662155126621502480600c7cfcfc00a00770201110101011101010113bbbbb311010129a9a93101110101
00000000000000000000000000000000000000005512215555122155000006a0ccc0c0c0000770420000011100000111013bbbbbbb3101112aa9aa3100000111
0000000000000000000000000000000000000000055115500551155000099600ccc0c0c000770900000111000001110013bbbbbbbbb3110022aaa33000011100
00000000000000000000000000000000000000000166555001665550000906000cfffff00770090000010100000101013bbbb3b3bbbb3100222a333000010100
000000000000000000000000000000000000000016555555165555551409960005555550560699041101110111011103bbbbb3b3bbbbb30122a9a33111011101
0000000000000000000000000000000000000000655665556556655502080000cccccccf500600020101000101010003bbbbbbbbbbbbb3012a999a3101010001
0000000000000000000000000000000000000000656676216566762112480000cccccccffa6600021111000111110003bbbbbbbbbbbbb301aaaaaaa111110001
000000000000000000000000000000000000000055677621556776210208990ff44aa4400a09984201011111010111113bbbbbbbbbbb31115555555101011111
000000000000000000000000000000000000000051266215512662150124090ffdd55dd006690401011101010111010103bbbbbbbbb301015777775101110101
000000000000000000000000000000000000000055122155551221550000089005500550000004210000011100000111003bbbbbbb3001115666665100000111
00000000000000000000000000000000000000000551155005511550000248000cc66cc000084200000111000001110000033333330111001555551000011100
00000000000000000000000000000000000000000166555001665550016655500006500008665550016655500166555001665550016655500166555000010100
00000000000000000000000000000000000000001655555516555555165555558655555586555555165555551655555516555555165555551655555511011101
00000000000000000000000000000000000000006556655565566555655665556556655565566555655665556556655565566555655665556556655501010001
00000000000000000000000000000000000000006566762165667621656676116566762265667611656676216566762165667621656676216566762111110001
00000000000000000000000000000000000000005567762155677621556776115567761155677611556776215567762155677621556776215567762101011111
00000000000000000000000000000000000000005126621551266215512662155126621551266215512662155126621551266215512662155126621501110101
00000000000000000000000000000000000000005512215555122155551221555512215555122155551221555512215555122155551221555512215500000111
00000000000000000000000000000000000000000551155005511550055115500551155005511550055115500551155005511550055115500551155000011100
00000000000000000000000000000000000000000166555001665550016655500166555001665550016655500166555001665550016655500166555000010100
00000000000000000000000000000000000000001655555516555555165555551655555516555555165555551655555516555555165555551655555511011101
00000000000000000000000000000000000000006556655565566555655665556556655565566555655665556556655565566555655665556556655501010001
00000000000000000000000000000000000000006566762165667621656676216566762165667621656676216566762165667621656676216566762111110001
00000000000000000000000000000000000000005567762155677621556776215567762155677621556776215567762155677621556776215567762101011111
00000000000000000000000000000000000000005126621551266215512662155126621551266215512662155126621551266215512662155126621501110101
00000000000000000000000000000000000000005512215555122155551221555512215555122155551221555512215555122155551221555512215500000111
00000000000000000000000000000000000000000551155005511550055115500551155005511550055115500551155005511550055115500551155000011100
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000016655500166555000010100
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000165555551655555511011101
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000655665556556655501010001
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000656676216566762111110001
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000556776215567762101011111
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000512662155126621501110101
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000551221555512215500000111
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055115500551155000011100
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000016655500166555000010100
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000165555551655555511011101
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000655665556556655501010001
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000656676216566762111110001
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000556776215567762101011111
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000512662155126621501110101
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000551221555512215500000111
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055115500551155000011100
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000016655500166555000010100
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000165555551655555511011101
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000655665556556655501010001
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000656676216566762111110001
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000556776215567762101011111
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000512662155126621501110101
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000551221555512215500000111
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055115500551155000011100
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
88888888888888888888888888888888888888888000000000000000000000000000000000000000aaa0aaa0aaa0aaa000007000707070000000777077000000
88888888888888888888888888888888888888888000000000000000000000000000000000000000a0a0a0a0a0a0a0a000007000707070000700707007000000
88888888888888888888888888888888888888888000000000000000000000000000000000000000a0a0a0a0a0a0a0a000007000707070000000707007000000
88888888888888888888888888888888888888888000000000000000000000000000000000000000a0a0a0a0a0a0a0a000007000777070000700707007000000
88888888888888888888888888888888888888888000000000000000000000000000000000000000aaa0aaa0aaa0aaa000007770070077700000777077700000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000101010100000000000000000000000001010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001800101010101010000000000008000
__map__
f2f2f2f2f2f2f6f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0ffffffffffffffffffffffffffffffffffffff
f2fffffffff2f0fffffffffffffffffffffffff5f0f0f0f0f0f0f0f0f0f0f0f0f0f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0ffffffffffffffffffffffffffffffffffffff
f2fffffffff2f0fffffffffffffffffffffffffffffffffffffffffff8fff5f0f0f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f0f0fffffffffffffffffffffffffffffffffffffff0f0f0f0fffffffffffffffffffffffffffffffffffffffffffff0f0ffffffffffffffffffffffffffffffffffffff
f2fffffffff2f0fffffffffffffffffffffffffffffffffffffffffff9fffff0f0f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f0f0fffffffffffffffffffffffffffffffffffffff0f0f0f0fffffffffffffffffffffffffffffffffffffffffffff0f0ffffffffffffffffffffffffffffffffffffff
f2fffffffff2f0fffffffffffffffdfffffffffffffffffffffffffef9fffff0f0f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f0f0fffffffffffffffffffffffffffffffffffffff0f0f0f0fffffffffffffffffffffffffffffffffffffffffffff0f0ffffffffffffffffffffffffffffffffffffff
f2fff4f4f3f2f5f0f0f0f0f0f0f0f0f0f7fffff6f0f0f0f0f0f0f0f0f7fffff0f0f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f0f0fffffffffffffffffffffffffffffffffffffff0f0f0f0fffffffffffffffffffffffffffffffffffffffffffff0f0ffffffffffffffffffffffffffffffffffffff
f2fff4f3f3f3f3f3f3f3f3f3f3f3f3f3f3fffff0f0f0f0f0f0f0f0f0f0fffff0f0f4f4f4f4f4f4f4f4f0f0f0f0f0f0f0f0f0f0f0f0f0f0f4f4f0f0f0f0f0fffffffffffffffffffffffffffffffffffffff5f0f0f0fffffffffffffffffffffffffffffffffffffffffffff0f0ffffffffffffffffffffffffffffffffffffff
f2fffff7fffffffffffffffffffffffffffff4f0f0f1f1f1f1f1f1f0f0fffff0f0f4f4f4f4f4f4f4f4f0f0f0f0f0f0f0f0f0f0f0f0f0f0f4f4f0f0f0f0f0fffffffffffffffffffffffffffffefffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0f0ffffffffffffffffffffffffffffffffffffff
f2fffff0fffffffffff8fffffffffffffff4f4f0f0f1f1f2f2f1f1f0f0fffff0f0f4f4f2f2f2f2f4f4f0f0fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff3f3f3f3fffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0f0ffffffffffffffffffffffffffffffffffffff
f2f0fff0f0f0fffffff9fffffffffffff4f4f4f0f0f1f1f4f4f1f1f0f0fffff0f0f4f4f2f2f2f2f4f4f0f0fffffffffffffffffffffffffffffffffffffffffff6f0f0f0f7fffffffffffffffffffffff6f0f0f0f7fffffffffffffffffffffffffffffffffffffffffffff0f0ffffffffffffffffffffffffffffffffffffff
f2fffffffff0fffffff9fffffffffff4f4f4f4f0f0f1f1f1f1f1f1f0f0fffff5f0f4f4f2f2f2f2f4f4f0f0fffffffffffffff0fefffffffffffffff6f0f7fffffffffffffffffffff6f0f0f0f0f7fffff0f0f0f0f0fffffffffffdfffffffffffffffffffffffffffffffff0f0ffffffffffffffffffffffffffffffffffffff
f2fffffffff7fffff0f3f3f3f3f3f3f0f0f0f0f0f0f2f2f2f2f2f2f0f0fffffffffffffffffffffffffffffffffffffffff0fff0fffffffffffffff0f0f0fffffffffffffffffffffffffffffffffffffff0f0f0f0f0f7fffffffffffffffdfffffff6fffff6fffffffffff0f0ffffffffffffffffffffffffffffffffffffff
f0f0f0f0fff7fffffff0f0f0f0f0f0f0f0f0f0f0f0f2f2f2f2f2f2f0f0fffffffffffffffffffdfffffefffffffffffffff0fff0fffffffffffffffffffffffff6f0f0f0f0f7fffffffffffffffffffdfff0f0f0f0f0f0fffffffffffffffffffffffffffffffff6fffffff0f0ffffffffffffffffffffffffffffffffffffff
f0f0fffffffff0fffffffffffffffffffffffffffffffffffffffff0f0f0f0f0f0f4f4f4f3f3f4f4f4f0f0f4f4fffffff0fffffff0fffffffffff0f0fffffffffffffffffffffffffffffffffffffffffff0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f7fffffffffffffffffff6f0f0ffffffffffffffffffffffffffffffffffffff
f0f0fffffffffff0fffffffffffffffffffffffffffffffffffffff0f0f0f0f0f0f4f4f4f3f3f4f4f4f0f0f4f4fffffff0fffffff0fffffffffffff0f0f0f0f0f3f3f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0fffffffffffffff6fffff0f0ffffffffffffffffffffffffffffffffffffff
f0f0fffffffffff8f0f0fffffffffffffffffffffffffffffffffff0f0fffff0f0f1f1f1f1f1f1f1f1f0f0fffffffff0fffffffffff0fffff6f7fff0f0f0f0f0f3f3f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f1f1f1f1f1f1f1f1f1f1f1f1f0f0fffffffffff6fffffffff0f0ffffffffffffffffffffffffffffffffffffff
f0f0fffffffffff9fffff0f0fffffffffffffffffffffffffff0f0f0f0fffff0f0f1f1f1f1f1f1f1f1f0f0fffffff0ffff2c2dfffffff0fffffffff4f0f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f0f0fffffff6fffffffffffff0f0ffffffffffffffffffffffffffffffffffffff
f0f0fffffffffff9fffffffffffffffefffffffffffdfffffff0f0f0f0fffff0f0f1f1f1f1f1f1f1f1f0f0fffffff0ffff3c3dfffffffffffffffff4f0f0f2f0f2f0f2f0f2f0f2f0f2f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f6fffffffffffffffffff0f0ffffffffffffffffffffffffffffffffffffff
f0fffffffffff0f0f4f3f2f4f3f2f4f3f2f4f3f2f6f0f0f0f7f0f0f0f0fffff0f0f1f1f1f1f1f1f1f1f0f0fffff0fffff62a2bf7fffffffffffffff0f0f2f0f2f0f2f0f2f0f2f0f2f0f2f0f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f0f0f0fffff6fffffffffffffff0f0ffffffffffffffffffffffffffffffffffffff
f0fffffffffffffffff3f2f4f3f2f4f3f2f4f3f2f0f0f0f0f0f0f0f0f0fffff0f0f1f1f1f1f1f1f1f1f0f0fffff0fffff03a3bf0fafffff0fffffff0fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff2f0f0f0fffffffff6fffffffffff0f0ffffffffffffffffffffffffffffffffffffff
f0f0fff0fffffffffff0f0f0fffffffffffffffffffffffffffffff0f0fffff0f0f1f1f1f1f1f1f1f1f0f0fff0f0f0f0f0f3f3f0f0f0f0f0f0fffffffffffffffdfffffffffffffffefffffffffdfffffefffffffffffffffffffffefff2f0f0f0fffffffffffff6fffffff0f0ffffffffffffffffffffffffffffffffffffff
f0f0fffffff0fffffff0f0f0fffffffffffffffffffffffffffffff0f0fffff0f0f1f1f1f1f1f1f1f1f0f0fffffffffffffffffffffffffefffffffefffffffffffffffffffffffffffffffffffffffffffffffffffffff0f0fffffffff2f0f0fffffffffffffffffffff6f0f0ffffffffffffffffffffffffffffffffffffff
fff0f0fffffffffff0fff0f0fffffffffffffffffffffffffffffff0f0fffff0f0f1f1f1f1f1f1f1f1f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f3f3f3f3f3f3f3f3f3f3f3f3f3f0f2f2f2f2f2f2f2f2f2f2f2fffffff0f0fffffffffffffffffffffffffffff6fff0f0ffffffffffffffffffffffffffffffffffffff
fff0f0fffffff0fffffff0f0fffffffffffffffffffffffffffffff0f0fffff0f0f1f1f1f1f1f1f1f1f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0fffffffffffffffff2fffffffffffffffffffffffffffffffffefffffffef0f0ffffffffffffffffffffffffffffffffffffff
fff0f0fffff0fffffffffff0f0fffffffffffffffffffffffffffff0f0fffff0f0f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0fffffffffffdfffffffffffffffffff2f2f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0ffffffffffffffffffffffffffffffffffffff
fff0f0f0fffffffffffffef0f0fffffffffffffffffffffffffffff0f0fffff0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f1f1f1f1f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0fffffffffffffffffffffffffff2f2f2f2f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0ffffffffffffffffffffffffffffffffffffff
fff0f0f0f0f0f0f0f0f0f0f0f0fffffffffffffffffffffffffffff0f0fffff0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f1f1f1f1f0f0fffffffffffffffffffffffffffffffffffffffffffff0f0f0fffffff0f2f2f2f2f2fff2f2f2f2f2f2f2f0ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
fff0f0f0f0f0f0f0f0f0f0f0f0fffffffffffffffffffffffffffff0f0fffffffffffffffffffffffffffffff0f0f1f1f1f1f0f0fffffffffffffffffffffffffffffffffffffffffffff0f0f0fffffffffffffffff2fffffffffffffff2f0ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
fffffffffffffffffffffffffffffffffffffffffffffffffffffff0f0fffffffffffffffffffffffffffffff0f0f1f1f1f1f0f0fffffffffffffffffffffffffffffffffffffffffffff0f0f0f0f0fffffffffffff2fffffffffdfffff2f0ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
fffffffffffffffffffffffffffffffffffffffffffffffffffffff0f0fffffffffffffffffffffffffffffff0f0f1f1f1f0f0f0fffffffffffffffffffffffffffffffffffffffffffff0f0f0fffffffffffffffff2f2f2f2f2f2f2f2f2f0ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
fffffffffffffffffffffffffffffffffffffffffffffffffffffff0f0fffffffffffffffffffffffffffffff0f0f1f1f1f0f0f0fffffffffffffffffffffffffffffffffffffffffffff0f0f0fffff6f0f7fffffff0f0f0f0f0f0f0f0f0f0ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
fffffffffffffffffffffffffffffffffffffffffffffffffffffff0f0fffffffffffffffffffffffffffffff0f0f1f1f1f0f0f0fffffffffffffffefffffffffffffffffffffffffffff0fffffffffffffffffff0f0ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
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
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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

