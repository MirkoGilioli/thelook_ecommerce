view: order_items {
  sql_table_name: `mydataset.order_items` ;;
  drill_fields: [id]

  # ----------------------------------------------------------------------
  # PRIMARY KEY & CORE DIMENSIONS
  # ----------------------------------------------------------------------
  dimension: id {
    primary_key: yes
    type: number
    description: "Unique identifier for each ordered item"
    sql: ${TABLE}.id ;;
  }

  dimension: order_id {
    type: number
    description: "Foreign key referencing the parent order"
    sql: ${TABLE}.order_id ;;
  }

  dimension: user_id {
    type: number
    description: "Foreign key referencing the customer user account"
    sql: ${TABLE}.user_id ;;
  }

  dimension: inventory_item_id {
    type: number
    description: "Foreign key referencing the specific inventory item"
    sql: ${TABLE}.inventory_item_id ;;
  }

  dimension: product_id {
    type: number
    description: "Foreign key referencing the product catalog"
    sql: ${TABLE}.product_id ;;
  }

  dimension: sale_price {
    type: number
    description: "Actual purchase price for this item"
    value_format_name: usd
    sql: ${TABLE}.sale_price ;;
  }

  dimension: status {
    type: string
    description: "Fulfillment status: Cancelled, Complete, Processing, Returned, Shipped"
    sql: ${TABLE}.status ;;
  }

  # ----------------------------------------------------------------------
  # TIMEFRAME DIMENSION GROUPS
  # ----------------------------------------------------------------------
  dimension_group: created {
    type: time
    timeframes: [raw, time, date, week, month, quarter, year]
    sql: ${TABLE}.created_at ;;
  }

  dimension_group: shipped {
    type: time
    timeframes: [raw, time, date, week, month, quarter, year]
    sql: ${TABLE}.shipped_at ;;
  }

  dimension_group: delivered {
    type: time
    timeframes: [raw, time, date, week, month, quarter, year]
    sql: ${TABLE}.delivered_at ;;
  }

  dimension_group: returned {
    type: time
    timeframes: [raw, time, date, week, month, quarter, year]
    sql: ${TABLE}.returned_at ;;
  }

  # ----------------------------------------------------------------------
  # ESCAPE ROOM BUSINESS PROBLEM DIMENSIONS
  # ----------------------------------------------------------------------
  dimension: is_returned {
    type: yesno
    description: "Room 2: Indicates if item was returned by customer"
    sql: ${status} = 'Returned' ;;
  }

  dimension: is_cancelled {
    type: yesno
    description: "Room 1 & 4: Indicates if item was cancelled before delivery"
    sql: ${status} = 'Cancelled' ;;
  }

  dimension: is_completed {
    type: yesno
    description: "Indicates if item was successfully delivered and kept"
    sql: ${status} = 'Complete' ;;
  }

  dimension: is_shipped {
    type: yesno
    description: "Indicates if item has departed the distribution center"
    sql: ${shipped_date} IS NOT NULL ;;
  }

  dimension: days_to_ship {
    type: number
    description: "Room 3: Processing lead time (days from order creation to shipment)"
    sql: DATE_DIFF(DATE(${shipped_date}), DATE(${created_date}), DAY) ;;
  }

  dimension: days_to_deliver {
    type: number
    description: "Room 3: Transit delivery duration (days from shipment to delivery)"
    sql: DATE_DIFF(DATE(${delivered_date}), DATE(${shipped_date}), DAY) ;;
  }

  dimension: total_fulfillment_days {
    type: number
    description: "Room 3: Total days from customer order placement to delivery"
    sql: DATE_DIFF(DATE(${delivered_date}), DATE(${created_date}), DAY) ;;
  }

  # ----------------------------------------------------------------------
  # MEASURES & ESCAPE ROOM METRICS
  # ----------------------------------------------------------------------
  measure: count {
    type: count
    description: "Total order items count"
    drill_fields: [detail*]
  }

  # Room 1: Vanishing Revenue & Top-Line Financials
  measure: total_gross_revenue {
    type: sum
    description: "Room 1: Gross revenue booked across all placed items"
    value_format_name: usd
    sql: ${sale_price} ;;
  }

  measure: total_revenue {
    type: sum
    description: "Room 1: Realized net revenue (excluding Cancelled & Returned items)"
    value_format_name: usd
    filters: [status: "-Cancelled,-Returned"]
    sql: ${sale_price} ;;
  }

  measure: total_lost_revenue {
    type: sum
    description: "Room 1: Total dollar value lost to cancellations and returns"
    value_format_name: usd
    filters: [status: "Cancelled,Returned"]
    sql: ${sale_price} ;;
  }

  measure: average_sale_price {
    type: average
    description: "Average selling price per item"
    value_format_name: usd
    sql: ${sale_price} ;;
  }

  # Room 2: Cursed Inventory & Return Rates
  measure: returned_count {
    type: count
    description: "Room 2: Total count of returned items"
    filters: [status: "Returned"]
  }

  measure: return_rate {
    type: number
    description: "Room 2: Return percentage (% of items returned)"
    value_format_name: percent_2
    sql: 1.0 * ${returned_count} / NULLIF(${count}, 0) ;;
  }

  measure: returned_lost_revenue {
    type: sum
    description: "Room 2: Dollar amount of lost revenue strictly from returns"
    value_format_name: usd
    filters: [status: "Returned"]
    sql: ${sale_price} ;;
  }

  # Room 4: Phantom Traffic & Cancellation Rates
  measure: cancelled_count {
    type: count
    description: "Room 4: Total count of cancelled items"
    filters: [status: "Cancelled"]
  }

  measure: cancellation_rate {
    type: number
    description: "Room 4: Cancellation percentage (% of items cancelled)"
    value_format_name: percent_2
    sql: 1.0 * ${cancelled_count} / NULLIF(${count}, 0) ;;
  }

  measure: cancelled_lost_revenue {
    type: sum
    description: "Room 4: Dollar amount of lost revenue strictly from cancellations"
    value_format_name: usd
    filters: [status: "Cancelled"]
    sql: ${sale_price} ;;
  }

  measure: complete_count {
    type: count
    description: "Total completed and realized items"
    filters: [status: "Complete"]
  }

  # Profit Margins
  measure: total_margin {
    type: number
    description: "Gross margin dollars (Revenue minus Inventory Cost)"
    value_format_name: usd
    sql: ${total_gross_revenue} - ${inventory_items.total_cost} ;;
  }

  measure: margin_rate {
    type: number
    description: "Gross profit margin percentage"
    value_format_name: percent_2
    sql: 1.0 * ${total_margin} / NULLIF(${total_gross_revenue}, 0) ;;
  }

  # Room 3: Logistics & Lead Time Measures
  measure: avg_days_to_ship {
    type: average
    description: "Room 3: Average warehouse processing days to ship"
    value_format_name: decimal_1
    sql: ${days_to_ship} ;;
  }

  measure: avg_days_to_deliver {
    type: average
    description: "Room 3: Average shipping transit days to customer"
    value_format_name: decimal_1
    sql: ${days_to_deliver} ;;
  }

  measure: avg_total_fulfillment_days {
    type: average
    description: "Room 3: Average total cycle time (order to delivery)"
    value_format_name: decimal_1
    sql: ${total_fulfillment_days} ;;
  }

  # ----------------------------------------------------------------------
  # DRILL SETS
  # ----------------------------------------------------------------------
  set: detail {
    fields: [
      id,
      users.last_name,
      users.id,
      users.first_name,
      inventory_items.id,
      inventory_items.product_name,
      products.name,
      products.id,
      orders.order_id
    ]
  }
}
