# Bộ Prompt Tạo Asset Theo Batch (Batch Prompts System)

Bộ prompt chuẩn hóa dùng cho AI Image Generation (Midjourney v6, DALL-E 3, SDXL, hoặc Gemini/Imagen) để tạo sprite sheet theo từng batch đồng bộ về artstyle, góc nhìn và bảng màu.
Tham khảo visual gốc: [`party-chaos.jpg`](file:///Users/thanhpv/Documents/Work/couple-chaos/party-chaos.jpg).

---

## 🎨 Master Style Prefix & Negative Prompt (Dùng chung cho mọi batch)

### Style Prefix (Đặt ở đầu mỗi prompt):
> `Cozy cute 2D chibi Korean anime game art style, vibrant soft pastel palette, clean solid line art, isometric 2.5D view angled from above, sprite sheet on pure solid white background, isolated sprites, evenly spaced, game asset ready, no background scenery`

### Negative Prompt (Loại bỏ tạp chất):
> `realistic, 3d render, photographic, dark gritty shadows, sketch, messy lines, gradients on background, overlapping sprites, cropped edges, watermark, text, blur`

---

## 📦 BATCH 1: Bạn Trai P1 (`char_boy_p1`) — 8 Poses

* **Mục tiêu:** Tạo trọn bộ 8 tư thế của nhân vật Bạn Trai.
* **Quy cách:** Grid 2×4 hoặc 1 hàng 8 sprite tách rời trên nền trắng trơn.

```text
Cozy cute 2D chibi Korean anime game art style, clean solid line art, isometric 2.5D view. A character sprite sheet of a cute teenage boy with messy brown hair, wearing a white t-shirt, dark trousers, and white sneakers. The sprite sheet contains 8 distinct poses on a pure solid white background, evenly spaced, each sprite full body isolated:
1. Idle standing breathing relaxed
2. Running forward action pose
3. Dashing fast forward with speed lines
4. Carrying an object with both hands in front of chest
5. Swinging arm to hit
6. Throwing an item forward
7. Slipping backward falling on back with comic shock face
8. Stunned sitting on ground with swirling dizzy eyes
Vibrant cheerful colors, consistent character design across all 8 poses, 2D game asset ready, no shadows on background --ar 16:9 --v 6.1
```

---

## 📦 BATCH 2: Bạn Gái P2 (`char_girl_p2`) — 8 Poses

* **Mục tiêu:** Tạo trọn bộ 8 tư thế của nhân vật Bạn Gái.
* **Quy cách:** Grid 2×4 hoặc 1 hàng 8 sprite tách rời trên nền trắng trơn.

```text
Cozy cute 2D chibi Korean anime game art style, clean solid line art, isometric 2.5D view. A character sprite sheet of an energetic cute teenage girl with wavy brown hair tied with a large pink ribbon bow, wearing a bright yellow t-shirt, dark blue athletic shorts with white trim, and pink sneakers. The sprite sheet contains 8 distinct poses on a pure solid white background, evenly spaced, each sprite full body isolated:
1. Idle standing with hands on hips smiling playfully
2. Running forward energetically chasing
3. Dashing fast forward with determination
4. Holding a big toy squeaky hammer with two hands ready to strike
5. Slamming the giant toy hammer downwards with high energy
6. Throwing a pillow forward with angry cute expression
7. Pouting angrily with puffed cheeks and folded arms
8. Victory jumping with arms raised and eyes closed happily
Vibrant cheerful colors, consistent character design across all 8 poses, 2D game asset ready, no background scenery --ar 16:9 --v 6.1
```

---

## 📦 BATCH 3: Boss Mèo Cam (`npc_orange_cat`) — 4 Poses

* **Mục tiêu:** Tạo trọn bộ animation cho Boss Mèo Cam.
* **Quy cách:** 1 hàng 4 sprite mèo trên nền trắng trơn.

```text
Cozy cute 2D chibi anime game asset, clean smooth line art, isometric 2.5D view. A sprite sheet of a chubby short-legged orange tabby cat with dark stripes and white belly, on a pure solid white background, containing 4 isolated poses, evenly spaced:
1. Sleeping curled up peacefully into a round ball
2. Startled jumping up on all four paws with wide shocked eyes and comic exclamation mark
3. Panicked full speed sprint running forward with little dust puffs
4. Hissing with arched back and fluffy tail
Cute humorous expressive cartoon physics, 2D game sprite ready, no background --ar 16:9 --v 6.1
```

---

## 📦 BATCH 4: Vũ Khí & Vật Phẩm Cầm Tay (`item_*`) — 8 Items

* **Mục tiêu:** Tạo 8 item tương tác trên sàn và icon hotbar.
* **Quy cách:** Grid 2×4 gồm 8 vật phẩm bo tròn, có viền nét rõ ràng.

```text
Cozy cute 2D chibi casual game art style, isometric 2.5D angle, clean vector line art. An asset pack sprite sheet of 8 cute everyday household weapons and items on a pure solid white background, isolated and evenly spaced:
1. A large colorful squeaky toy hammer with yellow head, red star emblem, and pink handle
2. A soft pastel pink feather pillow with a cute cat paw print
3. A clear plastic cup of brown bubble milk tea with black tapioca pearls and large straw
4. A red-and-white striped paper bucket overflowing with golden popped popcorn
5. A ripe bright yellow banana and an open 3-peel banana skin
6. A square cardboard box with two cute eye-holes cut out
7. A cute brown leather folding wallet with a shiny gold credit card sticking out
8. A modern white wireless gaming controller with colorful buttons
Bright cheerful colors, clean sticker-like outlines, ready for game UI and pickup sprites --ar 16:9 --v 6.1
```

---

## 📦 BATCH 5: Nội Thất Phòng Khách & Bàn PC (`fur_living_*`) — 6 Props

* **Mục tiêu:** Nội thất khu vực phòng khách và góc làm việc của Trai.

```text
Cozy 2D chibi casual apartment game furniture pack, isometric 2.5D perspective, warm aesthetic. A collection of cute indoor furniture props on a pure solid white background, isolated and separated:
1. A long vintage sage-green fabric couch sofa with 2 cozy throw pillows and a plaid draped blanket
2. A low light-wood coffee table with rounded corners holding a cookie plate and a small potted green plant
3. A wooden desk workstation with an open laptop displaying green code on screen, a warm desk lamp, and a coffee mug
4. A dark grey ergonomic swivel office chair on tiny wheels
5. A low wooden media console TV stand holding a flat screen television and game console
6. A round woven bohemian area rug with fringe edges
Consistent warm cozy colors, clean outlines, mobile game ready, no floor or room walls --ar 16:9 --v 6.1
```

---

## 📦 BATCH 6: Nội Thất Bếp & Phòng Ngủ (`fur_kitchen_bed_*`) — 5 Props

* **Mục tiêu:** Nội thất khu bếp và giường ngủ.

```text
Cozy 2D chibi casual apartment game furniture pack, isometric 2.5D perspective, soft pastel palette. A collection of cute furniture props on a pure solid white background, isolated:
1. A retro pastel cream double-door refrigerator covered with colorful heart stickers, magnets, and sticky notes
2. A cozy double bedroom bed with fluffy white duvet, pink folded blanket, and soft pillows
3. A compact kitchen counter with marble top, stainless steel sink, and cute faucet
4. A small round wooden dining table with a cute daisy flower vase and 2 padded wooden dining chairs
5. A wooden entryway door with round doorknob and adjacent 2-tier shoe rack with cute slippers
Consistent scale and style with living room set, clean edges, game ready, isolated on white --ar 16:9 --v 6.1
```

---

## 📦 BATCH 7: Bẫy Sàn, VFX & UI Buttons (`decal_*` & `ui_*`)

* **Mục tiêu:** Các vệt bẩn trên sàn, hiệu ứng hạt comic và nút bấm UI mobile.

```text
Cute 2D casual mobile game UI and VFX sprite sheet, isometric ground decals and cartoon effects on a pure solid white background, isolated:
1. A spilled dark brown boba milk tea puddle with scattered black tapioca pearls flat on the ground
2. A messy pile of scattered yellow popcorn kernels flat on the floor
3. A flat yellow banana peel slip trap
4. A comic impact hit effect with bright yellow cartoon star and 'BONK' action burst
5. A burst of flying white soft feathers exploding outward
6. Three spinning golden stars for stun effect
7. A round pink action button with a white toy hammer icon
8. A round yellow button with a white running sneaker icon
9. A round blue button with an open hand grab icon
10. A touch virtual joystick with directional arrows
Vibrant colors, clear alpha mask boundaries, 2D mobile game ready --ar 16:9 --v 6.1
```

---

## 📁 Thư mục lưu kết quả sau khi tạo ảnh:
Mỗi batch ảnh sau khi render xong hoặc tách nền, thả trực tiếp vào thư mục:
👉 [`asset/inbox/`](file:///Users/thanhpv/Documents/Work/couple-chaos/asset/inbox/) (đặt tên file theo batch: `batch_01_boy.png`, `batch_02_girl.png`, v.v.)
Agent cắt sprite sẽ tự động bóc tách từng sprite theo kích thước chuẩn trong [`ASSET_RULES.md`](file:///Users/thanhpv/Documents/Work/couple-chaos/asset/plan/ASSET_RULES.md).
