# set working directory for reading in dataset
setwd("C:/Users/jamie/OneDrive - University of Salford/ASDV/Assignment")

# load libraries
library(tidyverse)
library(dbplyr)
library(reshape2)
library(ggplot2)
library(grid)
library(gridExtra)
library(qqplotr)
library(moments)
library(pastecs)
library(rstatix)
library(corrplot)
library(psych)
library(ggstatsplot)
library(FSA)
library(ggfortify)
library(forecast)
library(GGally)

# load dataset
data <- read_csv("Jamie_Penhale_Jones_ASDV_data.csv")

# initial exploratory data analysis
view(data)
head(data)
glimpse(data)

# data preprocessing
# rename columns
data <- data %>% 
  rename(
    "year" = "Time",
    "country" = "Country Code",
    "ems_total" = "Total GHG emissions by sector (Mt CO2 eq) - Total including LUCF [CC.GHG.EMSE.IL]",
    "ems_agric" = "Total GHG emissions by sector (Mt CO2 eq) - Agriculture [CC.GHG.EMSE.AG]",
    "ems_build" = "Total GHG emissions by sector (Mt CO2 eq) - Building [CC.GHG.EMSE.BL]",
    "ems_elec_heat" = "Total GHG emissions by sector (Mt CO2 eq) - Electricity/Heat [CC.GHG.EMSE.EH]",
    "ems_energy" = "Total GHG emissions by sector (Mt CO2 eq) - Energy [CC.GHG.EMSE.EN]",
    "ems_industry" = "Total GHG emissions by sector (Mt CO2 eq) - Industrial Processes [CC.GHG.EMSE.IP]",
    "ems_man_const" = "Total GHG emissions by sector (Mt CO2 eq) - Manufacturing/Construction [CC.GHG.EMSE.MC]",
    "ems_transp" = "Total GHG emissions by sector (Mt CO2 eq) - Transportation [CC.GHG.EMSE.TR]",
    "agric_land_pc" = "Agricultural land (% of land area) [AG.LND.AGRI.ZS]",
    "gov_debt_pc" = "Central government debt, total (% of GDP) [GC.DOD.TOTL.GD.ZS]",
    "pop_total" = "Population, total [SP.POP.TOTL]",
    "urban_pop_pc" = "Urban population (% of total population) [SP.URB.TOTL.IN.ZS]",
    "ems_per_cap" =  "Per capita GHG emissions (tons/capita) [CC.GHG.PECA]",
    "ghg_growth_pc" = "GHG growth (annual %) [CC.GHG.GRPE]",
    "gdp_growth_pc" = "GDP growth (annual %) [NY.GDP.MKTP.KD.ZG]",
    "gdp_usd" = "GDP (current US$) [NY.GDP.MKTP.CD]",
    "gdp_per_cap_usd" = "GDP per capita (current US$) [NY.GDP.PCAP.CD]",
    "elec_consump" = "Electricity net consumption [CC.ELEC.CON]")

# drop columns - time code, country name
data = dplyr::select(data, -"Time Code", -"Country Name")
data
names(data)

# check types of variables
str(data)

# there are "chr" variables that should be numeric, but I need to deal with missing values first

# there appear to be many missing values for all countries in 2019
df_2019 <- data[data$year=="2019",]
df_2019

# filter df to remove all rows in 2019
data <- filter(data, year != "2019")
data

# "gov_debt_pc" column has values of ".." that need to be encoded to NA
na_rows <- data %>% 
  filter_all(any_vars(. %in% c('..')))

na_rows
tail(na_rows)
length(na_rows$`gov_debt_pc`)

# encode ".." to NA
data[data==".."] <- NA
sum(is.na(data))

# create new df to view the rows containing NA values
data_na <- data %>% filter_all(any_vars(is.na(.)))
data_na

length(data_na$`gov_debt_pc`)
length(data$`gov_debt_pc`)

sum_na_data <- data %>% 
  group_by(country) %>% summarise(NA_sum = sum(is.na(gov_debt_pc)))
sum_na_data
sum(sum_na_data$NA_sum !=0)
sum(sum_na_data$NA_sum == 14)

# drop gov-debt_pc as there is insufficient data to reliably impute the missing values
data <- dplyr::select(data, -gov_debt_pc)

# encode "chr" columns to "num"
glimpse(data)
cols_to_num <- c("year", "ems_total", "ems_agric", "ems_build",
                 "ems_elec_heat", "ems_energy", "ems_industry", "ems_man_const",
                 "ems_transp", "ems_per_cap", "ghg_growth_pc","gdp_growth_pc",
                 "gdp_usd", "gdp_per_cap_usd")

data[cols_to_num] <- sapply(data[cols_to_num], as.numeric)

# encode country to factor
data$country <- as.factor(data$country)
summary(data)

# df for ESP
esp_df <- filter(data, country=="ESP")

# df for POL
pol_df <- filter(data, country=="POL")

# df for ITA
ita_df <- filter(data, country=="ITA")

# df for DEU
deu_df <- filter(data, country=="DEU")

# df for FRA
fra_df <- filter(data, country=="FRA")

# create combined EU df from DEU, FRA, ITA, ESP, POL dfs
eu_list <- lst(deu_df, fra_df, ita_df, esp_df, pol_df)
eu_df <- bind_rows(eu_list)
eu_df <- dplyr::select(eu_df, -country)
eu_df <- eu_df %>% 
  group_by(year) %>% 
  summarise(across(c(ems_total, ems_agric, ems_build, 
                     ems_elec_heat, ems_energy, ems_industry, ems_man_const,
                     ems_transp, agric_land_pc, pop_total, urban_pop_pc,
                     ems_per_cap, ghg_growth_pc, gdp_growth_pc, gdp_usd,
                     gdp_per_cap_usd, elec_consump), sum))

# add EU as country for adding into main data
eu_df$country <- as.factor("EU")

# combine with main dataframe
data <- rbind(data, eu_df)
tail(data)

# remove the five EU countries from main dataframe as aggregated EU is added
data <- data[data$country!="FRA",]
data <- data[data$country!="ITA",]
data <- data[data$country!="DEU",]
data <- data[data$country!="POL",]
data <- data[data$country!="ESP",]


# order dataframe by year and country
data$country <- as.character(data$country)
data$country <- as.factor(data$country)
data <- data %>% 
  arrange(year, country)

# df for ems_total to calculate mean
ems_total_df <- data %>% 
  dplyr::select(year, country, ems_total) %>% 
  group_by(country)
ems_total_df_rs <- dcast(ems_total_df, country~...)
ems_total_df_rs

ems_total_df_summary <- ems_total_df %>% 
  group_by(year) %>% 
  summarise(avg_ems_total = mean(ems_total))

ems_total_df_summary
ems_total_df

# Descriptive Statistical Analysis
# set colours for plotting graphs
colours <- c("#73daa2",
            "#ec30a7",
            "#05bf4a",
            "#57439f",
            "#a3d22b",
            "#017cca",
            "#ce9300",
            "#c0b1ff",
            "#b95d00",
            "#00c6bb",
            "#a60f1a",
            "#006a43",
            "#ff72b5",
            "#ff7f00",
            "#853372",
            "#ffab8c",
            "#999999")

# line chart of total emissions over time
ggplot(data=data, aes(x=year, y=ems_total, colour=country)) +
  geom_point() +
  geom_line() +
  scale_colour_manual(values=colours) + 
  scale_y_continuous(expand = c(0, 0), limits = c(0, NA)) +
  ggtitle("Total Emissions by Country 2005-2018") +
  xlab("Year") + ylab("Total Emissions (Mt CO2 eq)") 

# line chart of total emissions per capita over time
ggplot(data=data, aes(x=year, y=ems_per_cap, colour=country)) +
  geom_point() +
  geom_line() +
  scale_colour_manual(values=colours) + 
  scale_y_continuous(expand = c(0, 0), limits = c(0, NA)) +
  ggtitle("Total Emissions per capita by Country 2005-2018") +
  xlab("Year") + ylab("Total Emissions per capita (Mt CO2 eq)") 

# histogram of ems_total
ggplot(data, aes(x=ems_total)) +
  geom_histogram(aes(y=..density..),binwidth=600, fill=colours[1]) +
  geom_density(alpha=0.2,fill=colours[2])
  
# line chart of mean total emissions over time
ggplot(ems_total_df_summary, aes(x=year, y=avg_ems_total)) +
  geom_point(color=colours[4]) +
  geom_line(color=colours[4]) +
  ggtitle("Mean Total GHG Emissions 2005-2018 ") +
  xlab("Year") + ylab("Mean Total Emissions (Mt CO2 eq)")

# plot gdp against total emissions
ggplot(data=data, aes(x=gdp_per_cap_usd, y=ems_total, colour=country)) +
  geom_point() +
  scale_colour_manual(values=colours)

# descriptive statistic summaries for each variable
summary_stats <- round(stat.desc(data, norm=TRUE), digits=2)
summary_stats <- dplyr::select(summary_stats, -year, -country)
# write.csv(summary_stats, "C:/Users/jamie/OneDrive - University of Salford/ASDV/Assignment/summary_stats.csv")

# plot histograms of distributions for emissions variables
ems_total_hist <- ggplot(data, aes(x=ems_total)) +
  geom_histogram(aes(y=..density..), bins=15, fill=colours[1]) +
  geom_density(color=colours[2]) +
  xlab("Total Emissions")

ems_agric <- ggplot(data, aes(x=ems_agric)) +
  geom_histogram(aes(y=..density..), bins=15,fill=colours[1]) +
  geom_density(color=colours[2]) +
  xlab("Agricultural Emissions")

ems_build_hist <- ggplot(data, aes(x=ems_build)) +
  geom_histogram(aes(y=..density..), bins=15,fill=colours[1]) +
  geom_density(color=colours[2]) +
  xlab("Building Emissions")

ems_elec_heat_hist <- ggplot(data, aes(x=ems_elec_heat)) +
  geom_histogram(aes(y=..density..), bins=15,fill=colours[1]) +
  geom_density(color=colours[2]) +
  xlab("Electricity/Heat Emissions") + 
  theme(axis.text=element_text(size=8))

ems_energy_hist <- ggplot(data, aes(x=ems_energy)) +
  geom_histogram(aes(y=..density..), bins=15,fill=colours[1]) +
  geom_density(color=colours[2]) +
  xlab("Energy Emissions")

ems_industry_hist <- ggplot(data, aes(x=ems_industry)) +
  geom_histogram(aes(y=..density..), bins=15,fill=colours[1]) +
  geom_density(color=colours[2]) +
  xlab("Industry Emissions")

ems_man_const_hist <- ggplot(data, aes(x=ems_man_const)) +
  geom_histogram(aes(y=..density..), bins=15,fill=colours[1]) +
  geom_density(color=colours[2]) +
  xlab("Manu/Const Emissions") + 
  theme(axis.text=element_text(size=8))

ems_transp_hist <- ggplot(data, aes(x=ems_transp)) +
  geom_histogram(aes(y=..density..), bins=15,fill=colours[1]) +
  geom_density(color=colours[2]) +
  xlab("Transportation Emissions") + 
  theme(axis.text=element_text(size=6))

ems_per_cap_hist <- ggplot(data, aes(x=ems_per_cap)) +
  geom_histogram(aes(y=..density..), bins=15,fill=colours[1]) +
  geom_density(color=colours[2]) +
  xlab("Emissions per capita")

grid.arrange(ems_total_hist, ems_agric, ems_build_hist, 
             ems_elec_heat_hist, ems_energy_hist, ems_industry_hist,
             ems_man_const_hist, ems_transp_hist, ems_per_cap_hist, 
             ncol=3, nrow=3, top = textGrob("Distributions of all Emissions Variables",
                            gp=gpar(fontsize=20,font=1)))

# plot histograms of distributions for non-emissions variables
pop_total_hist <- ggplot(data, aes(x=pop_total)) +
  geom_histogram(aes(y=..density..), bins=15, fill=colours[1]) +
  geom_density(color=colours[2]) +
  xlab("Total Population")

urban_pop_pc_hist <- ggplot(data, aes(x=urban_pop_pc)) +
  geom_histogram(aes(y=..density..), bins=15,fill=colours[1]) +
  geom_density(color=colours[2]) +
  xlab("Urban Population %")

ghg_growth_pc_hist <- ggplot(data, aes(x=ghg_growth_pc)) +
  geom_histogram(aes(y=..density..), bins=15,fill=colours[1]) +
  geom_density(color=colours[2]) +
  xlab("GHG Growth")

gdp_growth_pc_hist <- ggplot(data, aes(x=gdp_growth_pc)) +
  geom_histogram(aes(y=..density..), bins=15,fill=colours[1]) +
  geom_density(color=colours[2]) +
  xlab("GDP Growth")

gdp_usd_hist <- ggplot(data, aes(x=gdp_usd)) +
  geom_histogram(aes(y=..density..), bins=15,fill=colours[1]) +
  geom_density(color=colours[2]) +
  xlab("GDP (USD)")

gdp_per_cap_usd_hist <- ggplot(data, aes(x=gdp_per_cap_usd)) +
  geom_histogram(aes(y=..density..), bins=15,fill=colours[1]) +
  geom_density(color=colours[2]) +
  xlab("GDP per capita")

elec_consump_hist <- ggplot(data, aes(x=elec_consump)) +
  geom_histogram(aes(y=..density..), bins=15,fill=colours[1]) +
  geom_density(color=colours[2]) +
  xlab("Electricity Net Consumption")

grid.arrange(pop_total_hist, urban_pop_pc_hist, ghg_growth_pc_hist, 
             gdp_growth_pc_hist, gdp_usd_hist, gdp_per_cap_usd_hist,
             elec_consump_hist, ncol=3, nrow=3, 
             top = textGrob("Distributions of Other Variables", 
                            gp=gpar(fontsize=20,font=1)))

# assess normality of Total Emissions using q-q plot
ggplot(mapping=aes(sample=data$ems_total)) +
  stat_qq_point(size=2, color=colours[1]) +
  stat_qq_line(color=colours[2]) +
  xlab("Theoretical") + ylab("Sample") +
  ggtitle("Q-Q Plot of Total Emissions")

# shapiro-wilks test for normality of target variable
shapiro.test(data$ems_total)

# steps taken to attempt normalising data
# histograms of log-transformed variables
log_ems_total_hist <- ggplot(data, aes(x=log(ems_total))) +
  geom_histogram(aes(y=..density..), bins=15, fill=colours[1]) +
  geom_density(color=colours[2]) +
  xlab("log Total Emissions")

log_ems_agric <- ggplot(data, aes(x=log(ems_agric))) +
  geom_histogram(aes(y=..density..),bins=15,fill=colours[1])+
  geom_density(color=colours[2]) +
  xlab("log Agricultural Emissions")

log_ems_build_hist <- ggplot(data, aes(x=log(ems_build))) +
  geom_histogram(aes(y=..density..),bins=15,fill=colours[1])+
  geom_density(color=colours[2]) +
  xlab("log Building Emissions")

log_ems_elec_heat_hist <- ggplot(data, aes(x=log(ems_elec_heat))) +
  geom_histogram(aes(y=..density..),bins=15,fill=colours[1])+
  geom_density(color=colours[2]) +
  xlab("log Elec/Heat Emissions")

log_ems_energy_hist <- ggplot(data, aes(x=log(ems_energy))) +
  geom_histogram(aes(y=..density..),bins=15,fill=colours[1])+
  geom_density(color=colours[2]) +
  xlab("log Energy Emissions")

log_ems_industry_hist <- ggplot(data, aes(x=log(ems_industry))) +
  geom_histogram(aes(y=..density..),bins=15,fill=colours[1])+
  geom_density(color=colours[2]) +
  xlab("log Industry Emissions")

log_ems_man_const_hist <- ggplot(data, aes(x=log(ems_man_const))) +
  geom_histogram(aes(y=..density..),bins=15,fill=colours[1])+
  geom_density(color=colours[2]) +
  xlab("log Manu/Const Emissions") + 
  theme(axis.text=element_text(size=6))

log_ems_transp_hist <- ggplot(data, aes(x=log(ems_transp))) +
  geom_histogram(aes(y=..density..),bins=15,fill=colours[1])+
  geom_density(color=colours[2]) +
  xlab("log Transportation Emissions") + 
  theme(axis.text=element_text(size=6))

log_ems_per_cap_hist <- ggplot(data, aes(x=log(ems_per_cap))) +
  geom_histogram(aes(y=..density..), bins=15,fill=colours[1])+
  geom_density(color=colours[2]) +
  xlab("log Emissions per capita")

grid.arrange(log_ems_total_hist, log_ems_agric, 
             log_ems_build_hist, log_ems_elec_heat_hist, log_ems_energy_hist, 
             log_ems_industry_hist, log_ems_man_const_hist, log_ems_transp_hist, 
             log_ems_per_cap_hist, ncol=3, nrow=3,
             top = textGrob("Distributions of log-transformed Emissions Variables",
                            gp=gpar(fontsize=18,font=1)))

# histograms of log-transformed other variables
log_pop_total_hist <- ggplot(data, aes(x=log(pop_total))) +
  geom_histogram(aes(y=..density..), bins=15, fill=colours[1])+
  geom_density(color=colours[2]) +
  xlab("log Total Population")

log_urban_pop_pc_hist <- ggplot(data, aes(x=log(urban_pop_pc))) +
  geom_histogram(aes(y=..density..), bins=15,fill=colours[1])+
  geom_density(color=colours[2]) +
  xlab("log Urban Population %")

log_ghg_growth_pc_hist <- ggplot(data, aes(x=log(ghg_growth_pc))) +
  geom_histogram(aes(y=..density..),bins=15,fill=colours[1])+
  geom_density(color=colours[2]) +
  xlab("log GHG Growth")

log_gdp_growth_pc_hist <- ggplot(data, aes(x=log(gdp_growth_pc))) +
  geom_histogram(aes(y=..density..),bins=15,fill=colours[1])+
  geom_density(color=colours[2]) +
  xlab("log GDP Growth")

log_gdp_usd_hist <- ggplot(data, aes(x=log(gdp_usd))) +
  geom_histogram(aes(y=..density..), bins=15,fill=colours[1])+
  geom_density(color=colours[2]) +
  xlab("log GDP (USD)")

log_gdp_per_cap_usd_hist <- ggplot(data, aes(x=log(gdp_per_cap_usd))) +
  geom_histogram(aes(y=..density..), bins=15,fill=colours[1])+
  geom_density(color=colours[2]) +
  xlab("log GDP per capita")

log_elec_consump_hist <- ggplot(data, aes(x=log(elec_consump))) +
  geom_histogram(aes(y=..density..), bins=15,fill=colours[1])+
  geom_density(color=colours[2]) +
  xlab("log Electricity Net Consumption") + 
  theme(axis.text=element_text(size=6))

grid.arrange(log_pop_total_hist, log_urban_pop_pc_hist, log_ghg_growth_pc_hist, 
                 log_gdp_growth_pc_hist, log_gdp_usd_hist, log_gdp_per_cap_usd_hist,
                 log_elec_consump_hist, ncol=3, nrow=3, 
             top = textGrob("Distributions of log-transformed Other Variables", 
                            gp=gpar(fontsize=20,font=1)))

# boxplot of total emissions by year, showing CHN & USA as outliers
total_ems_by_year_box <- ggplot(data, aes(as.factor(year), ems_total)) +
  geom_boxplot(fill=colours[1:14]) + 
  ggtitle("Total Emissions by Year") +
  xlab("Year") + ylab("Total Emissions (Mt CO2 eq)")
total_ems_by_year_box

# boxplot of total emissions to show distance from China & USA to rest of countries
total_ems_by_country <- ggplot(data, aes(country, ems_total)) +
  geom_boxplot(fill=colours) +
  ggtitle("Annual Total Emissions 2005-2018 by Country") +
  xlab("Country") + ylab("Annual Total Emissions 2005-2018 (Mt CO2 eq)")
total_ems_by_country

# line chart of total emissions over time for CHN and USA (top 2 countries)
top2_countries <- filter(data, (country=="CHN" | country=="USA"))
top2_countries

top2_countries_line <- ggplot(data=top2_countries, aes(x=year, y=ems_total, colour=country)) +
  geom_point() +
  geom_line() +
  scale_colour_manual(values=colours[c(5, 15)]) +
  ggtitle("Plot of total emissions over time for China & USA") +
  xlab("Year") + ylab("Total Emissions")
top2_countries_line

# plot distributions of emissions variables with top 2 emitters removed
rest_of_g20_countries <- filter(data, (country !="CHN" & country !="USA"))
rest_of_g20_countries$country
ems_total_rest_of_g20_hist <- ggplot(rest_of_g20_countries, aes(x=ems_total)) +
  geom_histogram(aes(y=..density..), bins=15, fill=colours[1]) +
  geom_density(color=colours[2]) +
  xlab("Total Emissions")

ems_agric_rest_of_g20_hist <- ggplot(rest_of_g20_countries, aes(x=ems_agric)) +
  geom_histogram(aes(y=..density..), bins=15,fill=colours[1]) +
  geom_density(color=colours[2]) +
  xlab("Agricultural Emissions")

ems_build_rest_of_g20_hist <- ggplot(rest_of_g20_countries, aes(x=ems_build)) +
  geom_histogram(aes(y=..density..), bins=15,fill=colours[1]) +
  geom_density(color=colours[2]) +
  xlab("Building Emissions")

ems_elec_heat_rest_of_g20_hist <- ggplot(rest_of_g20_countries, aes(x=ems_elec_heat)) +
  geom_histogram(aes(y=..density..), bins=15,fill=colours[1]) +
  geom_density(color=colours[2]) +
  xlab("Elec/Heat Emissions")

ems_energy_rest_of_g20_hist <- ggplot(rest_of_g20_countries, aes(x=ems_energy)) +
  geom_histogram(aes(y=..density..), bins=15,fill=colours[1]) +
  geom_density(color=colours[2]) +
  xlab("Energy Emissions")

ems_industry_rest_of_g20_hist <- ggplot(rest_of_g20_countries, aes(x=ems_industry)) +
  geom_histogram(aes(y=..density..), bins=15,fill=colours[1]) +
  geom_density(color=colours[2]) +
  xlab("Industry Emissions")

ems_man_const_rest_of_g20_hist <- ggplot(rest_of_g20_countries, aes(x=ems_man_const)) +
  geom_histogram(aes(y=..density..), bins=15,fill=colours[1]) +
  geom_density(color=colours[2]) +
  xlab("Manu/Const Emissions")

ems_transp_rest_of_g20_hist <- ggplot(rest_of_g20_countries, aes(x=ems_transp)) +
  geom_histogram(aes(y=..density..), bins=15,fill=colours[1]) +
  geom_density(color=colours[2]) +
  xlab("Transportation Emissions")

ems_per_cap_rest_of_g20_hist <- ggplot(rest_of_g20_countries, aes(x=ems_per_cap)) +
  geom_histogram(aes(y=..density..), bins=15,fill=colours[1]) +
  geom_density(color=colours[2]) +
  xlab("Emissions per capita")

grid.arrange(ems_total_rest_of_g20_hist, ems_agric_rest_of_g20_hist,
             ems_build_rest_of_g20_hist, ems_elec_heat_rest_of_g20_hist, ems_energy_rest_of_g20_hist,
             ems_industry_rest_of_g20_hist, ems_man_const_rest_of_g20_hist, ems_transp_rest_of_g20_hist, 
             ems_per_cap_rest_of_g20_hist, ncol=3, nrow=3, 
             top = 
               textGrob("Distributions of all Emissions Variables excluding CHN & USA",
                            gp=gpar(fontsize=16,font=1)))

# plot distributions of non-emissions variables with top 2 emitters removed
pop_total_rest_of_g20_hist <- ggplot(rest_of_g20_countries, aes(x=pop_total)) +
  geom_histogram(aes(y=..density..), bins=15, fill=colours[1]) +
  geom_density(color=colours[2]) +
  xlab("Total Population")

urban_pop_pc_rest_of_g20_hist <- ggplot(rest_of_g20_countries, aes(x=urban_pop_pc)) +
  geom_histogram(aes(y=..density..), bins=15,fill=colours[1]) +
  geom_density(color=colours[2]) +
  xlab("Urban Population")

ghg_growth_pc_rest_of_g20_hist <- ggplot(rest_of_g20_countries, aes(x=ghg_growth_pc)) +
  geom_histogram(aes(y=..density..), bins=15,fill=colours[1]) +
  geom_density(color=colours[2]) +
  xlab("GHG Growth")

gdp_growth_pc_rest_of_g20_hist <- ggplot(rest_of_g20_countries, aes(x=gdp_growth_pc)) +
  geom_histogram(aes(y=..density..), bins=15,fill=colours[1]) +
  geom_density(color=colours[2]) +
  xlab("GDP Growth")

gdp_usd_rest_of_g20_hist <- ggplot(rest_of_g20_countries, aes(x=gdp_usd)) +
  geom_histogram(aes(y=..density..), bins=15,fill=colours[1]) +
  geom_density(color=colours[2]) +
  xlab("GDP (USD)")

gdp_per_cap_usd_rest_of_g20_hist <- ggplot(rest_of_g20_countries, aes(x=gdp_per_cap_usd)) +
  geom_histogram(aes(y=..density..), bins=15,fill=colours[1]) +
  geom_density(color=colours[2]) +
  xlab("GDP per capita")

elec_consump_rest_of_g20_hist <- ggplot(rest_of_g20_countries, aes(x=elec_consump)) +
  geom_histogram(aes(y=..density..), bins=15,fill=colours[1]) +
  geom_density(color=colours[2]) +
  xlab("Electricity Net Consumption")

grid.arrange(pop_total_rest_of_g20_hist, urban_pop_pc_rest_of_g20_hist, 
             ghg_growth_pc_rest_of_g20_hist, gdp_growth_pc_rest_of_g20_hist, gdp_usd_rest_of_g20_hist, 
             gdp_per_cap_usd_rest_of_g20_hist, elec_consump_rest_of_g20_hist, ncol=3, nrow=3, 
             top = 
               textGrob("Distributions of Other Variables excluding CHN & USA", 
                            gp=gpar(fontsize=16,font=1)))

# correlation analysis
# remove categorical variable "country" for correlation matrix
data_corr <- dplyr::select(data, -country)
str(data_corr)

# create correlation matrix
corr_matrix <- cor(data_corr, method="spearman")  
corr_matrix_p <- cor.mtest(data_corr, method="spearman", conf.level=0.95)

# correlation matrix visualisation - blank tiles have p-value < 0.05
corrplot(corr_matrix, p.mat=corr_matrix_p$p,  type="lower", method="square", 
         insig="blank", diag=FALSE, title = "Correlogram for Numerical Variables",
         mar=c(0,0,1,0), col = COL2('RdYlBu'), tl.srt=45, tl.col="black")

# full correlation statistics using psych library
corr_test <- corr.test(data_corr, method = "spearman", use = "complete.obs")
corr_test$ci

corr_test_full <- corr_test$ci
corr_test_full$r <- round(corr_test_full$r, digits=2)
corr_test_full$upper <- round(corr_test_full$upper, digits=2)
corr_test_full$lower <- round(corr_test_full$lower, digits=2)

# reorder columns
corr_test_full <- corr_test_full[,c(2,3,1,4)]
corr_test_full

# remove rows where p-value is more than significance level 0.05
corr_test_full <- filter(corr_test_full, p<=0.05)

# remove rows where correlation coefficient is less than 0.5
corr_test_full <- filter(corr_test_full, (r>=0.5) | (r<=-0.5))
corr_test_full <- corr_test_full[order(corr_test_full$r, decreasing = TRUE),]

# export corr_test_full for display in report
# write.csv(corr_test_full, "C:/Users/jamie/OneDrive - University of Salford/ASDV/Assignment/corr_test_full.csv")

# scatter plots of ems_total against the 3 most correlated variables
scatt_total_man_const <- ggplot(data, aes(x=ems_man_const, y=ems_total)) +
  geom_point(color=colours[1]) + labs(x="Manu/Cons Emissions", y="Total Emissions")

scatt_total_transp <- ggplot(data, aes(x=ems_transp, y=ems_total)) +
  geom_point(color=colours[1]) + labs(x="Transportation Emissions", y="Total Emissions")

scatt_total_energy <- ggplot(data, aes(x=ems_energy, y=ems_total)) +
  geom_point(color=colours[1]) + labs(x="Energy Emissions", y="Total Emissions")

grid.arrange(scatt_total_man_const, scatt_total_transp, scatt_total_energy, ncol=2, nrow=2, 
             top = textGrob("Relationships between Total Emissions and Correlated Variables", 
                            gp=gpar(fontsize=14,font=1)))

# hypothesis testing
# create df for rest of G20 countries with aggregated variables
rest_of_g20_df <- filter(data, (country !="CHN" & country !="USA"))
rest_of_g20_df <- rest_of_g20_df %>% 
  group_by(year) %>% 
  summarise(across(c(ems_total, ems_agric, ems_build, 
                     ems_elec_heat, ems_energy, ems_industry, ems_man_const,
                     ems_transp, agric_land_pc, pop_total, urban_pop_pc,
                     ems_per_cap, ghg_growth_pc, gdp_growth_pc, gdp_usd,
                     gdp_per_cap_usd, elec_consump), sum))

# add "Remaining G20" in country column for creating new df with china & usa
rest_of_g20_df$country <- as.factor("Remaining G20")

# combine with top2_countries dataframe
hypothesis_df <- rbind(top2_countries, rest_of_g20_df)

hypothesis_df_filtered <- hypothesis_df %>% 
  dplyr::select(year, country, ems_total, ems_man_const, ems_transp, ems_energy)

# boxplots of hypothesis_df for correlated variables by entity
ggplot(hypothesis_df_filtered, aes(country, ems_total)) +
  geom_boxplot(fill=colours[c(5, 16, 1)]) +
  ggtitle("Annual Total Emissions by Country") +
  xlab("Country") + ylab("Annual Total Emissions 2005-2018 (Mt CO2 eq)")

ggplot(hypothesis_df_filtered, aes(country, ems_man_const)) +
  geom_boxplot(fill=colours[c(5, 16, 1)]) +
  ggtitle("Annual Manufacturing/Construction Emissions by Country") +
  xlab("Country") + ylab("Manufacturing/Construction Emissions 2005-2018 (Mt CO2 eq)")

ggplot(hypothesis_df_filtered, aes(country, ems_transp)) +
  geom_boxplot(fill=colours[c(5, 16, 1)]) +
  ggtitle("Annual Transport Emissions by Country") +
  xlab("Country") + ylab("Annual Transport Emissions")

ggplot(hypothesis_df_filtered, aes(country, ems_energy)) +
  geom_boxplot(fill=colours[c(5, 16, 1)]) +
  ggtitle("Annual Energy Emissions by Country") +
  xlab("Country") + ylab("ANnual Energy Emissions")

# first hypothesis test using kruskal-wallis test
kruskal.test(ems_total ~ country, data=hypothesis_df_filtered)

# dunn's post hoc test for pairwise comparison for first hypothesis
dunnTest(ems_total ~ country, data=hypothesis_df_filtered, method="holm")

# second hypothesis test using kruskal-wallis test
kruskal.test(ems_man_const ~ country, data=hypothesis_df_filtered)

# dunn's post hoc test for pairwise comparison for second hypothesis
dunnTest(ems_man_const ~ country, data=hypothesis_df_filtered, method="holm")

# boxplot showing hypothesis test statistics
# ems_total tests
ggbetweenstats(
  data=hypothesis_df_filtered,
  x=country,
  y = ems_total,
  type = "nonparametric", 
  plot.type="box",
  pairwise_comparisons = TRUE,
  centrality.plotting=FALSE) + 
  ggtitle("Hypothesis Test for Annual Total Emissions by Country") +
  xlab("Country") + ylab("Annual Total Emissions(Mt CO2 eq)") +
  scale_y_continuous(limits = c(0, NA))

# ems_man_const tests
ggbetweenstats(
  data=hypothesis_df_filtered,
  x=country,
  y = ems_man_const,
  type = "nonparametric", 
  plot.type="box",
  pairwise_comparisons = TRUE,
  centrality.plotting=FALSE)  + 
  ggtitle("Hypothesis Test for Annual Manu/Const Emissions by Country") +
  xlab("Country") + ylab("Manufacturing/Construction Emissions (Mt CO2 eq)") +
  scale_y_continuous(limits = c(0, NA))

# regression analysis

# simple and multiple linear regression
# simple linear regression with 1 variable - ems_man_const
slr_model <- lm(ems_total ~ ems_man_const, data)
summary(slr_model)

# simple linear regression with 1 variable - ems_energy
slr_model2 <- lm(ems_total ~ ems_energy, data)
summary(slr_model2)

# multiple linear regression - ems_man_const + ems_energy
mlr_model <- lm(ems_total ~ ems_man_const + ems_energy, data)
summary(mlr_model)

# checking assumptions for the simple and multiple linear regression models
plot(slr_model, 1)
plot(slr_model, 2)
shapiro.test(slr_model$residuals)
plot(log(ems_total) ~ elec_consump, data, col="blue")
abline(slr_model, col="red")

plot(slr_model2, 1)
plot(slr_model2, 2)
shapiro.test(slr_model2$residuals)
plot(ems_total ~ ems_energy, data, col="blue")
abline(slr_model2, col="red")

plot(mlr_model, 1)
plot(mlr_model, 2)

# robust regression
library(robustbase) 

# robust 1 variable - ems_man_const
robust_lm <- lmrob(ems_total ~ ems_man_const, data=data)
summary(robust_lm)

# robust 1 variable - ems_energy
robust_lm2 <- lmrob(ems_total ~ ems_energy, data=data)
summary(robust_lm2)

# robust 2 variables - ems_man_const + ems_energy
robust_lm3 <- lmrob(ems_total ~ ems_man_const + ems_energy, data=data)
summary(robust_lm3)

# robust_lm3 is the best model - check assumptions
plot(robust_lm3, 1) # variance not constant
plot(robust_lm3, 2) # residuals not normally distributed
# double check residual normality
hist(robust_lm3$residuals)
shapiro.test(robust_lm3$residuals)
# residuals against fitted values
plot(robust_lm3, 3)

# aim to reduce residual errors by taking log of target variable
log_robust_lm2 <- lmrob(log(ems_total) ~ ems_man_const + ems_energy, data=data)
summary(log_robust_lm2)
plot(log_robust_lm2, 2)

# aim to reduce residual errors by taking sqrt of target variable
sqrt_robust_lm2 <- lmrob(sqrt(ems_total) ~ ems_man_const + ems_energy, data=data)
summary(sqrt_robust_lm2)
plot(sqrt_robust_lm2, 2)

# investigate outliers
ggplot(data=data, aes(x=ems_man_const, y=ems_total, colour=country)) +
  geom_point() +
  scale_colour_manual(values=colours) +
  ggtitle("Total Emissions by Manu/Constr Emissions for G20 2005-2018") +
  xlab("Manufacturing/Construction Emissions (Mt CO2 eq)") + ylab("Total Emissions (Mt CO2 eq)")

ggplot(data=data, aes(x=ems_energy, y=ems_total, colour=country)) +
  geom_point() +
  scale_colour_manual(values=colours) +
  ggtitle("Total Emissions by Energy Emissions for G20 2005-2018") +
  xlab("Energy Emissions (Mt CO2 eq)") + ylab("Total Emissions (Mt CO2 eq)")

# scatter plots of ems_total against the 3 most correlated variables for Rest of G20 countries only
scatt_total_man_const_rest_of_g20 <- ggplot(rest_of_g20_countries, aes(x=ems_man_const, y=ems_total)) +
  geom_point(color=colours[1])  +
  xlab("Manufacturing/Construction Emissions") + ylab("Total Emissions")

scatt_total_transp_rest_of_g20 <- ggplot(rest_of_g20_countries, aes(x=ems_transp, y=ems_total)) +
  geom_point(color=colours[1]) +
  xlab("Transportation Emissions") + ylab("Total Emissions")

scatt_total_energy_rest_of_g20 <- ggplot(rest_of_g20_countries, aes(x=ems_energy, y=ems_total)) +
  geom_point(color=colours[1]) +
  xlab("Energy Emissions") + ylab("Total Emissions")

grid.arrange(scatt_total_man_const_rest_of_g20, scatt_total_transp_rest_of_g20, scatt_total_energy_rest_of_g20,
             ncol=2, nrow=2, 
             top = textGrob("Relationships between Total Emissions and Correlated Variables excluding China & USA", 
                        gp=gpar(fontsize=12,font=1)))

# repeat robust regression models exluding usa and china
# 1 variable - ems_man_const
robust_lm_rest_of_g20 <- lmrob(ems_total ~ ems_man_const, data=rest_of_g20_countries)
summary(robust_lm_rest_of_g20)
plot(ems_total ~ ems_man_const, rest_of_g20_countries, col="blue")
abline(robust_lm_rest_of_g20, col="red")
plot(robust_lm_rest_of_g20, 1)
plot(robust_lm_rest_of_g20, 2)
plot(robust_lm_rest_of_g20, 3)
hist(robust_lm_rest_of_g20$residuals)

# 1 variable - ems_energy
robust_lm2_rest_of_g20 <- lmrob(ems_total ~ ems_energy, data=rest_of_g20_countries)
summary(robust_lm2_rest_of_g20)
plot(ems_total ~ ems_energy, data, col="blue")
abline(robust_lm2_rest_of_g20, col="red")
plot(robust_lm2_rest_of_g20, 1)
plot(robust_lm2_rest_of_g20, 2)
plot(robust_lm2_rest_of_g20, 3)
hist(robust_lm2_rest_of_g20$residuals)

# 2 variables 
robust_lm3_rest_of_g20 <- lmrob(ems_total ~ ems_man_const + ems_energy, data=rest_of_g20_countries)
summary(robust_lm3_rest_of_g20)
plot(robust_lm3_rest_of_g20, 1)
plot(robust_lm3_rest_of_g20, 2)
plot(robust_lm3_rest_of_g20, 3)

# quantile regression
# 1 variable - ems_man_const
library(quantreg)
rqfit <- rq(ems_total ~ ems_man_const, tau=0.5, data=data)
summary(rqfit, se="ker")

# comparison of simple linear and 1st quantile regression model lines for total emissions and manu/const emissions
ggplot(data, aes(ems_man_const, ems_total)) +
  geom_point() +
  geom_abline(aes(colour="Quantile", intercept=coef(rqfit)[1], slope=coef(rqfit)[2]), show.legend=FALSE) +
  geom_smooth(aes(colour="Linear"), method='lm', show.legend=NA) +
  ggtitle("Quantile and Linear Regression Comparison - Total by Manu/Const Emissions") +
  theme(plot.title=element_text(size=12)) +
  scale_colour_manual("", values=c("Quantile"="red", "Linear"="blue")) +
  xlab("Manufacturing/Costruction Emissions (Mt CO2 eq)") + ylab("Total Emissions (Mt CO2 eq)")
  

# 1 variable - ems_energy
rqfit2 <- rq(ems_total ~ ems_energy, tau=0.5, data=data)
summary(rqfit2, se="ker")

# 2 variables - ems_man_const + ems_energy
rqfit3 <- rq(ems_total ~ ems_man_const + ems_energy, tau=0.5, data=data)
summary(rqfit3, se="ker")

# evaluate the 3 quantile regression models with AIC score
AIC(rqfit)
AIC(rqfit2)
AIC(rqfit3)

names(data)

# time series
# dataframe for China only, create time series from China dataframe
china_df <- data %>% 
  filter(country=="CHN") %>% 
  dplyr::select(-country)

china_ems_total_ts <- ts(china_df$ems_total, 2005)
autoplot(china_ems_total_ts) + ggtitle("China's Total Emissions 2005-2018") +
  xlab("Year") + ylab("Total Emissions (Mt CO2 eq)")

china_df_ts <- china_df %>% 
  dplyr::select(-year) %>% 
  ts(2005)

china_emissions_vars <- china_df %>% 
  dplyr::select(-year, -agric_land_pc, -pop_total, -urban_pop_pc, -ghg_growth_pc, -gdp_growth_pc, -ems_per_cap, -gdp_usd, -gdp_per_cap_usd, -elec_consump)

china_correlating_vars <- china_df %>% 
  dplyr::select(ems_total, ems_man_const, ems_transp, ems_energy)

china_emissions_vars_ts <- ts(china_emissions_vars, 2005)
china_ems_transp_ts <- ts(china_df$ems_transp, 2005)
china_ems_energy_ts <- ts(china_df$ems_energy, 2005)
china_correlating_vars_ts <- ts(china_correlating_vars, 2005)

ggpairs(china_emissions_vars)
ggpairs(china_correlating_vars)

# split dataframe into training and test sets
china_ems_total_ts_window <- window(china_ems_total_ts, start=2005, end=2014)
china_ems_total_ts_window2 <- window(china_ems_total_ts, start=2015)

# fit simple ts models to the training set
china_ems_total_fit1 <- meanf(china_ems_total_ts_window, h=10)
china_ems_total_fit2 <- rwf(china_ems_total_ts_window, h=10)
china_ems_total_fit3 <- rwf(china_ems_total_ts_window, drift=TRUE, h=10)

# plot models against full china data
autoplot(china_ems_total_ts) +
  autolayer(china_ems_total_fit1, series="Mean", PI=FALSE) +
  autolayer(china_ems_total_fit2, series="Naive", PI=FALSE) +
  autolayer(china_ems_total_fit3, series="Drift", PI=FALSE) +
  xlab("Year") + ylab("Total Emissions (Mt CO2 eq)") + ggtitle("Simple Forecasts for China's Total Emissions") +
  guides(colour=guide_legend(title="Forecast"))

# evaluate models against test set
accuracy(china_ems_total_fit1, china_ems_total_ts_window2)
accuracy(china_ems_total_fit2, china_ems_total_ts_window2)
accuracy(china_ems_total_fit3, china_ems_total_ts_window2)

# Naive model best of the base model tests on the test set (data from 2015-2018)
checkresiduals(china_ems_total_fit2) # mean of residuals not zero so model can be improved

# multiple linear regression time series model
china_mlr_ts <- tslm(ems_total ~ ems_transp + ems_energy + ems_man_const, data=china_correlating_vars_ts)
summary(china_mlr_ts)

# ems_transp & ems_man_const not significant, drop these and refit model
china_mlr_ts2 <- tslm(ems_total ~ ems_energy, data=china_correlating_vars_ts)
summary(china_mlr_ts2)

# compare performance of models
CV(china_mlr_ts)
CV(china_mlr_ts2)

checkresiduals(china_mlr_ts2) # change in variation over time, otherwise all tests passed

# check residuals against variables in the emissions df to check for any relationship
china_emissions_vars[,"Residuals"] <- as.numeric(residuals(china_mlr_ts2))

plot1 <- ggplot(china_emissions_vars, aes(x=ems_agric, y=Residuals)) + geom_point(color=colours[2]) +
  xlab("Agricultural Emissions") + ylab("Residuals")
plot2 <- ggplot(china_emissions_vars, aes(x=ems_build, y=Residuals)) + geom_point(color=colours[2]) +
  xlab("Building Emissions") + ylab("Residuals")
plot3 <- ggplot(china_emissions_vars, aes(x=ems_elec_heat, y=Residuals)) + geom_point(color=colours[2]) +
  xlab("Elec/Heat Emissions") + ylab("Residuals")
plot4 <- ggplot(china_emissions_vars, aes(x=ems_energy, y=Residuals)) + geom_point(color=colours[2]) +
  xlab("Energy Emissions") + ylab("Residuals")
plot5 <- ggplot(china_emissions_vars, aes(x=ems_industry, y=Residuals)) + geom_point(color=colours[2]) +
  xlab("Industry Emissions") + ylab("Residuals")
plot6 <- ggplot(china_emissions_vars, aes(x=ems_man_const, y=Residuals)) + geom_point(color=colours[2]) +
  xlab("Manu/Const Emissions") + ylab("Residuals")
plot7 <- ggplot(china_emissions_vars, aes(x=ems_transp, y=Residuals)) + geom_point(color=colours[2]) +
  xlab("Transportation Emissions") + ylab("Residuals")

grid.arrange(plot1, plot2, plot3, plot4, plot5, plot6, plot7, nrow=3, 
             top = textGrob("Scatter Plots of Model Residuals with Emissions Variables", gp=gpar(fontsize=12,font=1)))

# check residuals against fitted values
cbind(Fitted = fitted(china_mlr_ts2), Residuals=residuals(china_mlr_ts2)) %>% 
  as.data.frame() %>% 
  ggplot(aes(x=Fitted, y=Residuals)) + geom_point() + ggtitle("Plot of Residual Errors against Fitted Values")

# plot of Total Emissions with fitted multiple linear regression times series model
autoplot(china_ems_total_ts, series="China Total Emissions") +
  autolayer(fitted(china_mlr_ts2), series="Fitted MLR Model") +
  xlab("Year") + ylab("Total Emissions (Mt CO2 eq)") + ggtitle("China's Total Emissions 2005-2018 with Fitted MLR Model") +
  guides(colour=guide_legend(title=""))

# create predictions from multiple linear regression model
china_mlr_forecast <- predict(china_mlr_ts2, china_correlating_vars_ts)
china_mlr_forecast <- forecast(china_mlr_forecast, h=5)
china_mlr_forecast
autoplot(china_mlr_forecast) +
  ggtitle("Forecast of China's Total Emissions using MLR") + xlab("Year") + ylab("Total Emissions (Mt CO2 eq)")

# simple exponential smoothing models
ses_model1 <- holt(china_ems_total_ts, h=5)
ses_model1$model

autoplot(china_ems_total_ts) +
  autolayer(ses_model1, series="Holt's Forecast", PI=FALSE) +
  ggtitle("Forecast of China's Total Emissions using Holt's Exponential Smoothing") +xlab("Year") + ylab("China's Total Emissions")

autoplot(ses_model1) +
  ggtitle("Forecast for China's Total Emissions using Holt's Exponential Smoothing") +
  xlab("Year")+ ylab("China's Total Emissions")
ses_model1[["model"]]

# ARIMA
# check if series is stationary
plot(china_ems_total_ts)
diff1 <- diff(china_ems_total_ts)
plot(diff1)
diff2 <- diff(china_ems_total_ts, differences=2)

# check ACF and PACF plots for autocorrelation
acf(diff2)
pacf(diff2)

# acf and pacf suggesting ARIMA(0,2,0) model, confirm with auto.arima()
auto.arima(china_ems_total_ts)

# create ARIMA(0,2,0) model
arima1 <- Arima(china_ems_total_ts, order=c(0,2,0))
summary(arima1)
checkresiduals(arima1)

autoplot(forecast(arima1, h=5))