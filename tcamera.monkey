Import minib3d
Import matrix

''moneky notes:
''
'' - will need a new gluProject()
'' -created a CameraLayer() mode, to isolate individual objects and their children from being rendered only by certain cameras
'' -  camera should maintain its own MVP matrices

Class TCamera Extends TEntity

	Global cam_list:EntityList<TCamera> = New EntityList<TCamera>
	Field cam_link:list.Node<TCamera>

	Field vx:Int,vy:Int,vwidth:Int,vheight:Int
	Field cls_r#=0.0,cls_g#=0.0,cls_b#=0.0
	Field cls_color:Int=True,cls_zbuffer:Int=True
	
	Field range_near#=1.0,range_far#=1000.0
	Field zoom#=1.0, inv_zoom#=1.0, fov_y#, aspect# ''inv_zoom for TText
	
	Field eyedx#=0.0, eyedy#=0.0, focus#=1.0
	
	Field proj_mode%=1
	
	Field fog_mode%
	Field fog_r#,fog_g#,fog_b#
	Field fog_range_near#=1.0,fog_range_far#=1000.0
	
	' used by CameraProject
	'mat:Matrix = cam view matrix (inverse it)
	Field mod_mat:Matrix =New Matrix ''this is the view matrix, sorry to confuse, but was this way before me
	Field proj_mat:Matrix =New Matrix'Float[16]
	Field projview_mat:Matrix = New Matrix
	Field view_mat:Matrix ''will point to mod_mat
	Field viewport:Int[4]
	
	Global projected_x#
	Global projected_y#
	Global projected_z#
	
	Field frustum:Float[][] '[6][4]
	
	''for cam layer
	Field layer_entity:TEntity


	'Field testdata:Float[10]

	Method New()
		
		frustum = AllocateFloatArray(6,4)
	
	End 
	

	Method CopyEntity:TEntity(parent_ent:TEntity=Null)

		' new cam
		Local cam:TCamera=New TCamera
		
		' copy contents of child list before adding parent
		For Local ent:TEntity=Eachin child_list
			ent.CopyEntity(cam)
		Next
		
		' lists
		
		' add parent, add to list
		cam.AddParent(parent_ent)
		cam.entity_link = entity_list.EntityListAdd(cam)

	
		' add to collision entity list
		If collision_type<>0
			TCollisionPair.ent_lists[collision_type].AddLast(cam)
		Endif
		
		' add to pick entity list
		If pick_mode<>0
			cam.pick_link = TPick.ent_list.AddLast(cam)
		Endif

	
		' update matrix
		If cam.parent<>Null
			cam.mat.Overwrite(cam.parent.mat)
		Else
			cam.mat.LoadIdentity()
		Endif
		
		' copy entity info
		
		cam.mat.Multiply(mat)
		
		cam.px=px
		cam.py=py
		cam.pz=pz
		cam.sx=sx
		cam.sy=sy
		cam.sz=sz
		cam.rx=rx
		cam.ry=ry
		cam.rz=rz
		cam.qw=qw
		cam.qx=qx
		cam.qy=qy
		cam.qz=qz

		cam.name=name
		cam.classname=classname
		cam.order=order
		cam.hide=False
		
		cam.cull_radius=cull_radius
		cam.radius_x=radius_x
		cam.radius_y=radius_y
		cam.box_x=box_x
		cam.box_y=box_y
		cam.box_z=box_z
		cam.box_w=box_w
		cam.box_h=box_h
		cam.box_d=box_d
		cam.pick_mode=pick_mode
		cam.obscurer=obscurer

		' copy camera info
		
		cam.cam_link = cam_list.EntityListAdd(cam) ' add new cam to global cam list
		
		cam.vx=vx
		cam.vy=vy
		cam.vwidth=vwidth
		cam.vheight=vheight
		cam.cls_r=cls_r
		cam.cls_g=cls_g
		cam.cls_b=cls_b
		cam.cls_color=cls_color
		cam.cls_zbuffer=cls_zbuffer
		cam.range_near=range_near
		cam.range_far=range_far
		'cam.zoom=zoom
		cam.CameraZoom(zoom) ''set zoom, fov
		cam.aspect=aspect
		cam.proj_mode=proj_mode
		cam.fog_mode=fog_mode
		cam.fog_r=fog_r
		cam.fog_g=fog_g
		cam.fog_b=fog_b
		cam.fog_range_near=fog_range_near
		cam.fog_range_far=fog_range_far

	End 
	
	Method FreeEntity()
	
		Super.FreeEntity() 
		
		cam_link.Remove()
		
	End

	Function CreateCamera:TCamera(parent_ent:TEntity=Null)

		Local cam:TCamera=New TCamera
		
		cam.CameraViewport(0,0,TRender.width,TRender.height)
		
		cam.classname="Camera"
		
		cam.AddParent(parent_ent)
		cam.entity_link = entity_list.EntityListAdd(cam) ' add to entity list
		cam.cam_link = cam_list.EntityListAdd(cam) ' add to cam list
		
		' update matrix
		If cam.parent<>Null
			cam.mat.Overwrite(cam.parent.mat)
			cam.UpdateMat()
		Else
			cam.UpdateMat(True) ''load identity
		Endif

		Return cam

	End 

	Method CameraViewport(x,y,w,h)

		vx=x
		vy=TRender.height-h-y
		vwidth=w
		vheight=h
		
		CameraZoom(zoom) ''set fov
		aspect = (Float(vwidth)/vheight)
		
		viewport[0] = vx
		viewport[1] = vy
		viewport[2] = w
		viewport[3] = h
		
	End
	
	Method CameraClsColor(r#,g#,b#)

		cls_r=r/255.0
		cls_g=g/255.0
		cls_b=b/255.0

	End
	
	Method CameraClsMode(color:Bool,zbuffer:Bool=True)

		cls_color=color
		cls_zbuffer=zbuffer
	
	End
	
	Method CameraRange(near#,far#)

		range_near=near
		range_far=far
	
	End
	
	Method CameraZoom(zoom_val#)

		zoom=zoom_val
		inv_zoom = 1.0/zoom_val
		fov_y =ATan(1.0/(zoom*(Float(vwidth)/vheight)))*2.0
		
		
	End
	
	Method CameraProjMode(mode=1)
	
		proj_mode=mode
		
	End
	
	' Calls function in TPick
	Method CameraPick:TEntity(x#,y#)
	
		Return TPick.CameraPick(Self,x,y)
	
	End
	
	Method CameraFogMode(mode)

		fog_mode=mode

	End
	
	Method CameraFogColor(r#,g#,b#)

		fog_r=r/255.0
		fog_g=g/255.0
		fog_b=b/255.0

	End
	
	Method CameraFogRange(near#,far#)

		fog_range_near=near
		fog_range_far=far
	
	End

	Method CameraProject:Vector(x#,y#,z#)
		
		''update cam matrix
		Update(Null)
		
		Local p:Vector
		p = GluProject(x,y,-z,Self) 'mod_mat,proj_mat,viewport)

		projected_x=Float(p.x)
		projected_y=Float(p.y)
		projected_z=Float(p.z)

		Return p
	End

	Method CameraUnProject:Vector(x#,y#,z#=0.5)
		
		''update cam matrix
		Update(Null)
		
		'Local z# = range_near+0.1
		y = viewport[3] - y
		Local p:Vector = GluUnProject(x,y,z, Self)
		p.z = -p.z
		
		projected_x=Float(p.x)
		projected_y=Float(p.y)
		projected_z=Float(p.z)

		Return p
	End

	Method ProjectedX#()
	
		Return projected_x
	
	End
	
	Method ProjectedY#()

		Return projected_y
	
	End
	
	Method ProjectedZ#()
	
		Return projected_z
	
	End

	Method EntityInView#(ent:TEntity)

		If TMesh(ent)<>Null

			' get new mesh bounds if necessary
			TMesh(ent).GetBounds()

		Endif
		
		Return EntityInFrustum(ent)
		
	End
		
	Method ExtractFrustum()

		Local proj#[] = proj_mat.ToArray()
		Local modl#[] = mod_mat.ToArray()
		Local clip#[16]
		Local t#
		
		' Get the current PROJECTION matrix from OpenGL
		'glGetFloatv( GL_PROJECTION_MATRIX, proj )
		
		' Get the current MODELVIEW matrix from OpenGL
		'glGetFloatv( GL_MODELVIEW_MATRIX, modl )
		

		' Combine the two matrices (multiply projection by modelview)
		clip[ 0] = modl[ 0] * proj[ 0] + modl[ 1] * proj[ 4] + modl[ 2] * proj[ 8] + modl[ 3] * proj[12]
		clip[ 1] = modl[ 0] * proj[ 1] + modl[ 1] * proj[ 5] + modl[ 2] * proj[ 9] + modl[ 3] * proj[13]
		clip[ 2] = modl[ 0] * proj[ 2] + modl[ 1] * proj[ 6] + modl[ 2] * proj[10] + modl[ 3] * proj[14]
		clip[ 3] = modl[ 0] * proj[ 3] + modl[ 1] * proj[ 7] + modl[ 2] * proj[11] + modl[ 3] * proj[15]
		
		clip[ 4] = modl[ 4] * proj[ 0] + modl[ 5] * proj[ 4] + modl[ 6] * proj[ 8] + modl[ 7] * proj[12]
		clip[ 5] = modl[ 4] * proj[ 1] + modl[ 5] * proj[ 5] + modl[ 6] * proj[ 9] + modl[ 7] * proj[13]
		clip[ 6] = modl[ 4] * proj[ 2] + modl[ 5] * proj[ 6] + modl[ 6] * proj[10] + modl[ 7] * proj[14]
		clip[ 7] = modl[ 4] * proj[ 3] + modl[ 5] * proj[ 7] + modl[ 6] * proj[11] + modl[ 7] * proj[15]
		
		clip[ 8] = modl[ 8] * proj[ 0] + modl[ 9] * proj[ 4] + modl[10] * proj[ 8] + modl[11] * proj[12]
		clip[ 9] = modl[ 8] * proj[ 1] + modl[ 9] * proj[ 5] + modl[10] * proj[ 9] + modl[11] * proj[13]
		clip[10] = modl[ 8] * proj[ 2] + modl[ 9] * proj[ 6] + modl[10] * proj[10] + modl[11] * proj[14]
		clip[11] = modl[ 8] * proj[ 3] + modl[ 9] * proj[ 7] + modl[10] * proj[11] + modl[11] * proj[15]
		
		clip[12] = modl[12] * proj[ 0] + modl[13] * proj[ 4] + modl[14] * proj[ 8] + modl[15] * proj[12]
		clip[13] = modl[12] * proj[ 1] + modl[13] * proj[ 5] + modl[14] * proj[ 9] + modl[15] * proj[13]
		clip[14] = modl[12] * proj[ 2] + modl[13] * proj[ 6] + modl[14] * proj[10] + modl[15] * proj[14]
		clip[15] = modl[12] * proj[ 3] + modl[13] * proj[ 7] + modl[14] * proj[11] + modl[15] * proj[15]
	
		
		
		' Extract the numbers for the right plane
		frustum[0][0] = clip[ 3] - clip[ 0]
		frustum[0][1] = clip[ 7] - clip[ 4]
		frustum[0][2] = clip[11] - clip[ 8]
		frustum[0][3] = clip[15] - clip[12]
		
		' Normalize the result
		t = 1.0/Sqrt( frustum[0][0] * frustum[0][0] + frustum[0][1] * frustum[0][1] + frustum[0][2] * frustum[0][2] )
		frustum[0][0] *= t
		frustum[0][1] *= t
		frustum[0][2] *= t
		frustum[0][3] *= t
		
		' Extract the numbers for the left plane 
		frustum[1][0] = clip[ 3] + clip[ 0]
		frustum[1][1] = clip[ 7] + clip[ 4]
		frustum[1][2] = clip[11] + clip[ 8]
		frustum[1][3] = clip[15] + clip[12]
		
		' Normalize the result
		t = 1.0/Sqrt( frustum[1][0] * frustum[1][0] + frustum[1][1] * frustum[1][1] + frustum[1][2] * frustum[1][2] )
		frustum[1][0] *= t
		frustum[1][1] *= t
		frustum[1][2] *= t
		frustum[1][3] *= t
		
		' Extract the BOTTOM plane
		frustum[2][0] = clip[ 3] + clip[ 1]
		frustum[2][1] = clip[ 7] + clip[ 5]
		frustum[2][2] = clip[11] + clip[ 9]
		frustum[2][3] = clip[15] + clip[13]
		
		' Normalize the result
		t = 1.0/Sqrt( frustum[2][0] * frustum[2][0] + frustum[2][1] * frustum[2][1] + frustum[2][2] * frustum[2][2] )
		frustum[2][0] *= t
		frustum[2][1] *= t
		frustum[2][2] *= t
		frustum[2][3] *= t
		
		' Extract the TOP plane
		frustum[3][0] = clip[ 3] - clip[ 1]
		frustum[3][1] = clip[ 7] - clip[ 5]
		frustum[3][2] = clip[11] - clip[ 9]
		frustum[3][3] = clip[15] - clip[13]
		
		' Normalize the result
		t = 1.0/Sqrt( frustum[3][0] * frustum[3][0] + frustum[3][1] * frustum[3][1] + frustum[3][2] * frustum[3][2] )
		frustum[3][0] *= t
		frustum[3][1] *= t
		frustum[3][2] *= t
		frustum[3][3] *= t
		
		' Extract the FAR plane
		frustum[4][0] = clip[ 3] - clip[ 2]
		frustum[4][1] = clip[ 7] - clip[ 6]
		frustum[4][2] = clip[11] - clip[10]
		frustum[4][3] = clip[15] - clip[14]
		
		' Normalize the result
		t = 1.0/Sqrt( frustum[4][0] * frustum[4][0] + frustum[4][1] * frustum[4][1] + frustum[4][2] * frustum[4][2] )
		frustum[4][0] *= t
		frustum[4][1] *= t
		frustum[4][2] *= t
		frustum[4][3] *= t
		
		' Extract the NEAR plane
		frustum[5][0] = clip[ 3] + clip[ 2]
		frustum[5][1] = clip[ 7] + clip[ 6]
		frustum[5][2] = clip[11] + clip[10]
		frustum[5][3] = clip[15] + clip[14]

		' Normalize the result 
		t = 1.0/Sqrt( frustum[5][0] * frustum[5][0] + frustum[5][1] * frustum[5][1] + frustum[5][2] * frustum[5][2] )
		frustum[5][0] *= t
		frustum[5][1] *= t
		frustum[5][2] *= t
		frustum[5][3] *= t

	End

	Method EntityInFrustum#(ent:TEntity)
	
		Local x#=ent.EntityX(True)
		Local y#=ent.EntityY(True)
		Local z#=ent.EntityZ(True)

		Local radius#=Abs(ent.cull_radius) ' use absolute value as cull_radius will be negative value if set by MeshCullRadius (manual cull)

		' if entity is mesh, we need to use mesh centre for culling which may be different from entity position
		Local mesh:TMesh = TMesh(ent)
		If mesh
			
			''moved to GetBounds() in TMesh
			' mesh centre
			'x=mesh.min_x
			'y=mesh.min_y
			'z=mesh.min_z
			'x=x+(mesh.max_x-mesh.min_x)*0.5
			'y=y+(mesh.max_y-mesh.min_y)*0.5
			'z=z+(mesh.max_z-mesh.min_z)*0.5
			
			'' transform mesh centre into world space
			'TEntity.TFormPoint (mesh.center_x,mesh.center_y,mesh.center_z,ent,Null)
			'''TEntity.TFormPoint (x,y,z,ent,Null)
			'x=tformed_x
			'y=tformed_y
			'z=tformed_z
			
			Local r:Float[] = ent.mat.TransformPoint(mesh.center_x,mesh.center_y,mesh.center_z)
			x=r[0]; y=r[1]; z=r[2]
			
			' radius - apply entity scale
			'Local rx#=radius*ent.gsx 'EntityScaleX(True)
			'Local ry#=radius*ent.gsy 'EntityScaleY(True)
			'Local rz#=radius*ent.gsz 'EntityScaleZ(True)

			'If rx<0 Then rx=-rx
			'If ry<0 Then ry=-ry
			'If rz<0 Then rz=-rz
			'radius = Max(Max(rx,ry),rz)
			Local gs:Float = Max(Max(ent.gsx,ent.gsy),ent.gsz) ''optimizing ABS()
			radius = radius*gs
			If radius<0 Then radius=-radius
			
		Endif
		
		' is sphere in frustum

		Local d#

		d = frustum[0][0] * x + frustum[0][1] * y + frustum[0][2] * -z + frustum[0][3]
		If d <= -radius Then Return 0
		d = frustum[1][0] * x + frustum[1][1] * y + frustum[1][2] * -z + frustum[1][3]
		If d <= -radius Then Return 0
		d = frustum[2][0] * x + frustum[2][1] * y + frustum[2][2] * -z + frustum[2][3]
		If d <= -radius Then Return 0
		d = frustum[3][0] * x + frustum[3][1] * y + frustum[3][2] * -z + frustum[3][3]
		If d <= -radius Then Return 0
		d = frustum[4][0] * x + frustum[4][1] * y + frustum[4][2] * -z + frustum[4][3]
		If d <= -radius Then Return 0
		d = frustum[5][0] * x + frustum[5][1] * y + frustum[5][2] * -z + frustum[5][3]
		If d <= -radius Then Return 0


		Return d + radius
	
	End
	
	
	''move to trender, keep frustum update here
	Method Update(cam:TCamera)
	
		'' old AA jitter stuff
		'Local jx#=0 'TGlobal.j[TGlobal.jitter][0]
		'Local jy#=0 'TGlobal.j[TGlobal.jitter][1]	
		'If TGlobal.aa=False Then jx=0;jy=0


		accPerspective(fov_y,range_near,range_far,0,0)

		'mod_mat = LoadIndentity()
		mod_mat = mat.Inverse()
		view_mat = mod_mat
		projview_mat.Overwrite(proj_mat ) 'Copy()
		projview_mat.Multiply4(mod_mat)
		
		If eyedx Or eyedy Then mod_mat.Translate(-eyedx,-eyedy,0.0)

		If cam Then ExtractFrustum() ''allows for skipping of frustum (used in camera project)
	
	End
	
	Method accPerspective(fovy#,zNear#,zFar#,pixdx#,pixdy#)
	
		Local fov2#,left_#,right_#,bottom#,top#
		'fov2=((fovy*Pi)/180.0)/2.0
		fov2=fovy*0.5 '/2.0
		
		top=zNear/(Cos(fov2)/Sin(fov2))
		bottom=-top
		right_=top*aspect
		left_=-right_
	
		accFrustum(left_,right_,bottom,top,zNear,zFar,pixdx,pixdy)
	
	End

	Method accFrustum(left_#,right_#,bottom#,top#,zNear#,zFar#,pixdx#,pixdy#)
	
		Local xwsize#,ywsize#
		Local dx#,dy#
		
		If pixdx Or pixdy
			xwsize=right_-left_
			ywsize=top-bottom
			dx=-(pixdx*xwsize/Float(viewport[2])+eyedx*zNear/focus)
			dy=-(pixdy*ywsize/Float(viewport[3])+eyedy*zNear/focus)
		Endif
	
		'gluPerspective(ATan((1.0/(zoom#*ratio#)))*2.0,ratio#,range_near#,range_far#)
		If proj_mode = 1 Then
			'glFrustumf(left_+dx,right_+dx,bottom+dy,top+dy,zNear,zFar)
			left_ += dx; right_ += dx; bottom += dy; top += dy
			proj_mat.grid[0][0] = 2.0 * zNear / (right_ - (left_) )
			proj_mat.grid[1][0] = 0.0
			proj_mat.grid[2][0] = (right_ + left_) / (right_ - left_)
			proj_mat.grid[3][0] = 0.0
			
		    proj_mat.grid[0][1] = 0.0
			proj_mat.grid[1][1] = 2.0 * zNear / (top - bottom )
			proj_mat.grid[2][1] = (top + bottom) / (top - bottom)
			proj_mat.grid[3][1] = 0.0
			
		    proj_mat.grid[0][2] = 0.0
			proj_mat.grid[1][2] = 0.0
			proj_mat.grid[2][2] = -(zFar + zNear) / (zFar - zNear)
			proj_mat.grid[3][2] = -(2.0 * zFar * zNear) / (zFar - zNear)
			
		    proj_mat.grid[0][3] = 0.0
			proj_mat.grid[1][3] = 0.0
			proj_mat.grid[2][3] = -1.0
			proj_mat.grid[3][3] = 0.0
		Else If proj_mode = 2
			'testdata=[1,left_+dx,right_+dx,bottom+dy,top+dy,zNear,zFar]
			'glOrthof(left_+dx,right_+dx,bottom+dy,top+dy,zNear,zFar)

			left_ += dx; right_ += dx; bottom += dy; top += dy
			proj_mat.grid[0][0] = 2.0 / (right_ - left_)
			proj_mat.grid[0][1] = 0.0
			proj_mat.grid[0][2] = 0.0
			proj_mat.grid[0][3] = 0.0
			
			proj_mat.grid[1][0] = 0.0
			proj_mat.grid[1][1] = 2.0 / (top - bottom)
			proj_mat.grid[1][2] = 0.0
			proj_mat.grid[1][3] = 0.0
			
			proj_mat.grid[2][0] = 0.0
			proj_mat.grid[2][1] = 0.0
			proj_mat.grid[2][2] = -2.0 / (zFar - zNear)
			proj_mat.grid[2][3] = 0.0
			
			proj_mat.grid[3][0] = -(right_ + left_) / (right_ - left_)
			proj_mat.grid[3][1] = -(top + bottom) / (top - bottom)
			proj_mat.grid[3][2] = -(zFar + zNear) / (zFar - zNear)
			proj_mat.grid[3][3] = 1.0

		Endif
		
		
	End
	
	
	''
	'' CameraLayer(entity)
	'' - this command isolates a camera's render to only this object and it's children
	'' - used for shaders and ui screens (if camera set to ortho)
	'' - lights are uneffected
	'' - camera are rendered in order they are added (or use EntityOrder() )
	Method CameraLayer(ent:TEntity)
		
		is_cam_layer = True
		layer_entity = ent
		ent.is_cam_layer = True
		ent.cam_layer = Self
		
		For Local ch:TEntity = Eachin ent.child_list
			
			ch.is_cam_layer = True
			ch.cam_layer = Self
			
		Next
		
	End
	
	'' GluProject()
	'' --takes a 3d point and returns screen coordinates.
	Function GluProject:Vector(x:Float, y:Float, z:Float, cam:TCamera) 'model:Float[], proj:Float[], viewport:Int[])
		''mod16, proj16, v4
		
		
		Local pos:Vector = New Vector
		
		Local temp:Float[4]
		
		Local mod_mat:Matrix = cam.mod_mat.Copy() 'New Matrix
		'mod_mat.FromArray(model)
		
		Local proj_mat:Matrix = cam.proj_mat.Copy() 'New Matrix
		'proj_mat.FromArray(proj)
		
		'point -> model matrix -> proj matrix
		mod_mat.Translate4(x, y, z, 1.0)
		proj_mat.Translate4(mod_mat.grid[3][0], mod_mat.grid[3][1], mod_mat.grid[3][2], mod_mat.grid[3][3])
		
		' normalize
		If (proj_mat.grid[3][3] = 0.0) Then Return New Vector(0.0,0.0,0.0)
		
		temp[0] = proj_mat.grid[3][0] /proj_mat.grid[3][3]
		temp[1] = proj_mat.grid[3][1] /proj_mat.grid[3][3]
		temp[2] = proj_mat.grid[3][2] /proj_mat.grid[3][3]
		
		' screen coordinates
		pos.x = cam.viewport[0] + (1.0 + temp[0]) * cam.viewport[2] *0.5
		pos.y = -cam.viewport[1] - (1.0 + temp[1]) * cam.viewport[3] *0.5 + cam.viewport[3]
		' z depth
		pos.z = (1.0 + temp[2]) *0.5
		
		Return pos
	
	End
	
	
	'' gluUnProject()
	'' takes a 2d screen point and returns 3d coordinates.
	'' (may need to pre-negate z)
	''
	Function  GluUnProject:Vector(wx:Float, wy:Float, wz:Float, cam:TCamera)
	
		'wy = cam.viewport[3] - wy ''adjust since opengl is 0,0 at bottom left
		Local x# = ((wx-cam.viewport[0]) / cam.viewport[2]) *2.0 -1.0
		Local y# = ((wy-cam.viewport[1]) / cam.viewport[3]) *2.0 -1.0
		Local z# = ( wz*2.0 - 1.0) 
		
		'Local proj_mat:Matrix = New Matrix
		'proj_mat.FromArray(cam.proj_mat)
	
	
		Local cam_mat:Matrix = cam.mat.Copy() '.Inverse()
		Local inv_mat:Matrix = cam_mat '.Inverse() ''normally inverse, but since we had to inverse the camera anyways...
	
		inv_mat.Multiply4(cam.proj_mat.Inverse4() )
		inv_mat.Translate4(x, y, z, 1.0)
		
		Local d:Float = inv_mat.grid[3][3]
		If d = 0.0 Then Return New Vector()
		d = 1.0/d
	
		Return New Vector(inv_mat.grid[3][0]*d,inv_mat.grid[3][1]*d,inv_mat.grid[3][2]*d)
	
	End
	
End



