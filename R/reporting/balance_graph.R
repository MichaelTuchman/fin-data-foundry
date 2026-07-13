balance_graph <- function(
    dt,
    ticks = c("monthly", "yearly", "weekly", "daily"),
    start_date = NULL,
    end_date = NULL,
    title = "Balance over time"
) {
  ticks <- match.arg(ticks)
  
  plot_dt <- data.table::copy(dt)
  
  if (is.null(start_date)) {
    start_date <- min(plot_dt$transaction_dt)
  }
  
  if (is.null(end_date)) {
    end_date <- max(plot_dt$transaction_dt)
  }
  
  data.table::setorder(
    plot_dt,
    account_label,
    transaction_dt
  )
  
  if (!"balance" %in% names(plot_dt)) {
    plot_dt[
      ,
      balance := -cumsum(amount),
      by = account_label
    ]
  }
  
  plot_dt <- plot_dt[
    transaction_dt >= start_date &
      transaction_dt <= end_date
  ]
  
  tick_settings <- switch(
    ticks,
    daily = list(
      date_breaks = "1 day",
      date_labels = "%b %d"
    ),
    weekly = list(
      date_breaks = "1 week",
      date_labels = "%b %d"
    ),
    monthly = list(
      date_breaks = "1 month",
      date_labels = "%b\n%Y"
    ),
    yearly = list(
      date_breaks = "1 year",
      date_labels = "%Y"
    )
  )
  
  ggplot2::ggplot(
    plot_dt,
    ggplot2::aes(
      x = transaction_dt,
      y = balance
    )
  ) +
    ggplot2::geom_hline(
      yintercept = 0,
      linewidth = 0.35,
      linetype = "dashed"
    ) +
    ggplot2::geom_line(
      linewidth = 0.8
    ) +
    ggplot2::facet_wrap(
      ggplot2::vars(account_label),
      scales = "free_y",
      ncol = 2
    ) +
    ggplot2::scale_x_date(
      date_breaks = tick_settings$date_breaks,
      date_labels = tick_settings$date_labels,
      limits = c(start_date, end_date),
      expand = ggplot2::expansion(
        mult = c(0.01, 0.02)
      )
    ) +
    ggplot2::scale_y_continuous(
      labels = scales::label_dollar(
        accuracy = 1,
        style_negative = "minus"
      ),
      expand = ggplot2::expansion(
        mult = c(0.05, 0.08)
      )
    ) +
    ggplot2::labs(
      title = title,
      x = "Transaction date",
      y = "Balance",
      caption = "Finance Foundry"
    ) +
    ggplot2::theme_minimal(
      base_size = 12
    ) +
    ggplot2::theme(
      plot.title = ggplot2::element_text(
        size = 20,
        face = "bold"
      ),
      plot.caption = ggplot2::element_text(
        face = "italic"
      ),
      strip.text = ggplot2::element_text(
        size = 11,
        face = "bold"
      ),
      strip.background = ggplot2::element_rect(
        fill = "grey92",
        color = NA
      ),
      panel.grid.minor = ggplot2::element_blank(),
      panel.grid.major.x = ggplot2::element_line(
        color = "grey90",
        linewidth = 0.3
      ),
      axis.title = ggplot2::element_text(
        face = "bold"
      ),
      axis.text.x = ggplot2::element_text(
        angle = 90,
        vjust = 0.5,
        hjust = 1,
        size = 7
      ),
      panel.spacing = grid::unit(
        1.2,
        "lines"
      )
    )
}