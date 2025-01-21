library(tidyverse)
library(lubridate)
library(gghighlight)
library(ggthemes)
library(ggridges)
library(ggplot2)
library(treemapify)
library(viridis)
library(hrbrthemes)
library(ggwordcloud)
library(ggdark)

rm(list = ls())

getwd()
setwd("D:/Trabajo/Code/Spotify_Wrapped")
getwd()

df <- read.csv("spotify_data/spotify_history.csv", header = TRUE)


# Preparing the data

spotify <- df %>%  mutate(
  ts = ymd_hms(ts),
  hour = hour(ts), # Convert character to timestamp
  date = as.Date(ts), # Extract date
  seconds = ms_played / 1000       # Calculate seconds from milliseconds
) %>%
  mutate(
    year = year(date), # Extract year
    month_num = month(date), # Extract month
    day = day(date), # Extract day
    day_of_week = wday(date, label = TRUE, abbr = FALSE) # Extract day of week
  ) %>%
  mutate(
    month = month.abb[month_num]
  ) %>%
  select(
    platform,
    hour,
    track_name,
    artist_name,
    seconds,
    album_name,
    year,
    month,
    day,
    day_of_week
  )  # Select columns of interest


#	Distribution of track duration
median_value <- median(spotify$seconds, na.rm = TRUE)
mean_value <- mean(spotify$seconds, na.rm = TRUE)

hist_tracks <- ggplot(spotify, aes(seconds)) +
  geom_histogram(
    aes(y = after_stat(density)),
    bins = 300,
    fill = "#6fcd64",
    color = "white"
  ) +
  annotate(
    "text",
    x = mean_value - 40,
    y = 0.015, label = paste("Mean =", round(mean_value), "s"),
    color = "white",
    size = 4,
    fontface = "bold"
  ) +
  annotate(
    "text",
    x = median_value + 40,
    y = 0.015, label = paste("Median =", round(median_value), "s"),
    color = "white",
    size = 4,
    fontface = "bold"
  ) +
  geom_vline(
    aes(xintercept = mean_value),
    color = "white",
    linewidth = 1,
    linetype = "dashed"
  ) +
  geom_vline(
    aes(xintercept = median_value),
    color = "white",
    linewidth = 1,
    linetype = "dotted"
  ) +
  labs(
    title = "Distribution of seconds listened per song",
    x = "Track Duration (s)",
    y = "Density"
  ) +
  coord_cartesian(xlim = c(0, 400)) +
  dark_theme_classic() +
  theme(plot.title = element_text(hjust = 0.5))

print(hist_tracks)

# Playback activity per month

ridge_act <- ggplot(
  spotify,
  aes(
    x = seconds,
    y = factor(month, levels = month.abb),
    fill = factor(after_stat(quantile))
  )
) +
  stat_density_ridges(
    geom = "density_ridges_gradient",
    calc_ecdf = TRUE,
    quantiles = 4,
    quantile_lines = TRUE
  ) +
  scale_fill_viridis_d(name = "Quartiles") +
  labs(
    title = "Distribution of seconds listened per song for each month",
    x = "Track Duration (s)",
    y = "Month"
  ) +
  coord_cartesian(xlim = c(0, 500)) +
  dark_theme_classic() +
  theme(
    axis.text.y = element_text(margin = margin(t = 10)),
    plot.title = element_text(hjust = 0.5)
  )

print(ridge_act)


# Playback activity per artist

artist <- spotify %>%
  group_by(artist_name) %>%
  summarize(minutes = sum(seconds) / 60) %>%
  slice_max(order_by = minutes, n = 20)

bar_artist <- ggplot(
  artist,
  aes(
    x = reorder(artist_name, minutes),
    y = minutes
  )
) +
  geom_col(fill = "#6fcd64") +
  coord_flip() +
  labs(
    title = "Top 20 Most Listened Artists",
    x = "Artist",
    y = "Minutes"
  ) +
  dark_theme_classic() +
  theme(
    axis.text.y = element_text(size = 13),
    plot.title = element_text(hjust = 0.5),
    axis.ticks.y = element_blank()
  )

print(bar_artist)

word_artist <- ggplot(
  artist,
  aes(
    label = artist_name,
    size = minutes,
    color = artist_name
  )
) +
  geom_text_wordcloud() +
  scale_size_area(max_size = 20) +
  labs(title = "Top 20 Most Listened Artists") +
  dark_theme_classic() +
  theme(plot.title = element_text(hjust = 0.5))

print(word_artist)


# Playback activity per song

song <- spotify %>%
  group_by(track_name) %>%
  summarize(minutes = sum(seconds) / 60) %>%
  slice_max(order_by = minutes, n = 20)

bar_song <- ggplot(song, aes(x = reorder(track_name, minutes), y = minutes)) +
  geom_col(fill = "#6fcd64") +
  coord_flip() +
  labs(title = "Top 20 Most Listened Songs",
    x = "Song",
    y = "Minutes"
  ) +
  dark_theme_classic() +
  theme(
    axis.text.y = element_text(size = 13),
    plot.title = element_text(hjust = 0.5),
    axis.ticks.y = element_blank()
  )

print(bar_song)

# Playback activity per album

album <- spotify %>%
  group_by(album_name) %>%
  summarize(minutes = sum(seconds) / 60) %>%
  slice_max(order_by = minutes, n = 20)

bar_album <- ggplot(album, aes(x = reorder(album_name, minutes), y = minutes)) +
  geom_col(fill = "#6fcd64") +
  coord_flip() +
  labs(
    title = "Top 20 Most Listened Albums",
    x = "Album",
    y = "Minutes"
  ) +
  dark_theme_classic() +
  theme(
    axis.text.y = element_text(size = 13),
    plot.title = element_text(hjust = 0.5),
    axis.ticks.y = element_blank()
  )

print(bar_album)


# Playback activity by time of the day

activity <- spotify %>%
  group_by(day_of_week, hour) %>%
  summarise(total_time = round(sum(seconds) / 60))

lolli_act <- ggplot(activity, aes(x = hour, y = total_time)) +
  geom_segment(
    aes(x = hour, xend = hour, y = 0, yend = total_time),
    color = "skyblue"
  ) +
  geom_point(
    aes(color = day_of_week, size = total_time),
    alpha = 0.5
  ) +
  scale_x_continuous(
    breaks = seq(0, 23, by = 1),
    labels = sprintf("%02d", seq(0, 23))
  ) +
  scale_colour_discrete() +
  labs(
    x = "Hour of Day",
    y = "Minutes",
    title = "Daily Activity"
  ) +
  dark_theme_classic() +
  theme(
    panel.grid.major.y = element_blank(),
    panel.grid.minor.y = element_blank(),
    panel.grid.minor.x = element_blank(),
    plot.title = element_text(hjust = 0.5)
  )

print(lolli_act)

# Heatmap of activity by day and hour

heatmap_act <- ggplot(
  activity,
  aes(x = "",
    y = factor(hour),
    fill = total_time
  )
) +
  geom_tile(aes(fill = total_time)) +
  scale_fill_gradient(
    low = "blue",
    high = "red"
  ) +
  labs(
    x = "",
    y = "Hour of Day",
    title = "Minutes Played Per Hour of Day"
  ) +
  scale_y_discrete(labels = function(x) sprintf("%02d:00", as.numeric(x))) +
  geom_text(
    aes(label = total_time),
    color = "white",
    size = 3
  ) +
  facet_wrap(~ day_of_week) +
  dark_theme_classic() +
  theme(
    axis.text.y = element_text(color = "white"),
    axis.ticks.y = element_line(color = "white"),
    axis.ticks.x = element_blank(),
    panel.grid.major.y = element_blank(),
    panel.grid.minor.y = element_blank(),
    strip.background = element_blank(),
    strip.text = element_text(size = 12),
    plot.title = element_text(hjust = 0.5)
  )

print(heatmap_act)


# Treemap of preferred platform

platform <- spotify %>%
  group_by(platform) %>%
  summarize(count = n()) %>%
  mutate(percentage = round((count / sum(count)) * 100, 2))


treemap_plat <- ggplot(
  platform,
  aes(
    area = percentage,
    fill = platform,
    label = paste(platform, sprintf("%.1f%%", percentage), sep = "\n")
  )
) +
  geom_treemap() +
  geom_treemap_text(
    colour = "white",
    place = "centre",
    size = 12
  ) +
  labs(title = "Music Platform Treemap") +
  dark_theme_classic() +
  theme(plot.title = element_text(hjust = 0.5))

print(treemap_plat)


# Line chart of total minutes played per year

year_act <- spotify %>%
  group_by(year, platform) %>%
  summarise(total_time = round(sum(seconds) / 60))

area_year <- ggplot(year_act, aes(x = year, y = total_time, fill = platform)) +
  geom_area(alpha = 0.6, position = "stack") +
  scale_fill_viridis_d() +
  scale_x_continuous(breaks = seq(2013, 2024, by = 1)) +
  scale_y_continuous(labels = scales::comma) +
  labs(
    title = "Playback Activity over the years",
    x = "Year",
    y = "Total Minutes",
    fill = "Platform"
  ) +
  dark_theme_classic() +
  theme(
    plot.title = element_text(hjust = 0.5),
    legend.position = "right"
  )

print(area_year)
