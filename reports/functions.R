## Prepare data for plotting ====================
manhattan_prep <- function(df) {
  df_prep <- df %>%
    # Compute chromosome size
    group_by(CHROM) %>%
    summarise(CHROM_len=max(GENPOS)) %>%

    # Calculate cumulative start position of each chromosome
    mutate(tot=cumsum(as.numeric(CHROM_len))-CHROM_len) %>%
    select(-CHROM_len) %>%

    # Add this info to the initial dataset
    left_join(df, ., by=c("CHROM"="CHROM")) %>%

    # Add a cumulative position of each SNP
    arrange(CHROM, GENPOS) %>%
    mutate( GENPOScum=GENPOS+tot)
  return(df_prep)

}

## Create Manhattan plot ===========================
#sources: https://www.r-graph-gallery.com/101_Manhattan_plot.html with modifications

manhattan_plot <- function(df_prep,
                           ymax = 0,
                           hlines = TRUE) {
  # prepare x axis
  axisdf <-  df_prep %>%
    group_by(CHROM) %>%
    summarize(center=( max(GENPOScum) + min(GENPOScum) ) / 2 )
  # prepare y axis
  if (ymax == 0) {
    ydim <- c(0, sum(max(df_prep$LOG10P), 0.5))
  } else {
    ydim <- c(0, ymax)
  }

  # create plot
  plot <- ggplot(df_prep, aes(x=GENPOScum, y=LOG10P)) +

    # Show all points
    geom_point(aes(color=as.factor(CHROM))) +
    scale_color_manual(values = rep(c("#779ECB", "#03254c"), 22 )) +

    # custom X axis:
    scale_x_continuous(label = axisdf$CHROM,
                       breaks= axisdf$center,
                       name = "Chromosome",
                       expand = c(0.01,0.01),
                       guide = guide_axis(check.overlap = TRUE)) +
    # custom y step 1annotation_limit
    scale_y_continuous(expand = c(0, 0),
                       name=expression(-log[10](italic(P))),
                       limits = ydim) +
    # Custom the theme:
    theme_classic() +
    theme(
      legend.position="none",
      panel.border = element_blank(),
      axis.text = element_text(size = 12,
                               color = "black"),
      axis.title = element_text(size = 14),
      axis.ticks = element_line(color = "black")
    )
  # switch hlines off
  if (hlines == TRUE) {
    plot <- plot +
      geom_hline(yintercept = -log10(5e-08),
                 linetype ="longdash",
                 color ="firebrick") + # genomewide significance
      geom_hline(yintercept = -log10(1e-5),
                 linetype ="longdash",
                 color ="darkgrey")  # suggestive significance
  } else {
    plot <- plot
  }
  return(plot)
}
