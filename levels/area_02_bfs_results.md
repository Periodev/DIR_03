# 第二區 BFS 紀錄

來源：`levels/area_02.txt`

| # | 關卡 | 最短指令數 | Discovered | Expanded | Peak frontier | 最短解 |
|---:|---|---:|---:|---:|---:|---|
| 1 | 直接碰撞 | 4 | 16 | 12 | 4 | `RRXT` |
| 2 | 對位碰撞 | 9 | 41 | 31 | 10 | `UUURULXLT` |
| 3 | 轉移碰撞 | 5 | 57 | 30 | 27 | `RDXDT` |
| 4 | 碰撞 + 折返 | 24 | 2,281 | 1,867 | 416 | `DDDXTDDRXRRDDRTUUULXUTLL` |
| 5 | 無向塊連續碰撞 | 12 | 792 | 527 | 265 | `UUDRXRRUXUTT` |
| 6 | 隔欄轉移 | 10 | 211 | 179 | 54 | `RRUXRRDXTT` |
| 7 | 連續碰撞 + 拉回 | 20 | 1,122 | 1,057 | 163 | `DDDLDRXRRDXDRTXTTRDD` |
| 8 | 彈射 | 11 | 176 | 151 | 34 | `RRUXRRRUXTT` |
| 9 | 碰撞L轉 | 14 | 734 | 593 | 143 | `DDDXLDLDRRRXTT` |
| 10 | 方向分散 + 折返 + 碰撞L轉 | 25 | 11,146 | 10,771 | 947 | `DDUXUDRXRURXLTUUDRTXTTRUU` |

`Discovered` 是去重後曾見過的狀態總數；`Expanded` 是實際從 BFS
frontier 取出並產生後繼的狀態數。
