
# # R Regression Models
#
# **Topics**
#
# * Formula interface for model specification
# * Function methods for extracting quantities of interest from models
# * Contrasts to test specific hypotheses
# * Model comparisons
# * Predicted marginal effects
# * Modeling continuous and binary outcomes
# * Modeling clustered data

# ## Setup
#
# ### Software and Materials
#
# Follow the [R Installation](./Rinstall.html) instructions and ensure that you can successfully start RStudio.
#
# ### Class Structure
#
# Informal - Ask questions at any time. Really!
#
# Collaboration is encouraged - please spend a minute introducing yourself to your neighbors!
#
# ### Prerequisites
#
# This is an intermediate R course:
#
# * Assumes working knowledge of R
# * Relatively fast-paced
# * This is not a statistics course! We will teach you *how* to fit models in R, but we assume you know the theory behind the models.
#
# ### Goals
#
# <div class="alert alert-success">
# We will learn about the R modeling ecosystem by fitting a variety of statistical models to different datasets. In particular, our goals are to learn about:
#
# 1. Modeling workflow
# 2. Visualizing and summarizing data before modeling
# 3. Modeling continuous outcomes
# 4. Modeling binary outcomes
# 5. Modeling clustered data
#
# We will not spend much time *interpreting* the models we fit, since this is not a statistics workshop. But, we will walk you through how model results are organized and orientate you to where you can find typical quantities of interest.
# </div>
#
# ### Launch an R session
#
# Start RStudio and create a new project:
#
# 1. On Mac, RStudio will be in your applications folder. On Windows, click the start button and search for RStudio. 
# 2. In RStudio go to `File -> New Project`. Choose `Existing Directory` and browse to the workshop materials directory on your desktop. This will create an `.Rproj` file for your project and will automaticly change your working directory to the workshop materials directory. 
# 3. Choose `File -> Open File` and select the file with the word "BLANK" in the name.
#
# ### Packages
#
# You should have already installed the `tidyverse` and `rmarkdown` packages onto your computer before the workshop --- see [R Installation](./Rinstall.html). Now let's load these packages into the search path of our R session.

library(tidyverse)
library(rmarkdown)

# Finally, lets install some packages that will help with modeling:

# install.packages("lme4")
library(lme4)  # for mixed models

# install.packages("emmeans")
library(emmeans)  # for marginal effects

# install.packages("effects")
library(effects)  # for predicted marginal means

# ## Modeling workflow
#
# Before we delve into the details of how to fit models in R, it's worth taking a step back and thinking more broadly about the components of the modeling process. These can roughly be divided into 3 stages:
#
# 1. Pre-estimation
# 2. Estimation
# 3. Post-estimaton
#
# At each stage, the goal is to complete a different task (e.g., to clean data, fit a model, test a hypothesis), but the process is sequential --- we move through the stages in order (though often many times in one project!)
#
# ![](R/Rmodels/images/R_model_pipeline.png)
#
# Throughout this workshop we will go through these stages several times as we fit different types of model.
#
# ## R modeling ecosystem
#
# There are literally hundreds of R packages that provide model fitting functionality. We're going to focus on just two during this workshop --- `stats`, from Base R, and `lme4`. It's a good idea to look at [CRAN Task Views](https://cran.r-project.org/web/views/) when trying to find a modeling package for your needs, as they provide an extensive curated list. But, here's a more digestable table showing some of the most popular packages for particular types of model.
#
# | Models              | Packages                               |             
# |:--------------------|:---------------------------------------|
# | Generalized linear  | `stats`, `biglm`, `MASS`, `robustbase` | 
# | Mixed effects       | `lme4`, `nlme`, `glmmTMB`, `MASS`      |                                     
# | Econometric         | `pglm`, `VGAM`, `pscl`, `survival`     | 
# | Bayesian            | `brms`, `blme`, `MCMCglmm`, `rstan`    | 
# | Machine learning    | `mlr`, `caret`, `h2o`, `tensorflow`    | 

# ## Before fitting a model
#
# <div class="alert alert-info">
# **GOAL: To learn about the data by creating summaries and visualizations.**
# </div>
#
# One important part of the pre-estimation stage of model fitting, is gaining an understanding of the data we wish to model by creating plots and summaries. Let's do this now.
#
# ### Load the data
#
# List the data files we're going to work with:

list.files("dataSets")

# We're going to use the `states` data first, which originally appeared in *Statistics with Stata* by Lawrence C. Hamilton.

  # read the states data
  states <- read_rds("dataSets/states.rds")

  # look at the last few rows
  tail(states)

# Here's a table that describes what each variable in the dataset represents:
#
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
  states_ex_sat <- states %>% 
      select(expense, csat)
  
  summary(states_ex_sat)

  # correlation between expense and csat
  cor(states_ex_sat, use = "pairwise") 

# ### Plot the data
#
# Plot the data to look for multivariate outliers, non-linear relationships etc.

  # scatter plot of expense vs csat
  qplot(x = expense, y = csat, geom = "point", data = states_ex_sat)

# Obviously, in a real project, you would want to spend more time investigating the data,
# but we'll now move on to modeling.

# ## Models with continuous outcomes
#
# <div class="alert alert-info">
# **GOAL: To learn about the R modeling ecosystem by fitting ordinary least squares (OLS) models.** In particular:
#
# 1. Formula representation of model specification
# 2. Model classes
# 3. Function methods
# 4. Model comparison
# </div>
#
# Once the data have been inspected and cleaned, we can start estimating models. The simplest models (but those with the most assumptions) are those for continuous and unbounded outcomes. Typically, for these outcomes, we'd use a model estimated using Ordinary Least Lquares (OLS), which in R can be fit with the `lm()` (linear model) function.
#
# To fit a model in R, we first have to convert our theoretical model into a `formula` --- a symbolic representation of the model in R syntax:

# formula for model specification
outcome ~ pred1 + pred2 + pred3

# NOTE the ~ is a tilde

# For example, the following theoretical model predicts SAT scores based on per-pupil expenditures:
#
# <div class="alert alert-secondary">
# $$
# SATscores_i = \beta_{0}1 + \beta_1expenditures_i + \epsilon_i
# $$
# </div>
#
# We can use `lm()` to fit this model:

  # fit our regression model
  sat_mod <- lm(csat ~ 1 + expense, # regression formula
                data = states) # data 

  # look at the basic printed output
  sat_mod

# The default printed output from the fitted model is very austere --- just point estimates of the coefficients. We can get more information by passing the fitted model object to the `summary()` function, which provides standard errors, test statistics, and p-values for individual coefficients, as well as goodness-of-fit measures for the overall model.

  # get more informative summary information 
  summary(sat_mod)

# If we just want to inspect the coefficients, we can further pipe the summary output into the function `coef()` to obtain just the table of coefficients.

  # show only the regression coefficients table 
  summary(sat_mod) %>% coef() 

# ### Why is the association between expense & SAT scores *negative*?
#
# Many people find it surprising that the per-capita expenditure on students is negatively related to SAT scores. The beauty of multiple regression is that we can try to pull these apart. What would the association between expense and SAT scores be if there were no difference among the states in the percentage of students taking the SAT?

  lm(csat ~ 1 + expense + percent, data = states) %>% 
  summary() 

# ### The `lm` class & methods
#
# Okay, we fitted our model. Now what? Typically, the main goal in the **post-estimation stage** of analysis
# is to extract **quantities of interest** from our fitted model. These quantities could be things like:
#
# 1. Testing whether one group is different on average from another group
# 2. Generating average response values from the model for interesting combinations of predictor values
# 3. Calculating interval estimates for particular coefficients
#
# But before we can do any of that, we need to know more about **what a fitted model actually is,**
# **what information it contains, and how we can extract from it information that we want to report**.
#
# To understand what a fitted model object is and what information we can extract from it, we need to know about the concepts of **class** and **method**. A class defines a type of object, describing what properties it possesses, how it behaves, and how it relates to other types of objects. Every object must be an instance of some class. A method is a function associated with a particular type of object.
#
# Let's start by examining the class of the model object:

  # what class of object is the fitted model?
  class(sat_mod)

# We can see that the fitted model object is of class `lm`, which stands for linear model. What quantities are stored within this model object? 

  # what are the elements stored within the fitted model object?
  names(sat_mod)

# We can see that 12 different things are stored within a fitted model of class `lm`. In what structure are these quantities organized?

  # what is the structure of the fitted model object?
  str(sat_mod)

# We can see that the fitted model object is a `list` structure (a container that can hold different types of objects). What have we learned by examining the fitted model object? We can see that the default output we get when printing a fitted model of class `lm` is only a small subset of the information stored within the model object. How can we access other quantities of interest from the model?
#
# We can use **methods** (functions designed to work with specific classes of object) to extract various quantities from a fitted model object (sometimes these are referred to as **extractor functions**). A list of all the available methods for a given class of object can be shown by using the `methods()` function with the `class` argument set to the class of the model object:

  # methods for class `lm`
  methods(class = class(sat_mod))

# There are 44 methods available for the `lm` class. We've already seen the `summary()` method for `lm`, which is always a good place to start after fitting a model:

  # summary table
  summary(sat_mod) 

# We can use the `confint()` method to get interval estimates for our coefficients:

  # confidence intervals
  confint(sat_mod) 

# And we can use the `anova()` method to get an ANOVA-style table of the model:

  # ANOVA table
  anova(sat_mod)   

# How does R know which method to call for a given object? R uses **generic functions**, which provide access to the methods. **Method dispatch** takes place based on the class of the first argument to the generic function. For example, for the generic function `summary()` and an object of class `lm`, the method dispatched will be `summary.lm()`. Here's a schematic that shows the process of method dispatch in action:
#
# ![](R/Rmodels/images/methods.png)
#
# Function methods always take the form `generic.method()`. Let's look at all the methods for the generic `summary()` function:

  # methods for generic `summary()` function
  methods("summary")

# There are 137 `summary()` methods and counting! 
#
# It's always worth examining whether the class of model you've fitted has a method for a particular generic extractor function. Here's a summary table of some of the most often used extractor functions, which have methods for a wide range of model classes. These are post-estimation tools you will want in your toolbox:
#
# | Function      | Package   | Output                                                  |
# |:--------------|:----------|:--------------------------------------------------------|
# | `summary()`   | `stats`   | standard errors, test statistics, p-values, GOF stats   |
# | `confint()`   | `stats`   | confidence intervals                                    |
# | `anova()`     | `stats`   | anova table (one model), model comparison (> one model) |
# | `coef()`      | `stats`   | point estimates                                         |
# | `drop1()`     | `stats`   | model comparison                                        |
# | `predict()`   | `stats`   | predicted response values (for observed or new data)    |
# | `fitted()`    | `stats`   | predicted response values (for observed data only)      |
# | `residuals()` | `stats`   | residuals                                               |
# | `rstandard()` | `stats`   | standardized residuals                                  |
# | `fixef()`     | `lme4`    | fixed effect point estimates (mixed models only)        |
# | `ranef()`     | `lme4`    | random effect point estimates (mixed models only)       |
# | `coef()`      | `lme4`    | empirical Bayes estimates (mixed models only)           |
# | `allEffects()`| `effects` | predicted marginal means                                |
# | `emmeans()`   | `emmeans` | predicted marginal means & marginal effects             |
# | `margins()`   | `margins` | predicted marginal means & marginal effects             |

# ### OLS regression assumptions
#
# OLS regression relies on several assumptions, including:
#
# 1. The model includes all relevant variables (i.e., no omitted variable bias).
# 2. The model is linear in the parameters (i.e., the coefficients and error term).
# 3. The error term has an expected value of zero.
# 4. All right-hand-side variables are uncorrelated with the error term.
# 5. No right-hand-side variables are a perfect linear function of other RHS variables.
# 6. Observations of the error term are uncorrelated with each other.
# 7. The error term has constant variance (i.e., homoscedasticity).
# 8. (Optional - only needed for inference). The error term is normally distributed.
#
# Investigate assumptions #7 and #8 visually by plotting your model:

  # split plotting area into 2 x 2 grid
  par(mfrow = c(2, 2))

  # plot model diagnostics
  plot(sat_mod)

# ### Comparing models
#
# Do congressional voting patterns predict SAT scores over and above expense? To find out, let's fit two models and compare them. First, let's create a new cleaned dataset that omits missing values in the variables we will use.

# drop missing values for the 4 variables of interest
states_voting_cleaned <- states %>%
    select(csat, expense, house, senate) %>%
    drop_na()

# The `drop_na()` function omits rows with missing values --- that is, it performs *listwise deletion* of observations. In some situations, we may need more flexibility. If, for example, we only want to exclude rows that have missing data for a subset of variables, we could do the following:

  # pseudocode
  df <- df %>%
    filter(!na.omit(var_name))

# Now that we have a dataset with complete cases, let's fit a more elaborate model:

  # fit another model, adding house and senate as predictors
  sat_voting_mod <- lm(csat ~ 1 + expense + house + senate,
                       data = states_voting_cleaned)

  summary(sat_voting_mod) %>% coef()

# To compare models, *we must fit them to the same data*. This is why we needed to clean the dataset. Now let's update our first model to use these cleaned data:

  # update model using the cleaned data
  sat_mod <- sat_mod %>%
      update(data = states_voting_cleaned)

  # compare using an F-test with the anova() function
  anova(sat_mod, sat_voting_mod)

# ### Exercise 0
#
# **Ordinary least squares regression**
#
# Use the `states` data set. Fit a model predicting energy consumed per capita (`energy`) from the percentage of residents living in metropolitan areas (`metro`). Be sure to:
#
# 1.  Examine/plot the data before fitting the model.
## 

# 2.  Print and interpret the model `summary()`.
## 

# 3.  Plot the model using `plot()` to look for deviations from modeling assumptions.
## 

# 4. Select one or more additional predictors to add to your model and repeat steps 1-3. Is this model significantly better than the model with `metro` as the only predictor?
## 

# <details>
#   <summary><span style="color:red"><b>Click for Exercise 0 Solution</b></span></summary>
#   <div class="alert alert-danger">
#
# Use the `states` data set. Fit a model predicting energy consumed per capita (`energy`) from the percentage of residents living in metropolitan areas (`metro`). Be sure to:
#
# 1.  Examine/plot the data before fitting the model.

  states_en_met <- states %>% 
      select(energy, metro)

  summary(states_en_met)
  cor(states_en_met, use = "pairwise")
  qplot(x = metro, y = energy, geom = "point", data = states_en_met)

# 2.  Print and interpret the model `summary()`.

  mod_en_met <- lm(energy ~ metro, data = states_en_met)
  summary(mod_en_met)

# 3.  Plot the model using `plot()` to look for deviations from modeling assumptions.

  par(mfrow = c(2, 2))

  plot(mod_en_met)

# 4. Select one or more additional predictors to add to your model and repeat steps 1-3. Is this model significantly better than the model with `metro` as the only predictor?

  states_en_met_pop_wst <- states %>%
      select(energy, metro, pop, waste)

  summary(states_en_met_pop_wst)
  cor(states_en_met_pop_wst, use = "pairwise")

  mod_en_met_pop_waste <- lm(energy ~ 1 + metro + pop + waste, data = states_en_met_pop_wst)
  summary(mod_en_met_pop_waste)
  anova(mod_en_met, mod_en_met_pop_waste)
# </div>
# </details>

# ## Interactions & factors
#
# <div class="alert alert-info">
# **GOAL: To learn how to specify interaction effects and fit models with categorical predictors.** In particular:
#
# 1. Formula syntax for interaction effects
# 2. Factor levels and labels
# 3. Contrasts and pairwise comparisons
# </div>
#
# ### Modeling interactions
#
# Interactions allow us assess the extent to which the association between one predictor and the outcome depends on a second predictor. For example: does the association between expense and SAT scores depend on the median income in the state?

  # add the interaction to a model
  sat_expense_by_income <- lm(csat ~ 1 + expense + income + expense : income, data = states)

  # same as above, but shorter syntax
  sat_expense_by_income <- lm(csat ~ 1 + expense * income, data = states) 

  # show the regression coefficients table
  summary(sat_expense_by_income) %>% coef() 

# ### Regression with categorical predictors
#
# Let's try to predict SAT scores (`csat`) from geographical region (`region`), a categorical variable. Note that you must make sure R does not think your categorical variable is numeric.

  # make sure R knows region is categorical
  str(states$region)

# Here, R is already treating `region` as categorical --- that is, in R parlance, a "factor" variable. If `region` were not already a factor, we could make it so like this:

  # convert `region` to a factor
  states <- states %>%
      mutate(region = factor(region))

  # arguments to the factor() function:
  # factor(x, levels, labels)

  # examine factor levels
  levels(states$region)

# Now let's add `region` to the model:

  # add region to the model
  sat_region <- lm(csat ~ 1 + region, data = states) 

  # show the results
  summary(sat_region) %>% coef() # show only the regression coefficients table

# We can get an omnibus F-test for `region` by using the `anova()` method:

  anova(sat_region) # show ANOVA table

# So, make sure to tell R which variables are categorical by converting them to factors!

# ### Setting factor reference groups & contrasts
#
# **Contrasts** is the umbrella term used to describe the process of testing linear combinations of parameters from regression models. All statistical sofware use contrasts, but each software has different defaults and their own way of overriding these.
#
# The default contrasts in R are "treatment" contrasts (aka "dummy coding"), where each level within a factor is identified within a matrix of binary `0` / `1` variables, with the first level chosen as the reference category. They're called "treatment" contrasts, because of the typical use case where there is one control group (the reference group) and one or more treatment groups that are to be compared to the controls. It is easy to change the default contrasts to something other than treatment contrasts, though this is rarely needed. More often, we may want to change the reference group in treatment contrasts or get all sets of pairwise contrasts between factor levels.
#
# First, let's examine the default contrasts for `region`:

  # default treatment (dummy) contrasts
  contrasts(states$region)

# We can see that the reference level is `West`. How can we change this? Let's use the `relevel()` function:

  # change the reference group
  states <- states %>%
      mutate(region = relevel(region, ref = "Midwest"))

  # check the reference group has changed
  contrasts(states$region)

# Now the reference level has changed to `Midwest`. Let's refit the model with the releveled `region` variable:

  # refit the model
  mod_region <- lm(csat ~ 1 + region, data = states)

  # print summary coefficients table
  summary(mod_region) %>% coef()

# Often, we may want to get all possible pairwise comparisons among the various levels of a factor variable, rather than just compare particular levels to a single reference level. We could of course just keep changing the reference level and refitting the model, but this would be tedious. Instead, we can use the `emmeans()` post-estimation function from the `emmeans` package to do the calculations for us:

  # get all pairwise contrasts between means
  mod_region %>%
      emmeans(specs = pairwise ~ region)


# ### Exercise 1
#
# **Interactions & factors**
#
# Use the `states` data set.
#
# 1.  Add on to the regression equation that you created in Exercise 1 by generating an interaction term and testing the interaction.
## 

# 2.  Try adding `region` to the model. Are there significant differences across the four regions?
## 

# <details>
#   <summary><span style="color:red"><b>Click for Exercise 1 Solution</b></span></summary>
#   <div class="alert alert-danger">
#
# Use the `states` data set.
#
# 1.  Add on to the regression equation that you created in exercise 1 by generating an interaction term and testing the interaction.

  mod_en_metro_by_waste <- lm(energy ~ 1 + metro * waste, data = states)

# 2.  Try adding `region` to the model. Are there significant differences across the four regions?

  mod_en_region <- lm(energy ~ 1 + metro * waste + region, data = states)
  anova(mod_en_metro_by_waste, mod_en_region)
# </div>
# </details>

# ## Models with binary outcomes
#
# <div class="alert alert-info">
# **GOAL: To learn how to use the `glm()` function to model binary outcomes.** In particular:
#
# 1. The `family` and `link` components of the `glm()` function call
# 2. Transforming model coefficients into odds ratios
# 3. Transforming model coefficients into predicted marginal means
# </div>
#
# ### Logistic regression
#
# Thus far we have used the `lm()` function to fit our regression models. `lm()` is great, but limited --- in particular it only fits models for continuous dependent variables. For categorical dependent variables we can use the `glm()` function.
#
# For these models we will use a different dataset, drawn from the National Health Interview Survey. From the [CDC website](http://www.cdc.gov/nchs/nhis.htm):
#
# > The National Health Interview Survey (NHIS) has monitored the health of the nation since 1957. NHIS data on a broad range of health topics are collected through personal household interviews. For over 50 years, the U.S. Census Bureau has been the data collection agent for the National Health Interview Survey. Survey results have been instrumental in providing data to track health status, health care access, and progress toward achieving national health objectives.
#
# Load the National Health Interview Survey data:

  NH11 <- read_rds("dataSets/NatHealth2011.rds")

# ### Logistic regression example
#
# If we were to use a linear model, rather than a logistic model, when we have a binary response we would find that:
#
# 1. Explanatory variables will not be linearly related to the outcome
# 2. Residuals will not be normally distributed
# 3. Variance will not be homoskedastic
# 4. Predictions will not be constrained to be on the interval [0, 1]
#
# Though, some of these issues can be dealt with by estimating a linear probability model with robust standard errors.
#
# ![](R/Rmodels/images/logistic.png)

# Anatomy of a generalized linear model:

  # OLS model using lm()
  lm(outcome ~ 1 + pred1 + pred2, 
     data = mydata)

  # OLS model using glm()
  glm(outcome ~ 1 + pred1 + pred2, 
      data = mydata, 
      family = gaussian(link = "identity"))
 
  # logistic model using glm()
  glm(outcome ~ 1 + pred1 + pred2, 
      data = mydata, 
      family = binomial(link = "logit"))

# The `family` argument sets the error distribution for the model, while the `link` function argument relates the predictors to the expected value of the outcome.
#
# Let's predict the probability of being diagnosed with hypertension based on age, sex, sleep, and bmi. Here's the theoretical model:
#
# <div class="alert alert-secondary">
# $$
# logit(p(hypertension_i = 1)) = \beta_{0}1 + \beta_1age_i + \beta_2sex_i + \beta_3sleep_i + \beta_4bmi_i 
# $$
# </div>
#
# where $logit(\cdot)$ is the non-linear link function that relates a linear expression of the predictors to the expectation of the binary response:
#
# <div class="alert alert-secondary">
# $$
# logit(p(hypertension_i = 1)) = ln \left( \frac{p(hypertension_i = 1)}{1-p(hypertension_i = 1)} \right) = ln \left( \frac{p(hypertension_i = 1)}{p(hypertension_i = 0)} \right)
# $$
# </div>
#
# And here's how we fit this model in R. First, let's clean up the hypertension outcome by making it binary:

  str(NH11$hypev) # check stucture of hypev
  levels(NH11$hypev) # check levels of hypev

  # collapse all missing values to NA
  NH11 <- NH11 %>%
      mutate(hypev = factor(hypev, levels=c("2 No", "1 Yes")))

# Now let's use `glm()` to estimate the model:

  # run our regression model
  hyp_out <- glm(hypev ~ 1 + age_p + sex + sleep + bmi,
                 data = NH11, 
                 family = binomial(link = "logit"))
  
  # summary model coefficients table
  summary(hyp_out) %>% coef()

# ### Odds ratios
#
# Generalized linear models use link functions to relate the average value of the response to the predictors, so raw coefficients are difficult to interpret. For example, the `age` coefficient of 0.06 in the previous model tells us that for every one unit increase in `age`, the log odds of hypertension diagnosis increases by 0.06. Since most of us are not used to thinking in log odds this is not too helpful!
#
# One solution is to transform the coefficients to make them easier to interpret. Here we transform them into odds ratios by exponentiating:

  # point estimates
  coef(hyp_out) %>% exp()
  
  # confidence intervals
  confint(hyp_out) %>% exp()

# ### Predicted marginal means
#
# Instead of reporting odds ratios, we may want to calculate predicted marginal means (sometimes called "least-squares means" or "estimated marginal means"). These are average values of the outcome at particular levels of the predictors. For ease of interpretation, we want these marginal means to be on the response scale (i.e., the probability scale). We can use the `effects` package to compute these quantities of interest for us (by default, the numerical output will be on the response scale).

  # get predicted marginal means
  hyp_out %>% 
      allEffects() %>%
      plot(type = "response") # "response" refers to the probability scale

# By default, `allEffects()` will produce predictions for all levels of factor variables, while for continuous variables it will chose 5 representative values based on quantiles. We can easily override this behavior using the `xlevels` argument and get predictions at any values of a continuous variable. 

  # generate a sequence of ages at which to get predictions of the outcome
  age_years <- seq(20, 80, by = 5)
  age_years
  
  # get predicted marginal means
  eff_df <- 
      hyp_out %>% 
      allEffects(xlevels = list(age_p = age_years)) %>% # override defaults for age
      as.data.frame() # get confidence intervals
  
  eff_df

# ### Exercise 2 
#
# **Logistic regression**
#
# Use the `NH11` data set that we loaded earlier. Note that the data are not perfectly clean and ready to be modeled. You will need to clean up at least some of the variables before fitting the model.
#
# 1.  Use `glm()` to conduct a logistic regression to predict ever worked (`everwrk`) using age (`age_p`) and marital status (`r_maritl`). Make sure you only keep the following two levels for `everwrk` (`2 No` and `1 Yes`). Hint: use the `factor()` function. Also, make sure to drop any `r_maritl` levels that do not contain observations. Hint: see `?droplevels`.
## 

# 2.  Predict the probability of working for each level of marital status. Hint: use `allEffects()`
## 

# Note that the data are not perfectly clean and ready to be modeled. You will need to clean up at least some of the variables before fitting the model.
#
# <details>
#   <summary><span style="color:red"><b>Click for Exercise 2 Solution</b></span></summary>
#   <div class="alert alert-danger">
#
# Use the `NH11` data set that we loaded earlier. Note that the data are not perfectly clean and ready to be modeled. You will need to clean up at least some of the variables before fitting the model.
#
# 1.  Use `glm()` to conduct a logistic regression to predict ever worked (`everwrk`) using age (`age_p`) and marital status (`r_maritl`). Make sure you only keep the following two levels for `everwrk` (`2 No` and `1 Yes`). Hint: use the `factor()` function. Also, make sure to drop any `r_maritl` levels that do not contain observations. Hint: see `?droplevels`.

  NH11 <- NH11 %>%
      mutate(everwrk = factor(everwrk, levels = c("2 No", "1 Yes")),
             r_maritl = droplevels(r_maritl)
             )

  mod_wk_age_mar <- glm(everwrk ~ 1 + age_p + r_maritl, 
                        data = NH11,
                        family = binomial(link = "logit"))

  summary(mod_wk_age_mar)

# 2.  Predict the probability of working for each level of marital status. Hint: use `allEffects()`.

  mod_wk_age_mar %>% 
      allEffects() %>%
      as.data.frame()
# </div>
# </details>

# ## Multilevel modeling
#
# <div class="alert alert-info">
# **GOAL: To learn about how to use the `lmer()` function to model clustered data.** In particular:
#
# 1. The formula syntax for incorporating random effects into a model
# 2. Calculating the intraclass correlation (ICC)
# 3. Model comparison for fixed and random effects
# </div>
#
# ### Multilevel modeling overview
#
# * Multi-level (AKA hierarchical) models are a type of **mixed-effects** model
# * They are used to model data that are clustered (i.e., non-independent)
# * Mixed-effects models include two types of predictors: **fixed-effects** and **random effects**
#   + **Fixed-effects** -- observed levels are of direct interest (.e.g, sex, political party...)
#   + **Random-effects** -- observed levels not of direct interest: goal is to make inferences to a population represented by observed levels
#   + In R, the `lme4` package is the most popular for mixed effects models
#   + Use the `lmer()` function for linear mixed models, `glmer()` for generalized linear mixed models

# ### The Exam data
#
# The `Exam.rds` data set contains exam scores of 4,059 students from 65 schools in Inner London. The variable names are as follows:
#
# | Variable | Description                             |
# |:---------|:----------------------------------------|
# | school   | School ID - a factor.                   |
# | normexam | Normalized exam score.                  |
# | standLRT | Standardized LR test score.             |
# | student  | Student id (within school) - a factor   |
#
# Let's read in the data:

  exam <- read_rds("dataSets/Exam.rds")

# ### The null model & ICC
#
# Before we fit our first model, let's take a look at the R syntax for multilevel models:

  # anatomy of lmer() function
  lmer(outcome ~ 1 + pred1 + pred2 + (1 | grouping_variable), 
       data = mydata)

# Notice the formula section within the brackets: `(1 | grouping_variable)`. This part of the formula tells R about the hierarchical structure of the model. In this case, it says we have a model with random intercepts (`1`) grouped by (`|`) a `grouping_variable`.
#
# As a preliminary modeling step, it is often useful to partition the variance in the dependent variable into the various levels. This can be accomplished by running a null model (i.e., a model with a random effects grouping structure, but no fixed-effects predictors) and then calculating the intra-class correlation (ICC).

  # null model, grouping by school but not fixed effects.
  Norm1 <-lmer(normexam ~ 1 + (1 | school), 
               data = na.omit(exam))
  summary(Norm1)

# The ICC is calculated as .163/(.163 + .852) = .161, which means that ~16% of the variance is at the school level. 
#
# There is no consensus on how to calculate p-values for MLMs; hence why they are omitted from the `lme4` output. But, if you really need p-values, the `lmerTest` package will calculate p-values for you (using the Satterthwaite approximation).

# ### Adding fixed-effects predictors
#
# Here's a theoretical model that predicts exam scores from student's standardized tests scores:
#
# <div class="alert alert-secondary">
# $$
# examscores_{ij} = \mu1 + \beta_1testscores_{ij} + U_{0j} + \epsilon_{ij}
# $$
# </div>
#
# where $U_{0j}$ is the random intercept for the $j$<sup>th</sup> `school`. Let's implement this in R using `lmer()`:

  # model with exam scores regressed on student's standardized tests scores
  Norm2 <-lmer(normexam ~ 1 + standLRT + (1 | school),
               data = na.omit(exam)) 
  summary(Norm2) 

# ### Multiple degree of freedom comparisons
#
# As with `lm()` and `glm()` models, you can compare the two `lmer()` models using the `anova()` function. With mixed effects models, this will produce a likelihood ratio test.

  # likelihood ratio test of two nested models
  anova(Norm1, Norm2)

# ### Random slopes
#
# We can add a random effect of students' standardized test scores as well. Now in addition to estimating the distribution of intercepts across schools, we also estimate the distribution of the slope of exam on standardized test.

  # add random effect of students' standardized test scores to model
  Norm3 <- lmer(normexam ~ 1 + standLRT + (1 + standLRT | school), 
                data = na.omit(exam)) 
  summary(Norm3) 

# ### Test the significance of the random slope
#
# To test the significance of a random slope just compare models with and without the random slope term using a likelihood ratio test:

  # likelihood ratio test for random slope term
  anova(Norm2, Norm3) 

# ### Exercise 3
#
# **Multilevel modeling**
#
# Use the `bh1996` dataset: 

## install.packages("multilevel")
data(bh1996, package = "multilevel")

# From the data documentation:
#
# > Variables are Leadership Climate (`LEAD`), Well-Being (`WBEING`), and Work Hours (`HRS`). The group identifier is named `GRP`.
#
# 1.  Create a null model predicting wellbeing (`WBEING`)
## 

# 2.  Calculate the ICC for your null model
## 

# 3.  Run a second multi-level model that adds two individual-level predictors, average number of hours worked (`HRS`) and leadership skills (`LEAD`) to the model and interpret your output.
## 

# 4.  Now, add a random effect of average number of hours worked (`HRS`) to the model and interpret your output. Test the significance of this random term.
## 

# <details>
#   <summary><span style="color:red"><b>Click for Exercise 3 Solution</b></span></summary>
#   <div class="alert alert-danger">
#
# Use the dataset `bh1996`:

  # install.packages("multilevel")
  data(bh1996, package="multilevel")

# From the data documentation:
#
# > Variables are Leadership Climate (`LEAD`), Well-Being (`WBEING`), and Work Hours (`HRS`). The group identifier is named `GRP`.
#
# 1.  Create a null model predicting wellbeing (`WBEING`).

  mod_grp0 <- lmer(WBEING ~ 1 + (1 | GRP), data = na.omit(bh1996))
  summary(mod_grp0)

# 2.  Calculate the ICC for your null model

  0.0358 / (0.0358 + 0.7895)

# 3.  Run a second multi-level model that adds two individual-level predictors, average number of hours worked (`HRS`) and leadership skills (`LEAD`) to the model and interpret your output.

  mod_grp1 <- lmer(WBEING ~ 1 + HRS + LEAD + (1 | GRP), data = na.omit(bh1996))
  summary(mod_grp1)

# 4.  Now, add a random effect of average number of hours worked (`HRS`) to the model and interpret your output. Test the significance of this random term.

  mod_grp2 <- lmer(WBEING ~ 1 + HRS + LEAD + (1 + HRS | GRP), data = na.omit(bh1996))
  anova(mod_grp1, mod_grp2)
# </div>
# </details>

# ## Wrap-up
#
# ### Feedback
#
# These workshops are a work in progress, please provide any feedback to: help@iq.harvard.edu
#
# ### Resources
#
# * IQSS 
#     + Workshops: <https://www.iq.harvard.edu/data-science-services/workshop-materials>
#     + Data Science Services: <https://www.iq.harvard.edu/data-science-services>
#     + Research Computing Environment: <https://iqss.github.io/dss-rce/>
#
# * HBS
#     + Research Computing Services workshops: <https://training.rcs.hbs.org/workshops>
#     + Other HBS RCS resources: <https://training.rcs.hbs.org/workshop-materials>
#     + RCS consulting email: <mailto:research@hbs.edu>
