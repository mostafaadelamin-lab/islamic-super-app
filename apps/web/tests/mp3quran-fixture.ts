/** A small answer shaped like mp3quran.net's API v3 (reciters, riwayat, radios), with bad entries mixed in. */
export const MP3_API = {
  reciters: {
    reciters: [
      {
        id: 153,
        name: "أخيل عبدالحي روا",
        moshaf: [
          {
            id: 153,
            name: "حفص عن عاصم - مرتل",
            rewaya_id: 1,
            server: "https://cdn.mp3quran.net/audio/akhil-rawa/r1/",
            surah_list: "50,51,52,56",
          },
        ],
      },
      {
        id: 7,
        name: "إبراهيم الأخضر",
        moshaf: [
          {
            id: 7,
            name: "حفص عن عاصم - مرتل",
            rewaya_id: 1,
            server: "https://server6.mp3quran.net/akdr",
            surah_list: "1,2,114,115,x,2",
          },
          { id: 70, name: "ورش عن نافع", rewaya_id: 2, server: "http://insecure.example/", surah_list: "1" },
          {
            id: 71,
            name: "ورش عن نافع",
            rewaya_id: 2,
            server: "https://cdn.mp3quran.net/warsh/",
            surah_list: "1,36",
          },
        ],
      },
      { id: 9, name: "بلا تلاوات", moshaf: [] },
      { name: "بلا رقم" },
    ],
  },
  riwayat: {
    riwayat: [
      { id: 1, name: "حفص عن عاصم" },
      { id: 2, name: "ورش عن نافع" },
    ],
  },
  radios: {
    radios: [
      { id: 1, name: "إبراهيم الأخضر", url: "https://backup.qurango.net/radio/ibrahim_alakdar" },
      { id: 2, name: "غير آمن", url: "http://example.com/radio" },
    ],
  },
};
