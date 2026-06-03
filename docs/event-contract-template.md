# Event Contract sơ bộ — Phân hệ Analytics (A5)

> File này ghi nhận thỏa thuận ban đầu cho các cặp Queue async mà Analytics (A5) đóng vai trò là Consumer. Đặc tả chi tiết bằng AsyncAPI sẽ chuyển sang Lab 03.

## 1. Thông tin dependency

- **Dependency số:** Pair 06, Pair 07, Pair 08, Pair 09
- **Producer:** IoT Ingestion (A1), Camera Stream (A2), Core Business (A6), Access Gate (A3)
- **Consumer:** Analytics (A5)
- **Cơ chế:** Queue async (Message Broker)
- **Người ghi:** Nguyễn Hữu Tuấn Minh (Leader Nhóm 6 - A5)
- **Ngày:** 2026-05-27

---

## 2. Mục đích nghiệp vụ, Trigger và Điều kiện phát sự kiện

### 2.1. Nguồn từ IoT Ingestion (Pair 06)
- **Mục đích:** Feed dữ liệu đo lường (telemetry) để Analytics tổng hợp lượng tiêu thụ điện/nước theo giờ/ngày và hiển thị lên Dashboard.
- **Trigger:** Hệ thống IoT Ingestion nhận được một gói tin MQTT từ phần cứng cảm biến.
- **Điều kiện phát:** Cảm biến trực tuyến, chỉ số đo lường hợp lệ.

### 2.2. Nguồn từ Camera Stream (Pair 07)
- **Mục đích:** Feed sự kiện phân tích hình ảnh để Analytics tổng hợp biểu đồ mật độ người theo khu vực (zone).
- **Trigger:** Module AI Vision phát hiện có chuyển động.
- **Điều kiện phát:** Độ tin cậy (confidence score) của AI > 85%.

### 2.3. Nguồn từ Core Business (Pair 08)
- **Mục đích:** Feed thông tin cảnh báo và chính sách để Analytics tính toán KPI vận hành.
- **Trigger:** Core Business tạo mới hoặc thay đổi trạng thái của một Cảnh báo.
- **Điều kiện phát:** Sự cố được xác nhận và ghi vào Database thành công.

### 2.4. Nguồn từ Access Gate (Pair 09)
- **Mục đích:** Feed lịch sử ra/vào để Analytics làm báo cáo thống kê.
- **Trigger:** Người dùng quẹt thẻ RFID hoặc quét vân tay tại cổng vật lý.
- **Điều kiện phát:** Thiết bị đầu đọc ghi nhận thành công mã thẻ.

---

## 3. Event name / topic quy chuẩn

| Nguồn (Producer) | Đích (Consumer) | Event Name (Định danh) | Topic / Queue (Kênh truyền) |
|---|---|---|---|
| IoT (A1) | Analytics (A5) | `iot.telemetry.ingested` | `campus.telemetry.events` |
| Camera (A2) | Analytics (A5) | `camera.motion.detected` | `campus.camera.events` |
| Core (A6) | Analytics (A5) | `core.alert.published` | `campus.core.events` |
| Gate (A3) | Analytics (A5) | `gate.access.logged` | `campus.access.events` |

---

## 4. Payload schema sơ bộ (Đặc tả cấu trúc sự kiện)

### 4.1. Cấu trúc Metadata chung (Bắt buộc cho mọi Event)

| Tên trường | Kiểu dữ liệu | Bắt buộc | Ràng buộc (Constraint) | Ý nghĩa nghiệp vụ |
|---|---|---|---|---|
| `eventId` | String | **Có** | Định dạng `UUID v4` | Định danh duy nhất của sự kiện. |
| `eventType` | String | **Có** | Regex: `^[a-z]+\.[a-z]+\.[a-z]+$` | Phân loại sự kiện. |
| `occurredAt` | String | **Có** | Chuẩn ISO 8601, Múi giờ UTC (`Z`) | Thời điểm phát sinh sự kiện gốc. |
| `correlationId` | String | **Có** | Max Length: 64 | ID dùng để nối chuỗi (tracing) log. |
| `source` | String | **Có** | Enum: `A1`, `A2`, `A3`, `A6` | Mã phân hệ Producer. |

### 4.2. Schema Data & Ví dụ JSON cho Pair 06 (IoT)
```json
{
  "eventId": "123e4567-e89b-12d3-a456-426614174000",
  "eventType": "iot.telemetry.ingested",
  "occurredAt": "2026-05-27T10:00:00Z",
  "correlationId": "req-987654321",
  "source": "A1",
  "data": {
    "deviceId": "SENSOR-001",
    "zoneId": "ZONE-A",
    "metric": "temperature",
    "value": 35.5
  }
}

--- 

### 5. Ràng buộc & Xử lý ngoại lệ (Edge Cases)

Vấn đề (Edge Case) | Quyết định xử lý sơ bộ
1. Duplicate | Analytics check eventId trong Redis (lưu 24h) để đảm bảo Idempotency. Nếu trùng sẽ drop.
2. Out-of-order | "Dùng trường occurredAt để sắp xếp lại timeline biểu đồ, không phụ thuộc thời gian nhận."
3. Missing field | "Nếu thiếu eventId hoặc occurredAt, từ chối xử lý ngay lập tức."
4. Invalid schema | Dữ liệu sai kiểu sẽ bị đẩy sang Dead-Letter Queue (DLQ) mang tên campus.analytics.dlq.
5. Retry | Consumer tự cấu hình Retry backoff 3 lần nếu Broker sập.