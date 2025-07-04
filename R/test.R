library(dplyr);  library(broom)

# ❶  Load your merged data exactly the same way
df <- readRDS(here::here("output", "AMZN", "AMZN_merged.rds")) |>
        arrange(date) |>
        tidyr::drop_na() |>
        dplyr::select(date, rtexcess, mkt_rf, smb, hml, rmw, cma, mom) |>
        dplyr::mutate(across(-date, as.numeric))       

# ❷  Extract rows 1-100 (or any 100-row slice you like)
sl <- df |> slice(1:100)

print(str(sl))
print(head(sl))