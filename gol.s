.section ".word"
	 /* Game state memory locations */ 
	.equ CURR_STATE, 0x90001000 /* Current state of the game */ 
	.equ GSA_ID, 0x90001004 /* ID of the GSA holding the current state */ 
	.equ PAUSE, 0x90001008 /* Is the game paused or running */ 
	.equ SPEED, 0x9000100C /* Current speed of the game */ 
	.equ CURR_STEP, 0x90001010 /* Current step of the game */ 
	.equ SEED, 0x90001014 /* Which seed was used to start the game */ 
	.equ GSA0, 0x90001018 /* Game State Array 0 starting address */ 
	.equ GSA1, 0x90001058 /* Game State Array 1 starting address */ 
	.equ CUSTOM_VAR_START, 0x90001200 /* Start of free range of addresses for custom vars */ 
	.equ CUSTOM_VAR_END, 0x90001300 /* End of free range of addresses for custom vars */ 
	.equ RANDOM, 0x40000000 /* Random number generator address */ 
	.equ LEDS, 0x50000000 /* LEDs address */ 
	.equ SEVEN_SEGS, 0x60000000 /* 7 - segment display addresses */ 
	.equ BUTTONS, 0x70000004 /* Buttons address */ 
	
	 /* States */ 
	.equ INIT, 0
	.equ RAND, 1
	.equ RUN, 2
	
	 /* Colors (0bBGR) */ 
	.equ RED, 0x100
	.equ BLUE, 0x400
	
	 /* Buttons */ 
	.equ JT, 0x10
	.equ JB, 0x8
	.equ JL, 0x4
	.equ JR, 0x2
	.equ JC, 0x1
	.equ BUTTON_2, 0x80
	.equ BUTTON_1, 0x20
	.equ BUTTON_0, 0x40
	
	 /* LED selection */ 
	.equ ALL, 0xF
	
	 /* Constants */ 
	.equ N_SEEDS, 4 /* Number of available seeds */ 
	.equ N_GSA_LINES, 10 /* Number of GSA lines */ 
	.equ N_GSA_COLUMNS, 12 /* Number of GSA columns */ 
	.equ MAX_SPEED, 10 /* Maximum speed */ 
	.equ MIN_SPEED, 1 /* Minimum speed */ 
	.equ PAUSED, 0x00 /* Game paused value */ 
	.equ RUNNING, 0x01 /* Game running value */ 
	
.section ".text.init"
	.globl main
	
main: 
  li sp, CUSTOM_VAR_START  /* Stack grows downward from start */
  main_outer_loop:
	  jal reset_game
      jal get_input
      mv s0, a0
      li s1, 0
  main_inner_loop:
      bnez s1, main_outer_loop
      mv a0, s0
      jal select_action
	  mv a0, s0
      jal update_state
	  li t0, SPEED
	  lw t1, 0(t0)
	  li t0, 2
	  blt t1, t0, main_mask
	  j resume_loop
	  main_mask:
	  	nop
	resume_loop:
      jal update_gsa
	  jal clear_leds
      jal mask
      jal draw_gsa
      jal wait
      jal decrement_step
      mv s1, a0 
	  nop
      jal get_input
      mv s0, a0
      j main_inner_loop
      ret
	ret

 /* BEGIN:auxiliary */ 
	/* Place all auxiliary procedures and additional constants
	that may be used by other procedures in this section */ 
 /* END:auxiliary */ 
	
 /* BEGIN:clear_leds */ 
clear_leds:
	li t0, LEDS
	li t1, 0x7FF
	sw t1, 0(t0)
	ret
	
 /* END:clear_leds */ 
	
 /* BEGIN:set_pixel */ 
set_pixel:
	li t0, LEDS
	li t1, 1
	slli t1, t1, 16
	li t2, RED
	or t1, t1, t2
	or t1, t1, a0
	slli a1, a1, 4
	or t1, t1, a1
	sw t1, 0(t0)
	ret
 /* END:set_pixel */ 
	
 /* BEGIN:wait */ 
wait:
	li t0, 2
slli t0, t0, 4
	li t1, SPEED
	lw t2, 0(t1)
wait_loop:
	sub t0, t0, t2
	bgt t0, x0, wait_loop
	ret
 /* END:wait */ 
	
 /* BEGIN:set_gsa */ 
set_gsa:
	addi sp, sp, -4
	sw ra, 0(sp)
	li t0, GSA_ID
	lw t1, 0(t0)
	beqz t1, set_gsa0
	li t2, GSA1
	j set_gsa_selected
set_gsa0:
	li t2, GSA0
set_gsa_selected:
	slli t3, a1, 2
	add t2, t2, t3
	sw a0, 0(t2)
	lw ra, 0(sp)
	addi sp, sp, 4
	ret
	
 /* END:set_gsa */ 
	
 /* BEGIN:get_gsa */ 
get_gsa:
	li t0, GSA_ID
	lw t1, 0(t0)
	beqz t1, get_gsa0
	li t2, GSA1
	j get_gsa_selected
get_gsa0:
	li t2, GSA0
get_gsa_selected:
	slli t3, a0, 2
	add t2, t2, t3
	lw a0, 0(t2)
	ret
 /* END:get_gsa */ 

/* BEGIN:draw_gsa */
draw_gsa:

	li t1, 0 #row counter
	li t2, 10 # max number of rows
draw_loop:
	beq t1, t2, draw_end
	mv a0, t1
	addi sp, sp, -12
	sw t1, 0(sp)
	sw t2, 4(sp)
	sw ra, 8(sp)
	jal get_gsa
	lw t1, 0(sp)
	lw t2, 4(sp)
	lw ra, 8(sp)
	addi sp, sp, 12
	mv t3, a0 #gsa element => t3
	li t4, 0 #col counter
	li t5, 12 # max number of cols
draw_col_loop:
	beq t4, t5, draw_col_end
	# Copy t3 to temporary register before shifting
	mv t0, t3
	srl t0, t0, t4  # Shift by column number instead of cumulative shifting
	andi t6, t0, 1  # get the specific bit for this column
	beqz t6, skip_col
	add a0, t4, x0
	add a1, t1, x0
	addi sp, sp, -32
	sw t0, 0(sp)
	sw t1, 4(sp)
	sw t2, 8(sp)
	sw t3, 12(sp)
	sw t4, 16(sp)
	sw t5, 20(sp)
	sw t6, 24(sp)
	sw ra, 28(sp)
	jal set_pixel
	lw t0, 0(sp)
	lw t1, 4(sp)
	lw t2, 8(sp)
	lw t3, 12(sp)
	lw t4, 16(sp)
	lw t5, 20(sp)
	lw t6, 24(sp)
	lw ra, 28(sp)
	addi sp, sp, 32
skip_col:
	addi t4, t4, 1
	j draw_col_loop  # Removed the destructive srli t3, t3, 1
draw_col_end:
	addi t1, t1, 1
	j draw_loop
draw_end:
	ret
/* END:draw_gsa */

/* BEGIN:random_gsa */
random_gsa:
    addi sp, sp, -20
    sw s0, 0(sp)
    sw s1, 4(sp)
    sw s2, 8(sp)
    sw s3, 12(sp)
    sw ra, 16(sp)

    li s0, 0                   # row counter
    li s1, 10                  # max rows
    li s2, RANDOM              # random number address (FIXED: single address!)

random_row_loop:
    beq s0, s1, random_loop_end
    li s3, 0                   # gsa element for this row
    
    li t1, 0                   # col counter
random_col_loop:
    li t2, 12
    beq t1, t2, random_col_end
    
    # Read random number - ALWAYS from the same RANDOM address!
    # Each read returns the NEXT random number in sequence
    lw t3, 0(s2)               # read from RANDOM (same address every time)
    
    # Get LSB (0 or 1)
    andi t4, t3, 1
    
    # Position this bit in the correct column
    sll t4, t4, t1             # shift to column position
    or s3, s3, t4              # combine into row
    
    addi t1, t1, 1
    j random_col_loop

random_col_end:
    # Store the row in GSA
    mv a0, s3
    mv a1, s0
    jal set_gsa
    
    addi s0, s0, 1
    j random_row_loop

random_loop_end:
    lw s0, 0(sp)
    lw s1, 4(sp)
    lw s2, 8(sp)
    lw s3, 12(sp)
    lw ra, 16(sp)
    addi sp, sp, 20
    ret
/* END:random_gsa */
	
 /* BEGIN:change_speed */ 
change_speed:
	li t1, SPEED
	lw t2, 0(t1)
	beqz a0, increment_speed
decrement_speed:
	li t3, 1
	beq t2, t3, change_speed_end
	addi t2, t2, - 1
	j change_speed_end
increment_speed:
	li t3, 10
	beq t2, t3, change_speed_end
	addi t2, t2, 1
change_speed_end:
	sw t2, 0(t1)
	ret
	
 /* END:change_speed */ 
	
 /* BEGIN:pause_game */ 
pause_game:
	li t1, PAUSE
	lw t2, 0(t1)
	xori t2, t2, 1
	sw t2, 0(t1)
	ret
 /* END:pause_game */ 
	
 /* BEGIN:change_steps */ 
change_steps:
	li t0, CURR_STEP
	lw t1, 0(t0)
	beqz a0, add_tens
	addi t1, t1, 0x1
add_tens:
	beqz a1, add_hundreds
	addi t1, t1, 0x10
add_hundreds:
	beqz a2, change_steps_end
	addi t1, t1, 0x100
change_steps_end:
	li t2, 0xFFF
	and t1, t1, t2
	sw t1, 0(t0)
	ret
	
 /* END:change_steps */ 
	
 /* BEGIN:set_seed */ 
set_seed:
	addi sp, sp, -4	
    sw   ra, 0(sp)
	la t0, SEEDS # base of seed table
	slli t1, a0, 2 # offset = seedID * 4
	add t0, t0, t1
	lw t2, 0(t0) # t2 = pointer to seedX
	li t3, 0
	li t4, 10
set_seed_loop:
	beq t3, t4, set_seed_end
	lw a0, 0(t2) # load row value
	mv a1, t3 # row index
	addi sp, sp, - 12
	sw t2, 0(sp)
	sw t3, 4(sp) #
	sw ra, 8(sp)
	jal set_gsa
	lw t2, 0(sp)
	lw t3, 4(sp)
	lw ra, 8(sp)
	addi sp, sp, 12
	addi t2, t2, 4
	addi t3, t3, 1
	j set_seed_loop
set_seed_end:
	lw   ra, 0(sp)
    addi sp, sp, 4
	ret
 /* END:set_seed */ 

/* BEGIN:increment_seed */
increment_seed:
    addi sp, sp, -4
    sw   ra, 0(sp)
    li   t0, SEED
    lw   t1, 0(t0)       # current seed
    # check if current state is already random state
    li   t2, N_SEEDS
    bge  t1, t2, already_random # if seed >= 4, we're already random
	# check if incrementing takes us to random state
	addi t3, t1, 1
	bge t3, t2, go_to_random

    # normal case: increment seed and set GSA
    addi t1, t1, 1
    sw   t1, 0(t0)
    mv   a0, t1
	addi sp, sp, -20
	sw t0, 0(sp)
	sw t1, 4(sp)
	sw t2, 8(sp)
	sw t3, 12(sp)
	sw ra, 16(sp)
    jal  set_seed
	lw t0, 0(sp)
	lw t1, 4(sp)
	lw t2, 8(sp)
	lw t3, 12(sp)
	lw ra, 16(sp)
	addi sp, sp, 20
    j    increment_done
go_to_random:
    # transition to random state (seed = 4)
    li   t1, 4
    sw   t1, 0(t0)
	addi sp, sp, -20
	sw t0, 0(sp)
	sw t1, 4(sp)
	sw t2, 8(sp)
	sw t3, 12(sp)
	sw ra, 16(sp)
    jal  random_gsa
	lw t0, 0(sp)
	lw t1, 4(sp)
	lw t2, 8(sp)
	lw t3, 12(sp)
	lw ra, 16(sp)
	addi sp, sp, 20
	j increment_done
already_random:
		addi sp, sp, -20
	sw t0, 0(sp)
	sw t1, 4(sp)
	sw t2, 8(sp)
	sw t3, 12(sp)
	sw ra, 16(sp)
    jal  random_gsa
	lw t0, 0(sp)
	lw t1, 4(sp)
	lw t2, 8(sp)
	lw t3, 12(sp)
	lw ra, 16(sp)
	addi sp, sp, 20
increment_done:
    lw   ra, 0(sp)
    addi sp, sp, 4
    ret
/* END:increment_seed */

 /* BEGIN:update_state */ 
update_state:
	li t0, CURR_STATE
	lw t1, 0(t0) #t1 = current state: 0 if init, 1 if rand, 2 if run
	li t3, SEED
	lw t4, 0(t3) #t4 = current seed: 0, 1, 2, 3, 4
	
	#Check JR
	li t5, JR
	and t5, t5, a0
	beqz t5, checkJC # if JR not pressed - > check JC
	
	li t6, RUN
	beq t1, t6, update_state_end # if already RUN - > do nothing
	mv t1, t6 # set state = RUN
	li t0, PAUSE
	li t2, RUNNING
	sw t2, 0(t0) # Set PAUSE to 0
	j update_state_end
	
checkJC:
	li t2, JC
	and t2, t2, a0
	beqz t2, checkJB # If JC is zero, then check JB
	bnez t1, update_state_end #JC only affects INIT

	li t3, N_SEEDS
	beq t4, t3, jc_to_rand
	j update_state_end
jc_to_rand:
	li t1, RAND
	j update_state_end
checkJB:
	li t2, JB
	and t2, t2, a0
	beqz t2, update_state_end
	li t6, RUN
	bne t1, t6, update_state_end # JB only affects RUN
	li t1, INIT
	addi sp, sp, -32
	sw t0, 0(sp)
	sw t1, 4(sp)
	sw t2, 8(sp)
	sw t3, 12(sp)
	sw t4, 16(sp)
	sw t5, 20(sp)
	sw t6, 24(sp)
	sw ra, 28(sp)
	jal reset_game
	lw t0, 0(sp)
	lw t1, 4(sp)
	lw t2, 8(sp)
	lw t3, 12(sp)
	lw t4, 16(sp)
	lw t5, 20(sp)
	lw t6, 24(sp)
	lw ra, 28(sp)
	addi sp, sp, 32
update_state_end:
	li t0, CURR_STATE
	sw t1, 0(t0)
	ret
 /* END:update_state */ 
	
 /* BEGIN:select_action */ 
select_action:
  addi sp, sp, -4
  sw ra, 0(sp)

	li t0, CURR_STATE
	lw t1, 0(t0)
	li t0, RAND
	beq t0, t1, select_action_rand
	li t0, RUN
	beq t0, t1, select_action_run
	
	# INIT State
	li t2, JC
	and t2, t2, a0
	beqz t2, init_JR_check
init_JC_check:
	addi sp, sp, -16
	sw t0, 0(sp)
	sw t1, 4(sp)
	sw t2, 8(sp)
	sw ra, 12(sp)
	jal increment_seed
	lw t0, 0(sp)
	lw t1, 4(sp)
	lw t2, 8(sp)
	lw ra, 12(sp)
	addi sp, sp, 16
	j select_action_done
	
init_JR_check:
	li t2, JR
	and t2, t2, a0
	beqz t2, init_buttons_check
	addi sp, sp, -20
	sw t0, 0(sp)
	sw t1, 4(sp)
	sw t2, 8(sp)
	sw t3, 12(sp)
	sw ra, 16(sp)
    jal  pause_game
	lw t0, 0(sp)
	lw t1, 4(sp)
	lw t2, 8(sp)
	lw t3, 12(sp)
	lw ra, 16(sp)
	addi sp, sp, 20
	j select_action_done
	
init_buttons_check:
	li t2, BUTTON_0
	li t3, BUTTON_1
	li t4, BUTTON_2
	and t2, t2, a0
	and t3, t3, a0
	and t4, t4, a0
	or t5, t2, t3
	or t5, t5, t4
	beqz t5, select_action_done
	snez a0, t2
	snez a1, t3
	snez a2, t4
	addi sp, sp, -28
	sw t0, 0(sp)
	sw t1, 4(sp)
	sw t2, 8(sp)
	sw t3, 12(sp)
	sw t4, 16(sp)
	sw t5, 20(sp)
	sw ra, 24(sp)
    jal  change_steps
	lw t0, 0(sp)
	lw t1, 4(sp)
	lw t2, 8(sp)
	lw t3, 12(sp)
	lw t4, 16(sp)
	lw t5, 20(sp)
	lw ra, 24(sp)
	addi sp, sp, 28
	j select_action_done
	
select_action_rand:
	li t2, JC
	and t2, t2, a0
rand_JC_check:
	beqz t2, rand_JR_check
	addi sp, sp, -28
	sw t0, 0(sp)
	sw t1, 4(sp)
	sw t2, 8(sp)
	sw t3, 12(sp)
	sw t4, 16(sp)
	sw t5, 20(sp)
	sw ra, 24(sp)
    jal  increment_seed
	lw t0, 0(sp)
	lw t1, 4(sp)
	lw t2, 8(sp)
	lw t3, 12(sp)
	lw t4, 16(sp)
	lw t5, 20(sp)
	lw ra, 24(sp)
	addi sp, sp, 28
	j select_action_done
rand_JR_check:
	li t2, JR
	and t2, t2, a0
	beqz t2, rand_buttons_check
	addi sp, sp, -28
	sw t0, 0(sp)
	sw t1, 4(sp)
	sw t2, 8(sp)
	sw t3, 12(sp)
	sw t4, 16(sp)
	sw t5, 20(sp)
	sw ra, 24(sp)
    jal  pause_game
	lw t0, 0(sp)
	lw t1, 4(sp)
	lw t2, 8(sp)
	lw t3, 12(sp)
	lw t4, 16(sp)
	lw t5, 20(sp)
	lw ra, 24(sp)
	addi sp, sp, 28
	j select_action_done
rand_buttons_check:
	li t2, BUTTON_0
	li t3, BUTTON_1
	li t4, BUTTON_2
	and t2, t2, a0
	and t3, t3, a0
	and t4, t4, a0
	or t5, t2, t3
	or t5, t5, t4
	beqz t5, select_action_done
	snez a0, t2
	snez a1, t3
	snez a2, t4
	addi sp, sp, -28
	sw t0, 0(sp)
	sw t1, 4(sp)
	sw t2, 8(sp)
	sw t3, 12(sp)
	sw t4, 16(sp)
	sw t5, 20(sp)
	sw ra, 24(sp)
    jal  change_steps
	lw t0, 0(sp)
	lw t1, 4(sp)
	lw t2, 8(sp)
	lw t3, 12(sp)
	lw t4, 16(sp)
	lw t5, 20(sp)
	lw ra, 24(sp)
	addi sp, sp, 28
	j select_action_done
select_action_run:
	li t2, JC
	and t2, t2, a0
	beqz t2, run_JR_check
	addi sp, sp, -28
	sw t0, 0(sp)
	sw t1, 4(sp)
	sw t2, 8(sp)
	sw t3, 12(sp)
	sw t4, 16(sp)
	sw t5, 20(sp)
	sw ra, 24(sp)
    jal  pause_game
	lw t0, 0(sp)
	lw t1, 4(sp)
	lw t2, 8(sp)
	lw t3, 12(sp)
	lw t4, 16(sp)
	lw t5, 20(sp)
	lw ra, 24(sp)
	addi sp, sp, 28
	j select_action_done
run_JR_check:
	li t2, JR
	and t2, t2, a0
	beqz t2, run_JL_check
	li a0, 0
	addi sp, sp, -28
	sw t0, 0(sp)
	sw t1, 4(sp)
	sw t2, 8(sp)
	sw t3, 12(sp)
	sw t4, 16(sp)
	sw t5, 20(sp)
	sw ra, 24(sp)
    jal  change_speed
	lw t0, 0(sp)
	lw t1, 4(sp)
	lw t2, 8(sp)
	lw t3, 12(sp)
	lw t4, 16(sp)
	lw t5, 20(sp)
	lw ra, 24(sp)
	addi sp, sp, 28
	j select_action_done
run_JL_check:
	li t2, JL
	and t2, t2, a0
	beqz t2, run_JB_check
	li a0, 1
	addi sp, sp, -28
	sw t0, 0(sp)
	sw t1, 4(sp)
	sw t2, 8(sp)
	sw t3, 12(sp)
	sw t4, 16(sp)
	sw t5, 20(sp)
	sw ra, 24(sp)
    jal  change_speed
	lw t0, 0(sp)
	lw t1, 4(sp)
	lw t2, 8(sp)
	lw t3, 12(sp)
	lw t4, 16(sp)
	lw t5, 20(sp)
	lw ra, 24(sp)
	addi sp, sp, 28
	j select_action_done
run_JB_check:
	li t2, JB
	and t2, t2, a0
	beqz t2, run_JT_check
	addi sp, sp, -28
	sw t0, 0(sp)
	sw t1, 4(sp)
	sw t2, 8(sp)
	sw t3, 12(sp)
	sw t4, 16(sp)
	sw t5, 20(sp)
	sw ra, 24(sp)
    jal  reset_game
	lw t0, 0(sp)
	lw t1, 4(sp)
	lw t2, 8(sp)
	lw t3, 12(sp)
	lw t4, 16(sp)
	lw t5, 20(sp)
	lw ra, 24(sp)
	addi sp, sp, 28
	j select_action_done
run_JT_check:
	li t2, JT
	and t2, t2, a0
	beqz t2, select_action_done
	addi sp, sp, -28
	sw t0, 0(sp)
	sw t1, 4(sp)
	sw t2, 8(sp)
	sw t3, 12(sp)
	sw t4, 16(sp)
	sw t5, 20(sp)
	sw ra, 24(sp)
    jal  random_gsa
	lw t0, 0(sp)
	lw t1, 4(sp)
	lw t2, 8(sp)
	lw t3, 12(sp)
	lw t4, 16(sp)
	lw t5, 20(sp)
	lw ra, 24(sp)
	addi sp, sp, 28
	j select_action_done
select_action_done:
    # restore ra and return
    lw   ra, 0(sp)
    addi sp, sp, 4
    ret
 /* END:select_action */ 
	
 /* BEGIN:cell_fate */ 
cell_fate:
	li t0, 2
	li t1, 3
	beqz a1, cell_dead # branch if the cell is dead
	
	# cell is alive
	beq a0, t0, cell_lives
	beq a0, t1, cell_lives
	li a0, 0
	ret
	
cell_lives:
	li a0, 1
	ret
	# cell is dead
cell_dead:
	beq a0, t1, cell_lives
	li a0, 0
	ret
 /* END:cell_fate */ 
	
/* BEGIN:find_neighbours */
find_neighbours:
    # Save registers
    addi sp, sp, -32
    sw s0, 0(sp)
    sw s1, 4(sp)
    sw s2, 8(sp)
    sw s3, 12(sp)
    sw s4, 16(sp)
    sw s5, 20(sp)
    sw s6, 24(sp)
    sw ra, 28(sp)
    
    mv s0, a0  # x coordinate
    mv s1, a1  # y coordinate
    li s2, 0   # neighbor count
    li s3, 0   # cell state
    
    # Compute wrapped x coordinates
    beqz s0, wrap_x0
    li t0, 11
    beq s0, t0, wrap_x11
    addi s4, s0, -1  # left = x-1
    addi s5, s0, 1   # right = x+1
    j wrap_x_done
    
wrap_x0:
    li s4, 11        # left = 11
    li s5, 1         # right = 1
    j wrap_x_done
    
wrap_x11:
    li s4, 10        # left = 10
    li s5, 0         # right = 0
    
wrap_x_done:
    # Compute wrapped y coordinates  
    beqz s1, wrap_y0
    li t0, 9
    beq s1, t0, wrap_y9
    addi s6, s1, -1  # up = y-1
    addi t1, s1, 1   # down = y+1
    j wrap_y_done
    
wrap_y0:
    li s6, 9         # up = 9
    li t1, 1         # down = 1
    j wrap_y_done
    
wrap_y9:
    li s6, 8         # up = 8
    li t1, 0         # down = 0
    
wrap_y_done:
    # Get current row (middle row)
    mv a0, s1
	addi sp, sp, -16
	sw t0, 0(sp)
	sw t1, 4(sp)
	sw t2, 8(sp)
	sw ra, 12(sp)
    jal get_gsa
	lw t0, 0(sp)
	lw t1, 4(sp)
	lw t2, 8(sp)
	lw ra, 12(sp)
	addi sp, sp, 16
    mv t0, a0        # current row bits
    
    # Get cell state at (x,y)
    srl t2, t0, s0
    andi s3, t2, 1   # cell state in s3
    
    # Check right neighbor (same row)
    srl t2, t0, s5
    andi t2, t2, 1
    add s2, s2, t2
    
    # Check left neighbor (same row)
    srl t2, t0, s4
    andi t2, t2, 1
    add s2, s2, t2
    
    # Get upper row
    mv a0, s6
	addi sp, sp, -16
	sw t0, 0(sp)
	sw t1, 4(sp)
	sw t2, 8(sp)
	sw ra, 12(sp)
    jal get_gsa
	lw t0, 0(sp)
	lw t1, 4(sp)
	lw t2, 8(sp)
	lw ra, 12(sp)
	addi sp, sp, 16
    mv t0, a0        # upper row bits
    
    # Check upper-right neighbor
    srl t2, t0, s5
    andi t2, t2, 1
    add s2, s2, t2
    
    # Check upper-middle neighbor  
    srl t2, t0, s0
    andi t2, t2, 1
    add s2, s2, t2
    
    # Check upper-left neighbor
    srl t2, t0, s4
    andi t2, t2, 1
    add s2, s2, t2
    
    # Get lower row
    mv a0, t1
	addi sp, sp, -16
	sw t0, 0(sp)
	sw t1, 4(sp)
	sw t2, 8(sp)
	sw ra, 12(sp)
    jal get_gsa
	lw t0, 0(sp)
	lw t1, 4(sp)
	lw t2, 8(sp)
	lw ra, 12(sp)
	addi sp, sp, 16
    mv t0, a0        # lower row bits
    
    # Check lower-right neighbor
    srl t2, t0, s5
    andi t2, t2, 1
    add s2, s2, t2
    
    # Check lower-middle neighbor
    srl t2, t0, s0
    andi t2, t2, 1
    add s2, s2, t2
    
    # Check lower-left neighbor
    srl t2, t0, s4
    andi t2, t2, 1
    add s2, s2, t2
    
    # Return values
    mv a0, s2  # neighbor count
    mv a1, s3  # cell state
    
    # Restore registers
    lw s0, 0(sp)
    lw s1, 4(sp)
    lw s2, 8(sp)
    lw s3, 12(sp)
    lw s4, 16(sp)
    lw s5, 20(sp)
    lw s6, 24(sp)
    lw ra, 28(sp)
    addi sp, sp, 32
    ret
/* END:find_neighbours */
	
 /* BEGIN:update_gsa */ 
update_gsa:
	addi sp, sp, -40
	sw s0, 0(sp)
	sw s1, 4(sp)
	sw s2, 8(sp)
	sw s3, 12(sp)
	sw s4, 16(sp)
	sw s5, 20(sp)
	sw s6, 24(sp)
	sw s7, 28(sp)
	sw s8, 32(sp)
	sw ra, 36(sp)
	
	li s0, PAUSE
	lw s1, 0(s0)
	beqz s1, dont_update_gsa
	li s0, GSA_ID
	lw s1, 0(s0) #GSA_ID
	li s3, 0 # counter over rows
	li s4, 10 # rows limit
	li s6, 12 # Columns limit
	beqz s1, next_is_GSA1
next_is_GSA0:
	li s0, GSA1 #Current GSA
	li s1, GSA0 #Next GSA
	j update_rows
next_is_GSA1:
	li s0, GSA0 #Current GSA
	li s1, GSA1 #Next GSA
update_rows:
	beq s3, s4, update_gsa_end
	li t0, 0 # the gsa element we are constructing
	li s5, 0 # Counter over columns
update_columns:
	beq s5, s6, update_columns_end
	mv a0, s5
	mv a1, s3
	addi sp, sp, -4
	sw t0, 0(sp)
	jal find_neighbours
	jal cell_fate # a0 = 1 if cell alive
	lw t0, 0(sp)
	addi sp, sp, 4
	sll a0, a0, s5
	or t0, t0, a0
	addi s5, s5, 1
	j update_columns
update_columns_end:
	mv a0, t0
	mv a1, s3
	li s8, GSA_ID
	lw s7, 0(s8)
	xori s7, s7, 1
	sw s7, 0(s8)
	addi sp, sp, -4
	sw t0, 0(sp)
	jal set_gsa
	lw t0, 0(sp)
	addi sp, sp, 4
	xori s7, s7, 1
	sw s7, 0(s8)
	# sw t0, 0(s1)
	addi s1, s1, 4
	addi s3, s3, 1
	j update_rows
update_gsa_end:
	li t0, GSA_ID
	lw t1, 0(t0)
	xori t1, t1, 1
	sw t1, 0(t0)
dont_update_gsa:
	lw s0, 0(sp)
	lw s1, 4(sp)
	lw s2, 8(sp)
	lw s3, 12(sp)
	lw s4, 16(sp)
	lw s5, 20(sp)
	lw s6, 24(sp)
	lw s7, 28(sp)
	lw s8, 32(sp)
	lw ra, 36(sp)
	addi sp, sp, 40
	ret
 /* END:update_gsa */ 
	
 /* BEGIN:get_input */ 
get_input:
	
	
	li t0, BUTTONS
	lw a0, 0(t0)
	sw x0, 0(t0)
	ret
 /* END:get_input */ 
	
/* BEGIN:decrement_step */
decrement_step:
    # Save registers
    addi sp, sp, -16
    sw s0, 0(sp)
    sw s1, 4(sp)
    sw s2, 8(sp)
    sw ra, 12(sp)

    # Check if game state is RUN
    li t0, CURR_STATE
    lw t1, 0(t0)
    li t2, RUN
    bne t1, t2, display_only  # If not RUN, just display current steps

    # Check if game is running (not paused)
    li t0, PAUSE
    lw t1, 0(t0)
    beqz t1, display_only     # If paused, just display

    # Game is RUNNING and in RUN state - check if steps > 0
    li t0, CURR_STEP
    lw t1, 0(t0)
    beqz t1, steps_zero       # If steps == 0, return 1

    # Decrement step counter
    addi t1, t1, -1
    sw t1, 0(t0)
    j display_steps

steps_zero:
    # Steps reached 0
    li a0, 1
    j decrement_end

display_only:
    # Just display current steps without decrementing
    li t0, CURR_STEP
    lw t1, 0(t0)

display_steps:
    # Convert steps to 7-segment display format
    # t1 contains current steps (12-bit value)
    li s0, SEVEN_SEGS        # 7-segment display address
    li s1, 0                 # Will build display value
    
    # Extract digits (each digit is 4 bits)
    # Digit 0 (units) - bits [3:0]
    andi t2, t1, 0xF
    slli t2, t2, 2          # Multiply by 4 for word offset
    la t3, font_data
    add t3, t3, t2
    lw t2, 0(t3)            # Get font pattern for digit
    or s1, s1, t2           # Store in digit 0 position
    
    # Digit 1 (tens) - bits [7:4]
    srli t2, t1, 4
    andi t2, t2, 0xF
    slli t2, t2, 2          # Multiply by 4 for word offset
    la t3, font_data
    add t3, t3, t2
    lw t2, 0(t3)            # Get font pattern for digit
    slli t2, t2, 8          # Shift to digit 1 position
    or s1, s1, t2
    
    # Digit 2 (hundreds) - bits [11:8]
    srli t2, t1, 8
    andi t2, t2, 0xF
    slli t2, t2, 2          # Multiply by 4 for word offset
    la t3, font_data
    add t3, t3, t2
    lw t2, 0(t3)            # Get font pattern for digit
    slli t2, t2, 16         # Shift to digit 2 position
    or s1, s1, t2
    
    # Digit 3 (thousands) - always show 0 or based on some logic
    # For simplicity, we'll set it to 0
    li t2, 0
    slli t2, t2, 24         # Shift to digit 3 position
    or s1, s1, t2
    
    # Write to 7-segment display
    sw s1, 0(s0)
    
    li a0, 0                # Return 0 (not done)

decrement_end:
    # Restore registers
    lw s0, 0(sp)
    lw s1, 4(sp)
    lw s2, 8(sp)
    lw ra, 12(sp)
    addi sp, sp, 16
    ret
/* END:decrement_step */

/* BEGIN:reset_game */
reset_game:
  addi sp, sp, -4
  sw ra, 0(sp)

  li t0, CURR_STATE
  sw x0, 0(t0)

  li t0, GSA_ID
  sw x0, 0(t0)

  li t0, SEED
  sw x0, 0(t0)

  li a0, 0
  jal set_seed

  li t0, PAUSE
  sw x0, 0(t0)

  li t0, SPEED
  li t1, 1
  sw t1, 0(t0)

  li t0, CURR_STEP
  li t1, MIN_SPEED
  sw t1, 0(t0)
  jal decrement_step
  jal clear_leds
  jal draw_gsa

  lw ra, 0(sp)
  addi sp, sp, 4
  ret

/* END:reset_game */
	
/* BEGIN:mask */
mask:
    # Save registers
    addi sp, sp, -32
    sw s0, 0(sp)
    sw s1, 4(sp)
    sw s2, 8(sp)
    sw s3, 12(sp)
    sw s4, 16(sp)
    sw s5, 20(sp)
    sw s6, 24(sp)
    sw ra, 28(sp)

    # Get current seed
    li s0, SEED
    lw s1, 0(s0)           # s1 = seed ID

    # Pointer to mask table
    la s2, MASKS
    slli s3, s1, 2         # offset = seedID * 4
    add s2, s2, s3
    lw s2, 0(s2)           # s2 = pointer to mask[seedID]

    li s0, 0               # row = 0
    li s1, 10              # max rows = 10

mask_loop:
    beq s0, s1, mask_loop_end

    # Get current GSA row
    mv a0, s0
    jal get_gsa
    mv s3, a0              # s3 = gsa row bits

    # Apply mask to GSA (walls become dead cells)
    lw s4, 0(s2)           # s4 = mask row bits
    and s3, s3, s4         # masked row
    
    # Store masked row back to GSA
    mv a0, s3
    mv a1, s0
    jal set_gsa

    # Draw blue walls where mask bit == 0
    li s5, 0               # col = 0
mask_draw_walls:
    li t0, 12
    beq s5, t0, mask_draw_walls_end
    
    # Check if this is a wall (mask bit == 0)
    srl t0, s4, s5
    andi t0, t0, 1
    bnez t0, skip_blue      # if mask bit == 1, not a wall
    
    # Draw blue pixel at (s5, s0) using the LED register format
    # We need to preserve existing red pixels, so we construct the control word properly
    li s6, LEDS            # LED register address
    
    # Build control word for blue pixel:
    li t1, 1               # set bit
    slli t1, t1, 16        # move to bit 16
    
    # Add blue color (0x400)
    li t2, BLUE            # BLUE = 0x400
    or t1, t1, t2          # add color
    
    # Add y coordinate (row) in bits [7:4]
    slli t2, s0, 4         # y << 4
    or t1, t1, t2          # add y coordinate
    
    # Add x coordinate (column) in bits [3:0]
    or t1, t1, s5          # add x coordinate
    
    # Write to LED register - this sets ONLY this specific pixel to blue
    # The LED controller handles multiple pixel writes correctly
    sw t1, 0(s6)
    
skip_blue:
    addi s5, s5, 1
    j mask_draw_walls

mask_draw_walls_end:
    addi s0, s0, 1
    addi s2, s2, 4
    j mask_loop

mask_loop_end:
    # Restore registers
    lw s0, 0(sp)
    lw s1, 4(sp)
    lw s2, 8(sp)
    lw s3, 12(sp)
    lw s4, 16(sp)
    lw s5, 20(sp)
    lw s6, 24(sp)
    lw ra, 28(sp)
    addi sp, sp, 32
    ret
/* END:mask */

	
	 /* 7 - segment display */ 
font_data:
	.word 0x3F
	.word 0x06
	.word 0x5B
	.word 0x4F
	.word 0x66
	.word 0x6D
	.word 0x7D
	.word 0x07
	.word 0x7F
	.word 0x6F
	.word 0x77
	.word 0x7C
	.word 0x39
	.word 0x5E
	.word 0x79
	.word 0x71
	
seed0:
	.word 0xC00
	.word 0xC00
	.word 0x000
	.word 0x060
	.word 0x0A0
	.word 0x0C6
	.word 0x006
	.word 0x000
	.word 0x000
	.word 0x000
	
seed1:
	.word 0x000
	.word 0x000
	.word 0x05C
	.word 0x040
	.word 0x240
	.word 0x200
	.word 0x20E
	.word 0x000
	.word 0x000
	.word 0x000
	
seed2:
	.word 0x000
	.word 0x010
	.word 0x020
	.word 0x038
	.word 0x000
	.word 0x000
	.word 0x000
	.word 0x000
	.word 0x000
	.word 0x000
	
seed3:
	.word 0x000
	.word 0x000
	.word 0x090
	.word 0x008
	.word 0x088
	.word 0x078
	.word 0x000
	.word 0x000
	.word 0x000
	.word 0x000
	
	
	# Predefined seeds
SEEDS:
	.word seed0
	.word seed1
	.word seed2
	.word seed3
	
mask0:
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	
mask1:
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0x1FF
	.word 0x1FF
	.word 0x1FF
	.word 0x1FF
	.word 0x1FF
	
mask2:
	.word 0x7FF
	.word 0x7FF
	.word 0x7FF
	.word 0x7FF
	.word 0x7FF
	.word 0x7FF
	.word 0x7FF
	.word 0x7FF
	.word 0x7FF
	.word 0x7FF
	
mask3:
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0x000
	.word 0x000
	.word 0x000
	
mask4:
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0x000
	.word 0x000
	.word 0x000
	
MASKS:
	.word mask0
	.word mask1
	.word mask2
	.word mask3
	.word mask4
