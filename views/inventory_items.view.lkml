view: inventory_items {
  sql_table_name: `mydataset.inventory_items` ;;
  drill_fields: [id]

  dimension: id {
    primary_key: yes
    type: number
    description: "Unique identifier for each inventory item"
    sql: ${TABLE}.id ;;
  }

  dimension: cost {
    type: number
    description: "Unit cost of inventory item"
    value_format_name: usd
    sql: ${TABLE}.cost ;;
  }

  dimension_group: created {
    type: time
    timeframes: [raw, time, date, week, month, quarter, year]
    sql: ${TABLE}.created_at ;;
  }

  dimension: product_brand {
    type: string
    sql: ${TABLE}.product_brand ;;
  }

  dimension: product_category {
    type: string
    sql: ${TABLE}.product_category ;;
  }

  dimension: product_department {
    type: string
    sql: ${TABLE}.product_department ;;
  }

  dimension: product_distribution_center_id {
    type: number
    sql: ${TABLE}.product_distribution_center_id ;;
  }

  dimension: product_id {
    type: number
    sql: ${TABLE}.product_id ;;
  }

  dimension: product_name {
    type: string
    sql: ${TABLE}.product_name ;;
  }

  dimension: product_retail_price {
    type: number
    value_format_name: usd
    sql: ${TABLE}.product_retail_price ;;
  }

  dimension: product_sku {
    type: string
    sql: ${TABLE}.product_sku ;;
  }

  dimension_group: sold {
    type: time
    timeframes: [raw, time, date, week, month, quarter, year]
    sql: ${TABLE}.sold_at ;;
  }

  dimension: is_sold {
    type: yesno
    description: "Indicates whether the inventory item has been sold"
    sql: ${sold_date} IS NOT NULL ;;
  }

  # --- Measures ---
  measure: count {
    type: count
    description: "Total inventory items count"
    drill_fields: [id, product_name, products.name, products.id, order_items.count]
  }

  measure: total_cost {
    type: sum
    description: "Total cost across inventory items"
    value_format_name: usd
    sql: ${cost} ;;
  }

  measure: average_cost {
    type: average
    description: "Average cost per item"
    value_format_name: usd
    sql: ${cost} ;;
  }

  measure: unsold_count {
    type: count
    description: "Current unsold items in warehouse inventory"
    filters: [is_sold: "no"]
  }
}
