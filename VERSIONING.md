# Lịch sử phiên bản (Changelog) — Phân hệ Analytics (A5)

Tài liệu này ghi nhận các thay đổi của hợp đồng sự kiện (Event Contract) và API qua từng phiên bản đàm phán.

## [1.0.0] - 2026-05-27

### Added (Thêm mới)
- Khởi tạo `event-contract-template.md` cho các luồng Queue Async: Pair 06 (IoT), Pair 07 (Camera), Pair 08 (Core Business), Pair 09 (Access Gate).
- Định nghĩa cấu trúc Metadata bắt buộc cho payload gửi đến Analytics (`eventId`, `occurredAt`, `correlationId`, `source`).
- Thiết lập 5 kịch bản xử lý rủi ro truyền tải và ngoại lệ dữ liệu (Duplicate, Out-of-order, Missing, Invalid Schema, Retry/DLQ).
- Khởi tạo `negotiation-log.md` và chốt hạ thành công 6 issue đàm phán với các phân hệ Producer (A1, A2, A3, A6).
- Hoàn thiện `analysis-provider.md` với các ràng buộc (constraints) kiểu dữ liệu và định dạng.