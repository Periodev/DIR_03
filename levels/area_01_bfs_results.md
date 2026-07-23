# 第一區 BFS 紀錄

來源：`levels/area_01.txt`

| # | 關卡 | 最短指令數 | Discovered | Expanded | Peak frontier | 最短解 |
|---:|---|---:|---:|---:|---:|---|
| 1 | L 轉 | 8 | 41 | 31 | 10 | `RRDRUXUT` |
| 2 | 轉移 | 8 | 103 | 57 | 46 | `DRUURXRT` |
| 3 | 拉回 | 11 | 76 | 67 | 15 | `DDDRRUXLTRR` |
| 4 | 方向分散 | 12 | 201 | 172 | 34 | `RDLXURRRDXTT` |
| 5 | 雙向拉回 | 17 | 117 | 109 | 17 | `DDDLLUXDTUURXTRUU` |
| 6 | 折返閃避 | 15 | 348 | 300 | 52 | `DDDRRDRUXUURTLL` |
| 7 | 雙向拉回（困難） | 19 | 939 | 849 | 97 | `DDDLUXURDXULLTRRRRT` |
| 8 | 反轉 | 19 | 855 | 807 | 108 | `LLLULLDRXRURTDXDDDT` |
| 9 | 綜合 | 33 | 12,273 | 11,170 | 1,106 | `LLULLDDUXLTRRRDXDRRULXLLTTLDXDDDT` |

`Discovered` 是去重後曾見過的狀態總數；`Expanded` 是實際從 BFS
frontier 取出並產生後繼的狀態數。
