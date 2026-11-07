# Nhiệm vụ độc lập — tạo ảnh nguồn Couple Chaos

Bạn là agent tạo ảnh. Tạo ảnh nguồn theo nhiệm vụ bên dưới, không hỏi lại. Chỉ tạo ảnh sheet chứa các pose riêng biệt; không cắt frame, không tạo atlas Godot, không sửa code, scene hoặc asset gốc. Nếu không có quyền truy cập dự án, dùng ảnh tham chiếu được cung cấp; nếu thiếu ảnh thiết yếu hoặc không tạo được ảnh, báo rõ thay vì tự nhận đã hoàn thành.

Dự án tham chiếu: `/Users/thanhpv/Documents/Work/couple-chaos`. Đọc `AGENTS.md`, `asset/plan/ASSET_RULES.md`, xem `party-chaos.jpg` và các ảnh tham chiếu bên dưới nếu có quyền truy cập. Giữ đúng thiết kế nhân vật. Lưu ảnh nguồn vào `asset/inbox/` với tiền tố `source_` trước tên file được yêu cầu; không ghi đè file có sẵn, thêm hậu tố phiên bản nếu trùng. Nếu không có quyền lưu vào dự án, bàn giao file ảnh có thể tải xuống với đúng tên tương ứng.

Phong cách: cozy chibi anime 2D, màu pastel ấm, nét viền nâu mượt, góc nhìn isometric 2.5D 30–45°. Mỗi ảnh chứa đúng số pose theo thứ tự từ trái sang phải, các pose tách rời, khoảng trống rộng và không chồng lấn; giữ cùng tỉ lệ, thiết kế và góc nhìn. Dùng nền trong suốt nếu công cụ hỗ trợ, nếu không dùng nền trắng trơn đồng nhất. Không chữ, số, watermark, đường kẻ, bóng đổ, bụi, vệt tốc độ, biểu tượng hoặc hiệu ứng dính vào nhân vật. Không cắt cụt cơ thể; mỗi pose phải thể hiện một giai đoạn chuyển động có ý nghĩa, không lặp một ảnh tĩnh cho cả chu kỳ. Hướng down nhìn thấy mặt, right nhìn sang phải, up nhìn thấy lưng; không cần vẽ left.

Ảnh nguồn không cần đạt kích thước atlas, lưới pixel, alpha hoàn hảo hoặc pivot chính xác. Người tích hợp sẽ tách pose, xử lý nền, căn chân, tạo atlas và kiểm thử animation sau. Ưu tiên hình đủ lớn, rõ nét và không chạm nhau để dễ cắt.

Tham chiếu mèo: `assets/pets/cat/sleep.png`, `run.png`, `startled.png`, `hiss.png` và `asset/plan/02-pets/`. Giữ mèo mướp cam thân tròn chân ngắn, sọc đậm, bụng trắng và đặc điểm thực tế của ảnh gốc. Chuẩn sau xử lý là 64×64 px mỗi frame, pivot chân (32, 58); không cần đạt chính xác trên ảnh nguồn.

## P0 — Mèo đi bộ

Tạo `cat_walk_down.png`, `cat_walk_right.png`, `cat_walk_up.png`. Mỗi sheet gồm 6 frame. Đi thư thả: chân luân phiên, thân chuyển trọng lượng, đầu và đuôi chuyển động nhẹ; frame cuối nối mượt frame đầu. Tạo từng hướng riêng theo tên file.

## Bàn giao

Kiểm tra trực quan đủ số pose, đúng hướng, không chồng lấn hoặc bị cắt, thiết kế nhất quán và thứ tự dễ nhận biết. Bàn giao ảnh nguồn cùng tên file và nêu những điểm còn bất thường. Không đánh giá ảnh nguồn là atlas production-ready; không yêu cầu GIF, metadata điểm nắm hay kiểm tra pixel-pivot. Người tích hợp sẽ đảm nhiệm các bước đó.
