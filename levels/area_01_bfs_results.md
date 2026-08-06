# 第一區 BFS 紀錄

來源：`levels/area_01.txt`

| ID | 關卡 | 最短指令數 | Discovered | Expanded | Peak frontier | 最短解 |
|---:|---|---:|---:|---:|---:|---|
| 1-0 | 推動 | 11 | 149 | 106 | 43 | `RRRURDDDDRR` |
| 1-1 | L 轉 | 8 | 105 | 75 | 32 | `RRDRUXUT` |
| 1-2 | 轉移 | 8 | 116 | 60 | 56 | `DRUURXRT` |
| 1-3 | 拉回 | 11 | 94 | 85 | 20 | `DDDRRUXLTRR` |
| 1-4 | 方向分散 | 12 | 209 | 180 | 34 | `RDLXURRRDXTT` |
| 1-5 | 隔欄轉移 | 10 | 211 | 179 | 54 | `RRUXRRDXTT` |
| 1-6 | 雙向拉回 | 17 | 159 | 145 | 19 | `DDDLLUXDTUURXTRUU` |
| 1-7 | 折返閃避 | 14 | 391 | 342 | 62 | `DDDRDRUXUURTLL` |
| 1-8 | 折返拉回 | 19 | 977 | 891 | 102 | `DDDLUXURDXULLTRRRRT` |
| 1-9 | Exchange | 16 | 547 | 451 | 104 | `RDDLUXDTUUDXRTLL` |
| 1-10 | 反轉 | 17 | 622 | 585 | 80 | `LLLULLDRXRURTDXDT` |
| 1-11 | 發條 | 31 | 10,443 | 10,089 | 692 | `RDLLUXDLLUULTRXRUXRRUTTXRRRUTXT` |

`Discovered` 是去重後曾見過的狀態總數；`Expanded` 是實際從 BFS
frontier 取出並產生後繼的狀態數。
