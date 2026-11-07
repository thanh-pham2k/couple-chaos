# Couple Chaos — Quy định & Cơ chế Multi-Agent

## 1. Cách làm việc
- Viết ngắn gọn, rõ ý theo *The Elements of Style* và TL;DR.
- Lời thoại trẻ trung, vui nhộn, bắt trend vừa đủ.
- Làm một mạch, hạn chế giải thích dài dòng.
- Mô tả Scene Blueprint bằng emoji/icon Unicode để dễ hình dung.

## 2. Multi-Agent & Subagent System (Chạy song song)
- **Cơ chế:** Khi có khối lượng việc lớn hoặc nhiều mảng độc lập, chia việc cho các subagent chạy song song qua công cụ `invoke_subagent` / `define_subagent`.
- **Phân vai subagent chuyên biệt:**
  * 🎨 **Asset & Media Agent:** Tạo prompt, cắt sprite, kiểm tra kích thước, anchor và tỉ lệ visual.
  * 💻 **Gameplay & Mechanics Agent:** Viết controller 2P, logic va chạm, nhặt/ném vật phẩm, tính điểm.
  * 🧪 **QA & Verification Agent:** Viết test, chạy kịch bản mô phỏng kiểm tra lỗi, bảo đảm game không crash.
- **Nguyên tắc song song:**
  * Mỗi agent làm việc trên file riêng biệt, tuyệt đối tránh 2 agent cùng sửa 1 file gây conflict.
  * Agent chính (Lead Orchestrator) chịu trách nhiệm giao task cụ thể, thu nhận kết quả và tích hợp tổng thể.

## 3. Định hướng Gameplay & Asset mới
- Chuẩn gameplay: Party Action 2 người (P1 Boy vs P2 Girl) theo [`gameplay-plan.md`](file:///Users/thanhpv/Documents/Work/couple-chaos/gameplay-plan.md).
- Chuẩn visual & layout: Tham khảo [`party-chaos.jpg`](file:///Users/thanhpv/Documents/Work/couple-chaos/party-chaos.jpg).

## 4. Quy chuẩn Kích thước & Anchor (Bắt buộc cho Asset Agent)
- Chi tiết đầy đủ tại: [`asset/plan/ASSET_RULES.md`](file:///Users/thanhpv/Documents/Work/couple-chaos/asset/plan/ASSET_RULES.md).
- Viewport chuẩn: `1920×1080` (Full HD), góc nghiêng Isometric 2.5D, PNG 32-bit trong suốt.
- **Quy tắc Anchor Y-Sort:** Tất cả nhân vật, pet, và đồ nội thất BẮT BUỘC đặt pivot tại `Bottom-Center` (điểm chân tiếp xúc sàn).
- **Kích thước chuẩn (Bounding Box):**
  * Nhân vật (`char_*`): `128×160` px.
  * Boss Mèo (`npc_*`): `64×64` px (bằng ~1/3 nhân vật).
  * Vật phẩm sàn (`item_*`): `64×64` px | Icon Hotbar: `48×48` px.
  * Bẫy sàn (`decal_*`): `128×80` px (trà sữa), `64×48` px (vỏ chuối).
  * Nội thất (`fur_*`): Sofa `260×160` px, Bàn trà `140×90` px, Bàn PC `180×140` px, Tủ lạnh `120×200` px.
  * UI Buttons: Búa `100×100` px, Lướt/Ném `72×72` px, Joystick `180×180` px.

