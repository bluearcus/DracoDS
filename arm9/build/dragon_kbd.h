
//{{BLOCK(dragon_kbd)

//======================================================================
//
//	dragon_kbd, 256x256@8, 
//	+ palette 256 entries, not compressed
//	+ 556 tiles (t|f reduced) lz77 compressed
//	+ regular map (in SBBs), lz77 compressed, 32x32 
//	Total size: 512 + 9212 + 1676 = 11400
//
//	Time-stamp: 2026-01-22, 15:23:49
//	Exported by Cearn's GBA Image Transmogrifier, v0.9.2
//	( http://www.coranac.com/projects/#grit )
//
//======================================================================

#ifndef GRIT_DRAGON_KBD_H
#define GRIT_DRAGON_KBD_H

#define dragon_kbdTilesLen 9212
extern const unsigned int dragon_kbdTiles[2303];

#define dragon_kbdMapLen 1676
extern const unsigned short dragon_kbdMap[838];

#define dragon_kbdPalLen 512
extern const unsigned short dragon_kbdPal[256];

#endif // GRIT_DRAGON_KBD_H

//}}BLOCK(dragon_kbd)
