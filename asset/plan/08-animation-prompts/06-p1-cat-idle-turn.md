# Nhiệm vụ độc lập — Couple Chaos

Bạn là agent tạo sprite sheet. Hãy tạo đầy đủ các sheet bên dưới, không hỏi lại. Chỉ tạo và kiểm tra asset; không sửa code, scene hay asset gốc. Nếu công cụ tạo ảnh hoặc chất lượng không đáp ứng, ghi rõ phần chưa đạt, không báo hoàn thành giả.

Dự án: `/Users/thanhpv/Documents/Work/couple-chaos`. Đọc `AGENTS.md`, `asset/plan/ASSET_RULES.md`, xem `party-chaos.jpg` và các ảnh tham chiếu chỉ định bên dưới. Giữ đúng nhân vật và phong cách hiện có. Lưu kết quả vào `assets/animation_pending/` với đúng tên file; không ghi đè asset gốc. Các file cùng thư mục chỉ có tên riêng của nhiệm vụ này; không sửa kết quả của nhiệm vụ khác.

Phong cách: cozy chibi anime 2D, màu pastel ấm, nét viền nâu mượt 2–3 px, góc nhìn isometric 2.5D 30–45°. PNG 32-bit RGBA, nền trong suốt, không halo. Các frame nằm liên tiếp từ trái sang phải, cùng tỉ lệ, camera, ánh sáng và thiết kế. Không chữ, watermark, đường kẻ, bóng đổ, bụi, vệt tốc độ, biểu tượng hoặc hiệu ứng gắn vào sprite. Không cắt cụt cơ thể, không lặp pose tĩnh để giả animation. Hướng down nhìn thấy mặt, right nhìn sang phải, up nhìn thấy lưng; left dùng lật ngang right. Kiểm tra và ghi chú nếu thiết kế bất đối xứng làm lật ngang không phù hợp.

Tham chiếu mèo: `assets/pets/cat/sleep.png`, `run.png`, `startled.png`, `hiss.png` và `asset/plan/02-pets/`. Giữ mèo mướp cam thân tròn chân ngắn, sọc đậm, bụng trắng và đặc điểm thực tế của ảnh gốc. Mỗi ô 64×64 px; pivot chân (32, 58). Không thay đổi căn chỉnh ô khi mèo nhảy.

## P1 — Mèo idle và quay hướng

Tạo `cat_idle_down.png`, `cat_idle_right.png`, `cat_idle_up.png`: mỗi sheet 4 frame, tổng 256×64 px, đứng thư giãn, thở nhẹ, chớp mắt hoặc nhúc nhích tai, loop mượt.

Tạo `cat_turn_down_to_right.png` và `cat_turn_right_to_up.png`: mỗi sheet 4 frame, tổng 256×64 px, gồm hướng đầu, hai tư thế trung gian, hướng cuối. Chân, đầu và thân quay tự nhiên; frame đầu/cuối khớp idle tương ứng. Đây là chuyển tiếp một lần; hướng ngược đọc frame ngược, hướng trái lật ngang.

## Kiểm tra và bàn giao

Kiểm tra đúng tên, kích thước, số ô, alpha, pivot, không cắt cụt; xem từng frame và phát thử chuỗi để kiểm tra trùng frame, nhảy vị trí, biến dạng và chuyển tiếp. Ghi kết quả, hạn chế và đường dẫn từng sheet vào file báo cáo riêng của nhiệm vụ trong `assets/animation_pending/`. Không khẳng định đã tích hợp hoặc kiểm thử trong Godot. Nếu sheet không đạt, ghi rõ và giữ trạng thái chưa đạt.
