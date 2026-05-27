# Webhook Contract sơ bộ — Phân hệ Analytics (A5)

> File này quy chuẩn hóa các API Webhook để Analytics (A5) tiếp nhận dữ liệu từ các hệ thống khác theo chuẩn REST API (Dùng cho Lab 02).

## 1. Thông tin dependency
- **Provider (Nơi nhận data):** Analytics (A5)
- **Consumer (Nơi gọi API):** IoT Ingestion (A1), Camera Stream (A2), Core Business (A6), Access Gate (A3)
- **Cơ chế:** REST HTTP POST (Webhooks)
- **Ngày:** 2026-05-27

---

## 2. API Endpoints (Giao thức truyền)

| Nguồn (Consumer) | Đích (Provider) | HTTP Method | Endpoint (URL Path) |
|---|---|---|---|
| IoT (A1) | Analytics (A5) | `POST` | `/api/v1/webhooks/telemetry` |
| Camera (A2) | Analytics (A5) | `POST` | `/api/v1/webhooks/camera-motion` |
| Core (A6) | Analytics (A5) | `POST` | `/api/v1/webhooks/core-alerts` |
| Gate (A3) | Analytics (A5) | `POST` | `/api/v1/webhooks/access-logs` |

---

## 3. Payload schema sơ bộ (Đặc tả JSON Body)

### Cấu trúc JSON mẫu cho `/api/v1/webhooks/telemetry` (A1 gọi A5)
```json
{
  "eventId": "123e4567-e89b-12d3-a456-426614174000",
  "occurredAt": "2026-05-27T10:00:00Z",
  "source": "A1",
  "data": {
    "deviceId": "SENSOR-001",
    "zoneId": "ZONE-A",
    "metric": "temperature",
    "value": 35.5
  }
}