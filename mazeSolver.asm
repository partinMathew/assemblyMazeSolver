.data

	#filenames for all mazes
	fin: 	.asciiz "maze01.txt"
		.asciiz "maze02.txt"
		.asciiz "maze03.txt"
		.asciiz "maze04.txt"
		.asciiz "maze05.txt"
		.asciiz "maze06.txt"
		.asciiz "maze07.txt"
		.asciiz "maze08.txt"
		.asciiz "maze09.txt"
		.asciiz "maze10.txt"
		.asciiz "maze11.txt"
		.asciiz "maze12.txt"
		.asciiz "maze13.txt"
		.asciiz "maze14.txt"
		.asciiz "maze15.txt"
		.asciiz "maze16.txt"
		.asciiz "maze17.txt"
		.asciiz "maze18.txt"
		.asciiz "maze19.txt"
		.asciiz "maze20.txt"
		.asciiz "maze21.txt"
		.asciiz "maze22.txt"
		.asciiz "maze23.txt"
		.asciiz "maze24.txt"
		.asciiz "maze25.txt"
		.asciiz "maze26.txt"
		.asciiz "maze27.txt"
		.asciiz "maze28.txt"
		.asciiz "maze29.txt"
		.asciiz "maze30.txt"
		.asciiz "maze31.txt"
		.asciiz "maze32.txt"
		.asciiz "maze33.txt"
		.asciiz "maze34.txt"
		.asciiz "maze35.txt"
		.asciiz "maze36.txt"
		.asciiz "maze37.txt"
		.asciiz "maze38.txt"
		.asciiz "maze39.txt"
		.asciiz "maze40.txt"
		
	buffer: .space 3072			#holds the data read from file, contains the maze
	ColorTable:
		.word 0x000000			#black
		.word 0x0000ff			#blue
		.word 0x00ff00			#green
		.word 0xff0000			#red
		.word 0x00ffff			#cyan
		.word 0xff00ff			#purple
		.word 0xffff00			#burnt-orange
		.word 0xffffff			#white
		
	runAgainPrompt:	.asciiz "\nWould you like to solve another maze? (y/n)\n"
	invalidCharacterPrompt: .asciiz "\nInvalid choice, please try again.\n"
		


.text
initialize:
	#this block is used to seed the random number generator
	li $v0, 30
	syscall					#gets system time
	add $a1, $0, $a0			#uses system time as seed for random number generator
	li $a0, 0
	li $v0, 40
	syscall					#seeds the random number generator
main:
	li $a0, 0
	li $a1, 40				#number of available files
	li $v0, 42
	syscall					#gets a random number, stored in a0
	move $t8, $a0
	
	#this draws a whit box as the background
	add $a0, $0, $0
	add $a1, $0, $0
	addi $a2, $0, 7
	addi $a3, $0, 32
	jal drawBox
	
	#open a file for writing
	li $v0, 13
	
	#calculate which file to read from, open it
	mul $t8, $t8, 11
	la $a0, fin($t8)				
	li $a1, 0
	li $a2, 0
	syscall
	
	#read from file
	move $s6, $v0
	li $v0, 14
	move $a0, $s6
	la $a1, buffer	
	li $a2, 3072				
	syscall
	
	#close the file
	li $v0, 16
	move $a0, $s6
	syscall

	add $s0, $0, $0					#x coordinate
	add $s1, $0, $0					#y coordinate
	
	#these nested loops will draw the maze before beginning to solve it
	outerLoop:					#this loop is designed to loop through the y coordinates			
	beq $s1, 31, endDrawMaze			#when y is max, the maze is done
	add $a1, $0, $0					
	add $a1, $0, $s1				#set y coordinate to current y counter
	innerLoop:					#this loop is designed to loop through the x coordinates
	beq $s0, 31, endInnerLoop			#when x is max, move the next line
	add $a0, $0, $s0				#set x coordinate to current x counter
	jal calcMazeAddr				#calculate the address in the buffer based on the coordinates
	lb $t0, 0($v0)					#grab the value at that address
	
	add $a1, $0, $0
	add $a0, $0, $0
	add $a1, $0, $s1
	add $a0, $0, $s0

	#if it is a character representing a wall, draw a black box,
	#it it is a space, draw a white box
	#if it is an S, draw a teal box (start)
	#if it is an E, draw a purple box (end)
	beq $t0, '+', wall
	beq $t0, '-', wall
	beq $t0, '|', wall
	beq $t0, ' ', blank
	beq $t0, 'E', end				
	beq $t0, 'S', start

		#these blocks set up the appropriate color for drawDot, and call that function
		wall:
			addi $a2, $0, 0
			j draw
		blank:
			addi $a2, $0, 7
			j draw
		start:

			addi $a2, $0, 4
			add $s2, $0, $a0		#stores the location of start to use later
			add $s3, $0, $a1
			j draw
		end:
			add $a2, $0, 5
					
			j draw
		draw:
			jal drawDot			#draw the appropiraite colored box
	addi $s0, $s0, 1				#increment x counter
	j innerLoop
	endInnerLoop:
	add $s0, $0, $0					#resets the x coordinate
	addi $s1, $s1, 1				#increments y
	
	j outerLoop
	endDrawMaze:
	add $a0, $0, $s2				#set the x and y coordinates to that of the start position of the mze
	add $a1, $0, $s3
	jal checkBegin					#begin the recursive check function, will return when the maze is solved
	
	add $a0, $0, $s2				#grab the location of "start" as it was stored earlier
	add $a1, $0, $s3
	jal traceFinalPath				#this is the actual depth first algorithm.
	#prompts the user to check if they would like to solve another maze
	#and also checks for invalid inputs
	runAgain:
	la $a0, runAgainPrompt
	li $v0, 4
	syscall
	li $v0, 12
	syscall
	beq $v0, 'n', exit				#these 4 options are the only acceptable characters for user entry
	beq $v0, 'N', exit				#if anything else is entered, it will prompt the user, about their
	beq $v0, 'y', main				#mistake, and ask them whether or not they would like to continue
	beq $v0, 'Y', main				#again
	la $a0, invalidCharacterPrompt
	li $v0, 4
	syscall
	j runAgain
	
	
		
exit:
        li $v0, 10				#ends the program
        syscall
################################################################################
#calculates the address to draw a dot at
#a0 = x coord (0 - 30)
#a1 = y coord (0 - 30)
#returns $v0	
###################################################################################
calcAddr:
	#address = x coord * 4 + base + y coord * 32 * 4
	move $t0, $a0
	move $t1, $a1
	mul $t0, $t0, 4
	add $t0, $t0, 0x10040000
	mul $t1, $t1, 32
	mul $t1, $t1, 4
	add $v0, $t0, $t1
	jr $ra
		
	
#####################################################################
#calculates address of "node" in the maze
#a0 = x coord (0 - 30)
#a1 = y coord (0 - 30)
#returns t9
#####################################################################
calcMazeAddr:
	#address = x coord  + base + y coord * 33?  //base == address of buffer
	la $v0, buffer
	move $t0, $a0
	move $t1, $a1
	mul $t1, $t1, 33			#I honestly cannot explain why this has to be 33, but it works so I'm not questioning it
	add $v0, $v0, $t0
	add $v0, $v0, $t1
	add $t0, $0, $0
	add $t1, $0, $0
	jr $ra
	
##############################################################################
#looks up the color number in the table
#a2 = color number (0-7)
#returns $v1
###############################################################################
getColor:
	la $t0, ColorTable		#load base
	move $t2, $a2
	sll $t2, $t2, 2			#index x4 is offset
	
	add $t1, $t0, $t2		#address is base + offset, in a2
	lw  $v1, 0($t1)			#get actual color
	
	jr $ra
	
###################################################################
#draws a single node on the screeen
#a0 = x - coord
#a1 = y - coord
#a2 = color number
##################################################################
drawDot:
	addiu $sp, $sp, -8		#adjust stack pointer, 2 words
	sw $ra, 4($sp)			#store $ra
	sw $a2, 0($sp)			#store a2
	jal calcAddr			#v0 will have address for pixel
	lw $a2, 0($sp)			#restore $a2
	sw $v0, 0($sp)			#store $v0 (address in same spot
	jal getColor			#v1 will have color for number
	lw $v0, 0($sp)			#restore address to $v0
	sw $v1, 0($v0)			#actually make dot
	lw $ra, 4($sp)			#load original $ra back
	addiu $sp, $sp, 8		#restore sp
	jr $ra
	
#############################################################################
#draws a horizontal line
#a0 = x coord
#a1 = y coord
#a2 = color numb
#a3 = length
################################################################################
drawHorizLine:
	add $t0, $0, $0
	addiu $sp, $sp, -24

Horz:							#part of drawHorizLine
	sw $t0, 20($sp)					#store stuff
	sw $ra, 16($sp)
	sw $a3, 12($sp)
	sw $a2, 8($sp)
	sw $a1, 4($sp)
	sw $a0, 0($sp)


	jal drawDot					#draw a dot
	lw $a3, 12($sp)					#load stuff before I loop again
	lw $a2, 8($sp)
	lw $a1, 4($sp)
	lw $a0, 0($sp)
	lw $t0, 20($sp)
	lw $ra, 16($sp)
	addi $a0, $a0, 1				#increment x coordinate
	addiu $t0, $t0, 1				#count how many pixels have been drawn
	bne $a3, $t0, Horz				#branch when the correct number of pixels have been drawn
	addiu $sp, $sp, 24				#restore stack pointer
	jr $ra


#############################################################################	
#Draws a filled box of a specified color at a specified location
#a0 = x coordinate
#a1 = y coordinate
#a2 = color number
#a3 = size of box
##############################################################################
drawBox:
	addiu $sp, $sp, -20
	add $t0, $0, $a3

BoxLoop:					#part of box drawBox
	sw $ra, 16($sp)				#save stuff
	sw $t0, 12($sp)
	sw $a0, 8($sp)
	sw $a1, 4($sp)
	sw $a2, 0($sp)

	jal drawHorizLine			#draw a horizontal line
	lw $ra, 16($sp)				#restore stuff
	lw $a0, 8($sp)
	lw $a1, 4($sp)
	lw $a2, 0($sp)
	lw $t0, 12($sp)
	addi $a1, $a1, 1			#increment the y cooordinate
	addi $t0, $t0, -1			#decrement the counter
	bne $t0, $0, BoxLoop			#when the box is the right size, stop drawing
	addiu $sp, $sp, 20
	jr $ra


##############################################################################
#checks the nodes adjacent to the current node in the following order:
#right, bottom, left, top
#it will also not check if the node is on one of the edges
#it will check for several things:
#a wall, the end, a node that is currently being checked, and a node that has
#finished being checked
#upon finding a blank space, the algorithm will immediately move there
#and run the check again



#This is a logically complex function, therefore it is long, but I cannot
#break it up much
##################################
#inputs
#a0 = x coordinate (0-30)
#a1 = y coordinate (0-30)
##############################################################################
checkBegin:
	addiu $sp, $sp, -12				#set up stack
	sw $ra, 0($sp)
check:
	sw $a0, 4($sp)					#store coordinates, I did this because I am not to sure how to work with the stack recursively
	sw $a1, 8($sp)
	addi $a0, $0, 0		#time to pause (this is done so that you can actually see what is going on with the algorithm)
	jal pause					#pause
	lw $a0, 4($sp)				#restore coordinates
	lw $a1, 8($sp)
	beq $a0, 30, bottom				#if you are on the right edge, do not check the node to the right (duh)
	addi $a0, $a0, 1				#add one to the x coordinate
	jal calcMazeAddr				#calculate the maze address
	lw $ra, 0($sp)					
	lb $t0, 0($v0)					#get the value at that address
	#perform the checks
	#if it is a wall, you should move on
	#if it is marked as C (a yellow node), you should move on
	#if it is marked as F (a red node), you should move on
	#if it is marked as E (the end), you should end the algorithm
	beq $t0, '+', skipRight
	beq $t0, '-', skipRight
	beq $t0, '|', skipRight
	beq $t0, 'C', skipRight
	beq $t0, 'F', skipRight
	beq $t0, 'S', skipRight
	beq $t0, 'E', noReturn
	#if all of those checks failed, then you know it was a blank space
	#therefore you should set the value at the current address to C, draw a yellow dot, and call the function again
	add $t5, $0, 'C'
	sb $t5, ($v0)
	addi $a2, $0, 6
	jal drawDot
	j check	
	skipRight:
	addi $a0, $a0, -1			#if you hit a wall in the previous check, you need to undo the previous coordinate change before you move on
	bottom:
	#the next portions are the same, except in different directions
	#they stay the same until you hit a dead end, which would be when you do not find a blank space when checking the top space
	beq $a1, 30, left
	addi $a1, $a1, 1
	jal calcMazeAddr
	lb $t0, 0($v0)
	beq $t0, '+', skipBottom
	beq $t0, '-', skipBottom
	beq $t0, '|', skipBottom
	beq $t0, 'C', skipBottom
	beq $t0, 'F', skipBottom
	beq $t0, 'S', skipBottom
	beq $t0, 'E', noReturn
	add $t5, $0, 'C'
	sb $t5, ($v0)
	addi $a2, $0, 6
	jal drawDot
	j check
	skipBottom:
	addi $a1, $a1, -1
	left:
	beq $a0, 0, top
	addi $a0, $a0, -1
	jal calcMazeAddr
	lb $t0, 0($v0)
	beq $t0, '+', skipLeft
	beq $t0, '-', skipLeft
	beq $t0, '|', skipLeft
	beq $t0, 'C', skipLeft
	beq $t0, 'F', skipLeft
	beq $t0, 'S', skipLeft
	beq $t0, 'E', noReturn
	add $t5, $0, 'C'
	sb $t5, ($v0)
	addi $a2, $0, 6
	jal drawDot

	j check
	skipLeft:
	addi $a0, $a0, 1
	top:
	beq $a1, 0, goBack
	addi $a1, $a1, -1
	jal calcMazeAddr
	lb $t0, 0($v0)
	beq $t0, '+', skipTop
	beq $t0, '-', skipTop
	beq $t0, '|', skipTop
	beq $t0, 'C', skipTop
	beq $t0, 'F', skipTop
	beq $t0, 'S', skipTop
	beq $t0, 'E', noReturn
	add $t5, $0, 'C'
	sb $t5, ($v0)
	addi $a2, $0, 6
	jal drawDot

	j check
	skipTop:
	addi $a1, $a1, 1
	goBack:
	#at this point the backtracing portion of the algorithm begins
	#this should kick in during a dead end
	#this is red node portion of the algorithm


	lw $a0, 4($sp)
	lw $a1, 8($sp)
	#at this point, you know that you are at a dead end
	#therefore, you should mark the current node as finished, and check the surrounding nodes
	jal calcMazeAddr
	add $t5, $0, 'F'
	sb $t5, ($v0)
	addi $a2, $0, 3
	jal drawDot
	#this section is searching the adjacent blocks for a 'C' character which allows for backtracking
	#######################################################
	#check top
	lw $a0, 4($sp)			#restore the x and y coordinates
	lw $a1, 8($sp)
	addi $a1, $a1, -1		#y - 1
	jal calcMazeAddr		#calculate the maze address
	lb $t0, 0($v0)			#grab the value at that adress
	beq $t0, 'C', return		#if that character is a C, then you should move there, which is handled at the label return
	#check left			#the value was not a C, so you should check the value to the left
	lw $a0, 4($sp)			#restore the original x and y coordinates
	lw $a1, 8($sp)
	addi $a0, $a0, -1		#x - 1
	jal calcMazeAddr		#from here its the same idea as above
	lb $t0, 0($v0)
	beq $t0, 'C', return
	#check bottom
	lw $a0, 4($sp)
	lw $a1, 8($sp)
	addi $a1, $a1, 1
	jal calcMazeAddr
	lb $t0, 0($v0)
	beq $t0, 'C', return
	#check right
	lw $a0, 4($sp)
	lw $a1, 8($sp)
	addi $a0, $a0, 1
	jal calcMazeAddr
	lb $t0, 0($v0)
	beq $t0, 'C', return
	j noReturn			#if this jump is run, something has gone wrong, but it according to the algorithm, it should be here
					#it would mean that you hit a dead end with no C adjacent to you. You would be in a box with no exit
	
	
	return:


	jal check			#the reason I have this as a jump instead of just sending it back to the top from the branch
					#is because of the "and link" portion of the the jump
	
	noReturn:
		
	lw $ra, 0($sp)
	addiu $sp, $sp, 12
	jr $ra
##########################################################	
#pauses for set amount of time
#a0 is number of miliseconds to pause
###########################################################
pause:
		move $t0, $a0			#save timeout argument
		li $v0, 30			#get time
		syscall
		move $t1, $a0			#save start time
	ploop: 	syscall				#get current time
		subu $t2, $a0, $t1		#t2 = current time - init time
		bltu $t2, $t0, ploop		#loop if elapsed < timeout
	 	
	jr $ra	
##############################################################
#this function will trace the direct path of the maze in green
#once the algorithm has been completed
#inputs
#a0 - x coordinate of start
#a1 - y coordinate of start
###############################################################
traceFinalPath:
	addiu $sp, $sp, -12
	sw $ra, 0($sp)
tracePath:
	#this function acts very similarly to the backtracing poriton of the algorithm
	jal calcMazeAddr			#calculate the maze address
	add $t5, $0, 'P'			#I must mark the node as the path, otherwise an infinite loop occurs
	sb $t5, ($v0)				#set the value to "P"
	sw $a0, 4($sp)
	sw $a1, 8($sp)				#store coordinates
	addi $a0, $0, 0			#time to pause (this is done so that you can actually see what is going on with the algorithm)
	jal pause				#pause
	

	lw $a0, 4($sp)				#reset coordinates to correct place
	lw $a1, 8($sp)
	addi $a0, $a0, 1			#x - 1
	jal calcMazeAddr			#calculate the address
	lb $t0, 0($v0)				#grab the value at that adress
	beq $t0, 'C', path			#if that character is a "C" then, recall the function there, which is handled at the path label
	
	lw $a0, 4($sp)				#restore the actual coordinates
	lw $a1, 8($sp)
	addi $a1, $a1, 1			#y + 1
	jal calcMazeAddr			#again, from here it remains very similar from this point on 
	lb $t0, 0($v0)
	beq $t0, 'C', path

	lw $a0, 4($sp)				#reset coordinates to correct place
	lw $a1, 8($sp)
	addi $a0, $a0, -1
	jal calcMazeAddr
	lb $t0, 0($v0)
	beq $t0, 'C', path

	lw $a0, 4($sp)
	lw $a1, 8($sp)
	addi $a1, $a1, -1
	jal calcMazeAddr
	lb $t0, 0($v0)
	beq $t0, 'C', path
	j noPath
	
	path:
	sw $a0, 4($sp)				#to be safe, store the current coordinates
	sw $a1, 8($sp)
	add $a2, $0, 2
	jal drawDot				#draw the green dot
	lw $a0, 4($sp)				#restore the coordinates
	lw $a1, 8($sp)
	jal tracePath				#call the funciton again on the current coordinates
	
	noPath:
	lw $ra, 0($sp)
	addiu $sp, $sp, 12
	jr $ra
