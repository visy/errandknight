pico-8 cartridge // http://www.pico-8.com
version 35
__lua__
gravity=0.1
intro = 2
cheat = 0

player = { x = 8*3, y = -512, walk = 0, dir = -1, attack = 0, atime = 0, 
weapon = 5, aspeed = 3, acooldown = 24, acooltimer = 0, hb_x = 9, hb_y = 1, hb_s = 11, hp = 100, maxhp = 100, w = 6, h = 17, xv=0,yv=0,jumpheight=2,speed=0.8,friction=0.5,iframes=0,
moveframes=0,totalsouls = 0,souls=0, level=1,dead = false,deathframes=0,keys=0,
onladder=false,prevladder=false,
jst = 10, ast = 20, st = 100, maxst = 100,streco=0.25,isjumping=false
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
		
			door = { x=mx*8,y=my*8, mx = mx, my = my, openframes=-2,opened= false }
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
			if (door.openframes > 0) then
				oo = 32-door.openframes
			end
			if (door.opened == true) return
			sspr(0,8,8,24,mx*8,my*8,8-oo/4,24)
		end
	end
end

rndr = {}

function _init()
	if (cheat == 1) then
--		player.keys = 99
--		player.maxhp = 1
--		player.hp = 39
	end
	
	for i=1,500 do
		rndr[i] = rnd()*32
	end

	initdoors()
	initenemies()
	inittab()

	music(0,500)

	
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


	if (isplayer == true and player.y > 0) then
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

	if (player.st < player.maxst) then
		player.st+=(player.streco+(0.1*player.level))
	end

	if (player.iframes > 0) then
		player.iframes -= 1
	end

	physics(player,true)

 if (btn(5) and player.attack == 0 and player.acooltimer == 0 and player.st > 2) then 
 	player.attack = 1
 	player.st-=player.ast

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
--	if mget(1+flr(player.x/8),flr(player.y/8)) == 252 then gameover = 2 end

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
 	if (d.mx == x) then 
 		d.di = i
	 	return d 
 	end
 end
end

function opendoor(tx,ty)
	dd = doorat(tx)
	if (dd.openframes == -2 and dd.opened == false and player.keys > 0) then
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
heals = {}
function damage(t,n)
	dmg = {x = t.x, y=t.y,n=n,frames=16}
	add(dmgs,dmg)
end

function healing(t,n,k)
	heal = {k=k, x = t.x, y=t.y,n=n,frames=16}
	add(heals,heal)
end

function wallerlogic(e)
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

			if (enemy.type != enemy_waller) then
				physics(enemy,false)
				humanlogic(enemy)
			else
				wallerlogic(enemy)
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
		 		enemy ={x = s.x - 16, 
		 		        y = s.y - 12, 
					 						animspeed = 4+rnd(12), 
						 					w = 12, h = 12, 
								 			hp = hpval, 
											 jumpheight=2+rnd(1),
											 speed=0.1+rnd(0.1),
											 friction=0.4,
											 bh=bh_patrol,
											 souls=flr(hpval*1.25),acooldown=4,
											 dmg = 10,
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
			player.hp+=5
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
												souls=12,
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
									 souls=20, walk=0,
									 attack = 0,dir=-1,
									 weapon=37,acooldown=4,
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

				rspr(100+enemy.aframe%4,enemy.x,enemy.y,a,1,1)
				end
				if (enemy.ydir != -0) then
				a = 90
				if (enemy.ydir == 1) then
				a = 270
				end
				rspr(100+enemy.aframe%4,enemy.x,enemy.y,a,1,1)
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
					if (player.totalsouls >= (player.level+player.level*1.5)*100) player.level+=1
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
	camera(player.x-64,player.y-64)
 r = {}
	for i=1,#dmgs do
		d = dmgs[i]
		if (d.frames >= 0) then
		oy = cos(i*0.1)*4
		print(flr(d.n),d.x+12,oy+-1+d.y-cos(d.frames*0.04)*4,0)
		print(flr(d.n),d.x+12,oy+1+d.y-cos(d.frames*0.04)*4,0)
		print(flr(d.n),d.x+12-1,oy+d.y-cos(d.frames*0.04)*4,0)
		print(flr(d.n),d.x+12+1,oy+d.y-cos(d.frames*0.04)*4,0)
		print(flr(d.n),d.x+12,oy+d.y-cos(d.frames*0.04)*4,8+(16-d.frames)*0.2)
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
		print("+"..flr(d.n),d.x+12,oy+-1+d.y-cos(d.frames*0.04)*4,0)
		print("+"..flr(d.n),d.x+12,oy+1+d.y-cos(d.frames*0.04)*4,0)
		print("+"..flr(d.n),d.x+12-1,oy+d.y-cos(d.frames*0.04)*4,0)
		print("+"..flr(d.n),d.x+12+1,oy+d.y-cos(d.frames*0.04)*4,0)
		print("+"..flr(d.n),d.x+12,oy+d.y-cos(d.frames*0.04)*4,co)
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

	spr(11,127-42,-1)
	spr(57,127-40,0)
	spr(11,127-32,-1)
	spr(11,127-24,-2)
	spr(9,127-16,-2)
	spr(11,127-8,-1)

	palt(0,false)
	spr(25,127-24,0,3,1)
		
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
	memset(0x9000,112,512)

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

				dv = peek(0x9000+(yi*16)+xi)
				dv+=2
				if (dv > 124) then dv = 124 end
				poke(0x9000+(yi*16)+xi,dv)

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
	poke(0x5f56, 0x90)
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
		spr(105, -time()*10+32+cos((i*32.0)*0.01)*32,-500+i*32+rndr[i],2,1)
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
	
--	print(stat(1),player.x,player.y-8)
	pal()
	-- actual
	-- level armor colors
	armor = {4,13,12,9,11,10,8}
	pal(12,armor[player.level])
	drawhumanoid(player,1)

	if (intro == 0) then
	drawenemies()
	drawitems()
	drawtorch()
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
00000000000600005555555055555550000600600000000000000000000000000000000000000000000000090000000000000000000000000000000000000000
00000000006600600500050005000500006606600000000000000000000000000000000000008000000000aa0000000000000003300000000000000000000000
0070070000660660555555555555555000660660000000000000000000000000000000000338a83000000aa003300b300000013bb31000000000000330000000
0007700005ccc66c66666666666666650c66ccc500000007000000000000000000007700393383330000aa0033333333000013bbbb3100000000013bb3100000
000770000c7ccccc333a2225333a22250ccccccc0000007700000000000000000077700097933003000aa0000b03300300013bbbbbb31000000013bbbb310000
007007000c7cfcfc33a9a22533a9a2250ccccccc000007700000000000000000077000000900000000aa0000000000000013bbbbbbbb310000013bbbbbb31000
000000000ccc0c0c3a999a253a999a250ccccccc00007700000000000000000777000000000000000590000000000000013bbbbbbbbbb3100013bbbbbbbb3100
000000000ccc0c0caaaaaaa5aaaaaaa50ccccccc0007700000000000000000770000000000000000550000000000000013bbbb3bb3bbbb31013bbbbbbbbbb310
1555551000cfffff00cfffff00cfffff00cffffc007700000000000000005670000000009990dddddddddddddddddd9013bbbb3bb3bbbb3113bbbb3bb3bbbb31
566666500055555500555555005555550055555505600000000000000ccf5000000000009440111111111111111111903bbbbb3bb3bbbbb33bbbbb3bb3bbbbb3
577777500ccccccc0ccccccc0ccccccc0cccccccf500000000000000cccff000000000009000dddddddddddddddddd903bbbbbbbbbbbbbb33bbbbb3bb3bbbbb3
555555500ccccccc0ccccccc0ccccccc0cccccccff00000000000000cc000000000000009901909091901901901111903bbbbbbbbbbbbbb33bbbbbbbbbbbbbb3
aaaaaaa0ff44aa44ff44aa44ff44aa44ff44444400000000000000000000000000000000940d994099409490990ddd9003bbbbbbbbbbbb3003bbbbbbbbbbbb30
2a999a30ffdd55ddffdd55ddffdd55ddffdd55dd00000000000000000000000000000000900194019401999094901990003bbbbbbbbbb300003bbbbbbbbbb300
22a9a3300055005500cc0055005500cc0055005500000000000000000000000000000000900d90dd90dd9490909094900003bbbbbbbb30000003bbbbbbbb3000
222a333000cc00cc000000cc00cc000000cc00cc0000000000000000000000000000000099909011901191909090999000003333333300000000333333330000
22aaa330000800002020000033300000099009900000000000000000000000000000000000000000555555555555555400005550550000001111101000110011
2aa9aa300066006020200000300033309aa99aa90000000000000000000000000000000011110000566666666666665400057775775000000111101000110000
22a9a3300086086020202220333003009aaaaaa900000000000000000000000000000000cccc1110564494949444965400057775775000001100001010000111
22aaa3300055266522202020003003009aa00aa90000000900000000000000000000a900ccccfff1564964949494965400057775775000000011110111110000
2aaaaa300522555520202220303003009aa00aa9000000aa000000000000000000aaa000ccccff10564494449494965400057775775000001110010100001111
29a9a9300555757520202000333003009aaaaaa900000aa000000000000000000aa00000cccc1100566494949494965400005775775000000001110111111110
2aa9aa3002258585202020000000030009aaaa900000aa00000000000000000aaa00000011110000564494949444965400005777777500000111110111110001
22aaa330055585850000200000000300009aa900000aa00000000000000000aa0000000000000000566666666666665400005771717500000000101111111011
222a3330005177710051777100517771009a900000aa000000000000000059a00000000000000000566664449666665400005777777500000000001111110000
22a9a330005555550055555500555555009a990005900000000000000227500000000000000000005666649496565654000005777e5000000011001111100000
2a999a30022222220222222202222222009aaa907500000000000000222770000000000000000230566664449666665400000057750000000111101111000110
aaaaaaa0022222220222222202222222009a99007700000000000000220000000000000000002823566664666656565400000577775000000111100000001111
55555550774499447744994477449944009aaa900000000000000000000000000000000000033203566664666665665400005775577500000011001100001111
5777775077dd55dd77dd55dd77dd55dd009a99000000000000000000000000000000000000033000566666666666665400057559955750000000101000000110
56666650005500550022005500550022000900000000000000000000000000000000000000bb3000555555555555555400005077770500001111000010010000
15555510002200220000002200220000000000000000000000000000000000000000000000bb0000444444444444444000000077770000000000111110111000
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
0288288008ee8ee00e22e22000000000900090000900090009000000000900090000000000007777777000000000000000000000000600600006006055555555
28ee8e288e22e28ee28828e200000000090000090000000900000090090000900000000000777777777770000000000000000000006606600066066011111111
28eeee288e22228ee28888e200000000000990000009900090099000000990000000000007777777777777000000000000000000006606600066066056100561
28eeee288e22228ee28888e200000000009aa900909aa900009aa909009aa90000000000777777777777770000000000000000000c66ccc50c66ccc556100561
28eeee288e22228ee28888e200000000909aa900009aa900009aa900009aa90900000000777777777777777000000000000000000ccccccc0ccccccc56100561
028ee28008e228e00e288e20000000000009900900099000000990000009900000000000777777777777770000000000000000000ccccccc0ccccccc56666661
00282800008e8e0000e2e200000000000900000009000090900000909000000000000000077777777777700000000000000000000ccccccc0ccccccc56100561
000080000000e00000002000000000000000009090009000000900090090009000000000000777777770000000000000000000000cccccccffcccccc56100561
1111111111111111101110111011101101110111011101110101010101010101000100010001000100010001000100010000000000cffffcffcffffc56100561
11111111111111111110111011101110101010101010101010101010101010101010101010101010010001000100010000000000ff5555550055555556666661
11111111111111111011101110111011110111011101110101010101010101010100010001000100000100010001000100000000ffcccccc00cccccc56100561
1111111111111111111011101110111010101010101010101010101010101010101010101010101001000100010001000000000000cccccc00cccccc56100561
11111111111111111011101110111011011101010111010101010101010101010001000100010001000100010001000100000000004444440044444456100561
1111111111111111111011101110111010101110101011101010101010101010101010101010101001000100010001000000000000dd55dd00dd55dd56666661
1111111111111111101110111011101111010101110101010101010101010101010001000100010000010001000100010000000000cc0055005500cc56100561
11111111111111111110111011101110101010111010101110101010101010101010101010101010010001000100010000000000000000cc00cc000056100561
fffffff72f2f2ffffff7ffffffffff4f4ff7ffffff3f4ff74f0f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f
1f1f1f1f1f1f1f1f1f1f1fbfbfbfbfbfbfbfbfbfbfbf1f1f1f3f3f3f3f3fffffffffffffff3f3f3f3f3f3f3f3ff73f3f3f3f3f3f3f3f3f3f3f3f3f3f1f1f1f1f
fffffff72f2f2fffffffefffffffff4f4ff7ffffff3f4ff74f3f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f
1f1f1f1f1f1f1f1f1f1f1f1f1f1f1fbfbfbfbfbf1f1f3f3f3f3f3fffffffffffffffffffffffffffffffffff3ff7ffffffffffffffffff3f3f3f3f3f1f1f1f1f
fffffff72f2f2f2f2f2f2f2ff6ffff4f4ff7ffffff3f2ff74f4f7f5f5f5f6f6f7f7f7f7f7f7f5f5f6f5f7f7f5f7f6f6f5f7f6f7f7f6f7f5f5f5f5f5f7f6f6f6f
5f6f7f7f6f5f6f1f1f1f1f1f1f1f1f1f1f1f1f1f1f3f3f3f3fffffffffffffffffffffffffffffffffffffff3ff7ffffffffffffffffffffffff3f3f1f1f1f1f
fffffff72f2f2f2f2f2f2f2ff7ffff4f4ff7ffffff4f3ff73f0f5f5f7f7f7f7f6f7f7f7f7f5f5f6f6f7f5f5f6f7f5f6f7f5f5f5f5f6f6f5f7f5f6f6f6f6f7f7f
5f7f5f5f7f7f5f1f1f1f1f1f1f1f1f1f3f3f3f3f3f3fffffffffffffffffffffffffffffffffffffffffffff3ff7ffffffffffffffffffffffff3f3f1f1f1f1f
fffffff72f2f2f2f2f2f2f2ff7ffff4f4ff7ffffff3fbff72f2f2f2f2f2fffffffffffffffffffffffffffffffff7f6fffffffffffffffffffffffffffffffff
ffffffffff6f5f1f1f1f1f1f1f1f1f3f3f3f3f3f3fffffffffffffffffffffffffffffffffffffffffffffff3ff7ffffffffffffffffffffffff3f3f3f1f1f1f
fffffff72f2f2f2f2f2f2f2ff7ffff4f4ff7ffffffbf4ff7ffffffffffffffffffffffcfffdfffffffffffffffff5f6fffffffffffffffffffffffffffffffff
ffffffffff6f6f1f1f1f1f1f3f3f3f3fffffffff8fffffffffffffffffffffffffffffffffffffffffffffff3ff7ffffffffffffffffffffffffff3f3f1f1f1f
fffffff7fffffffffffffffff7ffff4f4ff7ffffff4f3ff73f4f7f5f6f7f5f6f5f6f7f7f5f5f7fffffffffffffff7f7fffffffffffffffffffffffffffffffff
ffffffffff7f5f1f1f1f1f3f3f3f3fffffffffff9fffffffffffffffffffffffffffffffffffffffffffffff3ff7ffffffffffffffffffffffffff3f3f1f1f1f
fffffff7fffffffffffffffff7ffff4f4ff7ffffff4f0ff70f0f6f5f5f7f5f5f5f7f6f5f6f5f5f7fffffffffffff6f6fffffffffffffffffffffffffffffffff
ffffffffff5f5f1f1f3f3f3f3fffffffffffffff9fffffffffffefffffffffffffffffffffffffffffffffff3ff7ffffffffffffffffffffffffff3f3f1f1f1f
fffffff7ffffffffffffffffffffef4f4ff7ffffff2f4ff73f0f4f4f4f4f4f4f4f4f4f4f7f7f6f5f7fffffffffffffffffffffffffffcfffffffffffffcfffff
ffcfffffff6f7f3f3f3f3fffffffffffffffff3f3f3f3f3f3f3f3f3f3f3f3f3fffffffffffffffffffffffff8ff7ffffffffffffffffffffffffff3f3f3f1f1f
fffffff7ffffffff2f2fff2f2f2f2f4f4ff7ffffff2fbff72f0f4f4f4f4f4f4f4f4f4f4f5f6f7f5f7f7fffcfffefffffffffffffff6f7f6fffffff6f7f6fffff
7f6f6fffff5f5f3f3fffffffffffffffff3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3fffffffffffffffffffffff9ff7ffffffffffffffffffffffffffff3f3f1f1f
fffffff7ffffcfffffffff2f2f2f2f4f4ff7ffffff2f2ff7bf2f4f4fffffffffffff4f4f6f7f5f5f6f6f5f7f6f7f5fffffffffffff5f5f5fffffff5f7f6fffff
6f7f7fffff7f5fffffffffffffffff3f3f3f3f7f5f5f5f5f5f5f5f6f7f7f7f3f3f3fffffffffffffefffffff9fff5f5f6f7fffffffffffefffffffff3f3f1f1f
fffffff7ff2f2f2fffffff2f2f2f2f4f4ff7ffffffbf3ff72f4f4f4fffffffffffff4f4f5f7f7f5f5f5f7f5f6f6f7f6fffffffffff5f6f6fffffff5f6f5fffff
ffffffffff8f7fffffffffffff3f3f3f3f6f7f7f5f5f6f7f5f6f5f5f6f7f7f5f3f3f3f3f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f6f7f1f1f1f
ffffffffffffffffffffffffffcfff4f4fffffffff0f4ff7ffffffffffffffffffff4f4f4f4f4f4f4f4f4f4f4f4f4f4f4fffffffff5f5f7fffffffffffffffff
ffffffffff9fffffffffff3f3f3f3f7f7f7f7f0fffffffffffffffffffffffff5f3f3f3f5f5f6f7f7f7f7f6f7f7f7f7f7f7f7f7f7f7f7f7f7f7f5f6f7f7f7f1f
ffff2f2f2fffffffffffffffffffff4f4f4fffffffff3fffffffffffffffffefffff4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4ff6ffffffffffffffffffffffffff
ffffffffff9fffffff3f3f3f3f6f7f7f0f0fff8fffffffffffffffffffffffffff5f5f5f5fffffffffffffffffffffffffffffffffffffffffff5f5f5f6f7f1f
ffffffffffffffffefffffffffffff4f4f4fffffffff0f3f2fbfbf4fbfbf3f0f4ff64f4f2f2f2f2f2f2f2f2f2f2f2f2f4f4ff7ffffffffffffffffffffffffef
ffffffffff6f6f3f3f3f3f6f7f7f7f0fffffff9fffffffffffffffffffffffffffffff8fffffffffffffffffffffffffffffffffffffffffffffffff5f5f6f7f
2f2f2f2f2f2f2f2f2f2f2f2f2ff6ff4f4f4f4ffff63f3f3f4fbf0fbf2f3fbf3f3ff74f4f2f2f2f2f2f2f2f2f2f2f2f2f4f4ff7ffffffffffffffffbfbfbfbfbf
bfbfbfffff7f5f3f3f6f7f7f7f0fffffffffff9fffffffffffffdfffffcfffffffffff9fffffffffffffffffffffffffffffffffffffffffffffffef5f6f7f7f
2f2f2f2f2f2f2f2f2f2f2f2f2ff7ff4f4f4f4f4ff74f4f4f4f4f4f4f4f4f4f4f4ff74f4f2f2fffffffffffffffff2f2f4f4ff7ffffffffffffffbfbfbfbfbfbf
bfbfbfbfff5f6f5f6f7f7f0fffffffffffffff6f0f0f5f5f5f5f6f7f5f5f5f5f6f7fff9fffffffffdfffffffffffffffffffffffffefff5f5f5f5f6f5f6f7f7f
fffffffffffffffffffffffffff7ff4f4f4f4f4ff74f4f4f4f4f4f4f4f4f4f4f4ff74f4f2f2fffffffffcfffffff2f2f4f4fffffffffefffffbfbfbfbfffffff
ffbfbfbfff5f6f7f7f7f0fffffffffffff6f6f6f7f7f7f5f6f5f5f5f5f5f6f5f5f5f6f7f7f5f5f5f5f6f7fffffffffdfffffff5f5f5f6f7f5f6f7f7f7f7f7f1f
fffffffffffffffffffffffffff7ff4f4f4f4f4ff7fffffffffffffffffffffffff74f4f2f2fffffff7f7fffffff2f2f4f4fbfbfbfbfbfbfbfbfbfffffffffff
ff8fbfbf5f6f7f7f7f0fffffffffff6f6f6f7f7f7f1f1f1f1f1f1f1f1f1f1f1f1f5f5f5f5f5f5f6f7f5f6f5f5f5f5f6f7fff5f6f7f7f7f7f7f7f7f1f1f1f1f1f
ffffffffffffffffffffffffefffff4f4f4f4f4ff7fffffffffffffffffffffffff78fffffffffffff6f5fffffff2f2f8f4fbfbfbfbfbfbfbfbfffffffffffff
ff9fbfbf0f0f0f0f0fffffffffff6f6f7f7f7f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f5f5f5f6f7f5f5f6f5f6f7f7f1f1f1f1f1f1f1f1f1f1f1f
fffff62f2f2f2f2f2f2f2f2f2f2f2f4f4f4f4f4ff7ffffffffffdffffffffffffff79fffffffffffffffffffffffffff9fffffffffffffffffffffffffffffef
ff9fffffffffffffffffffffff6f5f6f7f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f
fffff72f2f2f2f2f2f2f2f2f2f2f2f4f4f4f4f4fffffffffffffffffcfffefffffff9fffffffffdfffffffdfffffdfff9fffffffffffffffffefffffbfbfbfbf
bff6ffffffffffffdfffffff6f6f7f7f7f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f
fffff7ffffffffffffffffffffffffff4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f2f2f2f2f2f2f2f2f2f2f2f2f4f4ff6ffffffffffbfbfbfbfbfffc2d2
bff7ffffff0f0f0f0f0f0f0f5f6f7f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f
fffff7ffffffffffffffffffffffffffffffff8f8fffffffffffffffffffffffff8f8fffffffffffffffffffffffffff8f8ff7ffffffffffbfbfbfbfbfffc3d3
fff7ffff0f0f0f0f0f0f0f0f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f
fffff7ffffffffffffffffffffffffffffffff9f9fffffffffffffffffffffffff9f9fffffffffffffffffffffffffff9f9ff7ffffbfbfbfbfbfbfbfbfffa2b2
ffffbfbf1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f
ffffffffffffffffffffffefffffffffffefff9f9fffffffffffefffffffffffff9f9fffefffffffffffffffffefffff9f9fffffbfbfbfbfbfbfbfbfbfbfa3b3
afbfbfbf1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f
2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f2f2f2f2f2f2f2f2f2f2f2f2fbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbf
bfbfbfbf1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f
2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f2f2f2f2f2f2f2f2f2f2f2f2fbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbf
bfbfbf1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f
0166555011111111016688800166ccc00166aaa061565550065665565665656000999000009aa9000000000001663330a999999a007777000000000000000000
16555555111111111688888816cccccc16aaaaaa52555555621212212211212609aaa900009aa9000000000016333333990000990755557000bbbb0000000000
6556655511111111688668886cc66ccc6aa66aaa52566555515555555555551509a6a900009aa900000000006336633399000099007575000b3333b000000000
6566762111111111686676216c6676316a66769161567621625766561267752600666000009aa900000000006366765199000099075555700b0330b000000000
556776211111111188677621cc677631aa67769162577621515776551267651609666900009aa900000000003367765199000099007557000b3333b000000000
512662151111111181266212c1366313a196691951555555615665555556652509a6a900009aa9007070000031566515990000990005500000b33b0000000000
551221551111111188122122cc133133aa1991996212112262522555555555259aaaaa90009aa90007000000331551559900009900077000000bb00000000000
0551155011111111088112200cc113300aa1199006565665525115500555651699999990009aa9007070000003311550a999999a000000000000000000000000
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
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000101010100000000000000000000000001010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000040000000000000c00000000000000000000000000000002
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001800101010101014040000100008000
__map__
f3f3f0fff3f3f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f3f3f3f3f3f3f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1
f3f3f0fff2f2f3f3f3f3f3f3f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f3f3f3f3f3f3f3f3f3f3f3f3f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1
f3f3fffff2f2fff3f3fffff3f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f3f3f3f3fffffffffffff3f3f3f3f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1
f3f3fffff2f2fff3f3fffff4f4f4f4f4f4f4f4f4f4f4f4f0f0f2f2f2f2f2f2f2f2f2f2f1f1f1f1f3f3f3fffffffffffffffffffff3f3f3f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1
f3f36ff3f3f3fffffffffff4f4f4f4f4f4f4f4f4f4f4f4f0f0f2f2f2f2f2f2f2f2f2f2f1f1f1f3f3f3fffffffffffffffffffffffff3f3f3f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1
f0f07ff3f0f3fffffffffff3fffffffffffffffffff4f4f0f0fffffffffffffffff2f2f1f1f3f3f3fffffffffffffcfffffffffffffff3f3f3f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1
f0f07ffff0f3fff3f3f0f0f3fffffffffffffffffff4f4f0f0fffffffffffffffff2f2f1f3f3f3fffffffffffff7f6f7f5fffffffffffff3f3f3f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1
f0ff7ffff0f3f1f1f1f0f0f3fffffffffffffffffff4f4f0f0fffffffffffffffff2f2f1f3f3fffffffffffffff6f7f5f7fffffffffffffff3f3f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1
f0ff7ffff0f0f1f1f1f0f0f3fffffffffffffffffff4f4f0f0fffffffffffffffff2f2f3f3f3fffffffffffffff6f7f6f5fffffffffffffff3f3f3f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1
f0ff7ffff0f0f1fff1f0f0f3fffffffffffffffffff4f4f0f0fffffffffffffffff2f2f3f3fffffffffffffffffffffffffffffffffffffffff3f3f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1
f0f07ffff0f0f0f0f0f0f0f3fffffffffffffffffff4f4f0f0fffffffff2f26ffff2f2f3f3fffffffffffffffffffffffffffffffffffffffff3f3f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1
f0f07ffff0f0f0f0f0f0f0fffffff6f6f7f6fffffffffff8fffffffffff2f27ffff2f2f3f3fffffffffffffffffffffffcfffffffffffffffff3f3f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1
f0ff7ffffffffffffffffffffffff6fffffffffffffffff9fffffff2f2f2f27ffff2f2f3f3fffffffffffff7f5f5f7f6f6f7f5fffffffffffff3f3f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1
f0f0fffffffffffffcfffffffff6f6fffffffffffffefff9fffffff2f2f2f27ffff2f2f3f3fffffffffffff5f7f7f6f6f6f6f7fffffffffffff3f3f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1
f0f0f0f0f0f0f0f0f0f4f4f4f4f4f4f4f4f4f4f4f4f4f4f0f0f2f2f2f2f2f27ffff2f2f3f3f3fffffffffff6f6f6f7f7f6f7f7fffffffffff3f3f3f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1
f0f0f0f0f0f0f0f0f0f4f4f4f4f4f4f4f4f4f4f4f4f4f4f0f0f2f2f2f2f2f27ffff2f2f1f3f3fffffffffff7f7f7f6f6f7f6f7fffffffffff3f3f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f1f1f1f1f1f1
fffffffffffffffffffffffffffffffcfffffff3f3f3f3f3f3ffffffffffff7ffff3f3f1f3f3f3fffffffffffffffffffffffffffffffff3f3f3f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1fbfbfbfbfbfbfbfbf1f1f1f1f1f1f1f1f1f1f1f1f1f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f1f1f1f1f1f1
fffffffffffffffffffffffffffffffffffffff3f3f3f3f3f3fffffffffffefffff3f3f1f1f3f3f3fffffffffffffffffffffffffffff3f3f3f1f1f1f1f1f1f1f1f1f1f1f1f1f1fbfbfbfbfbfbfbfbfbfbfbfbfbfbfbf1f1f1f1f1f1f1f1f1f1f4f4fffffffffffffffffffffffffffffffffffffffffffff4f4f1f1f1f1f1f1
fffffffffffffffffffffffffffffffffffffffffffffff3f3fffff3f3f3f3f3f3f3f3f1f1f1f3f3f3fffffffffffffffffffffffff3f3f3f1f1f1f1f1f1f1f1f1f1f1f1fbfbfbfbfbfbfbfbfffffffffffffffbfbfbfbfbf1f1f1f1f1f1f1f1f4f4fffffffffffffffffffffffffffffffffffffffffffff4f4f1f1f1f1f1f1
fffffffffffffff6f7fffffdfffffffffdfffffffffdfff3f3fffff3f3f3f8f3f3f3f3f1f1f1f1f3f3f3fffffffffffffffffffff3f3f3f1f1f1f1f1f1f1f1f1f1f1fbfbfbfbfbfbffffffffffff191a1bfffffffffbfbfbfbf1f1f1f1f1f1f1f4f4fffffffffffffffffffffffffffffffffffffffffffff4f4f1f1f1f1f1f1
fffffffffffff6f2f2f2f2f2f2f2f2f2f2f2f2f3f3f3f3f3f3f3fffffffff9fffff3f3f1f1f1f1f1f3f3f3f3fffffffffffff3f3f3f3f1f1f1f1f1f1f1f1f1f1f1fbfbfbfbfffffffffffffffffffffffffffffffffffffbfbf1f1f1f1f1f1f1f4f4fffffffffffffffffffffffffcfffffffffffffffffff4f4f1f1f1f1f1f1
fffffffffff6f2f2f2f2f2f2f2f2f2f2f2f2f3f3f3f3f3f3f3fffffffefff9fffff3f3f1f1f1f1f1f1f3f3f3f3fffffffff3f3f3f3f1f1f1f1f1f1f1f1f1f1fbfbfbfbfffffffffffffffffffffffffffffffffffffffffbfbf1f1f1f1f1f1f1f4f4ffffffffffffffff6ff3f3f3f3f36ffffffffffffffff4f4f1f1f1f1f1f1
ffffff6ff2f2f2f2f2f2f2f2f2f2f2f2f2f2f4f4f4f0f4fbfbf3f2f3f3f3f3f36ff3f3f3f3f3f3f3f3f3f3f3f3f36ffff3f3f3f3f3f3f3f3f3f3f3f3f3fbfbfbfbfbfffffffffffffffffffffffffffffffffffffffffffffbfbf1f1f1f1f1f1f4f4ffffffffffffffff7fffffffffff7ffffffffffffffff4f4f1f1f1f1f1f1
ffffff7ff2f2f2fffffffffffffffff8fffff4f4f4f3f3f2f0f3fbf3f3f3f3f37ff8f3f3f3f3f3f3f3f3f3f3f3f37ffff3f3f3f3f3f3f3f3f8f3f3f3f3f8fbfbfffffffffffffffffffffffffffbfbfbfffffffffffffffffbfbf1f1f1f1f1f1f4f4ffffffffffff6ffffffffcfffcffffff6ffffffffffff4f4f1f1f1f1f1f1
ffffff7ff2f2f2fffffffffffffffff9fffffffffff0fbffffffffffffffffff7ff9ffffffffffffffffffffffff7ffffffffffffffffffff9fffffffff9fffffffffffffffffffffffffffbfbfbfbfbfbfffffffffffffffffbfbf1f1f1f1f1f4f4ffffffffffff7ffff3f3f3f3f3f3f3ff7ffffffffffff4f4f1f1f1f1f1f1
ffffff7ff2f2f2fffffffffffffffff9fffffffffff2f3fffffffffffdffffff7ff9fffffffffffff6fffffffffdfffffffffff7fffffffff9fffffffff9fffffffffffffffffffffffbfbfbfbfbfbfffbfbfffffffffffffffbfbf1f1f1f1f1f4f4ffffffffffff7ffff3f3f3f3f3f3f3ff7ffffffffffff4f4f1f1f1f1f1f1
ffffff7ff2f2f2fffffffffff2f2f2f2fffffffffff0f36ff2f3f4f3f3f3f3f3f3f3f3f3f3f3fffff3f3f3f3f3f3f3f3f3f3f3f3fffff3f3f3f3f3f3f3fbfbfbfffffffffffffffbfbfbfbfffffbfbfffffbfbfffffffffffffbfbf1f1f1f1f1f4f4ffffffffffff7fffffffffffffffffff7ffffffffffff4f4f1f1f1f1f1f1
ffffff7ff2f2f2fffffffffff2f2f2f2f2fffffffff2fb7ff0f2f4f3f3f3f3f3f3f3f3f3f3f3fffff3f3f3f3f3f3f3f3f3f3f3f3fffff3f3f3f3f3f3f3fbfbfbfbfbfffffefbfbfbfbfffffffffbfbfffffffbfbfffbfffffffbfbf1f1f1f1f1f4f4ffffffffffff7fffffffffffffffffff7ffffffffffff4f4f1f1f1f1f1f1
ffffff7ff2f2f2ffff6ff2f2f2f2f2f2f2fff3fffff0f37ff0f3f4f3f3fffffffffffffffff3f3fffffffffffffffffffffffffffff3f3f3f1f1f1f1f1f1f1fbfbfbfbfbfbfbfbfffffffffffffbfb2c2dfffffffffffffff6fbf1f1f1f1f1f1f4f4ffffffffffff7fffffffffffffffffff7ffffffffffff4f4f1f1f1f1f1f1
ffffff7ff2f2f2ffff7ff2f2f2f2f2f2f2fffffffef4f37ffbf4f2f3f3fffffefffffffffffffffffffffffffffffffffefffffffffff3f3f1f1f1f1f1f1f1f1f1f1fbfbfbfbfbfbfffffcfffffbfb3c3dfffffffffffff6fbfbf1f1f1f1f1f1f4f4fffffcfffffcfffffcfffffffffffcfffffcfffffcfff4f4f1f1f1f1f1f1
ffffff7ff2f2f2ffff7ff2f2fffffff4f46ff2f2f2f0fb7ffbf2f4f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f1f1f1f1f1f1f1f1f1f1f1f1f1fbfbfbfbfbfbfffffbfb2a2bfffffffffff6fbfbf1f1f1f1f1f3f3f3f3f3f3f3f3f3f3f3f3f3f3f36ff3f3f3f3f3f3f3f3f3f3f4f4f1f1f1f1f1f1
ffffff7ff2f2f2ffff7ffffffffffff4f47ffffffff4f37ffbf0f4f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1fbfbfbfbfbfbfb3a3bfafffff6f6fbfbf1f1f1f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f37ff3f3f3f3f3f3f3f3f3f3f4f4f1f1f1f1f1f1
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

