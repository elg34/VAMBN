# VAMBN

This is the VAMBN implementation described in this [paper](link to be added). It is used to model the dependency structure of heterogeneous datasets. The main model is given by a conditional-gausssian Bayesian Network. This part of the code is written in R.
To restrict the number of modelled variables, groups of variables can be autoencoded using a modified variational autoencoder for heterogeneous data. This part of the code adapts the HIVAE approach develloped by Nazabal et al and is written in python, using the [original implementation](https://github.com/probabilistic-learning/HI-VAE).

Please cite both the VAMBN and the HIVAE [paper](https://arxiv.org/abs/1807.03653) if you use this code for your own research.

# Running the code

The code was last run using R version 3.5.3 and python 3.6.5.

The code is currently equipped to analyse the PPMI dataset and needs to be changed to adapt to a new dataset. If you need help with reformatting the data or adapting the code, please use the contact information included at the bottom of this page.

## Preparing the data

**IMPORTANT: Data is not included with this code! To run this code, you must provide a dataframe with the data and create Type files to tell the HIVAE about the structure of your data. More detailed instructions below.**

Data preprocessing is done in **clean_format.R** and **imputed_aux.R**.

- **clean_format.R**: The goal of this script is to create a list of dataframes, where each visit and variable group, including standalone variables, are recorded in a separate dataframe that includes a subject ID variable. As input you can give an R dataframe that has all of the variables for all data groups together, or you can skip this step by creating a dataframe with the same format yourself. If you want to use this script, you will need to modify it to reflect the variable/visit names you have used, else it will not run. The data file used in the example has all variables with a .BL/.V01/.V02/etc at the end of the variable names to denote the visit (Baseline visit, Visit 1, Visit 2, etc). The first word of the column name followed by an underscore reflect the variable group and must equally be adjusted in the script.
- **imputed_aux.R**: This script saves out the variable groups to be autoencoded by the HIVAE. The standalone variables are mean imputed and saved out for later use.

## Autoencoding variable groups

The HIVAE model is told the number, type and format of individual variables in each variable group using "types" files that need to be manually added to the data files saved out in data/HI-VAE/data_python/' by mputed_aux.R**. This is necessary as the decision to use a real or ordinal data type can greatly change the quality of the embedding. For examples of type files and the different available data types see the [GitHub repository](https://github.com/probabilistic-learning/HI-VAE)for the HIVAE.
- **1_PPMI_HIVAE_training.ipynb**: The code in this notebook trains the individual modules for each variable groups, returning s-codes and z-codes that represent the gaussian distributed embeddings.
- **2_PPMI_HIVAE_VP_decoding_and_counterfactuals**: After running the Bayesian Network, the Virtual Patient codes can be decoded using this notebook.

## Bayesian Network

The Bayesian Network code is found in **bnet.R**. Before structure learning and parameter fitting, the autoencoded data is merged with the standalone variables and auxiliary variables.  Higher-level auxiliary missing visit variables are introduced.

# Contact

**Luise Gootjes-Dreesbach**: elgootjesdreesbach@gmail.com
