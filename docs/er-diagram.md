# Entity relationship diagram

```mermaid
erDiagram
    USERS ||--o{ SESSIONS : starts
    SESSIONS ||--o{ EVENTS : records
    PRODUCTS ||--o{ EVENTS : concerns
    USERS ||--o{ ORDERS : places
    SESSIONS ||--o{ ORDERS : converts_to
    EVENTS ||--o| ORDERS : purchase_event
    USERS {
      bigint user_id PK
      date signup_date
      text city
      text acquisition_channel
    }
    PRODUCTS {
      int product_id PK
      text name
      text category
      numeric price
    }
    SESSIONS {
      bigint session_id PK
      bigint user_id FK
      text device
      boolean discount_offered
      timestamp start_time
    }
    EVENTS {
      bigint event_id PK
      bigint session_id FK
      int product_id FK
      text event_type
      timestamp event_time
    }
    ORDERS {
      bigint order_id PK
      bigint user_id FK
      bigint session_id FK
      bigint purchase_event_id FK
      numeric total_amount
      numeric discount
      text payment_method
    }
```

`orders.purchase_event_id` connects a successful order to the corresponding purchase event. `discount_offered` belongs to a session because exposure must be available for both converting and non-converting sessions.
