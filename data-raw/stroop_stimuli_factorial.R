library("dplyr")
library("tidyr")
library("tibble")

colors <- c("blue", "green", "red", "brown")
positions <- c("standing", "sitting")

congruent_stimuli <- tibble(word = colors,
			    font_color = colors,
			    congruency = "congruent") |>
    tidyr::crossing(positions)

incongruent_stimuli <- tibble(word = rep(colors, 3),
			      font_color = c(colors[c(2:4, 1)],
					     colors[c(3:4, 1:2)],
					     colors[c(4, 1:3)]),
			      congruency = "incongruent") |>
    tidyr::crossing(positions)

stroop_stimuli_factorial <- bind_rows(congruent_stimuli,
                                      congruent_stimuli,
                                      congruent_stimuli,
                                      congruent_stimuli,
                                      congruent_stimuli,
                                      congruent_stimuli,
                                      incongruent_stimuli,
                                      incongruent_stimuli) |>
    mutate(congruency = if_else(word == font_color, "congruent", "incongruent") |>
               as.factor(),
           positions = as.factor(positions),
           stimulus_id = row_number() |> as.factor(),
           word = factor(word),
           font_color = factor(font_color)) |>
    select(stimulus_id, everything())

usethis::use_data(stroop_stimuli_factorial, overwrite = TRUE)
