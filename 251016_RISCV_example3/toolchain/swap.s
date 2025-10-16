_start:
        li 		sp, 200
main:
        addi    sp,sp,-48
        sw      ra,44(sp)
        sw      s0,40(sp)
        addi    s0,sp,48
        sw      zero,-40(s0)
        sw      zero,-36(s0)
        sw      zero,-32(s0)
        sw      zero,-28(s0)
        sw      zero,-24(s0)
        sw      zero,-20(s0)
        li      a5,5
        sw      a5,-40(s0)
        li      a5,4
        sw      a5,-36(s0)
        li      a5,3
        sw      a5,-32(s0)
        li      a5,2
        sw      a5,-28(s0)
        li      a5,1
        sw      a5,-24(s0)
        addi    a5,s0,-40
        li      a1,5
        mv      a0,a5
        call    sort
        li      a5,0
        mv      a0,a5
        lw      ra,44(sp)
        lw      s0,40(sp)
        addi    sp,sp,48
        jr      ra
sort:
        addi    sp,sp,-48
        sw      ra,44(sp)
        sw      s0,40(sp)
        addi    s0,sp,48
        sw      a0,-36(s0)
        sw      a1,-40(s0)
        sw      zero,-20(s0)
        j       .L4
.L8:
        sw      zero,-24(s0)
        j       .L5
.L7:
        lw      a5,-24(s0)
        slli    a5,a5,2
        lw      a4,-36(s0)
        add     a5,a4,a5
        lw      a4,0(a5)
        lw      a5,-24(s0)
        addi    a5,a5,1
        slli    a5,a5,2
        lw      a3,-36(s0)
        add     a5,a3,a5
        lw      a5,0(a5)
        ble     a4,a5,.L6
        lw      a5,-24(s0)
        slli    a5,a5,2
        lw      a4,-36(s0)
        add     a3,a4,a5
        lw      a5,-24(s0)
        addi    a5,a5,1
        slli    a5,a5,2
        lw      a4,-36(s0)
        add     a5,a4,a5
        mv      a1,a5
        mv      a0,a3
        call    swap
.L6:
        lw      a5,-24(s0)
        addi    a5,a5,1
        sw      a5,-24(s0)
.L5:
        lw      a4,-40(s0)
        lw      a5,-20(s0)
        sub     a5,a4,a5
        addi    a5,a5,-1
        lw      a4,-24(s0)
        blt     a4,a5,.L7
        lw      a5,-20(s0)
        addi    a5,a5,1
        sw      a5,-20(s0)
.L4:
        lw      a5,-40(s0)
        addi    a5,a5,-1
        lw      a4,-20(s0)
        blt     a4,a5,.L8
        nop
        nop
        lw      ra,44(sp)
        lw      s0,40(sp)
        addi    sp,sp,48
        jr      ra
swap:
        addi    sp,sp,-48
        sw      ra,44(sp)
        sw      s0,40(sp)
        addi    s0,sp,48
        sw      a0,-36(s0)
        sw      a1,-40(s0)
        lw      a5,-40(s0)
        lw      a5,0(a5)
        sw      a5,-20(s0)
        lw      a5,-36(s0)
        lw      a4,0(a5)
        lw      a5,-40(s0)
        sw      a4,0(a5)
        lw      a5,-36(s0)
        lw      a4,-20(s0)
        sw      a4,0(a5)
        nop
        lw      ra,44(sp)
        lw      s0,40(sp)
        addi    sp,sp,48
        jr      ra