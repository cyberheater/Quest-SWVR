/* romzip.cpp - the working ROM images from a MAME ROM set (romzip.h): what
 * disasm/image.py does, for a host that cannot run it. */
#include <dirent.h>
#include <cstdint>
#include <cstdio>
#include <cstring>
#include <string>
#include <vector>
#include "romzip.h"
extern "C" {
#include "platform/windows/miniz.h"
}

/* image.py's CHIPS: part, CRC32, size */
enum { F214, F114, HJ102, JK203, KL104, M206, L105, JK107, H208, H110, J111, K112, L113, B109, N_CHIPS };
static const struct { const char *part; uint32_t crc; uint32_t size; } chips[N_CHIPS] = {
    { "136021-214.1f",  0x04F1876E, 0x4000 },       /* rev 2: $6000 bank 0 / bank 1 */
    { "136021-114.1f",  0xE75FF867, 0x4000 },       /* rev 1 */
    { "136021-102.1hj", 0xF725E344, 0x2000 },       /* $8000 */
    { "136021-203.1jk", 0xF6DA0A00, 0x2000 },       /* $A000 */
    { "136021-104.1kl", 0x7E406703, 0x2000 },       /* $C000 */
    { "136021-206.1m",  0xC7E51237, 0x2000 },       /* $E000 */
    { "136021-105.1l",  0x538E7D2F, 0x1000 },       /* vector ROM $3000 */
    { "136021-107.1jk", 0xDBF3AEA2, 0x2000 },       /* sound $4000 */
    { "136021-208.1h",  0xE38070A8, 0x2000 },       /* sound $6000 */
    { "136021-110.7h",  0x810E040E, 0x0400 },       /* mathbox PROMs */
    { "136021-111.7j",  0xAE69881C, 0x0400 },
    { "136021-112.7k",  0xECF22628, 0x0400 },
    { "136021-113.7l",  0x83FEBFDE, 0x0400 },
    { "136021-109.4b",  0x82FC3EB2, 0x0100 },       /* AVG state PROM */
};
/* the two bytes rev 2 differs in: address, rev 1, rev 2 */
static const struct { uint32_t at; uint8_t r1, r2; } rev2_patch[] = { { 0x6164, 0xB1, 0xB0 }, { 0x7A7C, 0x9C, 0x9D } };

static bool there(const std::string &path)
{
    FILE *f = fopen(path.c_str(), "rb");
    if (f) fclose(f);
    return f != nullptr;
}

static bool put(const std::string &path, const std::vector<uint8_t> &v)
{
    FILE *f = fopen(path.c_str(), "wb");
    if (!f) return false;
    const size_t n = fwrite(v.data(), 1, v.size(), f);
    return fclose(f) == 0 && n == v.size();
}

int sw_rom_images_from_zips(const char *dir, char *msg, unsigned msg_len)
{
    const std::string d = std::string(dir) + "/";
    if (msg_len) msg[0] = '\0';
    if (there(d + "starwars_main_rev2.bin") && there(d + "starwars_main_rev1.bin") && there(d + "starwars_bank1.bin") &&
        there(d + "starwars_sound.bin") && there(d + "starwars_mathbox.bin") && there(d + "starwars_avgprom.bin"))
        return SW_ROMZIP_OK;

    /* every .zip in the folder, every file in it: a chip is its CRC32 and size */
    std::vector<uint8_t> rom[N_CHIPS];
    int zips = 0;
    if (DIR *dp = opendir(dir)) {
        while (struct dirent *e = readdir(dp)) {
            const size_t n = strlen(e->d_name);
            if (n < 5 || strcasecmp(e->d_name + n - 4, ".zip")) continue;
            mz_zip_archive z;
            mz_zip_zero_struct(&z);
            if (!mz_zip_reader_init_file(&z, (d + e->d_name).c_str(), 0)) continue;
            zips++;
            for (mz_uint i = 0; i < mz_zip_reader_get_num_files(&z); i++) {
                mz_zip_archive_file_stat st;
                if (!mz_zip_reader_file_stat(&z, i, &st)) continue;
                for (int c = 0; c < N_CHIPS; c++) {
                    if (!rom[c].empty() || st.m_crc32 != chips[c].crc || st.m_uncomp_size != chips[c].size) continue;
                    rom[c].resize(chips[c].size);
                    if (!mz_zip_reader_extract_to_mem(&z, i, rom[c].data(), rom[c].size(), 0)) rom[c].clear();
                }
            }
            mz_zip_reader_end(&z);
        }
        closedir(dp);
    }
    if (!zips) return SW_ROMZIP_NONE;
    for (int c = 0; c < N_CHIPS; c++) {
        if (!rom[c].empty()) continue;
        if ((c == F214 && !rom[F114].empty()) || (c == F114 && !rom[F214].empty())) continue;     /* either revision will do */
        snprintf(msg, msg_len, "%s not found: no file of CRC %08X (%u bytes) in the .zip", chips[c].part,
                 (unsigned)chips[c].crc, (unsigned)chips[c].size);
        return SW_ROMZIP_BAD;
    }

    /* the images, as image.py lays them out */
    const std::vector<uint8_t> &one = rom[F214].empty() ? rom[F114] : rom[F214];
    std::vector<uint8_t> m(0x10000, 0xFF), m1, m2, snd(0x10000, 0xFF), mb;
    memcpy(&m[0x3000], rom[L105].data(), 0x1000);
    memcpy(&m[0x6000], one.data(), 0x2000);
    memcpy(&m[0x8000], rom[HJ102].data(), 0x2000);
    memcpy(&m[0xA000], rom[JK203].data(), 0x2000);
    memcpy(&m[0xC000], rom[KL104].data(), 0x2000);
    memcpy(&m[0xE000], rom[M206].data(), 0x2000);
    m1 = m2 = m;
    if (!rom[F114].empty()) memcpy(&m1[0x6000], rom[F114].data(), 0x2000);
    else for (auto &p : rev2_patch) m1[p.at] = p.r1;         /* each revision from the other, by the two bytes */
    if (!rom[F214].empty()) memcpy(&m2[0x6000], rom[F214].data(), 0x2000);
    else for (auto &p : rev2_patch) m2[p.at] = p.r2;
    memcpy(&snd[0x4000], rom[JK107].data(), 0x2000);
    memcpy(&snd[0xC000], rom[JK107].data(), 0x2000);
    memcpy(&snd[0x6000], rom[H208].data(), 0x2000);
    memcpy(&snd[0xE000], rom[H208].data(), 0x2000);
    for (int c = H110; c <= L113; c++) mb.insert(mb.end(), rom[c].begin(), rom[c].end());

    if (!put(d + "starwars_main_rev1.bin", m1) || !put(d + "starwars_main_rev2.bin", m2) ||
        !put(d + "starwars_bank1.bin", std::vector<uint8_t>(one.begin() + 0x2000, one.end())) ||
        !put(d + "starwars_sound.bin", snd) || !put(d + "starwars_mathbox.bin", mb) ||
        !put(d + "starwars_avgprom.bin", rom[B109])) {
        snprintf(msg, msg_len, "the images could not be written to %s", dir);
        return SW_ROMZIP_BAD;
    }
    return SW_ROMZIP_OK;
}
