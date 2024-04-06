.data
# DONNOTMODIFYTHISLINE
frameBuffer: .space 0x80000 # 512 wide X 256 high pixels
w: .word —   # Width of the rectangle
h: .word —    # Height of the rectangle
d: .word —   # Depth of the rectangle
cr: .word — # Red component of the color (0-255)
cg: .word — # Green component of the color (0-255)
cb: .word — # Blue component of the color (0-255)
# DONOTMODIFYTHISLINE
# Your other variables go BELOW here only


.text
main:
#Loading base address of the frame buffer
la $t0, frameBuffer		#address of the frame buffer ->t0
li $t3, 0xFFFF00		#yello = t3
li $t1, 0 			#we have t1 serve as pixel counter 


fill_Background:
sw $t3, 0($t0)			#add a yellow pixel
addi $t0, $t0, 4 		#move $t0 to next pixel 
addi $t1, $t1, 1		#add one to t1
bne $t1, 131072, fill_Background#goto fill_backgound if pixelcounter does not equal 131072 


# setColor section for overflow for both side and top colors
setColor:
    lw $t2, cr              # Loading cr into $t2
    lw $t3, cg              # Loading cg into $t3
    lw $t4, cb              # Loading cb into $t4

    # Calculate the color of the main face
    li $t1, 0               # Clearing $t1
    or $t1, $t1, $t2        # Insert red component
    sll $t1, $t1, 8         # Shift left 8 bits
    or $t1, $t1, $t3        # Insert green component
    sll $t1, $t1, 8         # Shift left 8 bits
    or $t1, $t1, $t4        # Insert blue component
    addi $t6, $t1, 0        # Store main face color in $t6
    
    # Calculate top face color in which we multiply each component by 2
    # We  are checking for overflow and cap at 255 if it is eneded
    sll $t5, $t2, 1         # Multiply red component by 2 
    sll $t7, $t3, 1         # Multiply green component by 2
    sll $t8, $t4, 1         # Multiply blue component by 2
    
    li $t9, 0xFF            # Max value for the color component
    bgt $t5, $t9, capRedTop # Cap redTOP if overflow
    bgt $t7, $t9, capGreenTop # Cap greenTIOP if overflow
    bgt $t8, $t9, capBlueTop # Cap blueTOP if overflow
    
    # Combine colors for  the top face which has no overflow
    combineTopFaceColors:
        li $t1, 0               # Clear $t1 for  thetop face color
        or $t1, $t1, $t5        # Insert capped or original red component
        sll $t1, $t1, 8         # Shift left 8 bits
        or $t1, $t1, $t7        # Insert cappedororiginal green component
        sll $t1, $t1, 8         # Shift left 8 bits
        or $t1, $t1, $t8        # Insert capped or original blue component
        sll $t7, $t1, 1         # Store top face color in $t7 which is ready for use
        j continueDrawing       # Jump to drawing logic

    capRedTop:
        li $t5, 0xFF            # Cap max ofred component
        j combineTopFaceColors  # Jump back to combine colors

    capGreenTop:
        li $t7, 0xFF            # Cap max of green component
        j combineTopFaceColors  # Jump back to combine colors

    capBlueTop:
        li $t8, 0xFF            # Cap max ofblue component
        j combineTopFaceColors  # Jump back to combine coors

continueDrawing:
#to get to the starting point of drawing rectangle skip (256 - h - d)/2 rows and (multiply by 2048 and add to frameBuffer)
#then add 4 * ((512-w-d)/2)+d)
la $t0, frameBuffer		#load initial address
li $t1, 0			#t1 = 0; will serve as counter 
li $t2, 256 			#t2 = 256
lw $t3, h			#t3 = h
sub $t2, $t2, $t3		#t2 = 256 - h
lw $t3, d			#t3 = h
sub $t2, $t2, $t3		#t2 = 256 - h - d
srl $t2, $t2, 1 		#t2 = (256-h-d)/2
skipRows:
addi $t0, $t0,2048		#skip 1 row 
addi $t1, $t1, 1		#t1++
bne $t1, $t2, skipRows		#goto skipRows if t1<t2 
				#now we have to do (4 * ((512-w-d)/2)+d))
li $t1, 512			#512= t1
lw $t2, w			#t2 = w
sub $t1, $t1, $t2 		#t1 = 512 - w
lw $t2, d			#t2 = d
sub $t1, $t1, $t2		#t1 = 512-w-d
srl $t1, $t1, 1			#t1 = (512-w-d)/2		
add $t1, $t1, $t2		#t1 = ((512-w-d)/2) + d
sll $t1, $t1, 2 		#t1 = 4*((512-w-d)/2) + d
add $t0, $t0, $t1		#t0 = starting point
li $t1, 0 			#t1 = 0; w counter
lw $t2, w			#t2 = w
lw $t3, d 			#t3 = d
li $t4, 0			#t4 =0; d counter 

drawLine:
sw $t7, 0($t0)			#add colored pixel
addi $t1, $t1, 1		#t1++
addi $t0, $t0, 4		#move t0 to next pixel
bne $t1, $t2, drawLine		#goto drawline if counter < width
				#once line is drawn, need to move to next line and subtract width*4 from t0 and add 2044 to 0
sub $t0, $t0, $t2		#t0 = t0-w
sub $t0, $t0, $t2		#t0 = t0-w
sub $t0, $t0, $t2		#t0 = t0-w
sub $t0, $t0, $t2		#t0 = t0-w
addi $t0, $t0, 2044		# t0+2044  = $to

li $t1, 0 			#reset the width counter 
addi $t4, $t4, 1 		#increment++ depth counter 
bne $t4, $t3, drawLine		#goto drawline if depth counter != depth 

				#t0 points to next line and starts main fac e
li $t1, 0			#width counter = t1
lw $t2, w			#w = t2
li $t3, 0			#height counter=t3
lw $t4, h			#h=t4 
draw_Main:
sw $t6, 0($t0)			#add colored pixel
addi $t1, $t1, 1		#increment width counter 
addi $t0, $t0, 4 		#goto next pixel
bne $t1, $t2, draw_Main		#if widthcounter < width goto draw_Main
addi $t3, $t3, 1		#increment height counter
				#need to go to beginning of next line now 
addi $t0, $t0, 2048		#add one line 
sub $t0, $t0, $t2		#t0 = t0-w
sub $t0, $t0, $t2		#t0 = t0-w
sub $t0, $t0, $t2		#t0 = t0-w
sub $t0, $t0, $t2		#t0 = t0-w
li $t1, 0 			#reset width counter 
				#at beginnging of next line 
bne $t3, $t4, draw_Main		#goto draw_main if t3 < t4


add $t0, $t0, $t2	
add $t0, $t0, $t2	
add $t0, $t0, $t2	
add $t0, $t0, $t2	
addi $t0, $t0, -2048

lw $t2, h 			#t2 = h 
lw $t3, d			#t3 = d 
li $t4, 0 			#t4 = height counter 
li $t5, 0 			#t5 = depth counter 
la $t6, 0($t0)			#t6 = starting point 
sll $t7, $t7, 1			#make side color 4x color of main

draw_Side_edge:
sw $t7, 0($t0) 			#add coloreds pixel
addi $t0, $t0, 4		#move 1 pixel to the right
addi $t0, $t0, -2048		#move 1 pixel up 
addi $t5, $t5, 1 		#increent depth counter 
bne $t5, $t3, draw_Side_edge	#goto draw_side_edge if depthCounter < depth
				#reset starting point,t0,depth counter, 
				#increment height counter and check if heightcounter < height 
addi $t6, $t6, -2048		#reset starting point 
la $t0, 0($t6)			#load address back to $t0
li $t5, 0 			#reset depth counter 
addi $t4, $t4, 1		#add 1 to height counter 
bne $t4, $t2, draw_Side_edge	#goto draw_side_edge if heightCounter < height


li $v0,10 # exit 
syscall 
