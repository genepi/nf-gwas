## Manhattan plot =====================
#sources: https://www.r-graph-gallery.com/101_Manhattan_plot.html with modifications
## << Prepare data for plotting ====================
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

## << Create Manhattan plot ===========================
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
                       name=expression("-log"[10]("p-value")),
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

## QQ plot =====================
#sources: Michele Filosi, Eurac Research Bozen (https://github.com/filosi/nf-gwas/commits?author=filosi) with modifications
## << Compute inflation (lambda gc) ============
compute.inflation <- function(x, log=FALSE) {
  if (sum(is.na(x)) > 1) {
    x <- x[!is.na(x)]
  }
  if (log){
    x <- 10**(-x)
  }
  chisq <- qchisq(x, 1, lower.tail = FALSE)
  lambda <- median(chisq) / qchisq(0.5, 1)
  return(lambda)
}

## << Create null distribution for qqplot =========
create_nulldist <- function(x, log=FALSE){
  n <- length(x)
  expected <- -log10(ppoints(n))
  if (log){
    xl <- x
  } else {
    xl <- -log10(x)
  }
  ix <- order(xl, decreasing=TRUE)
  newexp <- rep(1, n)
  newexp[ix] <- expected
  return(newexp)
}

## << -log10 ===================
mylog10 <- function(x){
  return(-log10(x))
  }

## << Create plot ====================

qq_plot <- function(df,
                    mafsplitting = FALSE,
                    mafbreaks = c(0, 0.0005, 0.005, 0.05, 1),
                    mafcol = "A1FREQ",
                    pvalcol_log = "LOG10P") {
  # calculate lambda
  overall.lmb <- compute.inflation(df %>% pull({{ pvalcol_log }}), log= TRUE)
  lmb.rounded <- round(overall.lmb, 2)
  # calculated expected values (with or without mafsplitting)
  if (!mafsplitting) {
    df$EXP <- create_nulldist(df %>% pull({{ pvalcol_log}}), log = TRUE)
  } else {
    df$MAFBRK <- cut(df %>% pull({{ mafcol }}), breaks=mafbreaks)
    df <- df %>%
      group_by(MAFBRK)  %>%
      mutate(
        across(
          any_of(pvalcol_log),
          ~create_nulldist(.x, log= TRUE),
          .names="EXP"))
  }
  # generate plot
  if (!mafsplitting) {
    qqp <- ggplot(df, aes_string("EXP", pvalcol_log)) +
      geom_abline() +
      geom_point(color="#779ECB") +
      theme_classic() +
      theme(legend.position = "none")
  } else {
    qqp <- ggplot(df, aes_string("EXP", pvalcol_log, color="MAFBRK")) +
      geom_abline() +
      geom_point() +
      theme_classic() +
      theme(legend.position = "right") +
      labs(color="MAF intervals") +
      scale_color_manual(values = c("#9ecae1",
                                    "#6baed6",
                                    "#4292c6",
                                    "#2171b5",
                                    "#08519c",
                                    "#08306b"))
  }
  qqp <- qqp +
    theme(
      legend.text = element_text(size = 12,
                               color = "black"),
      legend.title = element_text(size = 14,
                                color = "black"),
      panel.border = element_blank(),
      axis.text = element_text(size = 12,
                             color = "black"),
      axis.title = element_text(size = 14),
      axis.ticks = element_line(color = "black")) +
    labs(x = expression("Expected -log"[10]("p-value")),
         y = expression("Observed -log"[10]("p-value")))
  #set limits of axes to same length
  maximum <- max(max(df %>% pull({{ pvalcol_log }})), max(df$EXP))
  qqp <- qqp +
    ylim(0, maximum) +
    xlim(0, maximum)
  #add lambda
  xannot <- maximum - maximum*0.5
  yannot <- maximum - maximum*0.9
  qqp <- qqp +
    annotate(
      "text",
      x = xannot,
      y = yannot,
      size = 5,
      label = bquote(lambda == .(lmb.rounded)))
  return(qqp)
}
