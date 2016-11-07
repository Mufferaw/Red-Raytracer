Red [

	Needs: 'View
]


#system-global [
	#include %/E/Dev/red/red/runtime/random.reds
	_random/init
	_random/srand 123  

	vector3!: alias struct! [
	    x [float!]
	    y [float!]
	    z [float!]
	]	

	material!: alias struct! [
   		type 	[integer!]
   		param1 	[vector3!]
   		param2 	[float!]
	]
		
	sphere!: alias struct! [
		center 	[vector3!]
		radius 	[float!]
		material[material!]
	]

	Max-Reflection-Depth: 1
	Scene-Length: 0

	Pvector-list: as vector3! allocate size? vector3!
	Mvector-list: as vector3! allocate size? vector3!
	material-list: as material! allocate size? material!
	hit-list: as sphere! allocate size? sphere!
] ;-- End System Global

Trace: routine[
		/local nx ny ns
				lower_left_corner
				vertical horizontal	origin look-at
				v-up cam-u cam-v cam-w
				u v fi fnx fj fny
				v-FOV aspect theta half-height half-width
				vec3-sub vec3-add vec3-mul
				Set-Camera vec3-len vec3-unitvector vec3-cross vec3-Mfloat vec3-Dfloat get-rand
				vec3-random-in-unit-sphere
				vec3-reflect
				vec3-dot
				get-ray color hit-list-hit scatter hit-sphere ray-pap

		][

		vector3!: alias struct! [
		    x [float!]
		    y [float!]
		    z [float!]
		]	

		get-rand: func[
    		return: [float!]
    		/local
    			f 	[float!]
    		][
        		f: as float! _random/rand
        		f: ((f // 20000.0) / 10000.0) - 1.0
        		return f
   		]

		vec3-sub: func [
			dest 	[vector3!]
		    a 		[vector3!]
		    b 		[vector3!]
		    ][
		    	dest/x: a/x - b/x 
		    	dest/y: a/y - b/y 
		    	dest/z: a/z - b/z
		    ]

		vec3-add: func [
			dest 	[vector3!]
		    a 		[vector3!]
		    b 		[vector3!]
		    ][
		    	dest/x: a/x + b/x 
		    	dest/y: a/y + b/y
		    	dest/z: a/z + b/z
		    ]

		vec3-mul: func [
			dest 	[vector3!]
		    a 		[vector3!]
		    b 		[vector3!]
		    ][
		    	dest/x: a/x * b/x 
		    	dest/y: a/y * b/y
		    	dest/z: a/z * b/z
		    ]

		vec3-Mfloat: func [
			dest 	[Vector3!]
    		vec 	[vector3!]
    		f 		[float!]
    		][      
    			dest/x: vec/x * f
    			dest/y: vec/y * f
    			dest/z: vec/z * f
			]

		vec3-Dfloat: func [
			dest 	[vector3!]
    		vec 	[vector3!]
    		f  		[float!]
    		][
    		    dest/x: vec/x / f
    		    dest/y: vec/y / f
    		    dest/z: vec/z / f  
    		]

		vec3-dot: func [
		    a 		[vector3!]
		    b 		[vector3!]
		    return: [float!]
		    ][
		         (a/x * b/x) + (a/y * b/y) + (a/z * b/z)
		    ]

		vec3-cross: func [
			dest 	[vector3!]
		    a 		[vector3!] 
		    b 		[vector3!]
		    ][
		    	dest/x: (a/y * b/z) - (a/z * b/y)
		    	dest/y: -1.0 * ((a/x * b/z) - (a/z * b/x))
		    	dest/z: (a/x * b/y) - (a/y * b/x)
		    ]


		vec3-len: func [
		    a 		[vector3!]
		    return: [float!]
		    ][
		        sqrt ((a/x * a/x) + (a/y * a/y) + (a/z * a/z))
		    ]
		

		vec3-unitvector: func [
		    a 		[vector3!]
		    /local 
		    	normalizeLength [float!]
		    ][
		    	normalizeLength: vec3-len a
		    	vec3-Dfloat a a normalizeLength  
		    ]

		vec3-random-in-unit-sphere: func [
			dest 	[vector3!]
			/local 
				t 	[float!]
				l 	[float!]
				m 	[float!]
				n 	[float!]
			][
				t: 2.0
			
				while [t >= 1.0][
					l: get-rand m: get-rand n: get-rand
					t: (l * l) + (m * m) + (n * n)
				]
				
				dest/x: l dest/y: m dest/z: n
				
		    ]

		vec3-reflect: function [
			dest 	[vector3!]
		    a 		[vector3!] 
		    b 		[vector3!]
		    /local 
		    	tf 	[float!]
		    	v0 	[vector3!]
		    	v1 	[vector3!]
		][
		    v0: as vector3! allocate size? vector3!
			v1: as vector3! allocate size? vector3!

			v0/x: a/x 
			v0/y: a/y 
			v0/z: a/z

			v1/x: b/x 
			v1/y: b/y 
			v1/z: b/z 

		    tf: vec3-dot v0 v1
		    tf: tf * 2.0

		    vec3-Mfloat dest v1 tf
		    vec3-sub dest v0 dest  

		    free as byte-ptr! v0
			free as byte-ptr! v1   
		]    


		color: func[
			dest 	[vector3!]
			rorigin [vector3!]
			rdirection [vector3!]
			depth 	[integer!]
			return:	[integer!]
			/local 	
				unit-dir 	[vector3!]
				t 			[float!]
				v1 			[vector3!]
				v2 			[vector3!]
				v0 			[vector3!]
				rec-t 		[pointer! [float!]]
				rec-p 		[vector3!]
				rec-n 		[vector3!]
				rec-mat 	[material!]
				scattered-dir 	 [vector3!]
				scattered-origin [vector3!]
				attenuation [vector3!]
				scres 		[logic!]
				d 			[integer!]
				check 		[logic!]
		][
			rec-t: declare pointer! [float!] 
			rec-p: as vector3! allocate size? vector3!
			rec-n: as vector3! allocate size? vector3!
			rec-mat: as material! allocate size? material!
			rec-mat/type: 1
			rec-p/x: 0.0 
			rec-p/y: 0.0
			rec-p/z: 0.0		
			rec-n/x: 0.0 
			rec-n/y: 0.0
			rec-n/z: 0.0
	
			v0: as vector3! allocate size? vector3!
			attenuation: as vector3! allocate size? vector3!
	
			scattered-dir: as vector3! allocate size? vector3!
			scattered-dir/x: 0.0
			scattered-dir/y: 0.0
			scattered-dir/z: 0.0
	
			scattered-origin: as vector3! allocate size? vector3!
			scattered-origin/x: 0.0
			scattered-origin/y: 0.0
			scattered-origin/z: 0.0
	
			unit-dir: declare vector3!
	
			v1: declare vector3! v1/x: 1.0 v1/y: 1.0 v1/z: 1.0
			v2: declare vector3! v2/x: 0.5 v2/y: 0.7 v2/z: 1.0
	
			d: depth 
			check: false
			scres: false
		
			check: hit-list-hit rOrigin rDirection 0.001 1.0e32 rec-t rec-p rec-n rec-mat
	
			if (check)[
				scres: scatter rOrigin rDirection rec-p rec-n attenuation scattered-origin scattered-dir rec-mat
				either all[scres = true d < Max-Reflection-Depth][
					color v0 scattered-origin scattered-dir (d + 1)			
					vec3-mul dest v0 attenuation
					free as byte-ptr! attenuation
					free as byte-ptr! scattered-dir
					free as byte-ptr! scattered-origin
					free as byte-ptr! v0
					free as byte-ptr! rec-p
					free as byte-ptr! rec-n
					free as byte-ptr! rec-mat
					return 1
				][
					dest/x: 0.0 dest/y: 0.0 dest/z: 0.0 
					free as byte-ptr! attenuation
					free as byte-ptr! scattered-dir
					free as byte-ptr! scattered-origin
					free as byte-ptr! v0
					free as byte-ptr! rec-p
					free as byte-ptr! rec-n
					free as byte-ptr! rec-mat
					return 0
				]
			] 
			unit-dir: rdirection
			vec3-unitvector unit-dir
			t: 0.5 * (unit-dir/y + 1.0)
			vec3-Mfloat v2 v2 t 
			vec3-Mfloat v1 v1 (1.0 - t)
			vec3-add dest v1 v2
			free as byte-ptr! attenuation
			free as byte-ptr! scattered-dir
			free as byte-ptr! scattered-origin
			free as byte-ptr! v0
			free as byte-ptr! rec-p
			free as byte-ptr! rec-n
			free as byte-ptr! rec-mat
			return 2
		]

		scatter: func[
			rorigin-in		[vector3!]
			rdirection-in 	[vector3!]
			rec-p 			[vector3!]
			rec-n 			[vector3!]
			attenuation 	[vector3!]
			scattered-origin[vector3!]
			scattered-dir 	[vector3!]
			mat 			[material!]
			return: 		[logic!]
			/local 
				target 		[vector3!]
				v1 			[vector3!]
				f 			[float!]
				v3 			[vector3!]
				temp-rec-n 	[vector3!]
				temp-rec-p 	[vector3!]
				temp-scat-dir  [vector3!]
				temp-scat-orig [vector3!]
		][
			target: as vector3! allocate size? vector3!
			v1: as vector3! allocate size? vector3!
			v3: as vector3! allocate size? vector3!
			temp-rec-n: as vector3! allocate size? vector3!
			temp-rec-p: as vector3! allocate size? vector3!
			temp-scat-dir: as vector3! allocate size? vector3!
			temp-scat-orig: as vector3! allocate size? vector3!
	
			switch mat/type[
				1[	;-- Lambert
					vec3-random-in-unit-sphere v1
					vec3-add target rec-p rec-n
					vec3-add temp-scat-dir target v1
					vec3-sub temp-scat-dir temp-scat-dir rec-p
					scattered-origin/x: rec-p/x scattered-origin/y: rec-p/y scattered-origin/z: rec-p/z 
					scattered-dir/x: temp-scat-dir/x scattered-dir/y: temp-scat-dir/y scattered-dir/z: temp-scat-dir/z 

					attenuation/x: mat/param1/x 
					attenuation/y: mat/param1/y 
					attenuation/z: mat/param1/z
					free as byte-ptr! target
					free as byte-ptr! v1
					free as byte-ptr! v3
					free as byte-ptr! temp-rec-n
					free as byte-ptr! temp-rec-p 
					free as byte-ptr! temp-scat-dir 
					free as byte-ptr! temp-scat-orig
					return true
				]
				2[  ;-- Metal	
					v3: rdirection-in
					vec3-unitvector v3
					vec3-reflect scattered-dir v3 rec-n

					vec3-random-in-unit-sphere v3
					vec3-Mfloat v3 v3 mat/param2
					vec3-add scattered-dir scattered-dir v3

					scattered-origin/x: rec-p/x scattered-origin/y: rec-p/y scattered-origin/z: rec-p/z 
					attenuation/x: mat/param1/x 
					attenuation/y: mat/param1/y 
					attenuation/z: mat/param1/z
					f: vec3-dot scattered-dir rec-n
					free as byte-ptr! target
					free as byte-ptr! v1
					free as byte-ptr! v3
					free as byte-ptr! temp-rec-n
					free as byte-ptr! temp-rec-p 
					free as byte-ptr! temp-scat-dir 
					free as byte-ptr! temp-scat-orig
					return (f > 0.0)
				]
					;3[]
			]
			free as byte-ptr! target
			free as byte-ptr! v1
			free as byte-ptr! v3
			free as byte-ptr! temp-rec-n
			free as byte-ptr! temp-rec-p 
			free as byte-ptr! temp-scat-dir 
			free as byte-ptr! temp-scat-orig
			return false
		]

		get-ray: func[
			s 			[float!]
			t 			[float!]
			horizontal 	[vector3!]
			vertical 	[vector3!]
			lower_left_corner [vector3!]
			origin 		[vector3!]
			dest 		[vector3!]
			/local 
				temps 	[vector3!]
				tempt 	[vector3!]
		][
			temps: as vector3! allocate size? vector3!
			tempt: as vector3! allocate size? vector3!
			vec3-Mfloat temps horizontal s
			vec3-Mfloat tempt vertical t
			vec3-add dest lower_left_corner temps
			vec3-add dest dest tempt
			vec3-sub dest dest origin
			free as byte-ptr! temps
			free as byte-ptr! tempt
		]


		hit-list-hit: func[
			rorigin 	[vector3!]
			rdirection 	[vector3!]
			t-min 		[float!]
			t-max 		[float!]
			rec-t 		[pointer! [float!]]
			rec-p 		[vector3!]
			rec-n 		[vector3!]
			rec-mat		[material!]
			return: 	[logic!]
			/local 	
				hit-anything 	[logic!]
				closest-so-far 	[float!]
				list-len 		[integer!]
				list-as-array 	[byte-ptr!]
				item 			[sphere!]
				i 				[integer!]
				check 			[logic!]
				temp-rec-t 		[pointer! [float!]]
				temp-rec-p 		[vector3!]
				temp-rec-n 		[vector3!]
				temp-rec-mat 	[material!]
		][
			temp-rec-t: declare pointer! [float!] 
			temp-rec-p: as vector3! allocate size? vector3!
			temp-rec-n: as vector3! allocate size? vector3!
			temp-rec-mat: as material! allocate size? material!
	
			hit-anything: false
			closest-so-far: t-max
	
			list-len: 16
			item: declare sphere!							
			list-as-array: as byte-ptr! hit-list
			i: 1
			until [
				item: as sphere! list-as-array 
			   	check: hit-sphere item/center item/radius t-min closest-so-far rorigin rdirection temp-rec-t temp-rec-p temp-rec-n 
			    if (check) [
			    	hit-anything: true
			    	closest-so-far: temp-rec-t/value
			    	rec-p/x: temp-rec-p/x rec-p/y: temp-rec-p/y rec-p/z: temp-rec-p/z 
			    	rec-n/x: temp-rec-n/x rec-n/y: temp-rec-n/y rec-n/z: temp-rec-n/z 
			    	rec-t/value: temp-rec-t/value
	
			    	rec-mat/type: item/material/type
			    	rec-mat/param1: item/material/param1
			    	rec-mat/param2: item/material/param2
			    ]
			    list-as-array: list-as-array + list-len
			    i: i + 1
			    i > Scene-Length
			]
				
			free as byte-ptr! temp-rec-t 
			free as byte-ptr! temp-rec-p 
			free as byte-ptr! temp-rec-n 
			free as byte-ptr! temp-rec-mat 
			return hit-anything
		]

		hit-sphere: func[
			center		[vector3!]
			radius 		[float!]
			t-min		[float!]
			t-max		[float!]
			rorigin 	[vector3!]
			rdirection 	[vector3!]
			rec-t 		[pointer! [float!]]
			rec-p 		[vector3!]
			rec-n 		[vector3!]
			return: 	[logic!]
			/local 
				a 			[float!]
				b 			[float!]
				c 			[float!]
				discriminant [float!]
				oc 			[vector3!]
				temp 		[float!]
				ntemp 		[vector3!]
		][
			oc: 	as vector3! allocate size? vector3!	
			ntemp:  as vector3! allocate size? vector3!
		
			vec3-sub oc rorigin center
			a: vec3-dot rdirection rdirection
			b: vec3-dot oc rdirection
			c: (vec3-dot oc oc) - (radius * radius)
			discriminant: (b * b) - (a * c)
			
			if (discriminant > 0.0) [
				temp: ( ( (b * -1.0) - sqrt discriminant) / a)
				if all [temp < t-max temp > t-min][
					rec-t/value: temp
				 	ray-pap rec-p rorigin rdirection temp 
				 	vec3-sub ntemp rec-p center
				 	vec3-Dfloat rec-n ntemp radius
				 	free as byte-ptr! oc
				 	free as byte-ptr! ntemp
				 	return true	
				]
				temp: ( ( (b * -1.0) + sqrt discriminant) / a)
				if all [temp < t-max temp > t-min][
					rec-t/value: temp
				 	ray-pap rec-p rorigin rdirection temp 
				 	vec3-sub ntemp rec-p center
				 	vec3-Dfloat rec-n ntemp radius
				 	free as byte-ptr! oc
				 	free as byte-ptr! ntemp
				 	return true	
				]
			] 
			free as byte-ptr! oc
			free as byte-ptr! ntemp
			return false
		]

		ray-pap: func [
			dest 		[vector3!]
			origin 		[vector3!]
			direction 	[vector3!]
			t 			[float!]
		][
			vec3-Mfloat dest direction t
			vec3-add dest dest origin
		]

] ;end of trace routine



render: routine[
	half-height 	[float!]
	half-width 		[float!]
	nx 				[integer!]
	ny 				[integer!]
	ns 				[integer!]
	Depth 			[integer!]
	px 				[float!] 
	py 				[float!] 
	pz 				[float!] 
	tx 				[float!]
	ty 				[float!]
	tz 				[float!]
	img 			[image!]
	/local 
		lower_left_corner 	[vector3!]
		vertical 			[vector3!]
		horizontal 			[vector3!]
		origin 				[vector3!]
		look-at 			[vector3!]
		v-up 				[vector3!]
		cam-u 				[vector3!]
		cam-v 				[vector3!]
		cam-w 				[vector3!]
		i 					[integer!]
		j 					[integer!]
		s 					[integer!]
		u 					[float!]
		v 					[float!]
		col 				[vector3!]
		col-temp 			[vector3!]
		ir 					[integer!]
		ig 					[integer!]
		ib 					[integer!]
		fnx  				[float!]
		fny  				[float!]
		fns  				[float!]
		fi  				[float!]
		fj  				[float!]
		tempv 				[vector3!]			
		pix 				[int-ptr!]
		handle
				
][

			handle: 0
			pix: image/acquire-buffer img :handle
			
			lower_left_corner: declare vector3!
			vertical: declare vector3!
			horizontal: declare vector3!
			origin: declare vector3!
			look-at: declare vector3!
			v-up: declare vector3!
			cam-u: declare vector3!
			cam-v: declare vector3!
			cam-w: declare vector3!

			origin/x: px 				origin/y: py 				origin/z: pz
			look-at/x: tx				look-at/y: ty 				look-at/z: tz
			v-up/x: 0.0 				v-up/y: 1.0 				v-up/z: 0.0

			vec3-sub cam-w origin look-at
			vec3-unitvector cam-w
			vec3-cross cam-u v-up cam-w
			vec3-unitvector cam-u
			vec3-cross cam-v cam-w cam-u
			
			
			vec3-Mfloat lower_left_corner cam-u half-width
			vec3-Mfloat vertical cam-v half-height
			vec3-sub lower_left_corner origin lower_left_corner
			vec3-sub lower_left_corner lower_left_corner vertical
			vec3-sub lower_left_corner lower_left_corner cam-w
	
			vec3-Mfloat horizontal cam-u (2.0 * half-width)
			vec3-Mfloat vertical cam-v (2.0 * half-height)

			i: 0
			j: ny - 1
			s: 0
			
			u: 0.0
			v: 0.0

			Max-Reflection-Depth: Depth
			
			col: declare vector3! 
			col-temp: declare vector3!

			
			ir: 0 ig: 0 ib: 0
			fnx: as float! nx
			fny: as float! ny
			fns: as float! ns
			
			tempv: declare vector3!
	
			{Main Loop}
			while [j >= 0] [
				i: 0
				fj: as float! j 
				while [i < nx] [
					col/x: 0.0 		col/y: 0.0 		col/z: 0.0
					fi: as float! i  
					
					while [s < ns][
						col-temp/x: 0.0 col-temp/y: 0.0 col-temp/z: 0.0
						u: (fi + get-rand) / fnx
					 	v: (fj + get-rand) / fny
			
						get-ray u v horizontal vertical lower_left_corner origin tempv
						color col-temp origin tempv 0
						vec3-add col col col-temp
			
						s: s + 1
					]
					vec3-Dfloat col col fns
					ir: as integer! (255.99 * col/x)
					ig: as integer! (255.99 * col/y)
					ib: as integer! (255.99 * col/z)
					pix/value: FF000000h + (ir << 16) + (ig << 8) + ib
					;print [ir " " ig " " ib lf]
					s: 0
					i: i + 1
					pix: pix + 1
				]
				j: j - 1
			]  
			image/release-buffer img handle yes


];-- end of render routine 

convert: routine[
    ob 		[block!]
    ob-len 	[integer!]
    /local 
    	s 
    	value 
    	tail 
    	fl 
    	head 
    	sphere 
    	Pvec 
    	Mvec
    	mat 
][
		Scene-Length: ob-len / 9
		s: GET_BUFFER (ob)
		
		head:  s/offset
		value: head
		tail:  s/tail

  {  while [value < tail][
        fl: as red-float! value
        probe fl/value
        value: value + 1
    ]
}

   	Pvector-list: as vector3! allocate ( (ob-len / 9) * 2) * size? vector3!
   	Pvec: Pvector-list

   	Mvector-list: as vector3! allocate ( (ob-len / 9) * 2) * size? vector3!
   	Mvec: Mvector-list

   	material-list: as material! allocate (ob-len / 9) * size? material!
   	mat: material-list

   	hit-list: as sphere! allocate (ob-len / 9) * size? sphere!
    sphere: hit-list 
    

    while [value < tail][
    	fl: as red-float! value
    	sphere/radius: fl/value

		fl: as red-float! (value + 1)
		Pvec/x: as float! fl/value

		fl: as red-float! (value + 2)
		Pvec/y: as float! fl/value

		fl: as red-float! (value + 3)
		Pvec/z: as float! fl/value

		fl: as red-float! (value + 4)
		mat/type: as integer! fl/value
		
		fl: as red-float! (value + 5)
		Mvec/x: as float! fl/value

		fl: as red-float! (value + 6)
		Mvec/y: as float! fl/value

		fl: as red-float! (value + 7)
		Mvec/z: as float! fl/value

		fl: as red-float! (value + 8)
		Mat/param2: as float! fl/value

		sphere/center: Pvec
		mat/param1: Mvec
		sphere/material: mat

		value: value + 9
		sphere: sphere + 1
		Pvec: Pvec + 1
		Mvec: Mvec + 1
		mat: mat + 1
	]

]

parse-scene: function[
	scene 	[string!]
][
	translated: []
	clear translated

	radius: ['radius set ver number! ]
	position: ['position set v1 number! set v2 number! set v3 number! ]
	metal: ['metal set m1 number! set m2 number! set m3 number! set m4 number! (t: 2.0)]
	lambert: ['lambert set m1 number! set m2 number! set m3 number! set m4 number! (t: 1.0)]

	rule: [
    set name word! 'sphere
    any [radius | position ]
    [lambert | metal] 
    to end ( append translated  reduce [ ver v1 v2 v3 t m1 m2 m3 m4] )
	]

	scene2B: split scene #"^/"

	sceneB:[]
	clear sceneB
	foreach i scene2b [append/only sceneB load i]

	foreach i sceneB [parse i rule]
	convert translated length? translated

]

Setup-Camera: function[
	img 	[image!] 
	Samples [string!] 
	Depth 	[string!]
	FOV 	[string!]
	px 		[string!] 
	py 		[string!] 
	pz 		[string!] 
	tx 		[string!] 
	ty 		[string!]
	tz 		[string!]
	][
		f_px: to float! px
		f_py: to float! py
		f_pz: to float! pz
		f_tx: to float! tx
		f_ty: to float! ty
		f_tz: to float! tz
		i_samples: to integer! Samples
		i_depth: to integer! Depth
		i_fov: to integer! FOV

		img/rgb: red
		half-height: 0.0
		half-width: 0.0
		x-res: 500
		y-res: 250
		aspect: (to float! x-res) / (to float! y-res)
		theta: to float! i_fov * pi / 180.0
		half-height: tan theta / 2.0
		half-width: aspect * half-height
		render half-height half-width x-res y-res i_samples i_depth f_px f_py f_pz f_tx f_ty f_tz img
]

save-as-png: function[][
	filename: request-file/save/filter["*.png"]
	save filename display/image /as[png]
	
]

posx: 		"0.0"
posy: 		"0.0"
posz: 		"0.0"
tarx: 		"0.0"
tary: 		"0.0"
tarz: 		"-1.0"
samples: 	"10"
depth: 		"40"
fov: 		"90"
scene-block: "redsphere sphere radius 0.5 position 0.0 0.0 -1.0 lambert 1.0 0.2 0.2 0.0"

font-Consolas: make font! [
	name: "Consolas"
	size: 10
	color: black
	style: []
	anti-alias?: yes
]

font-Consolas-light: make font! [
	name: "Consolas"
	size: 10
	color: 200.200.200
	style: []
	anti-alias?: yes
]

font-Consolas-gray: make font! [
	name: "Consolas"
	size: 10
	color: 180.180.180
	style: []
	anti-alias?: yes
]

canvas: make face! [
	type: 'base offset: 0x0 size: 650x610 color: pewter
	draw: [

		pen 95.95.95			;--Big box
		fill-pen 105.105.105
		box 0x0 114x199 10

		pen 60.60.60 			;--Camera Position Shadow
		fill-pen 60.60.60
		box 3x3 113x27 8
		pen 100.100.100 		;--Camera Position Box
		fill-pen linear 0x100 75 170 90 white gray black
		box 2x2 112x26 8

		pen 60.60.60 			;--X box shadow
		fill-pen 60.60.60
		box 11x29 106x49 4
		pen 100.100.100 		;--x box 
		fill-pen 120.120.120
		box 10x28 105x48 4

		pen 60.60.60 			;--Y box shadow
		fill-pen 60.60.60
		box 11x51 106x71 4
		pen 100.100.100
		fill-pen 120.120.120
		box 10x50 105x70 4

		pen 60.60.60 			;--Z box shadow
		fill-pen 60.60.60
		box 11x73 106x93 4
		pen 100.100.100
		fill-pen 120.120.120
		box 10x72 105x92 4

		pen 60.60.60 			;--Camera Target Shadow
		fill-pen 60.60.60
		box 3x99 113x123 8
		pen 100.100.100 		;--Camera Target Box
		fill-pen linear 0x100 75 170 90 white gray black
		box 2x98 112x122 8


		fill-pen off
		pen 60.60.60 			;--X box shadow
		fill-pen 60.60.60
		box 11x125 106x145 4
		pen 100.100.100
		fill-pen 120.120.120
		box 10x124 105x144 4	

		pen 60.60.60 			;--Y box shadow
		fill-pen 60.60.60
		box 11x147 106x167 4
		pen 100.100.100
		fill-pen 120.120.120
		box 10x146 105x166 4

		pen 60.60.60 			;--Z box shadow
		fill-pen 60.60.60
		box 11x169 106x189 4
		pen 100.100.100
		fill-pen 120.120.120
		box 10x168 105x188 4




		pen 95.95.95			;--Big box Settings
		fill-pen 105.105.105
		box 0x210 114x310 10

		pen 60.60.60 			;--Settings Shadow
		fill-pen 60.60.60
		box 3x213 113x237 8
		pen 100.100.100 		;--Settings Box
		fill-pen linear 0x100 200 270 90 white gray black
		box 2x212 112x236 8

		pen 60.60.60 			;--Samples box shadow
		fill-pen 60.60.60
		box 6x239 110x259 4
		pen 100.100.100
		fill-pen 120.120.120
		box 5x238 109x258 4

		pen 60.60.60 		
		fill-pen 60.60.60
		box 6x261 110x281 4
		pen 100.100.100
		fill-pen 120.120.120
		box 5x260 109x280 4

		pen 60.60.60 		
		fill-pen 60.60.60
		box 6x283 110x303 4
		pen 100.100.100
		fill-pen 120.120.120
		box 5x282 109x302 4
		

		fill-pen 200.200.200
		box 134x270 642x378 4






		fill-pen off
		pen black
		font font-Consolas-gray
		text 6x7 "Camera Position"
		text 13x103 "Camera Target"
		text 31x217 "Settings"
		font font-Consolas
		text 5x6 "Camera Position"
		text 12x102 "Camera Target"
		text 30x216 "Settings"
		text 31x31 "X:"
		text 31x53 "Y:"
		text 31x75 "Z:"

		text 31x127 "X:"
		text 31x149 "Y:"
		text 31x171 "Z:"

		text 11x241 "Samples:"
		text 11x263 "Depth:"
		text 11x285 "FOV:"

		font font-Consolas-light
		text 30x30 "X:"
		text 30x52 "Y:"
		text 30x74 "Z:"

		text 30x126 "X:"
		text 30x148 "Y:"
		text 30x170 "Z:"

		text 10x240 "Samples:"
		text 10x262 "Depth:"
		text 10x284 "FOV:"
	]
]


win: make face! [
	type: 'window text: "Ray Tracer" size: 676x450 color: pewter
	menu: [
		"File" [
			"Save Image..."		save-as
			---
			"Exit"				exit
		]
	]
	actors: object [
		on-menu: func [face [object!] event [event!]][
			switch event/picked [
				save-as [
					save-as-png
				]
				exit [
					unview/all
				]
			]
		]
	]
]
		

win/pane: reduce [

	make face! [										;-- clip view for canvas
		type: 'panel offset: 12x28 size: 650x610
		pane: reduce [canvas]
	]

	Display: make face! [										;--image area
		type: 'base offset: 150x28 size: 500x250
		image: make image! 500x250
	]

	

	Render-Button: make face! [
		type: 'button text: "Render" offset: 12x350 size: 115x40 font: font-Consolas color: 50.50.50
		para: make para! [align: 'center]
		actors: object [
			on-click: func [face [object!] event [event!]][
				parse-scene scene-block
				Setup-Camera display/image samples depth fov posx posy posz tarx tary tarz
			]
		]
	]

	make face! [
		type: 'area text: "redsphere sphere radius 0.5 position 0.0 0.0 -1.0 lambert 1.0 0.2 0.2 0.0" offset: 150x302 size: 500x100 color: 200.200.200
		font: font-Consolas
		flags: [no-border]
		actors: object [
			on-change: func [face [object!] event [event!]][
				scene-block: face/text
			]
		]
	]

	make face! [
		type: 'field text: "0.0" offset: 60x58 size: 50x15 
		color: 120.120.120
		font: font-Consolas
		para: make para! [align: 'left]
		flags: [no-border]
		actors: object [
			on-change: func [face [object!] event [event!]][
				posx: face/text
			]
		]
	]

	make face! [
		type: 'field text: "0.0" offset: 60x80 size: 50x15 
		color: 120.120.120
		font: font-Consolas
		para: make para! [align: 'left]
		flags: [no-border]
		actors: object [
			on-change: func [face [object!] event [event!]][
				posy: face/text
			]
		]
	]

	make face! [
		type: 'field text: "0.0" offset: 60x102 size: 50x15 
		color: 120.120.120
		font: font-Consolas
		para: make para! [align: 'left]
		flags: [no-border]
		actors: object [
			on-change: func [face [object!] event [event!]][
				posz: face/text
			]
		]
	]

	make face! [
		type: 'field text: "0.0" offset: 60x154 size: 50x15 
		color: 120.120.120
		font: font-Consolas
		para: make para! [align: 'left]
		flags: [no-border]
		actors: object [
			on-change: func [face [object!] event [event!]][
				tarx: face/text
			]
		]
	]

	make face! [
		type: 'field text: "0.0" offset: 60x176 size: 50x15 
		color: 120.120.120
		font: font-Consolas
		para: make para! [align: 'left]
		flags: [no-border]
		actors: object [
			on-change: func [face [object!] event [event!]][
				tary: face/text
			]
		]
	]

	make face! [
		type: 'field text: "-1.0" offset: 60x198 size: 50x15 
		color: 120.120.120
		font: font-Consolas
		para: make para! [align: 'left]
		flags: [no-border]
		actors: object [
			on-change: func [face [object!] event [event!]][
				tarz: face/text
			]
		]
	]

	make face! [
		type: 'field text: "10" offset: 82x268 size: 35x15 
		color: 120.120.120
		font: font-Consolas
		para: make para! [align: 'left]
		flags: [no-border]
		actors: object [
			on-change: func [face [object!] event [event!]][
				samples: face/text
			]
		]
	]

	make face! [
		type: 'field text: "40" offset: 82x290 size: 35x15 
		color: 120.120.120
		font: font-Consolas
		para: make para! [align: 'left]
		flags: [no-border]
		actors: object [
			on-change: func [face [object!] event [event!]][
				depth: face/text
			]
		]
	]

	make face! [
		type: 'field text: "90" offset: 82x312 size: 35x15 
		color: 120.120.120
		font: font-Consolas
		para: make para! [align: 'left]
		flags: [no-border]
		actors: object [
			on-change: func [face [object!] event [event!]][
				fov: face/text
			]
		]
	]


]

;view/flags win [resize]
view win

