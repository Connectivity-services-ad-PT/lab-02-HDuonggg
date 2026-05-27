# Biên bản đàm phán hợp đồng API - Phân hệ Analytics (A5)

- Cặp đàm phán: Pair 06, 07, 08, 09 (Nhóm A5 đàm phán với A1, A2, A6, A3)
- Product: Product A
- Provider: Analytics (A5)
- Consumer: IoT (A1), Camera (A2), Core Business (A6), Access Gate (A3)
- Phiên: v1.0
- Ngày: 2026-05-27

---

## Issue #1 (Đàm phán với Pair 06 - IoT)
- Raised by: Provider (Analytics)
- Endpoint: Topic `iot.telemetry.ingested`
- Concern: Cần khóa phân cụm để vẽ biểu đồ theo khu vực, nhưng Payload mặc định của IoT không có thông tin vị trí.
- Proposal: Thêm trường tùy chọn `zoneId` vào payload của sự kiện đo lường cảm biến.
- Resolution: Accepted
- Rationale: Giúp Analytics có thể nhóm (group by) các chỉ số tiêu thụ điện/nước theo từng tòa nhà mà không cần gọi ngược lại API của Core Business để tra cứu.
- Impact: Nhóm A1 cần sửa lại schema sinh dữ liệu, thêm trường `zoneId`.

---

## Issue #2 (Đàm phán với Pair 06 - IoT)
- Raised by: Provider (Analytics)
- Endpoint: Topic `iot.telemetry.ingested`
- Concern: Định dạng kiểu dữ liệu của giá trị cảm biến (`value`) dễ bị gửi nhầm thành chuỗi (String).
- Proposal: Ép kiểu dữ liệu của `value` bắt buộc phải là số (Number/Float) trong schema.
- Resolution: Accepted
- Rationale: Analytics cần chạy các hàm toán học (SUM, AVG) realtime. Nếu để chuỗi sẽ gây lỗi crash Worker khi ép kiểu.
- Impact: Nhóm IoT phải validate chặt kiểu dữ liệu trước khi đẩy vào Queue.

---

## Issue #3 (Đàm phán chung cho cả 4 Pair)
- Raised by: Provider (Analytics)
- Endpoint: Tất cả các Event
- Concern: Không thống nhất định dạng thời gian dẫn đến sai lệch biểu đồ thống kê khi các service chạy ở các server có múi giờ khác nhau.
- Proposal: Trường `timestamp` bắt buộc sử dụng định dạng ISO 8601 và múi giờ UTC (đuôi Z).
- Resolution: Accepted
- Rationale: UTC là chuẩn quốc tế, giúp Analytics đồng bộ timeline chính xác tuyệt đối từ mọi nguồn phát.
- Impact: Cả 4 nhóm Consumer phải format lại datetime trước khi đẩy event.

---

## Issue #4 (Đàm phán với Pair 09 - Access Gate)
- Raised by: Provider (Analytics)
- Endpoint: Topic `gate.access.logged`
- Concern: Sự cố rớt mạng có thể khiến cổng quẹt thẻ gửi trùng một lượt quẹt nhiều lần khi có mạng lại, làm sai lệch số lượng người ra vào tòa nhà.
- Proposal: Thêm trường `eventId` (chuẩn UUID) làm khóa Idempotency. Analytics sẽ drop các event có UUID đã tồn tại trong 24h qua.
- Resolution: Accepted
- Rationale: Đảm bảo tính chính xác cho báo cáo lưu lượng ra vào (Exactly-once processing mindset).
- Impact: Access Gate phải sinh UUID duy nhất cho mỗi lượt quẹt thẻ cứng.

---

## Issue #5 (Đàm phán với Pair 07 - Camera)
- Raised by: Consumer (Camera - A2)
- Endpoint: Topic `camera.motion.detected`
- Concern: Dữ liệu phát hiện chuyển động quá nhiều (50 khung hình/giây), nếu bắn lẻ tẻ sẽ gây sập Message Broker.
- Proposal: Cho phép Consumer đóng gói (Batch) dữ liệu, 5 giây bắn lên Queue một lần dưới dạng mảng (Array).
- Resolution: Accepted
- Rationale: Tối ưu băng thông mạng và giảm tải cho Analytics Worker.
- Impact: Analytics phải viết lại logic parse JSON để đọc mảng thay vì object đơn.

---

## Issue #6 (Đàm phán với Pair 08 - Core Business)
- Raised by: Provider (Analytics)
- Endpoint: Topic `core.alert.published`
- Concern: Nếu Core bắn payload thiếu thông tin (ví dụ thiếu mã `severity`), Analytics không biết phân loại màu sắc biểu đồ cảnh báo.
- Proposal: Các thông điệp sai Schema sẽ bị Analytics từ chối thẳng và đẩy vào luồng Dead-Letter Queue (DLQ).
- Resolution: Accepted
- Rationale: Giữ cho luồng dữ liệu chính vào Data Warehouse luôn sạch sẽ, không bị kẹt vì một tin nhắn lỗi.
- Impact: Core phải đảm bảo validate JSON chặt chẽ trước khi publish.

---

# Chốt hợp đồng v1.0

Provider sign-off: Nguyễn Hữu Tuấn Minh (Leader A5)  
Consumer sign-off: Leader các nhóm A1, A2, A3, A6 (Đã xác nhận qua group chung)    
Date: 2026-05-27