DEFC FILE_NAME_BUFFER = $FA00 ; 256 bytes
DEFC FILE_BUFFER = $C000 ; 4k

; locations for global variables
DEFC VBR_SECTOR     = $FB00 ; 4 bytes
DEFC FAT_SECTOR     = $FB04 ; 4 bytes
DEFC DATA_SECTOR    = $FB08 ; 4 bytes
DEFC FAT_SIZE       = $FB0C ; 4 bytes
DEFC CLUSTER_SIZE   = $FB10 ; 1 byte
DEFC DIR_FILE_COUNT = $FB11 ; 1 byte
DEFC CURRENT_BLOCK  = $FB12 ; 4 bytes