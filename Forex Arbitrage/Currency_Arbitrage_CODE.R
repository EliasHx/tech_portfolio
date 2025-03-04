# Load necessary libraries
library(dplyr)
library(ggplot2)

# Initial investment
Q <- 100000  

# Fixed exchange rates
exchange_rates <- list(
  "USD_to_CAD" = 1.43,
  "USD_to_EUR" = 0.95,
  "EUR_to_CAD" = 1.50
)

# Function to compute arbitrage opportunities for a given spread (0% to 1%)
calculate_arbitrage <- function(spread) {
  
  # Adjusted exchange rates with spread
  adjusted_rates <- list(
    "USD_to_CAD" = exchange_rates$USD_to_CAD * (1 - spread),
    "USD_to_EUR" = exchange_rates$USD_to_EUR * (1 - spread),
    "EUR_to_CAD" = exchange_rates$EUR_to_CAD * (1 - spread),
    "CAD_to_USD" = (1 / exchange_rates$USD_to_CAD) * (1 - spread),
    "EUR_to_USD" = (1 / exchange_rates$USD_to_EUR) * (1 - spread),
    "CAD_to_EUR" = (1 / exchange_rates$EUR_to_CAD) * (1 - spread)
  )
  
  # Define arbitrage paths
  paths <- list(
    "USD -> CAD -> EUR -> USD" = function(Q) {
      Q_CAD <- Q * adjusted_rates$USD_to_CAD
      Q_EUR <- Q_CAD * adjusted_rates$CAD_to_EUR
      Q_USD <- Q_EUR * adjusted_rates$EUR_to_USD
      return(Q_USD)
    },
    "USD -> EUR -> CAD -> USD" = function(Q) {
      Q_EUR <- Q * adjusted_rates$USD_to_EUR
      Q_CAD <- Q_EUR * adjusted_rates$EUR_to_CAD
      Q_USD <- Q_CAD * adjusted_rates$CAD_to_USD
      return(Q_USD)
    }
  )
  
  # Store results
  results <- list()
  
  for (path in names(paths)) {
    final_amount <- paths[[path]](Q)
    profit <- final_amount - Q
    results[[length(results) + 1]] <- data.frame(
      Spread = spread * 100,  # Convert to percentage
      Path = path,
      Profit = profit
    )
  }
  
  return(do.call(rbind, results))  
}

# Run calculations for spreads from 0% to 1% in steps of 0.1% (0.001)
spread_values <- seq(0.000, 0.010, by = 0.001)
arbitrage_results <- do.call(rbind, lapply(spread_values, calculate_arbitrage))

# Display the computed results (only profit)
arbitrage_results <- arbitrage_results %>% select(Spread, Path, Profit)
print(arbitrage_results)

# Plot: Profit vs. Spread for Both Paths
ggplot(arbitrage_results, aes(x = Spread, y = Profit, color = Path)) +
  geom_line(size = 1) +
  geom_point(size = 2) +
  theme_minimal() +
  labs(title = "Arbitrage Profit vs. Spread (0% to 1%)",
       x = "Spread (%)",
       y = "Profit ($)",
       color = "Arbitrage Path")