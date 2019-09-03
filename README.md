# VAMBN

This is the VAMBN implementation described in this [paper](link to be added). It is used to model the dependency structure of heterogeneous datasets. The main model is given by a conditional-gausssian Bayesian Network. This part of the code is written in R.
To restrict the number of modelled variables, groups of variables can be autoencoded using a modified variational autoencoder for heterogeneous data. This part of the code adapts the HIVAE approach develloped by Nazabal et al and is written in python, using the [original implementation](https://github.com/probabilistic-learning/HI-VAE).

Please cite both the VABM and the HIVAE [paper](https://arxiv.org/abs/1807.03653) if you use this code for your own research.

# Running the code

The code was last run using R version 3.5.3 and python 3.6.5.

The code is currently equipped to analyse the PPMI dataset and needs to be changed to adapt to a new dataset. If you need help with reformatting the data or adapting the code, please use the contact information included at the bottom of this page.

## Preparing the data

Data preprocessing is done in **clean_format.R** and **imputed_aux.R**.

- **clean_format.R**: If you are using a new dataset, the goal of this script is to create a list of dataframes, where each visit and variable group, including standalone variables, are recorded in a separate dataframe that includes a subject ID variable.
- **imputed_aux.R**: This script saves out the variable groups to be autoencoded by the HIVAE. The standalone variables are mean imputed and saved out for later use.

## Autoencoding variable groups

The HIVAE model is told the number, type and format of individual variables in each variable group using "types" files that need to be manually added to the data files saved out by **imputed_aux.R**. This is necessary as the decision to use a real or ordinal data type can greatly change the quality of the embedding.
- **1_PPMI_HIVAE_training.ipynb**: The code in this notebook trains the individual modules for each variable groups, returning s-codes and z-codes that represent the gaussian distributed embeddings.
- **2_PPMI_HIVAE_VP_decoding_and_counterfactuals**: After running the Bayesian Network, the Virtual Patient codes can be decoded using this notebook.

## Bayesian Network

The Bayesian Network code is found in **bnet.R**. Before structure learning and parameter fitting, the autoencoded data is merged with the standalone variables and auxiliary variables.  Higher-level auxiliary missing visit variables are introduced.

# Contact

**Luise Gootjes-Dreesbach**: elgootjesdreesbach@gmail.com
