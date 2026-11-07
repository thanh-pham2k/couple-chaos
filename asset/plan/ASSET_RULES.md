# Quy Chuẩn Kích Thước & Tỉ Lệ Asset (Asset Dimension & Anchor Contract)

Tài liệu quy định bắt buộc về kích thước (pixel), điểm neo (Anchor/Pivot) và chuẩn kỹ thuật để các Agent tạo asset và ghép vào Godot đồng bộ 100%, không bị lệch tỉ lệ hoặc lỗi phân lớp (Y-sort).

---

## 1. Chuẩn Canvas & Viewport Game
* **Độ phân giải hiển thị chuẩn (Target Viewport):** `1920 × 1080` (Full HD, tỉ lệ 16:9).
* **Góc nhìn (Camera Perspective):** Isometric 2.5D (góc nghiêng ~30° đến 45° nhìn từ trên xuống).
* **Định dạng file:** PNG 32-bit (RGBA, nền trong suốt hoàn toàn, viền cắt sát rìa vừa đủ, không dính halo trắng).

---

## 2. Bảng Kích Thước Tiêu Chuẩn Cho Từng Nhóm

| Nhóm Asset | Mã Nhóm | Kích Thước Canvas (W × H px) | Điểm Neo (Pivot / Anchor) | Ghi chú & Tỉ lệ thị giác |
| :--- | :--- | :---: | :---: | :--- |
| **Nhân vật** | `char_*` | **128 × 160** px | `Bottom-Center` (64, 150) | Chibi đầu to thân nhỏ, chiều cao chuẩn ~140–150px. |
| **Thú cưng (Boss Mèo)**| `npc_*` | **64 × 64** px | `Bottom-Center` (32, 58) | Bằng ~1/3 chiều cao nhân vật. |
| **Vũ khí / Cầm tay** | `item_*` (Trên sàn) | **64 × 64** px | `Center` (32, 32) | Có viền highlight nhẹ, khi cầm gắn vào tay nhân vật. |
| **Vũ khí / Hotbar Icon**| `item_*_icon` | **48 × 48** px | `Center` (24, 24) | Dùng cho UI Hotbar dưới đáy màn hình. |
| **Bẫy sàn & Vết bẩn** | `decal_*` | **128 × 80** px (trà sữa)<br>**64 × 48** px (vỏ chuối) | `Center` hoặc `Bottom-Center` | Dẹt theo phối cảnh mặt sàn, Z-index dưới chân nhân vật. |
| **Hiệu ứng VFX** | `vfx_*` | **128 × 128** px | `Center` (64, 64) | Tự giải phóng (queue_free) sau 0.3s – 1.0s. |

---

## 3. Quy Chuẩn Nội Thất & Môi Trường (Furniture Bounds)

| Món Nội Thất | Mã Asset | Kích Thước (W × H px) | Điểm Neo (Y-Sort Pivot) |
| :--- | :--- | :---: | :---: |
| **Sofa dài 3 chỗ** | `fur_sofa` | **260 × 160** px | `Bottom-Center` (chân trước sofa) |
| **Bàn trà phòng khách** | `fur_coffee_table` | **140 × 90** px | `Bottom-Center` |
| **Bàn làm việc + Laptop**| `fur_workstation` | **180 × 140** px | `Bottom-Center` |
| **Ghế xoay văn phòng** | `fur_office_chair` | **80 × 90** px | `Bottom-Center` |
| **Giường ngủ đôi** | `fur_bedroom_bed` | **240 × 260** px | `Bottom-Center` |
| **Tủ lạnh 2 cánh** | `fur_fridge` | **120 × 200** px | `Bottom-Center` |
| **Kệ bếp & Chậu rửa** | `fur_kitchen_counter` | **220 × 140** px | `Bottom-Center` |
| **Kệ TV + Tivi** | `fur_tv_console` | **200 × 160** px | `Bottom-Center` |
| **Bàn ăn + 2 ghế** | `fur_dining_set` | **160 × 140** px | `Bottom-Center` |

---

## 4. Quy Chuẩn Giao Diện Người Dùng (UI / HUD)

* **Khung Avatar P1 & P2:** `96 × 96` px (tròn, viền viền pastel nổi bật).
* **Icon Tim máu ❤️:** `32 × 32` px.
* **Thanh thể lực (Stamina Bar):** `160 × 20` px.
* **Virtual Joystick:**
  * Đế ngoài (Base): `180 × 180` px (trong suốt 40%).
  * Núm gạt (Stick): `80 × 80` px.
* **Bộ nút kỹ năng (Action Buttons):**
  * Nút chính Đập Búa 🔨: `100 × 100` px.
  * Nút Lướt 🏃: `72 × 72` px.
  * Nút Nhặt / Ném 🖐️: `72 × 72` px.
* **Thanh Hotbar:**
  * Khung tổng: `360 × 72` px (chứa 5 ô).
  * Mỗi ô chứa đồ (Slot): `60 × 60` px.

---

## 5. Nguyên Tắc Vàng Khi Agent Tạo Asset
1. **Quy tắc Y-Sort:** Tất cả nhân vật, pet, và đồ nội thất **BẮT BUỘC** đặt điểm neo (Anchor/Pivot) tại **chân tiếp xúc mặt sàn** (`Bottom-Center`). Không neo ở giữa hình để tránh bị lỗi nhân vật đi xuyên đè lên đồ vật.
2. **Quy tắc Tỉ lệ tương đối:**
   * Mèo = 1/3 Người.
   * Gối / Búa = 1/2 thân người.
   * Cốc trà sữa / Vỏ chuối = 1/4 thân người.
   * Sofa dài = gấp đôi chiều ngang người.
3. **Quy tắc Batching:** Tạo asset theo batch 4–8 sprite để giữ nguyên bảng màu (Palette) và độ dày nét viền (Outline 2-3px mượt mà).
