## List of packages used for data cleaning
library(tibble)
library(arrow)
library(dplyr)
library(purrr)

## List of packages used for plotting
library(ggplot2)
library(scales)
library(ggraph)
library(igraph)
library(ggiraph)

## Load arxiv taxonomy
source("arxiv_taxonomy.R")

## ...
arxiv_snapshot_raw <- read_parquet("arxiv.parquet")

## ...
arxiv_snapshot <- 
  arxiv_snapshot_raw |> 
  inner_join(arxiv_taxonomy, by = join_by(subcategory))


# Topic bubbles -------------------------------------------------------------------------------------

## Count papers per subcategory (filtering for top 3)
subcategory_counts <- 
  arxiv_snapshot |> 
  # filter(category %in% c("physics", "math", "cs", "q-bio", "stat")) |> 
  filter(category %in% c("physics", "math", "cs"), year == 2025L) |> 
  count(category, subcategory)

## Total per category
category_counts <- 
  subcategory_counts |> 
  group_by(category) |>
  reframe(n = sum(n))

## Edges for hierarchy
edges <- 
  bind_rows(
    tibble(from = "arxiv", to = category_counts$category),
    tibble(from = subcategory_counts$category, to = subcategory_counts$subcategory)
  )

## Vertices with category labels
vertices <- 
  bind_rows(
    tibble(name = "arxiv", n = sum(category_counts$n), my_depth = 0, label = "arXiv"),
    category_counts |> transmute(name = category, n, my_depth = 1, label = category),
    subcategory_counts |> transmute(name = subcategory, n, my_depth = 2, label = subcategory)
  ) |> 
  mutate(
    my_leaf = my_depth == 2,
    is_category = my_depth == 1
  )

## Build the graph
graph <- graph_from_data_frame(edges, vertices = vertices)

## Cirle plot showing categories and subcategories
plot_1 <-
  graph |> 
  ggraph(
    layout = "circlepack", 
    weight = n
  ) +
  geom_node_circle(
    aes(fill = as.factor(my_depth), color = as.factor(my_depth)), 
    colour = "white",
    show.legend = FALSE
  ) +
  geom_node_label(
    aes(label = ifelse(label == "cs", "CS", str_to_title(label)), filter = is_category), 
    size = 13 / .pt, 
    label.size = 1, 
    label.padding = unit(0.4, "lines"),
    colour = "black",
    fontface = "bold"
  ) +
  theme_void() +
  coord_fixed()

## ...
ggsave("arxiv_2025_top_three_categories.png", scale = 1, dpi = 600)


# How many authors are on each paper where the y-axis is the count of authors --------------------------------------------------------

# arxiv_snapshot |>
#   group_by(index) |> 
#   filter(categories == "cs.CL") |> 
#   ungroup() |> 
#   count(year, authors) |> 
#   # filter(authors < 25) |> 
#   ggplot(
#     aes(x = year, y = authors, fill = n)
#   ) +
#   geom_tile(
#     width = 1, 
#     height = 1, 
#     colour = "black", 
#     linewidth = 0.8,
#     show.legend = FALSE
#   ) +
#   scale_x_continuous(
#     breaks = 2001:2025,
#     labels = function(x) substr(as.character(x), 3, 4),
#     minor_breaks = 2000:2025 + 0.5,
#     expand = c(0.05, 0, 0.05, 0)
#   ) +
#   scale_y_continuous(
#     position = "right",
#     breaks = seq(1, 100, 5),
#     limits = c(0, 100.5),
#     minor_breaks = NULL,
#     expand = c(0.05, 0.05, 0, 0)
#   ) +
#   scale_fill_viridis_b(
#     direction = -1, 
#     begin = 0.4,
#     end = 1,
#     option = "B",
#     breaks = seq(1, 24, 1),
#     name = "Count"
#   ) +
#   labs(
#     title = "This is a real who-dun-it",
#     subtitle = "Number of authors on ML papers posted to arxiv, by year*",
#     x = NULL,
#     y = NULL
#   ) +
#   theme(
#     text = element_text(family = "sans"),
#     plot.title = element_text(size = 18, face = "bold"),
#     plot.subtitle = element_text(size = 16),
#     plot.caption = element_text(size = 16, colour = "grey40", face = "plain", hjust = 0, vjust = 0, margin = margin(t = 15, r = 0, b = 0, l = 0)),
#     plot.caption.position = "plot",
#     axis.text.x = element_text(size = 15, vjust = -1, margin = margin(t = -60, r = 0, b = 15, l = 0)),
#     axis.text.y.right = element_blank(),
#     axis.ticks.x = element_blank(),
#     axis.ticks.y = element_blank(),
#     panel.background = element_rect(fill = "#EEE"),
#     panel.grid.major.x = element_blank(),
#     panel.grid.minor.x = element_blank(),
#     panel.grid.major.y = element_blank(),
#     panel.grid.minor.y = element_blank()
#   )


# ## Get the ranks based on the highest average at the end
# arxiv_snapshot_top_5 <-
#   arxiv_snapshot |> 
#   filter(year == 2025) |> 
#   count(category_name) |> 
#   slice_max(n = 5, order_by = n) |> 
#   select("category_name") |> 
#   pull()

# ## ...
# plot_2 <-
#   arxiv_snapshot |>
#   filter(category_name %in% arxiv_snapshot_top_5) |> 
#   count(year, category_name) |> 
#   filter(year < 2025) |> 
#   ggplot(
#     aes(x = factor(year), y = n, colour = category_name, group = category_name, data_id = category_name, tooltip = category_name)
#     ) +
#   geom_line_interactive(
#     linewidth = 1.25, 
#     alpha     = 0.60
#     ) +
#   scale_x_discrete(
#     expand = c(0.05, 0, 0.1, 0),
#     breaks = as.character(c(2001, seq(2003, 2024, 3))),
#     guide = guide_axis(minor.ticks = TRUE)
#     ) +
#   scale_y_continuous(
#     expand = c(0, 0, 0.1, 0),
#     limits = c(0L, 5500L),
#     breaks = seq(0, 5000, 1000),
#     position = "right",
#     labels = label_comma()
#     ) +
#   scale_colour_manual(
#     values = c("Quantum Physics" = "#2B4F72", "General Relativity and Quantum Cosmology" = "#FFB500", "High Energy Physics - Theory" = "#2E8B57", "Mathematical Physics" = "#E31937", "High Energy Physics - Phenomenology" = "#8C428B"),
#     breaks = arxiv_snapshot_top_5
#       ) +
#   labs(
#     title    = "Higher and Higher",
#     subtitle = "Top five tagged categories, ranked by total papers*",
#     caption = "Source: ArXiv",
#     x        = NULL,
#     y        = NULL,
#     colour   = NULL
#     ) +
#   theme(
#     text                      = element_text(family = "sans"),
#     plot.title                = element_text(size = 18, face = "bold"),
#     plot.subtitle             = element_text(size = 16),
#     plot.caption              = element_text(size = 16, colour = "grey40", face = "plain", hjust = 0, vjust = 0, margin = margin(t = 15, r = 0, b = 0, l = 0)),
#     plot.caption.position     = "plot",
#     legend.text               = element_text(size = 13),
#     axis.text.x               = element_text(size = 15, vjust = 0.02, margin = margin(t = 5, r = 0, b = 0, l = 0)),
#     axis.text.y.right         = element_text(size = 15, margin = margin(t = 0, r = 5, b = 0, l = -45), hjust = 1, vjust = -0.4),
#     axis.ticks.x              = element_line(colour = "black", linewidth = 0.55),
#     axis.minor.ticks.x.bottom = element_line(colour = "black", linewidth = 0.55),
#     axis.ticks.length.x       = unit(x = 0.25, units = "cm"),
#     axis.minor.ticks.length.x = unit(x = 0.20, units = "cm"),
#     axis.ticks.y.right        = element_blank(),
#     panel.grid.major.x        = element_blank(),
#     panel.grid.minor.x        = element_blank(),
#     panel.grid.major.y        = element_line(linetype = 1, linewidth = 0.10, colour = "grey65"),
#     panel.grid.minor.y        = element_blank(),
#     panel.background          = element_rect(fill = "transparent"),
#     legend.position.inside    = c(0.25, 0.78),
#     legend.position           = "inside",
#     axis.line.x = element_line(colour = "black")
#     )

# ## ...
# girafe(
#   ggobj = plot_2,
#   width_svg  = 12,
#   height_svg = 6,
#   options = 
#     list(
#       opts_hover(css = "stroke-width: 5pt;"),
#       opts_hover_inv(css = "opacity: 0.10;"),
#       opts_tooltip(opacity = 0.80, offx = -80, offy = 25, delay_mouseover = 500, delay_mouseout = 500, css = "background-color: black; color: white; font-family: sans-serif; font-size: 15pt; padding-left: 8pt; padding-right: 8pt; padding-top: 5pt; padding-bottom: 5pt")
#       )
#   )
