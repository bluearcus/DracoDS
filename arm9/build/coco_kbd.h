
//{{BLOCK(coco_kbd)

//======================================================================
//
//	coco_kbd, 256x256@8, 
//	+ palette 256 entries, not compressed
//	+ 590 tiles (t|f reduced) lz77 compressed
//	+ regular map (in SBBs), lz77 compressed, 32x32 
//	Total size: 512 + 11308 + 1736 = 13556
//
//	Time-stamp: 2026-01-22, 15:23:50
//	Exported by Cearn's GBA Image Transmogrifier, v0.9.2
//	( http://www.coranac.com/projects/#grit )
//
//======================================================================

#ifndef GRIT_COCO_KBD_H
#define GRIT_COCO_KBD_H

#define coco_kbdTilesLen 11308
extern const unsigned int coco_kbdTiles[2827];

#define coco_kbdMapLen 1736
extern const unsigned short coco_kbdMap[868];

#define coco_kbdPalLen 512
extern const unsigned short coco_kbdPal[256];

#endif // GRIT_COCO_KBD_H

//}}BLOCK(coco_kbd)
