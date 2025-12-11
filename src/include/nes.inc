;-------------------------------------------------
; NES Register Aliases
;-------------------------------------------------

.ifndef _NES_IO_
_NES_IO_ = 1

PPUCTRL		   = $2000
PPUMASK 	   = $2001
PPUSTATUS	   = $2002
PPU_SPR_ADDR   = $2003 ;alias for OAMADDR
OAMADDR		   = $2003
PPU_SPR_DATA   = $2004 ;alias for OAMDATA
OAMDATA		   = $2004
PPU_SCROLL_REG = $2005 ;alias for PPUSCROLL
PPUSCROLL	   = $2005
PPUADDR		   = $2006
PPUDATA		   = $2007
SND_DELTA_REG  = $4010 ;alias for DMC_FREQ
DMC_FREQ	   = $4010
SPR_DMA		   = $4014 ;alias for OAMDMA
OAMDMA		   = $4014
JOY1	       = $4016
JOY2		   = $4017
PAD_A          = %10000000
PAD_B          = %01000000
PAD_SELECT     = %00100000
PAD_START      = %00010000
PAD_UP         = %00001000
PAD_DOWN       = %00000100
PAD_LEFT       = %00000010
PAD_RIGHT      = %00000001

;PPUCTRL SETTINGS
NT_2000        = %00000000
NT_2400        = %00000001
NT_2800        = %00000010
NT_2C00        = %00000011
OBJ_0000       = %00000000 ;bit 3 (4th from the right) is 0
OBJ_1000       = %00001000 ;bit 3 is 1
BG_0000        = %00000000 ;bit 4 (5th from the right) is 0
BG_1000        = %00010000 ;bit 4 is 1
OBJ_8X16       = %00100000 ;enable 8x16 mode for sprites
AGENT_MODE     = %01000000 ;ppu master/slave select
VBLANK_NMI     = %10000000

;PPUMASK SETTINGS
GREYSCALE      = %00000001
BG_OFF         = %00000000 ;bit 3 (4th from the right) is 0
BG_CLIPPED     = %00001000 ;bit 3 is 1, bg is clipped on leftmost 8 pixels of screen
BG_ON          = %00001010 ;bit 3 is 1, and bg is fully shown on screen
OBJ_OFF        = %00000000 ;bit 4 (5th from the right) is 0
OBJ_CLIPPED    = %00010000 ;bit 4 is 1, sprites are clipped on leftmost 8 pixels of screen
OBJ_ON         = %00010100 ;bit 4 is 1, and sprites are fully shown on screen
EMPHASIZE_R    = %00100000
EMPHASIZE_G    = %01000000
EMPHASIZE_B    = %10000000

.endif
