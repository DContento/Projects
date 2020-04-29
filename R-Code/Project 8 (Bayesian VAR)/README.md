In this project we fit a Bayesian Vector Auto Regressive model to a times series data set of stock returns. We create this BVAR using a 
Gibbs Sampler to make draws from our dataset. We then look at the Impulse response function of our BVAR to determine whether a change in the SP500 has a significant effect on GE stock returns (a large cap stock) and vice versa. We also looked to determine Granger Causality between the GE stock and SP500 index.