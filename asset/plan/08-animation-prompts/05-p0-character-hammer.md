# Nhiệm vụ độc lập — Couple Chaos

Bạn là agent tạo sprite sheet. Hãy tạo đầy đủ các sheet bên dưới, không hỏi lại. Chỉ tạo và kiểm tra asset; không sửa code, scene hay asset gốc. Nếu công cụ tạo ảnh hoặc chất lượng không đáp ứng, ghi rõ phần chưa đạt, không báo hoàn thành giả.

Dự án: `/Users/thanhpv/Documents/Work/couple-chaos`. Đọc `AGENTS.md`, `asset/plan/ASSET_RULES.md`, xem `party-chaos.jpg` và các ảnh tham chiếu chỉ định bên dưới. Giữ đúng nhân vật và phong cách hiện có. Lưu kết quả vào `assets/animation_pending/` với đúng tên file; không ghi đè asset gốc. Các file cùng thư mục chỉ có tên riêng của nhiệm vụ này; không sửa kết quả của nhiệm vụ khác.

Phong cách: cozy chibi anime 2D, màu pastel ấm, nét viền nâu mượt 2–3 px, góc nhìn isometric 2.5D 30–45°. PNG 32-bit RGBA, nền trong suốt, không halo. Các frame nằm liên tiếp từ trái sang phải, cùng tỉ lệ, camera, ánh sáng và thiết kế. Không chữ, watermark, đường kẻ, bóng đổ, bụi, vệt tốc độ, biểu tượng hoặc hiệu ứng gắn vào sprite. Không cắt cụt cơ thể, không lặp pose tĩnh để giả animation. Hướng down nhìn thấy mặt, right nhìn sang phải, up nhìn thấy lưng; left dùng lật ngang right. Kiểm tra và ghi chú nếu thiết kế bất đối xứng làm lật ngang không phù hợp.

Tham chiếu Boy: `assets/characters/boy/idle.png`, `carry.png`, `run.png`, `swing.png`, `throw.png`. Tham chiếu Girl: các file cùng tên trong `assets/characters/girl/`; nếu thiếu tên nào, chọn pose gần nhất trong thư mục. Giữ đúng mặt, tóc, trang phục và tỉ lệ của từng nhân vật. Mỗi ô 128×160 px; pivot chân (64, 150). Vẽ nhân vật và tay, không vẽ vật phẩm vào sprite; tay phải thể hiện điểm nắm rõ để Godot gắn item riêng. Hai tay cầm búa cùng hướng tới một cán.

## P0 — Vung búa

Tạo 6 sheet `boy_hammer_down.png`, `boy_hammer_right.png`, `boy_hammer_up.png`, `girl_hammer_down.png`, `girl_hammer_right.png`, `girl_hammer_up.png`. Mỗi sheet 6 frame, tổng 768×160 px. Thứ tự: thủ thế → lấy đà → giơ tay → vung → va chạm → hồi phục. Animation một lần, không loop; bàn tay nắm cán vô hình.

## Kiểm tra và bàn giao

Kiểm tra đúng tên, kích thước, số ô, alpha, pivot, không cắt cụt; xem từng frame và phát thử chuỗi để kiểm tra trùng frame, nhảy vị trí, biến dạng và chuyển tiếp. Ghi kết quả, hạn chế và đường dẫn từng sheet vào file báo cáo riêng của nhiệm vụ trong `assets/animation_pending/`. Không khẳng định đã tích hợp hoặc kiểm thử trong Godot. Nếu sheet không đạt, ghi rõ và giữ trạng thái chưa đạt.
Với mỗi sheet nhân vật, ghi tọa độ điểm nắm đề xuất của từng frame theo góc trên trái ô 128×160. Ghi frame va chạm cho búa hoặc frame thả vật cho ném nếu áp dụng.
