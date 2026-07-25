# 第二區 BFS 紀錄

來源：`levels/area_02.txt`

| # | 關卡 | 最短指令數 | Discovered | Expanded | Peak frontier | 最短解 |
|---:|---|---:|---:|---:|---:|---|
| 1 | 直接碰撞 | 4 | 16 | 12 | 4 | `RRXT` |
| 2 | 對位碰撞 | 9 | 41 | 31 | 10 | `UUURULXLT` |
| 3 | 封口對位碰撞 | 17 | 2,250 | 1,841 | 428 | `RDRRUXUUURRUUUTDD` |
| 4 | 轉移碰撞 | 10 | 223 | 175 | 49 | `RRDXDDRXTT` |
| 5 | 碰撞 + 折返 | 24 | 2,281 | 1,867 | 416 | `DDDXTDDRXRRDDRTUUULXUTLL` |
| 6 | 無向塊連續碰撞 | 12 | 723 | 519 | 204 | `UUDRXRRUXUTT` |
| 7 | 連續碰撞 + 拉回 | 20 | 1,122 | 1,057 | 163 | `DDDLDRXRRDXDRTXTTRDD` |
| 8 | 接力碰撞 | 22 | 1,224 | 1,180 | 118 | `DRRRUXDRRLUXDRRRLUTXTT` |
| 9 | 碰撞L轉 | 14 | 734 | 593 | 143 | `DDDXLDLDRRRXTT` |
| 10 | 方向分散 + 折返 + 碰撞L轉 | 25 | 11,146 | 10,771 | 947 | `DDUXUDRXRURXLTUUDRTXTTRUU` |

`Discovered` 是去重後曾見過的狀態總數；`Expanded` 是實際從 BFS
frontier 取出並產生後繼的狀態數。
