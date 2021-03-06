## ----setup, echo = FALSE------------------------------------------------------
NOT_CRAN <- identical(tolower(Sys.getenv("NOT_CRAN")), "true")
knitr::opts_chunk$set(
  echo = TRUE,
  eval = NOT_CRAN,
  collapse = TRUE,
  comment = "#>"
)

## ----get_phylo, fig.width = 7, fig.height = 7---------------------------------
library(fishtree)

tree <- fishtree_phylogeny(rank = "Tetraodontiformes")

plot(tree, show.tip.label = FALSE, no.margin = TRUE)

## ----fishbase, cache=TRUE-----------------------------------------------------
library(rfishbase)

tips <- gsub("_", " ", tree$tip.label, fixed = TRUE)

fb_results <- species(species_list = tips, fields = c("Species", "DemersPelag"))
fb_results <- fb_results[!is.na(fb_results$DemersPelag), ]
head(fb_results)

## ----get_reef-----------------------------------------------------------------
reef <- data.frame(tip = gsub(" ", "_", fb_results$Species),
                   is_reef = as.numeric(fb_results$DemersPelag == "reef-associated"))
head(reef)

## ----namecheck----------------------------------------------------------------
library(geiger)

rownames(reef) <- reef$tip
nc <- geiger::name.check(tree, reef)
nc

## ----droptip------------------------------------------------------------------
library(ape)
tree <- drop.tip(tree, nc$tree_not_data)

## ----clean--------------------------------------------------------------------
reef <- reef[!rownames(reef) %in% nc$data_not_tree, ]

## ----clean2-------------------------------------------------------------------
Ntip(tree) == nrow(reef)

## ----getrates-----------------------------------------------------------------
rates <- fishtree_tip_rates(rank = "Tetraodontiformes")
head(rates)

## ----merge--------------------------------------------------------------------
rates <- data.frame(tip = gsub(" ", "_", rates$species), dr = rates$dr)
rownames(rates) <- rates$tip
merged <- merge(reef, rates)

## ----dr_histo, fig.width = 7, fig.height = 7----------------------------------
breaks <- seq(min(merged$dr), max(merged$dr), length.out = 30)
hist(subset(merged, is_reef == 1)$dr, col = "orange", density = 20, angle = 135,
     breaks = breaks)
hist(subset(merged, is_reef == 0)$dr, col = "purple", density = 20, angle = 45,
     breaks = breaks, add = TRUE)

## ----plot_tree_dr, fig.width = 7, fig.height = 7------------------------------
# Plot tree and extract plotting data
plot(tree, show.tip.label = FALSE, no.margin = TRUE)
obj <- get("last_plot.phylo", .PlotPhyloEnv)

# Generate a color ramp
ramp <- grDevices::colorRamp(c("black", "red"), bias = 10)
tiporder <- match(rates$tip, tree$tip.label)
scaled_rates <- rates$dr / max(rates$dr, na.rm = TRUE)
tipcols <- apply(ramp(scaled_rates), 1, function(x) do.call(rgb, as.list(x / 255)))

# Place colored bars
for (ii in 1:length(tiporder)) {
    tip <- tiporder[ii]
    lines(x = c(obj$xx[tip] + 0.5, obj$xx[tip] * 1.5 + 0.5 + scaled_rates[ii]),
          y = rep(obj$yy[tip], 2),
          col = tipcols[ii])
}

## ----load_hisse---------------------------------------------------------------
library(hisse)

## ----run_bisse----------------------------------------------------------------
trans.rates.bisse <- TransMatMakerHiSSE()

pp.bisse.full <- hisse(tree, reef,
                       hidden.states = FALSE, sann = FALSE,
                       turnover = c(1, 2), eps = c(1, 1),
                       trans.rate = trans.rates.bisse)

pp.bisse.null <- hisse(tree, reef,
                       hidden.states = FALSE, sann = FALSE,
                       turnover = c(1, 1), eps = c(1, 1),
                       trans.rate = trans.rates.bisse)

## ----run_hisse----------------------------------------------------------------
trans.rates.hisse <- TransMatMakerHiSSE(hidden.traits = 1)
trans.rates.hisse <- ParEqual(trans.rates.hisse, c(1, 2, 1, 3, 1, 4, 1, 5))

pp.hisse.full <- hisse(tree, reef,
                       hidden.states = TRUE, sann = FALSE,
                       turnover = c(1, 2, 3, 4), eps = c(1, 1, 1, 1),
                       trans.rate = trans.rates.hisse)

## ----run_hisse_null-----------------------------------------------------------
pp.hisse.null2 <- hisse(tree, reef,
                        hidden.states = TRUE, sann = FALSE,
                        turnover = c(1, 1, 2, 2), eps = c(1, 1, 1, 1),
                        trans.rate = trans.rates.hisse)

## ----get_hisse_results--------------------------------------------------------
results <- list(pp.bisse.full, pp.bisse.null, pp.hisse.null2, pp.hisse.full)
aicc <- sapply(results, `[[`, "AICc")
lnl <- sapply(results, `[[`, "loglik")

data.frame(model = c("bisse_full", "bisse_null", "hisse_cid2", "hisse_full"), aicc, lnl)

