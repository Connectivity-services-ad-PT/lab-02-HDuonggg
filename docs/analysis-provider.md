# Phân tích yêu cầu — vai Provider (Tổng hợp các luồng dữ liệu)

- Cặp đàm phán: - Pair 06: IoT Ingestion (A1) ➔ Analytics (A5)
  - Pair 07: Camera Stream (A2) ➔ Analytics (A5)
  - Pair 08: Core Business (A6) ➔ Analytics (A5)
  - Pair 09: Access Gate (A3) ➔ Analytics (A5)
- Product: Product A
- Provider service: Analytics (A5)
- Consumer services: IoT Ingestion (A1), Camera Stream (A2), Core Business (A6), Access Gate (A3)
- Người viết: Nguyễn Hữu Tuấn Minh
- Ngày: 2026-05-27

---

## 1. Resource chính

Vì đặc thù hệ thống Analytics tiếp nhận dữ liệu từ nhiều phân hệ thông qua Message Broker, cấu trúc các gói tin sự kiện (Event Payload) cần được quy chuẩn hóa cấu trúc để phục vụ việc lưu trữ và tổng hợp dữ liệu.

| Resource | Mô tả | Thuộc tính bắt buộc | Thuộc tính tùy chọn |
|---|---|---|---|
| `TelemetryEvent` (A1) | Dữ liệu đo lường từ hệ thống cảm biến môi trường, điện nước và thiết bị IoT. | `eventId`, `eventType`, `deviceId`, `metric`, `value`, `timestamp` | `zoneId`, `unit` |
| `CameraMotionEvent` (A2)| Sự kiện phát hiện chuyển động hoặc phân tích luồng hình ảnh từ Camera thông minh. | `eventId`, `eventType`, `cameraId`, `motionLevel`, `timestamp` | `zoneId`, `snapshotUrl`, `detectedObjects` |
| `CoreAlertEvent` (A6) | Các quyết định xử lý nghiệp vụ, cảnh báo hệ thống hoặc vi phạm chính sách cấp trường. | `eventId`, `eventType`, `sourceService`, `severity`, `message`, `timestamp` | `relatedEventId`, `status` |
| `AccessLogEvent` (A3) | Lịch sử quẹt thẻ ra/vào, kiểm soát an ninh tại các cổng phòng học, tòa nhà. | `eventId`, `eventType`, `gateId`, `cardId`, `decision`, `timestamp` | `employeeId`, `maskWorn` |

---

## 2. Action/API dự kiến (Cơ chế Lắng nghe Sự kiện - Subscribe)

Do các cặp phụ thuộc sử dụng cơ chế Queue Async (Bất đồng bộ), phân hệ Analytics không cung cấp các Endpoint REST HTTP truyền thống để các Consumer gọi vào. Thay vào đó, Analytics sẽ thực hiện đăng ký (Subscribe) các Topic tương ứng trên Message Broker.

| Cơ chế | Tên Event / Topic | Mục đích | Consumer đẩy khi nào? |
|---|---|---|---|
| SUBSCRIBE | `iot.telemetry.ingested` | Thu thập chỉ số điện, nước, nhiệt độ để xử lý thống kê lượng tiêu thụ. | Khi cổng IoT Ingestion thu nhận và làm sạch dữ liệu từ sensor. |
| SUBSCRIBE | `camera.motion.detected` | Tiếp nhận tần suất chuyển động để phân tích mật độ phân bổ người tại các zone. | Khi hệ thống Camera phát hiện chuyển động hoặc nhận diện thực thể. |
| SUBSCRIBE | `core.alert.published` | Thu nhận dữ liệu cảnh báo để đo lường KPI vận hành và thời gian xử lý sự cố. | Khi phân hệ Trung tâm phát ra các alert nghiêm trọng toàn trường. |
| SUBSCRIBE | `gate.access.logged` | Ghi nhận lưu lượng ra vào phục vụ báo cáo điểm danh và thống kê mật độ tòa nhà. | Khi có sự kiện quẹt thẻ phát sinh realtime tại các cổng kiểm soát. |

---

## 3. Error case (Kịch bản xử lý ngoại lệ xử lý tin nhắn bất đồng bộ)

Hệ thống hướng sự kiện không sử dụng HTTP Status trực tiếp để báo lỗi cho Consumer, tuy nhiên để đảm bảo tính toàn vẹn, Analytics áp dụng quy trình phân loại lỗi và xử lý như sau:

| Mã lỗi phân loại | Tình huống phát sinh | Cách thức Provider (Analytics) xử lý |
|---:|---|---|
| 400 (Invalid Schema) | Payload sai cấu trúc định dạng JSON hoặc thiếu các trường bắt buộc (`eventId`, `timestamp`). | Từ chối xử lý, trích xuất và đẩy thông điệp lỗi sang **Dead-Letter Queue (DLQ)** để điều tra. |
| 409 (Duplicated Event)| Nhận trùng lặp tin nhắn lỗi mạng phía Consumer thực hiện cơ chế Retry lặp lại. | **Idempotency Check:** Kiểm tra `eventId` trong bộ nhớ đệm Cache 24h; nếu trùng sẽ Drop bỏ dữ liệu mới. |
| 422 (Data Violation) | Sai kiểu dữ liệu nghiêm trọng (Ví dụ: trường dữ liệu `value` trắc đo truyền chuỗi ký tự thay vì số). | Ghi nhận log cảnh báo hệ thống, hủy bỏ (Drop) thông điệp để tránh sai lệch biểu đồ thống kê. |
| 408 (Late Arriving) | Tin nhắn đến quá muộn do nghẽn Queue cục bộ (Múi giờ `timestamp` lệch quá xa so với thời gian thực tế). | Tiếp nhận và đẩy vào luồng xử lý hậu kỳ (Batch Processing) để cập nhật lại cơ sở dữ liệu lịch sử. |
| 500 (DB Write Error) | Lỗi kết nối nội bộ giữa Analytics Worker và kho lưu trữ Analytics Data Warehouse. | Kích hoạt cơ chế **Retry Backoff** tự động thử lại sau (3 lần); nếu tiếp tục lỗi thì chuyển tin nhắn vào Queue tạm thời. |

---

## 4. Giả định bổ sung

- **Giả định 1 (Chuẩn thời gian):** Trường thời gian `timestamp` trong tất cả gói tin thuộc cả 4 cặp bắt buộc phải định dạng theo chuẩn ISO 8601, sử dụng múi giờ UTC (kết thúc bằng ký tự `Z`).
- **Giả định 2 (Tính nhất quán định danh):** Mã phân vùng `zoneId`, mã thiết bị `deviceId`, `cameraId` và `gateId` phải được đồng bộ theo bảng danh mục thiết bị chung của dự án Smart Campus, tránh việc một bên dùng chữ thường, một bên dùng chữ hoa.
- **Giả định 3 (Tần suất nén):** Giả định rằng hệ thống IoT Ingestion (A1) và Camera Stream (A2) có thể tự động gộp (Batching) các sự kiện có mật độ cao trước khi đẩy vào Queue nếu tần suất phát sinh lớn hơn 50 tin nhắn/giây trên một thiết bị.

---

## 5. Câu hỏi cho các bên Consumer

1. **Câu hỏi cho IoT (A1) & Camera (A2):** Kế hoạch xử lý của các bạn như thế nào khi các thiết bị phần cứng đầu cuối bị mất mạng cục bộ rồi đột ngột hoạt động lại? Các bạn sẽ đẩy dồn (Burst) toàn bộ tin nhắn cũ lên Queue hay sẽ lược bỏ bớt?
2. **Câu hỏi cho Core Business (A6):** Khi một lỗi nghiệp vụ được chuyển đổi trạng thái (ví dụ từ `OPEN` sang `RESOLVED`), các bạn sẽ bắn một Event cập nhật trạng thái mới hay chỉ bắn duy nhất một lần lúc Alert khởi tạo?
3. **Câu hỏi cho Access Gate (A3):** Sự kiện quẹt thẻ `gate.access.logged` có bao gồm cả lượt quẹt thẻ của khách (Guest) hay chỉ phục vụ thẻ định danh của cán bộ và sinh viên trong trường?

---

## 6. Rủi ro tích hợp

| Rủi ro | Tác động | Đề xuất xử lý |
|---|---|---|
| Thay đổi cấu trúc schema đột ngột từ một phía | Analytics Worker bị crash, ngừng xử lý toàn bộ hàng đợi dữ liệu. | Áp dụng cơ chế kiểm soát phiên bản Event (Ví dụ thêm trường `version: "1.0.0"` vào cấu trúc siêu dữ liệu metadata). |
| Nghẽn mạng / Quá tải Broker (Message Spike) | Biểu đồ Dashboard hiển thị dữ liệu trễ, không phản ánh đúng trạng thái thực tế. | Thiết kế Analytics Worker theo mô hình phân tán, sẵn sàng scale-up số lượng Consumer node để tăng tốc độ tiêu thụ tin nhắn. |
| Trùng lặp dữ liệu KPI | Biểu đồ thống kê bị sai lệch (ví dụ: một người quẹt thẻ nhưng hệ thống đếm thành hai). | Bắt buộc triển khai giải pháp lưu trữ danh sách `eventId` ngắn hạn bằng Redis tại phân hệ Analytics để lọc trùng hoàn toàn. |