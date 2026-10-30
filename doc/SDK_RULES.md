# Quy tắc phát triển SDK thể thao

Tài liệu này là hợp đồng cho các thay đổi tiếp theo. [SOURCE_SUMMARY.md](SOURCE_SUMMARY.md) phân biệt chức năng đang có với những phần còn thiếu. Giữ các rule này cùng chiều với `CLAUDE.md` và tài liệu của package.

## 1. Tính độc lập và hướng dependency

1. SDK nền phải cài và chạy riêng: GPS không cần BLE; BLE không cần GPS; activity nhận source qua interface; workout/challenge không tự phụ thuộc thiết bị đo. Package tầng trên được ghép package tầng dưới bằng dependency công khai và có lý do cụ thể.
2. Không đưa loại thiết bị, tên app hoặc UI vào core của một môn/challenge. GPS/BLE gửi số đo; core workout/challenge quyết định tiến độ; multisport định nghĩa môn và mục tiêu; app quyết định cách hiển thị, báo hiệu và lưu vào backend.
3. Adapter là tùy chọn và theo **một provider**: `flutter_tracking_gps_adapter` không kéo BLE, `flutter_sport_ble_adapter` không kéo GPS. Package gộp chỉ giữ tương thích. Đường kiểm chứng: app mới chỉ khai báo một SDK nền và adapter tương ứng vẫn build được Android và iOS.
4. Mỗi native core nằm trong package sở hữu nó, có version/test/release riêng. Không import core của package khác hoặc đưa nhiều core vào cùng một framework.

## 2. Hợp đồng số đo

1. Mọi sample có metric, đơn vị rõ ràng, source ID, thời điểm đo hoặc age, và epoch khi nguồn có thể reconnect. Giá trị chưa có là `null`/vắng mặt; số 0 chỉ dùng khi thiết bị thật sự đo được 0.
2. Counter tích lũy (GPS total, quãng đường máy, vòng bánh, strokes) chỉ được cộng theo **chênh lệch trong cùng nguồn, epoch, stage và đoạn active**. Sample đầu tiên sau start/pause/reconnect/đổi nguồn/đổi chặng là baseline; không tạo quãng đường từ tổng cũ.
3. Mỗi metric tiến độ của một chặng chỉ có **một nguồn đang tính**. Không cộng GPS và footpod trên cùng quãng chạy. Nguồn khác có thể được lưu như telemetry và đổi sang khi chính sách cho phép.
   Với telemetry tức thời như heart rate, app cũng phải chọn nguồn chính cho thống kê khi nhiều thiết bị cùng đo một metric; API hiện lưu tất cả mẫu được attach và chưa tự chọn nguồn cho summary.
4. Không gán sample đến chặng theo lúc callback tới; dùng lúc nó **được đo**. Manual delta dùng event ID ổn định để retry không đếm hai lần; thao tác từ UI phải mang activation của chặng đang thấy để callback trễ không kết thúc chặng mới.
5. Core native dùng một đồng hồ monotonic của điện thoại. Dart telemetry hiện dùng wall clock; khi thay đổi phải bảo toàn tính đúng khi đổi giờ hệ thống và ghi rõ giới hạn nếu chưa làm được.

## 3. Session, lưu trữ và kết quả

1. GPS giữ route, raw fixes và journal tracking. `flutter_activity` giữ chuỗi HR/cadence/speed/distance của một buổi. Challenge giữ tiến độ và bằng chứng hoàn thành; stage telemetry giữ lịch sử mẫu cảm biến theo chặng. Không coi `SportBle.snapshots` hoặc `StageResult` thống kê là lịch sử chi tiết.
2. Không báo “đã lưu” chỉ vì UI đang hiện số. Native journal phải ghi trước khi publish thay đổi theo hợp đồng hiện tại. Dart telemetry phải theo dõi `isDurable`/`hasWriteFailures`, chờ `flush()`/`finish()` khi xuất kết quả, và báo lỗi ghi rõ ràng.
3. Dùng session ID riêng cho mỗi buổi; restore về paused, không tính thời gian process chết. Dữ liệu thiếu/hỏng phải được thể hiện trong restore status và kết quả. App phải lưu definition/config của challenge để restore bằng cùng danh sách chặng.
4. Kết quả của mỗi chặng gồm môn, goal, tiến độ, active time, nguồn/bằng chứng hoàn thành và số đo thực có. Nhịp tim không có thiết bị thì để trống. `stageSamples()`/`stageSeries()` phải giữ đúng chặng và khoảng trống cảm biến, kể cả sau restore.

## 4. Completion và chuyển chặng

1. Phân biệt **đạt mục tiêu**, **chặng được xác nhận hoàn thành**, và **bắt đầu chặng sau**. `automatic`, `confirmed`, `manualOnly` và `waitForUser`/`autoNext` có ý nghĩa riêng; UI nghe event của coordinator để rung/âm báo/hiện nút.
2. Mục tiêu duration dùng active time của challenge native, dừng khi pause. Mục tiêu distance/reps cần nguồn đo hoặc thao tác thủ công; không giả định một môn luôn có sensor. Đặc biệt swimming distance chưa có source mặc định.
3. Không hứa tự chuyển chặng khi process chết: coordinator hiện dùng Dart timer; sau restore phải đọc snapshot và xác định bước tiếp theo. Muốn background transition thực sự cần owner native và test thiết bị.
4. Với môn mới do người dùng tự định nghĩa, không ép mọi môn vào enum `SportType` cố định nếu yêu cầu gồm đơn vị/metric mới. Thiết kế schema versioned và migration trước khi mở rộng runtime catalog.

## 5. Kiểm chứng và phát hành

1. Test ở lớp sở hữu rule: Kotlin core cho tính toán và journal; native test cho bridge/khôi phục; Dart test cho source, telemetry và coordinator; app demo cho tích hợp. Ưu tiên các case pause, callback trễ, reconnect, nhiều nguồn, journal lỗi, khôi phục và missing data.
2. Build package trong một app mới chỉ phụ thuộc package đó trước khi nói SDK phát hành độc lập. Với nhiều plugin, kiểm tra Android merged manifest và iOS frameworks cùng link/chạy được.
3. Ghi bằng chứng đúng mức: fake/simulator build khác với thiết bị thật. `doc/QUALITY_GATES.md` chỉ chuyển sang PASS khi có lệnh và kết quả; `doc/COMPATIBILITY.yaml` chỉ đánh `verified: true` khi đã đo trên đúng device/firmware và nền tảng.
4. Chỉnh Pigeon source rồi regenerate; không sửa file `*.g.*`. Cập nhật companion `.md` cho native file và docs này khi API/behavior thay đổi. Các threshold chưa đo là giá trị khởi đầu, không phải cam kết độ chính xác.
