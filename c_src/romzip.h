/* romzip.h - the working ROM images straight from a MAME ROM set, for a host
 * with no Python to run disasm/image.py on (the headset).
 *
 * sw_rom_images_from_zips(dir) leaves in dir the images app.cpp loads
 * (starwars_main_rev1.bin, starwars_main_rev2.bin, starwars_bank1.bin,
 * starwars_sound.bin, starwars_mathbox.bin, starwars_avgprom.bin), made as
 * image.py makes them: the chips are found by CRC32 and size, whatever their
 * names, in every .zip in dir.
 */
#ifndef SW_ROMZIP_H
#define SW_ROMZIP_H

enum {
    SW_ROMZIP_OK = 0,       /* the images are there: already, or written now */
    SW_ROMZIP_NONE,         /* no images, and no .zip to make them from */
    SW_ROMZIP_BAD           /* a .zip, but not the starwars set: msg names a chip it lacks */
};
int sw_rom_images_from_zips(const char *dir, char *msg, unsigned msg_len);

#endif
