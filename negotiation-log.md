# Biên bản đàm phán hợp đồng API - Phân hệ Analytics (A5)

- Cặp đàm phán: Pair 06, 07, 08, 09
- Product: Product A
- Provider: Analytics (A5)
- Consumer: IoT (A1), Camera (A2), Core Business (A6), Access Gate (A3)
- Phiên: v1.0
- Ngày: 2026-05-27

---

## Issue #1 (Đàm phán với Pair 06 - IoT)
- Raised by: Provider (Analytics)
- Endpoint: `POST /api/v1/webhooks/telemetry`
- Concern: Cần khóa phân cụm để vẽ biểu đồ theo khu vực, nhưng Payload mặc định của IoT không có vị trí.
- Proposal: Thêm trường tùy chọn `zoneId` vào Request Body.
- Resolution: Accepted
- Rationale: Giúp Analytics group dữ liệu theo tòa nhà nhanh chóng mà không cần gọi API ngoại lai.
- Impact: Nhóm A1 sửa schema đẩy dữ liệu, thêm `zoneId`.

---

## Issue #2 (Đàm phán với Pair 06 - IoT)
- Raised by: Provider (Analytics)
- Endpoint: `POST /api/v1/webhooks/telemetry`
- Concern: Giá trị cảm biến (`value`) dễ bị đẩy nhầm thành chuỗi (String).
- Proposal: Ép kiểu dữ liệu của `value` trong OpenAPI schema bắt buộc là số (Number/Float). Nếu gửi chuỗi sẽ bị trả về 400 Bad Request.
- Resolution: Accepted
- Rationale: Analytics cần chạy hàm toán học realtime.
- Impact: A1 phải ép kiểu dữ liệu chặt chẽ trước khi gọi API.

---

## Issue #3 (Đàm phán chung cho cả 4 Pair)
- Raised by: Provider (Analytics)
- Endpoint: Tất cả các Webhook
- Concern: Sai lệch múi giờ giữa các máy chủ gây lỗi biểu đồ.
- Proposal: Trường `timestamp` phải dùng chuẩn ISO 8601 (UTC).
- Resolution: Accepted
- Rationale: Đồng bộ timeline chính xác tuyệt đối.
- Impact: 4 nhóm Consumer format lại Datetime trước khi POST.

---

## Issue #4 (Đàm phán với Pair 09 - Access Gate)
- Raised by: Provider (Analytics)
- Endpoint: `POST /api/v1/webhooks/access-logs`
- Concern: Sự cố mạng có thể khiến cổng gọi API trùng lặp một lượt quẹt thẻ nhiều lần.
- Proposal: Sử dụng trường `eventId` trong Body làm Idempotency Key. Nếu Analytics thấy ID trùng sẽ trả về HTTP 409 Conflict và không xử lý.
- Resolution: Accepted
- Rationale: Đảm bảo số đếm lưu lượng người ra vào không bị sai lệch.
- Impact: Access Gate phải sinh UUID duy nhất cho mỗi lượt quẹt.

---

## Issue #5 (Đàm phán với Pair 07 - Camera)
- Raised by: Consumer (Camera - A2)
- Endpoint: `POST /api/v1/webhooks/camera-motion`
- Concern: Gọi API quá nhiều lần mỗi giây khi có chuyển động liên tục sẽ bị dính lỗi 429 Too Many Requests từ máy chủ Analytics.
- Proposal: Đổi Endpoint thành dạng nhận mảng (Array) dữ liệu. Camera sẽ gom (Batch) 5 giây rồi gọi API 1 lần.
- Resolution: Accepted
- Rationale: Giảm tải kết nối HTTP TCP và tối ưu băng thông.
- Impact: Analytics đổi Request Body schema thành kiểu `type: array`.

---

## Issue #6 (Đàm phán với Pair 08 - Core Business)
- Raised by: Provider (Analytics)
- Endpoint: `POST /api/v1/webhooks/core-alerts`
- Concern: Khó kiểm soát định dạng phản hồi lỗi cho Consumer.
- Proposal: Mọi lỗi (4xx, 5xx) đều sẽ trả về cấu trúc chuẩn RFC 7807 (Problem Details).
- Resolution: Accepted
- Rationale: Tuân thủ đúng yêu cầu Contract-First của Lab 02.
- Impact: Consumer đọc lỗi dựa trên trường `type` và `detail` của Problem Details.

---

# Chốt hợp đồng v1.0

Provider sign-off: Nguyễn Hữu Tuấn Minh (Leader A5)  
Consumer sign-off: Leader các nhóm A1, A2, A3, A6    
Date: 2026-05-27