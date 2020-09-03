; ��A��������+��
; ��B��������-��
; ��C��������*�� 
; ��D�����������š� 
; ��E��������=�� 
; ��F������ ��ʼ���㣨�����������㣩����Ļ��ʾ ��0����
;
; ����Ҫ�� 
;     �� ������������ݣ�С����λ����������ܸ�����ʾ�� 
;     �� �� ��+������-������*�� �� �����š� ʱ����ǰ��ʾ���ݲ��䡣 
;     �� ����������ʱ������ܸ�����ʾ�� 
;     �� �� ��E�� ʱ����ʾ���ս�����ݡ���������Ϊ����������� 1 ����ɫ��������ܣ��������� 1 ���
;     ����Ӳ��ʵ�֣���˸����������Ϊż��������� 2 ����ɫ��������ܣ��������� 2 ������Ӳ��ʵ�֣���
;     ˸�� 
;     �� �� ��F�� ��������ĸ�����������ұߣ���Ӧ��λ������һ����ʾ ��0����������������ʾ���ݡ�
;     ͬʱϨ������ķ�������ܣ��ȴ���һ������Ŀ�ʼ�� 
;     �� ��Ҫ������������ȼ����⡣ 
;     �� ����ֻ�������������㣬�����Ǹ�����ʵ�����㡣���ſ��Բ�����Ƕ���������������ʵ����ʽ
 ;     �д��ڶ���ƽ�����ŵļ��㡣
;
; ���˵���� 
;     ��������ʱ����������ʾ��Χ����Ӧ�������֡��ڼ�����������ʾ��Χʱ������ʾ ��F����

code    segment
        assume cs:code

org  1000h

    ; �жϿ����� 8259
    ; 8259ֻ��������8253�ļ�ʱ�ж�
    port59_0    equ 0ffe4h
    port59_1    equ 0ffe5h
    icw1        equ 13H         ; ���ش���
    icw2        equ 08h         ; �ж����ͺ� 08H 09H ...
    icw4        equ 09h         ; ȫǶ�ף��ǻ��壬���Զ�EOI��8086/88ģʽ
    ocw1open    equ 07fh        ; IRQ7�����ͺ�Ϊ0fh��������ַƫ�Ƶ�ַ3ch���ε�ַ0���ο�ʾ����13��
    ocw1down    equ 0ffh        ; TODO �Ƿ���Ҫ

    ; ���нӿ�оƬ 8255
    ; 8255��led�����led״̬
    port55_a    equ 0ffd8H
    port55_ctrl equ 0ffdBH

    ; ������ʱоƬ 8253
    port53_0    equ 0ffe0H
    port53_ctrl equ 0ffe3H      ; ���ƿ�
    count_1sec  equ 19200       ; 1s��������
    count_2sec  equ 38400       ; 2s��������


    led_status              db 6 dup(?)
    led_count               db 0
    previous_key            db 20h
    current_key             db 20h
    has_previous_bracket    db 0
    same_as_pre             db 0

    operand_stack           db 0ffh, 100 dup(?)
    operator_stack          dw 0ffffh, 100 dup(?)
    operator_stack_top      db ?    ; TODO �Ƿ���Ҫ
    operator_next           db '#'  ; TODO �Ƿ���Ҫ

    current_num             dw 0
    result                  dw 0
    led_overflow            db 0
    error                   db 0

    OUTSEG  equ  0ffdch             ;�ο��ƿ�
    OUTBIT  equ  0ffddh             ;λ���ƿ�/��ɨ��
    IN_KEY  equ  0ffdeh             ;���̶����
    ;�˶ι���ʾ��
    LedMap  db   0c0h,0f9h,0a4h,0b0h,099h,092h,082h,0f8h
            db   080h,090h,088h,083h,0c6h,0a1h,086h,08eh
    ;���붨��
    KeyTable db   07h,04h,08h,05h,09h,06h,0ah,0bh
            db   01h,00h,02h,0fh,03h,0eh,0ch,0dh


; start
    cli
    call init_all
main:
    sti
    call get_key
    call handle_key
    jmp main
; end



init_all proc
        call init8259
        call init8255
        call init8253
        call init_stack
        call clean_led
        ret
init_all endp


init8259 proc
        push ax
        push dx
        mov dx, port59_0
        mov al, icw1
        out dx, al
        mov dx, port59_1
        mov al, icw2
        mov dx, port59_1
        out dx, al
        mov al, icw4
        out dx, al
        mov al, ocw1open
        out dx, al
        pop dx
        pop ax
        ret
init8259 endp


init8255 proc
        push ax
        push dx
        mov dx, port55_ctrl
        mov al, 88H
        out dx, al
        mov al, lightOff
        mov dx, port55_a
        out dx, al
        pop dx
        pop ax
        ret
init8255 endp


init8253 proc
        push dx
        push ax
        mov dx, port53_ctrl
        mov al, 30H; 计数�?0，先�?8位，再高8位，方式0，二进制计数
        out dx, al
        pop ax
        pop dx
        ret
init8253 endp


init_stack proc
        ; TODO init operand stack
        ; TODO init operator stack
init_stack endp


clean_all proc
        call init_stack
clean_all endp


clean_led proc
        ; TODO 最后一位显�?0，其余不显示
clean_led endp


get_key proc                    ;�?�?子程�?
    ; store key in current_key
        push ax
        push bx
        push cx
        push dx

        mov al, current_key     ;��һ��ɨ��ķ���
        mov previous_key, al

        mov  al,0ffh            ;����ʾ��
        mov  dx,OUTSEG
        out  dx,al
        mov  bl,0
        mov  ah,0feh
        mov  cx,8
    key1:   
        mov  al,ah
        mov  dx,OUTBIT
        out  dx,al
        shl  al,1
        mov  ah,al
        nop
        nop
        nop
        nop
        nop
        nop
        mov  dx,IN_KEY
        in   al,dx
        not  al
        nop
        nop
        and  al,0fh
        jnz  key2
        inc  bl
        loop key1
    nkey:   
        mov  al,20h
        mov current_key, al
        pop dx
        pop cx
        pop bx
        pop ax
        ret
    key2:   
        test al,1
        je   key3
        mov  al,0
        jmp  key6
    key3:   
        test al,2
        je   key4
        mov  al,8
        jmp  key6
    key4:   
        test al,4
        je   key5
        mov  al,10h
        jmp  key6
    key5:   
        test al,8
        je   nkey
        mov  al,18h
    key6:   
        add  al,bl
        cmp  al,10h
        jnc  fkey
        mov  bx,offset KeyTable
        xlat
    fkey:   
        mov current_key, al
        pop dx
        pop cx
        pop bx
        pop ax
        ret
get_key endp


handle_key proc
        call is_same_as_pre
        cmp same_as_pre, 1
        jne handle_key_continue
        call do_nothing ; TODO
        ret
    handle_key_continue:
        cmp al, 10
        jnb handle_key_a
        call handle_number
        ret
    handle_key_a:
        cmp al, 0ah
        jne handle_key_b
        call handle_a
        ret
    handle_key_b:
        cmp al, 0bh
        jne handle_key_c
        call handle_b
        ret
    handle_key_c:
        cmp al, 0ch
        jne handle_key_d
        call handle_c
        ret
    handle_key_d:
        cmp al, 0dh
        jne handle_key_e
        call handle_d
        ret
    handle_key_e:
        cmp al, 0eh
        jne handle_key_f
        call handle_a
        ret
    handle_key_f:
        cmp al, 0fh
        call handle_error
        ret
handle_key endp

is_same_as_pre proc
    ;��same_as_pre��ֵ
    push ax
    mov al, current_key
    cmp al, previous_key
    je is_same
    mov same_as_pre, 0
    jmp return
is_same: 
    mov same_as_pre, 1
return:    
    pop ax
    ret
is_same_as_pre endp



handle_number proc
    ; ��� led_count < 4
    ;   current_num = current_num * 10 + current_key
    ;   led_count += 1
    ; ����
    ;   call do_nothing
handle_number endp

handle_error proc
handle_error endp

handle_a proc
handle_a endp

handle_b proc
handle_b endp

handle_c proc
handle_c endp

handle_d proc
handle_d endp

handle_e proc
handle_e endp

handle_f proc
handle_f endp


cal_one_op proc

cal_one_op endp


push_stack proc
push_stack endp
