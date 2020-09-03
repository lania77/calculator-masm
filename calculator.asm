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

    ; �ж�������ַ = �ж����ͺ� * 4

    ; ִ���ж� : ���ж���������ȡ���жϷ���������ڵ�ַ -> ���� cs IP -> ִ���жϷ������
    ; �� �жϷ������ ��, 1.�����ֳ�(��ؼĴ���) -> �жϷ������ -> �ָ��ֳ�

    ; �ж������ź� ͨ�� �жϿ�����8259 �� 8086 ����INTR �ж�����
    ; �ж������־ IF = 1 CPUִ���굱ǰָ�����Ӧ�ж�

    ; sure �ж�������ַ
        ;�ж���Ӧ�� ִ��2������������ �ж���Ӧ�������� to get �ж����ͺ�
            ; 1st �������� : CPU ����һ�������ź�, �����жϵ��ⲿ�ж�ϵͳ(8259A) -> ׼�����ж����ͺ�
            ; 2nd �������� : CPU �ٷ���һ�������ź�, 8259A ���յ���, �� �ж����ͺ� ���� �������ߵͰ�λ


    ; �ж����� : �жϷ���������ڵ�ַ -- 4�ֽ� -- ǰ���ֽ�IP �����ֽ�CS
    ; �ж������� : ��������ж�������һ���ڴ�����
    ; �ж�������ַ : �ж��������ж��������еĴ�ŵ�ַ


    ; �жϿ����� 8259
    ; 8259ֻ��������8253�ļ�ʱ�ж�
    port59_0    equ 0ffe4h
    port59_1    equ 0ffe5h  ; ? 
    ; оƬ���Ƴ�ʼ�� icw1
    ; icw1 A0 = 0 д��ż��ַ (С��ַ)
    icw1        equ 13H         ; 000  1(icw1��־)   0(����)    0   1(��Ƭ8259 )   1(��Ҫicw4)  ���ش���
    
    ; icw2 �ж����ͳ�ʼ��
    ; A0 = 1 д�����ַ (���ַ)
    icw2        equ 08h         ; 00001-�ж����ͺŵĸ���λ �ж����ͺ� 08H 09H ... 0FH

    ; ʲôʱ����Ҫ��ʽ������ ? 
    ; ��ʽ������ 
    ; icw4 A0 = 1 д�����ַ (���ַ)
    icw4        equ 09h         ; (000)-(ICW4��־λ) 0-ȫǶ�� 10-���巽ʽ/��Ƭ   0-���Զ�EOI 1-8086/88ģʽ

    ; ocw1 ���������� -> IMR
    ; A0 = 1 д�����ַ (���ַ)
    ; 0000 0111 
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


    ledbuf                  db 6 dup(?)
    led_count               db 0
    previous_key            db 20h
    current_key             db 20h
    has_previous_bracket    db 0
    same_as_pre             db 0

    operator_stack          db '#', 100 dup(?)      ; si
    operand_stack           dw 0ffffh, 100 dup(?)   ; di

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


start:
    cli
    call init_all
main:
    sti
    call get_key
    cmp current_key, 20h
    je handle
    and  al,0fh
    handle:
    call handle_key
    call disp
    jmp main
; end



init_all proc
        call init8259
        call init8255
        call init8253
        call init_stack
        call clean_led
        mov previous_key, 20h
        mov current_key, 20h
        mov led_count, 0
        mov has_previous_bracket, 0
        mov same_as_pre, 0
        mov current_num, 0
        mov result, 0
        mov led_overflow, 0
        mov error, 0
        ret
init_all endp

; �ж��ӳ����װ�� 
; ?

init8259 proc
    push ax
    push dx

    mov dx, port59_0
    mov al, icw1
    out dx, al

    mov dx, port59_1
    mov al, icw2
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
        mov al, 88H ; 1(��ʽѡ�������)00(��ʽ0)0(A��I/O: ��) 1(C�ڸ�λ:��)0(B�ڷ�ʽ0)0(B��I/O: ��)0(C�ڵ�λ:��) 
        out dx, al

        mov al, lightOff
        ; TODO
        mov dx, port55_a
        out dx, al

        pop dx
        pop ax
        ret
init8255 endp


init8253 proc
        ; 8253�ĳ�ʼ��
        ; ��д�����֣����ͼ�����ֵ
        ; ����16λ��ֵ����Ҫ���͵�8λ�����͸�8λ�� 
        push dx
        push ax

        mov dx, port53_ctrl
        mov al, 30H ; 00(������0)11(�ȵ�8λ�ٸ�8λ) 000(��ʽ 0) 0(�����Ƽ���)
        out dx, al

        ; TODO

        pop ax
        pop dx
        ret
init8253 endp


init_stack proc
        mov si, 0
        mov di, 0
init_stack endp


clean_all proc
        call init_stack
clean_all endp


clean_led proc
        mov  LedBuf+0,0ffh
        mov  LedBuf+1,0ffh
        mov  LedBuf+2,0ffh
        mov  LedBuf+3,0c0h
        mov  LedBuf+4,0ffh
        mov  LedBuf+6,0ffh
clean_led endp


get_key proc    ; ��ɨ�ӳ���
    ; store key in current_key
        push ax
        push bx
        push cx
        push dx

        mov al, current_key     ; ��һ��ɨ��ķ���   current_key ��ʼΪ 20H
        mov previous_key, al    ; 

        mov  al,0ffh            ;����ʾ��
        mov  dx,OUTSEG
        out  dx,al

        ; TODO ???
        mov  bl,0
        mov  ah,0feh ;1111 1110
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
        push ax
        call is_same_as_pre
        mov al, current_key
        cmp same_as_pre, 1
        jne handle_key_continue
        pop ax
        ret
    handle_key_continue:
        cmp al, 10
        jnb handle_key_a
        call handle_number
        pop ax
        ret
    handle_key_a:
        cmp al, 0ah
        jne handle_key_b
        call handle_a
        pop ax
        ret
    handle_key_b:
        cmp al, 0bh
        jne handle_key_c
        call handle_b
        pop ax
        ret
    handle_key_c:
        cmp al, 0ch
        jne handle_key_d
        call handle_c
        pop ax
        ret
    handle_key_d:
        cmp al, 0dh
        jne handle_key_e
        call handle_d
        pop ax
        ret
    handle_key_e:
        cmp al, 0eh
        jne handle_key_f
        call handle_e
        pop ax
        ret
    handle_key_f:
        cmp al, 0fh
        jne key_error
        call handle_f
        jmp handle_key_f_ret
        key_error:
        call handle_error
        handle_key_f_ret:
        pop ax
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
    ; ��������������ķ��ŵ�ʱ����Ҫ��led_count���
    push ax
    push bx
    push dx
    cmp led_count, 4
    jae handle_number_ret
    mov ax, current_num
    mov bx, 10
    mul bx
    mov bl, current_key
    mov bh, 0
    add ax, bx               
    mov current_num, ax          ;current_num = current_num * 10 + current_key
    inc led_count
    handle_number_ret:
    call set_led_num
    pop dx
    pop bx
    pop ax
    ret
handle_number endp

handle_error proc
    ;����get_key�õ����ַ��������ֺͷ��ŵ����������current_key=20h
    cmp current_key, 20h
    je handle_error_ret
    TODO ;���������ķ���
    handle_error_ret:
    ret
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


set_led_num proc
    ; ֻ��handle_number������ã�
    ; ��ʱled_count = �����������λ��
    ; led_count - 1 = ����ʾ������λ��
        push ax
        push bx
        push dx
        push di
        mov di, 3
        mov ax, current_number
        mov dx, 0
    ax_not_zero:
        mov dx, 0
        mov bx, 10
        div bx
        mov bl, ledmap[dx]
        mov ledbuf[di], bl
        dec di
        cmp ax, 0
        jne ax_not_zero
    fill_empty:
        cmp di, 0    
        jb set_led_num_ret
        mov ledbuf[di], 0ffh
        dec di
        jmp fill_empty
    set_led_num_ret:
        pop di
        pop dx
        pop bx
        pop ax
        ret
set_led_num endp



disp proc
        mov  bx,offset LEDBuf
        mov  cl,6               ;��6���˶ι�
        mov  ah,00100000b       ;����߿�ʼ��ʾ
    DLoop:
        mov  dx,OUTBIT
        mov  al,0
        out  dx,al              ;�����а˶ι�
        mov  al,[bx]
        mov  dx,OUTSEG
        out  dx,al

        mov  dx,OUTBIT
        mov  al,ah
        out  dx,al              ;��ʾһλ�˶ι�

        push ax
        mov  ah,1
        call Delay
        pop  ax

        shr  ah,1
        inc  bx
        dec  cl
        jnz  DLoop

        mov  dx,OUTBIT
        mov  al,0
        out  dx,al              ;�����а˶ι�
        ret
disp endp

delay proc                         ;��ʱ�ӳ���
        push  cx
        mov   cx,256
        loop  $
        pop   cx
        ret
delay endp

code    ends
        end start
