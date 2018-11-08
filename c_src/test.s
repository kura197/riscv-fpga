	.file	"test.c"
	.option nopic
	.text
	.align	2
	.globl	main
	.type	main, @function
main:
	addi	sp,sp,-32
	sw	ra,28(sp)
	sw	s0,24(sp)
	addi	s0,sp,32
	li	a2,0
	li	a1,512
	li	a5,32768
	addi	a0,a5,-1024
	call	readseg
	li	a5,32768
	addi	a5,a5,-1024
	sw	a5,-20(s0)
	lw	a5,-20(s0)
	jalr	a5
	nop
	lw	ra,28(sp)
	lw	s0,24(sp)
	addi	sp,sp,32
	jr	ra
	.size	main, .-main
	.align	2
	.type	inb, @function
inb:
	addi	sp,sp,-48
	sw	s0,44(sp)
	addi	s0,sp,48
	mv	a5,a0
	sh	a5,-34(s0)
	lhu	a4,-34(s0)
	li	a5,-4096
	add	a5,a4,a5
	lbu	a5,0(a5)
	sb	a5,-17(s0)
	lbu	a5,-17(s0)
	mv	a0,a5
	lw	s0,44(sp)
	addi	sp,sp,48
	jr	ra
	.size	inb, .-inb
	.align	2
	.type	insl, @function
insl:
	addi	sp,sp,-48
	sw	s0,44(sp)
	addi	s0,sp,48
	sw	a0,-36(s0)
	sw	a1,-40(s0)
	sw	a2,-44(s0)
	lw	a5,-40(s0)
	sw	a5,-20(s0)
	j	.L5
.L6:
	lw	a4,-36(s0)
	li	a5,-4096
	add	a5,a4,a5
	lbu	a5,0(a5)
	andi	a4,a5,0xff
	lw	a5,-20(s0)
	sb	a4,0(a5)
	lw	a5,-20(s0)
	addi	a5,a5,1
	sw	a5,-20(s0)
.L5:
	lw	a5,-44(s0)
	addi	a4,a5,-1
	sw	a4,-44(s0)
	bgtz	a5,.L6
	nop
	lw	s0,44(sp)
	addi	sp,sp,48
	jr	ra
	.size	insl, .-insl
	.align	2
	.type	outb, @function
outb:
	addi	sp,sp,-32
	sw	s0,28(sp)
	addi	s0,sp,32
	mv	a5,a0
	mv	a4,a1
	sh	a5,-18(s0)
	mv	a5,a4
	sb	a5,-19(s0)
	lhu	a4,-18(s0)
	li	a5,-4096
	add	a5,a4,a5
	mv	a4,a5
	lbu	a5,-19(s0)
	sb	a5,0(a4)
	nop
	lw	s0,28(sp)
	addi	sp,sp,32
	jr	ra
	.size	outb, .-outb
	.align	2
	.globl	waitdisk
	.type	waitdisk, @function
waitdisk:
	addi	sp,sp,-16
	sw	ra,12(sp)
	sw	s0,8(sp)
	addi	s0,sp,16
	nop
.L9:
	li	a0,503
	call	inb
	mv	a5,a0
	andi	a4,a5,192
	li	a5,64
	bne	a4,a5,.L9
	nop
	lw	ra,12(sp)
	lw	s0,8(sp)
	addi	sp,sp,16
	jr	ra
	.size	waitdisk, .-waitdisk
	.align	2
	.globl	readsect
	.type	readsect, @function
readsect:
	addi	sp,sp,-32
	sw	ra,28(sp)
	sw	s0,24(sp)
	addi	s0,sp,32
	sw	a0,-20(s0)
	sw	a1,-24(s0)
	li	a1,1
	li	a0,498
	call	outb
	lw	a5,-24(s0)
	andi	a5,a5,0xff
	mv	a1,a5
	li	a0,499
	call	outb
	lw	a5,-24(s0)
	srli	a5,a5,8
	andi	a5,a5,0xff
	mv	a1,a5
	li	a0,500
	call	outb
	lw	a5,-24(s0)
	srli	a5,a5,16
	andi	a5,a5,0xff
	mv	a1,a5
	li	a0,501
	call	outb
	lw	a5,-24(s0)
	srli	a5,a5,24
	andi	a5,a5,0xff
	mv	a1,a5
	li	a0,502
	call	outb
	li	a1,32
	li	a0,503
	call	outb
	call	waitdisk
	li	a2,512
	lw	a1,-20(s0)
	li	a0,496
	call	insl
	nop
	lw	ra,28(sp)
	lw	s0,24(sp)
	addi	sp,sp,32
	jr	ra
	.size	readsect, .-readsect
	.align	2
	.globl	readseg
	.type	readseg, @function
readseg:
	addi	sp,sp,-48
	sw	ra,44(sp)
	sw	s0,40(sp)
	addi	s0,sp,48
	sw	a0,-36(s0)
	sw	a1,-40(s0)
	sw	a2,-44(s0)
	lw	a4,-36(s0)
	lw	a5,-40(s0)
	add	a5,a4,a5
	sw	a5,-20(s0)
	lw	a5,-44(s0)
	andi	a5,a5,511
	sub	a5,zero,a5
	lw	a4,-36(s0)
	add	a5,a4,a5
	sw	a5,-36(s0)
	lw	a5,-44(s0)
	srli	a5,a5,9
	sw	a5,-44(s0)
	j	.L12
.L13:
	lw	a1,-44(s0)
	lw	a0,-36(s0)
	call	readsect
	lw	a5,-36(s0)
	addi	a5,a5,512
	sw	a5,-36(s0)
	lw	a5,-44(s0)
	addi	a5,a5,1
	sw	a5,-44(s0)
.L12:
	lw	a4,-36(s0)
	lw	a5,-20(s0)
	bltu	a4,a5,.L13
	nop
	lw	ra,44(sp)
	lw	s0,40(sp)
	addi	sp,sp,48
	jr	ra
	.size	readseg, .-readseg
	.ident	"GCC: (GNU) 7.2.0"
