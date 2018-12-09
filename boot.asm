
;%define	_BOOT_DEBUG_	
%ifdef	_BOOT_DEBUG_
	org  0100h			
%else
	org  07c00h			
%endif

;-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
%ifdef	_BOOT_DEBUG_
BaseOfStack		equ	0100h		; 调试状态下堆栈基地址
%else
BaseOfStack		equ	07c00h	; Boot状态下堆栈基地址
%endif

%include	"load.inc"
;-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

	jmp short LABEL_START		
	nop				

; 下面是 FAT12 磁盘的头
%include	"fat12hdr.inc"

LABEL_START:	
	mov	ax, cs
	mov	ds, ax
	mov	es, ax
	mov	ss, ax
	mov	sp, BaseOfStack

	; 清屏
	mov	ax, 0600h		
	mov	bx, 0700h		
	mov	cx, 0			
	mov	dx, 0184fh		
	int	10h			

	mov	dh, 0			
	call	DispStr			
	
	xor	ah, ah	
	xor	dl, dl	
	int	13h	
	
; 下面在 A 盘的根目录寻找 LOADER.BIN
	mov	word [wSectorNo], SectorNoOfRootDirectory
LABEL_SEARCH_IN_ROOT_DIR_BEGIN:
	cmp	word [wRootDirSizeForLoop], 0	
	jz	LABEL_NO_LOADERBIN		
	dec	word [wRootDirSizeForLoop]	
	mov	ax, LOADER_SEG
	mov	es, ax			
	mov	bx, LOADER_OFF		
	mov	ax, [wSectorNo]		
	mov	cl, 1
	call	ReadSector

	mov	si, LoaderFileName	
	mov	di, LOADER_OFF		
	cld
	mov	dx, 10h
LABEL_SEARCH_FOR_LOADERBIN:
	cmp	dx, 0					
	jz	LABEL_GOTO_NEXT_SECTOR_IN_ROOT_DIR	
	dec	dx					
	mov	cx, 11
LABEL_CMP_FILENAME:
	cmp	cx, 0
	jz	LABEL_FILENAME_FOUND	
	dec	cx
	lodsb				
	cmp	al, byte [es:di]
	jz	LABEL_GO_ON
	jmp	LABEL_DIFFERENT		
; 我们要找的 LOADER.BIN
LABEL_GO_ON:
	inc	di
	jmp	LABEL_CMP_FILENAME	

LABEL_DIFFERENT:
	and	di, 0FFE0h		
	add	di, 20h			
	mov	si, LoaderFileName	
	jmp	LABEL_SEARCH_FOR_LOADERBIN

LABEL_GOTO_NEXT_SECTOR_IN_ROOT_DIR:
	add	word [wSectorNo], 1
	jmp	LABEL_SEARCH_IN_ROOT_DIR_BEGIN

LABEL_NO_LOADERBIN:
	mov	dh, 2			; "No LOADER."
	call	DispStr		; 显示字符串
%ifdef	_BOOT_DEBUG_
	mov	ax, 4c00h		
	int	21h			
%else
	jmp	$			; 没有找到 LOADER.BIN, 死循环在这里
%endif

LABEL_FILENAME_FOUND:		; 找到 LOADER.BIN 后便来到这里继续
	mov	ax, RootDirSectors
	and	di, 0FFE0h		
	add	di, 01Ah		
	mov	cx, word [es:di]
	push	cx			; 保存此 Sector 在 FAT 中的序号
	add	cx, ax
	add	cx, DeltaSectorNo	; 这句完成时 cl 里面变成 LOADER.BIN 的起始扇区号 
	mov	ax, LOADER_SEG
	mov	es, ax			; es <- LOADER_SEG
	mov	bx, LOADER_OFF		; bx <- LOADER_OFF	
	mov	ax, cx			; ax <- Sector 号

LABEL_GOON_LOADING_FILE:
	push	ax			
	push	bx			
	mov	ah, 0Eh			
	mov	al, '.'			
	mov	bl, 0Fh			
	int	10h			
	pop	bx			
	pop	ax			

	mov	cl, 1
	call	ReadSector
	pop	ax			; 取出此 Sector 在 FAT 中的序号
	call	GetFATEntry
	cmp	ax, 0FFFh
	jz	LABEL_FILE_LOADED
	push	ax			; 保存 Sector 在 FAT 中的序号
	mov	dx, RootDirSectors
	add	ax, dx
	add	ax, DeltaSectorNo
	add	bx, [BPB_BytsPerSec]
	jmp	LABEL_GOON_LOADING_FILE
LABEL_FILE_LOADED:

	mov	dh, 1			
	call	DispStr			

;-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	jmp	LOADER_SEG:LOADER_OFF	; 这一句正式跳转到已加载到内存中的 LOADER.BIN 的开始处
						; 开始执行 LOADER.BIN 的代码
						; Boot Sector 的使命到此结束
;-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------



;-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
;变量
;----------------------------------------------------------------------------
wRootDirSizeForLoop	dw	RootDirSectors	
wSectorNo		dw	0		; 要读取的扇区号
bOdd			db	0		; 奇数还是偶数

;-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
;字符串
;----------------------------------------------------------------------------
LoaderFileName		db	"LOADER  BIN", 0	
;下面每个字符串的长度均为 MessageLength
MessageLength		equ	9
BootMessage:		db	"Booting  "
Message1		db	"Ready.   "
Message2		db	"No LOADER"
;-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


;----------------------------------------------------------------------------
; 函数名: DispStr
;----------------------------------------------------------------------------
; 作用:
;	显示一个字符串, 函数开始时 dh 中应该是字符串序号
DispStr:
	mov	ax, MessageLength
	mul	dh
	add	ax, BootMessage
	mov	bp, ax			
	mov	ax, ds			
	mov	es, ax			
	mov	cx, MessageLength	
	mov	ax, 01301h		
	mov	bx, 0007h		
	mov	dl, 0
	int	10h			
	ret


;----------------------------------------------------------------------------
; 函数名: ReadSector
;----------------------------------------------------------------------------
; 作用:
;	从第 ax 个 Sector 开始, 将 cl 个 Sector 读入 es:bx 中
ReadSector:
	
	push	bp
	mov	bp, sp
	sub	esp, 2			

	mov	byte [bp-2], cl
	push	bx			
	mov	bl, [BPB_SecPerTrk]	
	div	bl			
	inc	ah			
	mov	cl, ah			
	mov	dh, al			
	shr	al, 1			
	mov	ch, al			
	and	dh, 1			
	pop	bx			
	
	mov	dl, [BS_DrvNum]		
.GoOnReading:
	mov	ah, 2			
	mov	al, byte [bp-2]		
	int	13h
	jc	.GoOnReading		

	add	esp, 2
	pop	bp

	ret

;----------------------------------------------------------------------------
; 函数名: GetFATEntry
;----------------------------------------------------------------------------
; 作用:
;	找到序号为 ax 的 Sector 在 FAT 中的条目, 结果放在 ax 中

GetFATEntry:
	push	es
	push	bx
	push	ax
	mov	ax, LOADER_SEG	
	sub	ax, 0100h		
	mov	es, ax			
	pop	ax
	mov	byte [bOdd], 0
	mov	bx, 3
	mul	bx			
	mov	bx, 2
	div	bx			
	cmp	dx, 0
	jz	LABEL_EVEN
	mov	byte [bOdd], 1
LABEL_EVEN:;偶数
	xor	dx, dx			
	mov	bx, [BPB_BytsPerSec]
	div	bx			
					
	push	dx
	mov	bx, 0			
	add	ax, SectorNoOfFAT1	
	mov	cl, 2
	call	ReadSector		
	pop	dx
	add	bx, dx
	mov	ax, [es:bx]
	cmp	byte [bOdd], 1
	jnz	LABEL_EVEN_2
	shr	ax, 4
LABEL_EVEN_2:
	and	ax, 0FFFh

LABEL_GET_FAT_ENRY_OK:

	pop	bx
	pop	es
	ret
;----------------------------------------------------------------------------

times 	510-($-$$)	db	0	
dw 	0xaa55				
