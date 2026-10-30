# Source summary: Flutter sport SDK

## Mục tiêu

Repo này là một **bộ SDK ghép theo nhu cầu** cho app thể thao, không phải một app hoàn chỉnh. App có thể chỉ ghi đường chạy bằng điện thoại, có thể gắn nhiều cảm biến BLE để hiện và lưu nhịp tim/nhịp chân, hoặc tổ chức một thử thách gồm nhiều chặng với mục tiêu khác nhau. Mô hình thử thách là danh sách chặng có thứ tự: mỗi chặng có môn, mục tiêu, nguồn đo, cách xác nhận hoàn thành và cách chuyển sang chặng kế tiếp.

## Những package đang có

| Package | Vai trò và API chính | Quan hệ |
|---|---|---|
| [`flutter_tracking_gps`](../packages/flutter_tracking_gps/) | Ghi GPS/route và bước chân bằng native Android/iOS; tính quãng đường, thời gian, tốc độ, chất lượng GPS; `FlutterTrackingGps`, `TrackingSession.updates`, `persistedFixes()`; journal và khôi phục. | Không phụ thuộc BLE/workout/challenge. |
| [`flutter_sport_ble`](../packages/flutter_sport_ble/) | Quét/kết nối nhiều thiết bị BLE; giải mã heart rate, running/cycling cadence/speed, cycling power, fitness-machine data; `SportBle.snapshots` cho giá trị trực tiếp theo metric và theo device. | Không phụ thuộc GPS hoặc challenge. Không tự lưu lịch sử. |
| [`flutter_activity`](../packages/flutter_activity/) | Ghi **một activity** và chuỗi dữ liệu cảm biến bằng `ActivityRecorder`; `summary()`, `samplesOf()`, `series()` để xem lại nhịp tim, cadence, pace, coverage; `FileTelemetryStore` lưu trên máy. | Pure Dart; nhận `ProgressSource`/`TelemetrySource`, không biết GPS/BLE. |
| [`flutter_workout`](../packages/flutter_workout/) | Phiên workout độc lập, tính **một** quãng đường từ counter/speed và tránh đếm trùng khi pause, reconnect, đổi nguồn; native journal, restore. | Không tự lấy dữ liệu cảm biến; app phải feed. Hiện chỉ có distance/time. |
| [`flutter_challenge`](../packages/flutter_challenge/) | Engine native cho nhiều chặng: mục tiêu distance/reps/duration, tiến độ riêng từng chặng, auto/manual/confirmation, journal và restore. | Không tự đo và không cần BLE. |
| [`flutter_multisport`](../packages/flutter_multisport/) | `SportCatalog` và `ChallengeCoordinator` biến lựa chọn môn + mục tiêu thành challenge; phát `StageCompleted`, `AwaitingNextStage`, `ChallengeFinished`; `StageResult` có tiến độ và thống kê cảm biến theo chặng. | Phụ thuộc `flutter_challenge` và `flutter_activity`, không phụ thuộc trực tiếp GPS/BLE. |
| [`flutter_tracking_gps_adapter`](../packages/flutter_tracking_gps_adapter/) | Chuyển GPS total/speed thành source cho activity/challenge. | Chỉ phụ thuộc GPS + activity; không kéo BLE. |
| [`flutter_sport_ble_adapter`](../packages/flutter_sport_ble_adapter/) | Chuyển counter/telemetry của từng BLE device thành source cho activity/challenge. | Chỉ phụ thuộc BLE + activity; không kéo GPS. |
| [`flutter_multisport_adapters`](../packages/flutter_multisport_adapters/) | Export cả hai adapter cũ để giữ tương thích import. | Cài package này sẽ kéo cả GPS lẫn BLE. |

Các engine GPS, BLE, workout và challenge có Kotlin Multiplatform core riêng trong package của mình. Android biên dịch core vào plugin; iOS dùng XCFramework riêng. Pigeon nối Dart với native. `examples/sensors_demo` thử GPS + BLE + workout; `examples/multisport_demo` cho tạo/chạy thử thách với sensor mô phỏng và challenge native. Demo không phải bằng chứng thiết bị thật hoạt động.

## Cách ghép cho các trường hợp bạn nêu

| Nhu cầu | Cài package | Luồng dữ liệu |
|---|---|---|
| Chỉ record chạy bằng điện thoại | `flutter_tracking_gps` | Điện thoại → GPS native → `TrackingSession.updates` (live) và `persistedFixes()` (route sau buổi). Không cần BLE. |
| Record GPS và xem lại nhịp tim/cadence từ nhiều device | GPS + BLE + `flutter_activity` + hai adapter riêng | GPS ghi route/quãng đường; BLE kết nối nhiều device, chọn một giá trị live cho mỗi metric; `ActivityRecorder` lưu sample có thời gian, trả summary và chart series. App dựng màn hình live và màn hình lịch sử. |
| Record GPS và lịch sử activity **không** cài BLE | GPS + `flutter_activity` + `flutter_tracking_gps_adapter` | `GpsProgressSource` và `GpsTelemetrySource` dùng riêng; không có dependency BLE. |
| Thử thách không cần cảm biến | `flutter_multisport` (kéo `flutter_challenge` + `flutter_activity`) | Chặng duration dùng đồng hồ của challenge; chặng manual/reps dùng `addProgress()`/`confirm()`. |
| Thử thách có GPS và nhiều BLE device | `flutter_multisport` + GPS + BLE + adapters | App attach các source vào coordinator; challenge chỉ nhận source được phép cho chặng hiện tại; telemetry được phân vào từng chặng theo **thời điểm đo**. |

Một challenge dạng **chạy 1 km → bơi 200 m → tập tạ 1 giờ** có thể biểu diễn bằng `SportStageConfig` cho running distance, swimming distance và strength duration. Chạy dùng `gps` làm **source ID mặc định**; app vẫn phải tạo GPS session và attach `GpsProgressSource`. Bơi chưa có nguồn đo mặc định: app phải cung cấp nguồn đếm mét phù hợp hoặc chọn hoàn thành thủ công. Chặng tập tạ 1 giờ dùng đồng hồ active-time của challenge; heart rate chỉ có nếu cảm biến gửi được dữ liệu. Từng chặng chọn `StageCompletion` (tự động, đạt mục tiêu rồi xác nhận, hoặc thủ công) và `TransitionPolicy` (chờ nút “Tiếp” hoặc tự chuyển sau delay). `StageResult` lưu thời gian, tiến độ, bằng chứng hoàn thành và thống kê theo metric. Route vẫn nằm trong GPS, không nằm trong `StageResult`.

## Luồng dữ liệu và quyền sở hữu

```text
GPS điện thoại ──► flutter_tracking_gps ──► ProgressSource ──┬──► flutter_activity (buổi lẻ)
BLE device A/B ─► flutter_sport_ble ──────► TelemetrySource ──┘
                                    │
                                    └──► ChallengeCoordinator ──► flutter_challenge (tiến độ/chuyển chặng)
                                                   └───────────► stage telemetry (lịch sử/thống kê chặng)
```

GPS/thiết bị cung cấp số đo; activity lưu lịch sử một buổi; challenge quyết định tiến độ; multisport đặt nghĩa môn và điều phối chặng; app quyết định giao diện, rung/âm báo, database hoặc đồng bộ server. Quãng đường cộng từ **delta của một nguồn**, không cộng nguyên tổng GPS với tổng footpod/máy. Pause, reconnect và đổi chặng phải đặt lại baseline.

## Trạng thái thực tế và khoảng trống

- Đã có API, logic core, unit/widget/native simulator tests cho các luồng chính. `doc/QUALITY_GATES.md` ghi lệnh đã chạy và những gate **chưa chạy**. BLE/GPS chưa được xác nhận trên thiết bị thật; `doc/COMPATIBILITY.yaml` chỉ là danh sách thiết bị dự định thử.
- BLE không tự reconnect, không giữ link sau khi Flutter engine chết. Workout/challenge có journal và restore về **paused**, nhưng sensor feed từ Dart dừng khi Flutter engine mất. Chuyển chặng tự động của `ChallengeCoordinator` dùng Dart `Timer`, nên chưa thể cam kết tự chuyển khi app/process không còn chạy.
- `flutter_activity` có `samplesOf()` và `series()` để dựng chart sau buổi. `ChallengeCoordinator.stageSamples()` và `stageSeries()` đọc lại theo chặng/metric, kể cả sau restore; `telemetryRestoreStatus` báo nếu lịch sử bị sửa phần hỏng. App phải chọn nguồn telemetry khi nhiều thiết bị cùng đo một metric: nếu attach hai nguồn heart rate, thống kê hiện gộp mẫu của cả hai. App vẫn phải tự dựng UI và lưu kết quả vào database riêng nếu cần đồng bộ lâu dài.
- `SportType` hiện là enum cố định; `SportType.custom` chỉ hỗ trợ duration/repetitions. Chưa có cơ chế người dùng tự tạo bất kỳ môn mới nào với loại quãng đường/đơn vị riêng ở runtime. `SportStageConfig.title` chỉ đặt tên hiển thị.
- Bơi 200 m chưa có nguồn đo tích hợp. BLE dưới nước không nên được giả định là hoạt động ổn định; cần xác định thiết bị/phương thức đo thực tế. `sensors_demo` chỉ kiểm tra các plugin cùng khởi động/link, còn `multisport_demo` dùng cảm biến giả và bộ nhớ tạm; chưa có demo record GPS + BLE thật rồi xem lại toàn bộ challenge. Chưa có kiểm chứng trọn luồng 4 plugin trên thiết bị thật, iOS link cả 4 framework, hoặc publish từng package độc lập.
- Chưa có backend, tài khoản, bảng xếp hạng, giải đấu, judge authentication, thông báo hệ thống hay UI thành phẩm trong SDK. App tích hợp tự sở hữu các phần đó.

## Hướng hoàn thiện theo nhu cầu này

1. Kiểm tra bản phát hành độc lập của từng adapter trong app sạch và giữ package gộp chỉ để tương thích; app cần lưu cấu hình challenge để `restore()` dùng đúng danh sách chặng ban đầu.
2. Làm một demo tích hợp thật: GPS-only; GPS + nhiều BLE device; challenge chạy → bơi nguồn ngoài/thủ công → strength duration, với live UI, tín hiệu hoàn thành, chuyển chặng và màn hình kết quả.
3. Thử trên thiết bị Android/iOS thật, ghi rõ profile/firmware và độ chính xác, mất kết nối, background, process death; sau đó mới chốt chính sách nguồn đo, ngưỡng và cam kết hỗ trợ.

Chi tiết hợp đồng kỹ thuật: [SDK_RULES.md](SDK_RULES.md), [WORKOUT_CORE.md](WORKOUT_CORE.md), [CHALLENGE_CORE.md](CHALLENGE_CORE.md), [QUALITY_GATES.md](QUALITY_GATES.md).
