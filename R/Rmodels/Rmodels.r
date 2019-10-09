
# # R Regression Models
#
# **Topics**
#
# * R formula interface
# * Run and interpret variety of regression models in R
# * Factor contrasts to test specific hypotheses
# * Model comparisons
# * Predicted marginal effects

# ## Setup
#
# ### Software & materials
#
# You should have R and RStudio installed --- if not:
#
# * Download and install R: <http://cran.r-project.org>
# * Download and install RStudio: <https://www.rstudio.com/products/rstudio/download/#download>
#
# Download materials:
#
# * Download class materials at <https://iqss.github.io/dss-workshops-redux/R/Rmodels.zip>
# * Extract materials from `Rmodels.zip` and move to your desktop!
#
# Start RStudio and create a new project:
#
# * On Windows click the start button and search for RStudio. On Mac
#     RStudio will be in your applications folder.
# * In Rstudio go to `File -> New Project`.
# * Choose `Existing Directory` and browse to the `Rmodels` directory.
# * Choose `File -> Open File` and select the blank version of the `.Rmd` file.
#
# While R's built-in packages are powerful, in recent years there has
# been a big surge in well-designed *contributed packages* for R. 
# In particular, a collection of R packages called 
# [tidyverse](https://www.tidyverse.org/) have been 
# designed specifically for data science. All packages included in 
# `tidyverse` share an underlying design philosophy, grammar, and 
# data structures. We will use `tidyverse` packages throughout the 
# workshop, so let's install them now:

# install.packages("tidyverse")
library(tidyverse)

# ### Goals
#
# Class Structure and Organization:
#
# * Ask questions at any time. Really!
# * Collaboration is encouraged - please spend a minute introducing yourself to your neighbors!
#
# This is an intermediate R course:
#
# * Assumes working knowledge of R
# * Relatively fast-paced
# * This is not a statistics course! We assume you know the theory behind the models

# ## Before fitting a model
#
# ### Load the data
#
# List the data files we're going to work with:

list.files("dataSets")

# We're going to use the `states` data first, which originally appeared in *Statistics with Stata* by Lawrence C. Hamilton.

  # read the states data
  states_data <- read_rds("dataSets/states.rds") 

# | Variable | Description                                        |
# |:---------|:---------------------------------------------------|
# | csat     | Mean composite SAT score                           |
# | expense  | Per pupil expenditures                             |
# | percent  | % HS graduates taking SAT                          |
# | income   | Median household income, $1,000                    |
# | region   | Geographic region: West, N. East, South, Midwest   |
# | house    | House '91 environ. voting, %                       |
# | senate   | Senate '91 environ. voting, %                      |
# | energy   | Per capita energy consumed, Btu                    |
# | metro    | Metropolitan area population, %                    |
# | waste    | Per capita solid waste, tons                       |

# ### Examine the data
#
# Start by examining the data to check for problems.

  # summary of expense and csat columns, all rows
  sts_ex_sat <- subset(states_data, select = c("expense", "csat"))
  summary(sts.ex.sat)
  # correlation between expense and csat
  cor(sts_ex_sat) 

# ### Plot the data
#
# Plot the data to look for multivariate outliers, non-linear relationships etc.

  # scatter plot of expense vs csat
  plot(sts_ex_sat)

# ![](R/Rmodels/images/statesCorr1.png)

# ## Regression with continuous outcomes
#
# * Ordinary least squares (OLS) regression models can be fit with the `lm()` function
# * For example, we can use `lm` to predict SAT scores based on per-pupal expenditures:

  # Fit our regression model
  sat_mod <- lm(csat ~ expense, # regression formula
                data=states_data) # data 
                
  # Summarize and print the results
  summary(sat_mod) # show regression coefficients table

# ### Why is the association between expense and SAT scores *negative*?
#
# Many people find it surprising that the per-capita expenditure on students is negatively related to SAT scores. The beauty of multiple regression is that we can try to pull these apart. What would the association between expense and SAT scores be if there were no difference among the states in the percentage of students taking the SAT?

  lm(csat ~ expense + percent, data = states_data) %>% 
  summary()

# ### The `lm` class and methods
#
# OK, we fit our model. Now what?
#
# * Examine the model object:

  class(sat_mod)
  str(sat_mod)
  names(sat_mod)
  methods(class = class(sat_mod))

# * Use function methods to get more information about the fit

  summary(sat_mod)
  summary(sat_mod) %>% coef()
  methods("summary")
  confint(sat_mod)

# ### OLS regression assumptions
#
# * OLS regression relies on several assumptions, including that the residuals are normally distributed and homoscedastic, the errors are independent and the relationships are linear.
# * Investigate these assumptions visually by plotting your model:

  par(mfrow = c(2, 2)) 
  plot(sat_mod)

# ### Comparing models
#
# Do congressional voting patterns predict SAT scores over and above expense? Fit two models and compare them:

  # fit another model, adding house and senate as predictors
  sat_voting_mod <- lm(csat ~ expense + house + senate,
                        data = na.omit(states_data))

  sat_mod <- update(sat_mod, data=na.omit(states_data))

  # compare using the anova() function
  anova(sat_mod, sat_voting_mod)
  summary(sat_voting_mod) %>% coef()

# ## Exercise 0
#
# **Ordinary least squares regression**
#
# Use the *states.rds* data set. Fit a model predicting energy consumed per capita (energy) from the percentage of residents living in metropolitan areas (metro). Be sure to
#
# 1.  Examine/plot the data before fitting the model
# 2.  Print and interpret the model `summary`
# 3.  `plot` the model to look for deviations from modeling assumptions
#
# Select one or more additional predictors to add to your model and repeat steps 1-3. Is this model significantly better than the model with *metro* as the only predictor?

# ## Interactions and factors
#
# ### Modeling interactions
#
# Interactions allow us assess the extent to which the association between one predictor and the outcome depends on a second predictor. For example: Does the association between expense and SAT scores depend on the median income in the state?

    # Add the interaction to the model
  sat_expense_by_percent <- lm(csat ~ expense + income + expense : income, data=states_data)
  sat_expense_by_percent <- lm(csat ~ expense * income, data=states_data) # same as above, but shorter syntax

  # Show the regression coefficients table
  summary(sat_expense_by_percent) %>% coef() 

# ### Regression with categorical predictors
#
# Let's try to predict SAT scores from region, a categorical variable. 
# Note that you must make sure R does not think your categorical variable is numeric.

  # make sure R knows region is categorical
  str(states_data$region)
  states_data$region <- factor(states_data$region)

  # Add region to the model
  sat_region <- lm(csat ~ region, data=states_data) 

  # Show the results
  summary(sat_region) %>% coef() # show the regression coefficients table
  anova(sat_region) # show ANOVA table

# Again, **make sure to tell R which variables are categorical by converting them to factors!**
#
# ### Setting factor reference groups and contrasts
#
# In the previous example we use the default contrasts for region. The default in R is treatment contrasts, with the first level as the reference. We can change the reference group or use another coding scheme using the `C` function.

  # print default contrasts
  contrasts(states_data$region)

  # change the reference group
  states_data$region <- relevel(states_data$region, ref = "Midwest")
  m1 <- lm(csat ~ region, data=states_data)
  summary(m1) %>% coef()

  # get all pairwise contrasts between means
  # install.packages("emmeans")
  library(emmeans)
  means <- emmeans(m1, specs = ~ region)
  means
  contrast(means, method = "pairwise")

  # change the coding scheme
  lm(csat ~ C(region, contr.helmert), data=states_data) %>%
  summary() %>%
  coef()

# See `?contr.treatment` for other coding schemes and also `?contrasts` and `?relevel`.

# ## Exercise 1
#
# **Interactions and factors**
#
# Use the states data set.
#
# 1.  Add on to the regression equation that you created in exercise 1 by generating an interaction term and testing the interaction.
#
# 2.  Try adding region to the model. Are there significant differences across the four regions?

# ## Regression with binary outcomes
#
# ### Logistic regression
#
# This far we have used the `lm` function to fit our regression models. `lm` is great, but limited--in particular it only fits models for continuous dependent variables. For categorical dependent variables we can use the `glm()` function.
#
# For these models we will use a different dataset, drawn from the National Health Interview Survey. From the [CDC website](http://www.cdc.gov/nchs/nhis.htm):
#
# > The National Health Interview Survey (NHIS) has monitored the health of the nation since 1957. NHIS data on a broad range of health topics are collected through personal household interviews. For over 50 years, the U.S. Census Bureau has been the data collection agent for the National Health Interview Survey. Survey results have been instrumental in providing data to track health status, health care access, and progress toward achieving national health objectives.
#
# Load the National Health Interview Survey data:

  NH11 <- read_rds("dataSets/NatHealth2011.rds")

# ### Logistic regression example
#
# Let's predict the probability of being diagnosed with hypertension based on age, sex, sleep, and bmi

  str(NH11$hypev) # check stucture of hypev
  levels(NH11$hypev) # check levels of hypev

  # collapse all missing values to NA
  NH11$hypev <- factor(NH11$hypev, levels=c("2 No", "1 Yes"))

  # run our regression model
  hyp_out <- glm(hypev ~ age_p + sex + sleep + bmi,
                data = NH11, family = binomial(link = "logit"))
  summary(hyp_out) %>% coef()

# ### Logistic regression coefficients
#
# Generalized linear models use link functions, so raw coefficients are difficult to interpret. For example, the age coefficient of .06 in the previous model tells us that for every one unit increase in age, the log odds of hypertension diagnosis increases by 0.06. Since most of us are not used to thinking in log odds this is not too helpful!
#
# One solution is to transform the coefficients to make them easier to interpret

  hyp_out_tab <- summary(hyp_out) %>% coef()
  hyp_out_tab[, "Estimate"] <- coef(hyp_out) %>% exp()
  hyp_out_tab

# ### Packages for computing and graphing predicted values
#
# Instead of doing all this ourselves, we can use the effects package to compute quantities of interest for us.

  library(effects)
  eff <- allEffects(hyp_out)
  eff2 <- allEffects(hyp_out, xlevels = list(age_p, seq(20, 80, by = 5)))
  plot(eff)
  as.data.frame(eff) # confidence intervals

# ![](R/Rmodels/images/effects1.png)

# ## Exercise 2 
#
# **Logistic regression**
#
# Use the NH11 data set that we loaded earlier.
#
# 1.  Use glm to conduct a logistic regression to predict ever worked (everwrk) using age (age_p) and marital status (r_maritl).
# 2.  Predict the probability of working for each level of marital status.
#
# Note that the data is not perfectly clean and ready to be modeled. You will need to clean up at least some of the variables before fitting the model.

# ## Multilevel modeling
#
# ### Multilevel modeling overview
#
# * Multi-level (AKA hierarchical) models are a type of mixed-effects models
# * Used to model variation due to group membership where the goal is to generalize to a population of groups
# * Can model different intercepts and/or slopes for each group
# * Mixed-effecs models include two types of predictors: fixed-effects and random effects
#   + Fixed-effects -- observed levels are of direct interest (.e.g, sex, political party...)
#   + Random-effects -- observed levels not of direct interest: goal is to make inferences to a population represented by observed levels
#   + In R the lme4 package is the most popular for mixed effects models
#   + Use the `lmer` function for liner mixed models, `glmer` for generalized mixed models

  library(lme4)

# ### The Exam data
#
# The Exam data set contans exam scores of 4,059 students from 65 schools in Inner London. The variable names are as follows:
#
# | Variable | Description                             |
# |:---------|:----------------------------------------|
# | school   | School ID - a factor.                   |
# | normexam | Normalized exam score.                  |
# | standLRT | Standardised LR test score.             |
# | student  | Student id (within school) - a factor   |

  Exam <- read_rds("dataSets/Exam.rds")

# ### The null model and ICC
#
# As a preliminary step it is often useful to partition the variance in the dependent variable into the various levels. This can be accomplished by running a null model (i.e., a model with a random effects grouping structure, but no fixed-effects predictors).

  # null model, grouping by school but not fixed effects.
  Norm1 <-lmer(normexam ~ 1 + (1 | school),
                data=na.omit(Exam), REML = FALSE)
  summary(Norm1)

# The is .169/(.169 + .848) = .17: 17% of the variance is at the school level. 
#
# There is no consensus on how to calculate p-values for MLMs; hence why they are omitted from the `lme4` output. 
# But, if you really need p-values, the `lmerTest` package will calculate p-values for you (using the Satterthwaite 
# approximation) and you can use the same model syntax:

  # install.packages("lmerTest")
  Norm1_test <- lmerTest::lmer(normexam ~ 1 + (1 | school),
                      data=na.omit(Exam), REML = FALSE)
  summary(Norm1_test)


# ### Adding fixed-effects predictors
#
# Predict exam scores from student's standardized tests scores

  Norm2 <-lmer(normexam ~ 1 + standLRT + (1 | school),
               data=na.omit(Exam), REML = FALSE) 
  summary(Norm2) 

# ### Multiple degree of freedom comparisons
#
# As with `lm` and `glm` models, you can compare the two `lmer` models using the `anova` function.

  anova(Norm1, Norm2)

# ### Random slopes
#
# Add a random effect of students' standardized test scores as well. Now in addition to estimating the distribution of intercepts across schools, we also estimate the distribution of the slope of exam on standardized test.

  Norm3 <- lmer(normexam ~ 1 + standLRT + (1 + standLRT | school), 
                data = na.omit(Exam), REML = FALSE) 
  summary(Norm3) 

# ### Test the significance of the random slope
#
# To test the significance of a random slope just compare models with and without the random slope term

  anova(Norm2, Norm3) 

# ## Exercise 3
#
# **Multilevel modeling**
#
# Use the dataset, bh1996: 

data(bh1996, package="multilevel")

# From the data documentation:
#
# > Variables are Leadership Climate (LEAD), Well-Being (WBEING), and Work Hours (HRS). The group identifier is named "GRP".
#
# 1.  Create a null model predicting wellbeing ("WBEING")
# 2.  Calculate the ICC for your null model
# 3.  Run a second multi-level model that adds two individual-level predictors, average number of hours worked ("HRS") and leadership skills ("LEAD") to the model and interpret your output.
# 4.  Now, add a random effect of average number of hours worked ("HRS") to the model and interpret your output. Test the significance of this random term.
#

# ## Exercise solutions
#
# ### Ex 0: prototype
#
# Use the *states.rds* data set.

  states <- read_rds("dataSets/states.rds")

# Fit a model predicting energy consumed per capita (energy) from the percentage of residents living in metropolitan areas (metro). Be sure to
#
# 1.  Examine/plot the data before fitting the model

  states_en_met <- subset(states, select = c("metro", "energy"))
  summary(states_en_met)
  plot(states_en_met)
  cor(states_en_met, use="pairwise")

# 2.  Print and interpret the model `summary`

  mod_en_met <- lm(energy ~ metro, data = states)
  summary(mod_en_met)

# 3.  `plot` the model to look for deviations from modeling assumptions

  plot(mod_en_met)

# Select one or more additional predictors to add to your model and repeat steps 1-3. Is this model significantly better than the model with *metro* as the only predictor?

  states_en_met_pop_wst <- subset(states, select = c("energy", "metro", "pop", "waste"))
  summary(states_en_met_pop_wst)
  plot(states_en_met_pop_wst)
  cor(states_en_met_pop_wst, use = "pairwise")

  mod_en_met_pop_waste <- lm(energy ~ metro + pop + waste, data = states)
  summary(mod_en_met_pop_waste)
  anova(mod_en_met, mod_en_met_pop_waste)

# ### Ex 1: prototype
#
# Use the states data set.
#
# 1.  Add on to the regression equation that you created in exercise 1 by generating an interaction term and testing the interaction.

  mod_en_metro_by_waste <- lm(energy ~ metro * waste, data = states)

# 2.  Try adding a region to the model. Are there significant differences across the four regions?

  mod_en_region <- lm(energy ~ metro * waste + region, data = states)
  anova(mod_en_region)

# ### Ex 2: prototype
#
# Use the NH11 data set that we loaded earlier. Note that the data is not perfectly clean and ready to be modeled. You will need to clean up at least some of the variables before fitting the model.
#
# 1.  Use glm to conduct a logistic regression to predict ever worked (everwrk) using age (age_p) and marital status (r_maritl).

  nh11_wrk_age_mar <- subset(NH11, select = c("everwrk", "age_p", "r_maritl"))
  summary(nh11_wrk_age_mar)

  NH11 <- transform(NH11,
                    everwrk = factor(everwrk, levels = c("1 Yes", "2 No")),
                    r_maritl = droplevels(r_maritl))

  mod_wk_age_mar <- glm(everwrk ~ age_p + r_maritl, data = NH11,
                        family = binomial(link = "logit"))

  summary(mod_wk_age_mar)

# 2.  Predict the probability of working for each level of marital status.

  library(effects)
  data.frame(Effect("r_maritl", mod_wk_age_mar))

# ### Ex 3: prototype
#
# Use the dataset, bh1996:

  data(bh1996, package="multilevel")

# From the data documentation:
#
# > Variables are Cohesion (COHES), Leadership Climate (LEAD), Well-Being (WBEING) and Work Hours (HRS). The group identifier is named "GRP".
#
# 1.  Create a null model predicting wellbeing ("WBEING")

  library(lme4)
  mod_grp0 <- lmer(WBEING ~ 1 + (1 | GRP), data = bh1996)
  summary(mod_grp0)

# 3.  Run a second multi-level model that adds two individual-level predictors, average number of hours worked ("HRS") and leadership skills ("LEAD") to the model and interpret your output.

  mod_grp1 <- lmer(WBEING ~ HRS + LEAD + (1 | GRP), data = bh1996)
  summary(mod_grp1)

# 3.  Now, add a random effect of average number of hours worked ("HRS") to the model and interpret your output. Test the significance of this random term.

  mod_grp2 <- lmer(WBEING ~ HRS + LEAD + (1 + HRS | GRP), data = bh1996)
  anova(mod_grp1, mod_grp2)

# ## Wrap-up
#
# ### Feedback
#
# These workshops are a work in progress, please provide any feedback to: help@iq.harvard.edu
#
# ### Resources
#
# * IQSS 
#     + Workshops: <https://dss.iq.harvard.edu/workshop-materials>
#     + Data Science Services: <https://dss.iq.harvard.edu/>
#     + Research Computing Environment: <https://iqss.github.io/dss-rce/>
#
# * HBS
#     + Research Computing Services workshops: <https://training.rcs.hbs.org/workshops>
#     + Other HBS RCS resources: <https://training.rcs.hbs.org/workshop-materials>
#     + RCS consulting email: <mailto:research@hbs.edu>