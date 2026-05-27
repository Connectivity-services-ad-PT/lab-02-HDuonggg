# Phân tích yêu cầu — vai Provider (Tổng hợp các luồng dữ liệu)

- Cặp đàm phán: 
  - Pair 06: IoT Ingestion (A1) ➔ Analytics (A5)
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

Phân hệ Analytics tiếp nhận dữ liệu từ nhiều nguồn khác nhau. Cấu trúc Payload được quy chuẩn hóa để phục vụ lưu trữ và phân tích.

| Resource | Mô tả | Thuộc tính bắt buộc | Thuộc tính tùy chọn |
|---|---|---|---|
| `Telemetry` | Dữ liệu đo lường từ cảm biến môi trường, điện nước. | `eventId`, `deviceId`, `metric`, `value`, `timestamp` | `zoneId`, `unit` |
| `CameraMotion`| Sự kiện phát hiện chuyển động từ Camera. | `eventId`, `cameraId`, `motionLevel`, `timestamp` | `zoneId`, `detectedObjects` |
| `CoreAlert` | Quyết định xử lý nghiệp vụ, cảnh báo hệ thống. | `eventId`, `sourceService`, `severity`, `message`, `timestamp` | `status` |
| `AccessLog` | Lịch sử quẹt thẻ ra/vào tại cổng vật lý. | `eventId`, `gateId`, `cardId`, `decision`, `timestamp` | `employeeId` |

---

## 2. Action/API dự kiến (Cơ chế REST Webhook)

Analytics sẽ cung cấp 4 API Endpoint dạng `POST` để các hệ thống Consumer chủ động đẩy (push) dữ liệu vào.

| HTTP Method | API Path | Mục đích | Consumer gọi khi nào? |
|---|---|---|---|
| POST | `/api/v1/webhooks/telemetry` | Thu thập chỉ số điện/nước. | Khi IoT Ingestion có dữ liệu sensor mới. |
| POST | `/api/v1/webhooks/camera-motion` | Nhận tín hiệu chuyển động. | Khi Camera phát hiện chuyển động. |
| POST | `/api/v1/webhooks/core-alerts` | Ghi nhận cảnh báo hệ thống. | Khi Core phát ra alert. |
| POST | `/api/v1/webhooks/access-logs` | Ghi nhận lịch sử quẹt thẻ. | Khi có người quẹt thẻ qua cổng. |

---

## 3. Error case (HTTP Status Codes)

Các lỗi trả về sẽ tuân thủ cấu trúc `Problem Details` theo chuẩn OpenAPI 3.1.

| HTTP Status | Tình huống phát sinh | Cách xử lý của Provider |
|---:|---|---|
| 400 Bad Request | Payload sai cấu trúc schema hoặc thiếu trường bắt buộc. | Trả về lỗi Problem Details, từ chối ghi nhận. |
| 401 Unauthorized | Thiếu hoặc sai Token xác thực trong Header. | Chặn request ngay tại API Gateway. |
| 409 Conflict | Request gửi trùng lặp `eventId` (do Consumer gọi retry). | Trả về 409, không ghi đè dữ liệu cũ. |
| 422 Unprocessable Entity | Kiểu dữ liệu không hợp lệ (vd: `value` là string thay vì number). | Trả về lỗi chi tiết từng field bị sai. |
| 429 Too Many Requests | Nhận quá nhiều request mỗi giây từ một Camera/IoT. | Báo lỗi Rate Limit, yêu cầu gửi dạng Batch. |

---

## 4. Giả định bổ sung
- **Chuẩn thời gian:** Trường `timestamp` trong mọi Payload phải định dạng chuẩn ISO 8601 (UTC).
- **Idempotency:** Các Consumer phải gửi kèm ID sự kiện duy nhất để Analytics lọc trùng lặp khi có lỗi rớt mạng gọi lại (Retry).