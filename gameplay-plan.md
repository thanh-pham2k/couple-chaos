# Couple Chaos — Kế hoạch Gameplay 2 Người (Party Action Dual-Player)

Tài liệu thiết kế chế độ chơi 2 người (P1 Bạn Trai & P2 Bạn Gái) theo định hướng Party Action đối kháng/phối hợp thời gian thực.
Tham khảo hình ảnh: `party-chaos.jpg`.

---

## 1. Tổng quan & Vibe
* **Thể loại:** Party Action / Co-op & PvP Couch Game (vibe *Tom & Jerry* x *Overcooked* phong cách chibi 2D).
* **Góc nhìn:** Top-down nghiêng (Isometric 2.5D), toàn cảnh căn phòng 960×540 (hoặc full HD 1920×1080).
* **Nhịp độ:** 2–3 phút / round (⏱️ Timer đếm ngược), hành động liên tục, vật lý cartoon vui nhộn.

---

## 2. Hệ thống Điều khiển (Mobile Controls)

* **Phía trái:** Virtual Joystick 🕹️ di chuyển 8 hướng.
* **Phía phải (3 nút hành động):**
  * 🔨 **Dùng đồ (Action / Attack):** Phang búa, vung gối, kích hoạt item đang cầm.
  * 🏃 **Lướt nhanh (Dash / Sprint):** Tăng tốc né đòn / bứt phá (tiêu hao thanh thể lực ⚡).
  * 🖐️ **Tương tác / Nhặt & Ném (Grab / Throw):** Nhặt vật phẩm dưới sàn, ném cản đường đối phương.
* **Thanh Hotbar (Bottom Center):** Chứa các item nhặt được trong phòng (gối, búa, vỏ chuối, hộp xốp, cốc trà sữa).

---

## 3. Hệ thống Nhiệm vụ Song Song (Dual-Quest System)

Cả hai người chơi đều có bảng nhiệm vụ độc lập hiển thị góc màn hình:

### Chế độ 1: "Người Dọn vs Kẻ Phá" (Asymmetrical PvP)
* **👦 P1 (Bạn Trai) — Nhiệm vụ Sinh tồn & Dọn dẹp:**
  * 🧋 Lau sạch 2 bãi trà sữa đổ trên sàn.
  * 📚 Gom 3 cuốn sách vứt lung tung trả về giá.
  * 💻 Cắm lại nguồn laptop để không mất file code.
  * 🐱 Bắt con mèo đang chạy loạn đặt về nệm.
  * ❤️ Bảo toàn tối thiểu 1 tim (né búa của bạn gái).
* **👧 P2 (Bạn Gái) — Nhiệm vụ Gây Hỗn Loạn (Chaos 5/5):**
  * 🔨 Vung búa đập trúng bạn trai 3 lần.
  * 🍿 Hất tung xô bắp rang bơ ra thảm phòng khách.
  * 🍌 Đặt 2 bẫy vỏ chuối khiến bạn trai trượt té.
  * 🛏️ Ném gối bay lông vũ làm mù màn hình của bạn trai trong 3s.

### Chế độ 2: "Tranh Đồ Chuẩn Bị Đi Chơi" (Race to Win)
* Cả 2 cùng đua gom đủ 5 món đồ cá nhân vào vali của mình trước khi hết giờ.
* Đồ của Trai: Ví tiền 👛, Laptop 💻, Gamepad 🎮, Chìa khoá xe 🔑.
* Đồ của Gái: Son môi 💄, Váy 👗, Trà sữa 🧋, Túi xách 👜.
* Tương tác: Dùng búa gõ choáng đối phương để cướp đồ hoặc làm rơi đồ.

### Chế độ 3: "5 Phút Trước Khi Phụ Huynh Gõ Cửa" (Co-op Chaos)
* Cả hai cùng hợp lực dọn sạch căn phòng trước khi ⏱️ đếm ngược về 0.
* Vừa dọn vừa có thể trượt vỏ chuối hoặc ném đồ nhầm vào mặt nhau tạo tiếng cười.

---

## 4. Scene Blueprint (Isometric Action Layout)

```text
[P1: 👦 Trai ❤️❤️❤️❤️ ⚡]  📋 Nhiệm vụ: Gây hỗn loạn! ⭐ 3/5  ⏱️ 02:18  [P2: 👧 Gái ❤️❤️❤️❤️ ⚡]
───────────────────────────────────────────────────────────────────────────────────
  💻 Bàn code                      🚪 Cửa chính                  🧊 Tủ lạnh
  (Bừa bộn, đèn bàn)              (Kệ giày, dép văng)            (Gắn sticker couple)

        🏃‍♂️ P1 ôm gối chạy           🐱 Mèo hoảng hốt         🏃‍♀️ P2 vung búa dí
        [💨 Khói / Lông vũ]         [ 🧋 Trà sữa đổ ]        [ ⭐ Tia giận dữ ]

  🕹️ Joystick                     ☕ Bàn trà (Bánh kẹo)     [🔨 Phang] [🏃 Lướt] [🖐️ Ném]
  [D-pad điều hướng]              🛋️ Sofa dài              [ 🛏️ 🔨 🍌 📦 🧋 Hotbar ]
```

---

## 5. Danh mục Vật phẩm & Tác động (Items & Hazards)

| Vật phẩm | Icon | Cách nhặt / xuất hiện | Hiệu ứng khi dùng / ném |
| :--- | :---: | :--- | :--- |
| **Búa hơi đồ chơi** | 🔨 | Nhặt từ sofa / sàn | Đập cận chiến gây choáng (Stun) 1.5s, rơi đồ trên tay. |
| **Gối lông vũ** | 🛏️ | Có sẵn trên sofa | Ném tầm xa, khi trúng nổ tung lông vũ che tầm nhìn. |
| **Vỏ chuối** | 🍌 | Ăn chuối / nhặt từ bàn | Đặt bẫy sàn, ai dẫm phải trượt dài 2m và té ngã. |
| **Cốc trà sữa** | 🧋 | Nhặt trên bàn trà | Ném tạo vũng trơn bẩn, người dọn phải tốn thời gian lau. |
| **Thùng các-tông** | 📦 | Ở góc cửa | Đội lên đầu để tàng hình / né một đòn búa. |
| **Mèo cam** | 🐱 | NPC tự do | Chạy hoảng loạn khi có người lướt qua, quẹt trúng ai người đó giật mình. |

---

## 6. Kế hoạch triển khai kỹ thuật (Godot 4)

1. **Phase 1 — Character Controller 2P:**
   - Tạo CharacterBody2D cho Boy và Girl với di chuyển 8 hướng + Dash (tiêu hao Stamina).
   - Hỗ trợ 2 người chơi cùng máy (chia nửa màn hình / 2 gamepad) hoặc Local Wifi / Bluetooth.
2. **Phase 2 — Item & Pick/Drop System:**
   - Hệ thống nhặt (Grab), ném (Throw) và sử dụng (Use) qua Hotbar.
3. **Phase 3 — Hazard & Environment Physics:**
   - Vũng trượt (trà sữa, vỏ chuối), lông vũ bay, phản xạ va chạm vật cản (sofa, bàn, tủ lạnh).
4. **Phase 4 — Quest Tracker & HUD:**
   - Logic kiểm tra điều kiện hoàn thành (3/5, 5/5) và Timer đếm ngược.
