# Couple Chaos — Danh Mục Từng Asset Cốt Lõi (Asset Breakdown)

Danh sách phân tách chi tiết: **7 Nhóm chính ➔ 30 Mục con (mỗi mục là 1 asset độc lập)** phục vụ trực tiếp cho việc vẽ prompt, cắt sprite và tích hợp vào Godot.

---

## 👫 NHÓM 1: NHÂN VẬT (CHARACTERS)

### 1.1 `char_boy_p1` — Bạn Trai (P1)
* **Visual:** Chibi tóc rối nâu hạt dẻ, áo thun trắng cộc tay, quần âu tối màu, giày sneaker.
* **Bộ Sprite:** 
  * Di chuyển 8 hướng (`run_8dir`)
  * Lướt nhanh (`dash`)
  * Ôm đồ trước ngực (`carry`)
  * Vung đập / Vụt cận chiến (`swing`)
  * Ném đồ xa (`throw`)
  * Trượt té ngửa chổng vó (`slip_fall`)
  * Choáng ôm đầu (`stunned`)

### 1.2 `char_girl_p2` — Bạn Gái (P2)
* **Visual:** Chibi tóc nâu xoăn buộc nơ hồng to, áo phông vàng năng động, quần short thể thao viền trắng, giày sneaker hồng.
* **Bộ Sprite:**
  * Di chuyển 8 hướng (`run_8dir`)
  * Lướt nhanh truy đuổi (`dash`)
  * Ôm đồ trước ngực (`carry`)
  * Giơ hai tay đập búa uy lực (`slam_hammer`)
  * Ném đồ bực tức (`throw`)
  * Dậm chân phồng má giận dữ (`angry_pout`)
  * Nhảy cẫng ăn mừng chiến thắng (`victory`)

---

## 🐱 NHÓM 2: THÚ CƯNG & NPC (PETS & NPCS)

### 2.1 `npc_orange_cat` — Boss Mèo Cam
* **Visual:** Mèo mướp cam sọc đậm, thân tròn béo mầm, mắt to tròn.
* **Bộ Sprite:**
  * Nằm cuộn tròn ngủ tít (`sleep`)
  * Bật ngửa 4 chân hoảng hốt mắt `!!` (`startled`)
  * Phi nước đại 4 chân bay khói (`sprint`)
  * Giơ vuốt cào nhẹ khi bị dẫm đuôi (`hiss`)

---

## 🛋️ NHÓM 3: MÔI TRƯỜNG & NỘI THẤT (ENVIRONMENT & FURNITURE)

### 3.1 `env_floor_carpet` — Nền sàn & Thảm đa phòng
* **Visual:** Gạch gỗ sồi sáng màu (phòng khách/ngủ), gạch men trắng vuông (khu bếp), kèm tấm thảm dệt tròn viền tua rua đặt giữa phòng khách.

### 3.2 `env_wall_door` — Tường nhà & Cửa chính
* **Visual:** Tường tone màu be/kem ấm áp, cửa ra vào bằng gỗ sồi có tay nắm tròn, bên cạnh có kệ để giày dép và thảm chùi chân.

### 3.3 `fur_workstation` — Bàn làm việc P1
* **Visual:** Bàn gỗ chữ nhật, trên bàn có màn hình laptop bật sáng (dòng code xanh lá), đèn bàn học sáng vàng và cốc cà phê.

### 3.4 `fur_office_chair` — Ghế xoay công thái học
* **Visual:** Ghế văn phòng màu xám đen có bánh xe, tự động xoay và trôi nhẹ khi bị nhân vật chạy va vào.

### 3.5 `fur_sofa` — Sofa văng phòng khách
* **Visual:** Ghế sofa bọc vải nỉ xanh rêu vintage dài 3 chỗ, có đệm tựa lưng và khăn dệt kẻ sọc vắt ngang.

### 3.6 `fur_coffee_table` — Bàn trà phòng khách
* **Visual:** Bàn trà gỗ thấp hình bo góc đặt trước sofa, trên mặt bàn có đĩa bánh quy và chậu cây xanh nhỏ.

### 3.7 `fur_tv_console` — Kệ TV & Máy chơi game
* **Visual:** Kệ tủ gỗ thấp kê sát tường, đặt tivi màn hình phẳng, máy console và 2 tay cầm game.

### 3.8 `fur_bedroom_bed` — Giường ngủ đôi
* **Visual:** Giường nệm đôi ga trắng phủ chăn hồng, đầu giường có gối ngủ (điểm spawn gối ôm liên tục).

### 3.9 `fur_fridge` — Tủ lạnh 2 cánh
* **Visual:** Tủ lạnh màu kem pastel phong cách retro, cánh tủ dán nhiều sticker trái tim, nam châm và giấy note vàng.

### 3.10 `fur_kitchen_counter` — Kệ bếp & Bồn rửa chén
* **Visual:** Mặt đá bếp vân mây, chậu rửa bát inox có vòi nước (khu vực có nguy cơ tạo vũng nước trơn).

### 3.11 `fur_dining_set` — Bàn ăn & 2 Ghế
* **Visual:** Bàn ăn gỗ tròn nhỏ xinh kèm 2 ghế ăn bọc nệm, giữa bàn có bình hoa cúc họa mi.

---

## 🔨 NHÓM 4: VẬT PHẨM CẦM TAY & VŨ KHÍ (WEAPONS & PICKUPS)

### 4.1 `item_toy_hammer` — Búa hơi đồ chơi
* **Visual:** Búa đồ chơi đầu vàng in ngôi sao đỏ, cán cầm màu hồng tím (vũ khí đập gây choáng).

### 4.2 `item_pillow` — Gối ôm lông vũ
* **Visual:** Chiếc gối vuông màu hồng phấn in hình dấu chân mèo (ném phát nổ lông vũ).

### 4.3 `item_boba_tea` — Cốc trà sữa trân châu
* **Visual:** Ly nhựa trong suốt nhìn rõ trà sữa và trân châu đen, nắp màng ép dán hình tim (uống tăng tốc hoặc ném tạo bãi bẩn).

### 4.4 `item_popcorn_bucket` — Xô bắp rang bơ
* **Visual:** Xô giấy sọc đỏ trắng đầy ắp bắp rang vàng ươm (ném đổ tung toé cản bước).

### 4.5 `item_banana` — Quả chuối / Vỏ chuối
* **Visual:** Nải chuối vàng óng; khi ăn xong biến thành vỏ chuối 3 cánh xoè dùng làm bẫy trượt.

### 4.6 `item_cardboard_box` — Thùng các-tông
* **Visual:** Thùng các-tông dán băng keo vuông vức, khoét 2 lỗ mắt (dùng úp lên người để trốn / đỡ đòn).

### 4.7 `item_wallet` — Ví tiền & Thẻ ngân hàng
* **Visual:** Chiếc ví gập da nâu kẹp thẻ tín dụng vàng lấp lánh (vật phẩm nhiệm vụ giằng co).

### 4.8 `item_gamepad` — Tay cầm chơi game
* **Visual:** Tay cầm console màu trắng hai cần analog (vật phẩm nhiệm vụ thu thập của P1).

---

## 🧋 NHÓM 5: BẪY SÀN & VẾT BẨN (GROUND HAZARDS & DECALS)

### 5.1 `decal_boba_spill` — Vũng trà sữa đổ
* **Visual:** Vũng nước trà sữa nâu sẫm loang lổ trên sàn kèm hạt trân châu văng quanh (giảm tốc 40%).

### 5.2 `decal_popcorn_mess` — Đống bắp rang vương vãi
* **Visual:** Cụm hàng chục hạt bắp rang vàng rải rác trên thảm sàn (bước vào phát ra âm thanh lộ vị trí).

### 5.3 `decal_banana_peel` — Bẫy vỏ chuối
* **Visual:** Vỏ chuối màu vàng tươi nằm dẹt trên mặt sàn, có vệt trượt dài phía sau khi có người dẫm phải.

### 5.4 `decal_dropped_books` — Đống sách rơi
* **Visual:** 2-3 cuốn sách bìa màu xanh/đỏ nằm xòe trang trên sàn (vật cản chặn đường di chuyển).

### 5.5 `decal_feather_heap` — Lông vũ rụng
* **Visual:** Đám lông vũ tơi xốp màu trắng vương quanh khu vực gối vừa nổ.

---

## ✨ NHÓM 6: HIỆU ỨNG HÌNH ẢNH (VFX & PARTICLES)

### 6.1 `vfx_feather_explosion` — Nổ lông vũ
* **Visual:** Vụ nổ hạt bung toả 15-20 cọng lông vũ trắng bay lượn từ tâm va chạm.

### 6.2 `vfx_stun_stars` — Sao choáng đầu
* **Visual:** 3 ngôi sao vàng 5 cánh xoay tròn theo quỹ đạo elip quanh đỉnh đầu nhân vật.

### 6.3 `vfx_dash_dust` — Khói lướt chân
* **Visual:** 2 cụm khói trắng tròn cuộn ra sau gót chân khi nhân vật kích hoạt tốc biến/lướt.

### 6.4 `vfx_comic_hit` — Bùng nổ va chạm Comic
* **Visual:** Đốm sao nổ dạng truyện tranh kèm tia nhọn (comic impact star) phát sáng khi búa đập trúng người.

### 6.5 `vfx_emotion_pop` — Cảm xúc biểu cảm
* **Visual:** Icon dấu chấm than `!!`, tia sét bực bội `💢`, hoặc tim hồng `💖` nảy lên trên đầu nhân vật.

---

## 📱 NHÓM 7: GIAO DIỆN NGƯỜI DÙNG (UI & HUD)

### 7.1 `ui_hud_p1` — Cụm chỉ số Bạn Trai (Top-Left)
* **Visual:** Khung avatar tròn mặt Boy + dải 4 icon tim hồng ❤️ + thanh thể lực stamina màu vàng sọc sét ⚡.

### 7.2 `ui_hud_p2` — Cụm chỉ số Bạn Gái (Top-Right)
* **Visual:** Khung avatar tròn mặt Girl gắn nơ + dải 4 icon tim hồng ❤️ + thanh thể lực stamina vàng ⚡.

### 7.3 `ui_mission_tracker` — Bảng nhiệm vụ & Đồng hồ (Top-Center)
* **Visual:** Đồng hồ nền đen viền vàng đếm ngược `⏱️ 02:00` + 2 khung thẻ checklist tiến độ của P1 và P2 (dạng `⭐ 3/5`).

### 7.4 `ui_virtual_joystick` — Cần điều hướng ảo (Bottom-Left)
* **Visual:** Đế tròn mờ trong suốt + núm joystick viền trắng có 4 mũi tên điều hướng xúc giác.

### 7.5 `ui_action_buttons` — Bộ 3 nút bấm kỹ năng (Bottom-Right)
* **Visual:** 
  * Nút lớn tròn màu hồng in icon Búa 🔨 (Tấn công)
  * Nút nhỏ vàng in icon Người chạy 🏃 (Lướt)
  * Nút nhỏ xanh dương in icon Bàn tay mở 🖐️ (Nhặt / Ném / Dọn)

### 7.6 `ui_hotbar` — Thanh trang bị vật phẩm (Bottom-Center)
* **Visual:** Khung thanh ngang gồm 5 ô vuông bo góc viền cam sữa, ô đang chọn có viền đỏ nhấp nháy, kèm số lượng vật phẩm nhỏ ở góc.
