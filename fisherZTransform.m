%--------------------------------------------------------------------------
%fisherZTransform
%By: Brielle Ferguson
%Date: 2/8/24
%Will take an array of corelation coefficients and apply a fisher Z
%transformation to return an average r value and p value
%inputs - 
%   r: a double array of correlation coefficients
%outputs - 
%   R: the adjusted mean of the input correlation coeeficients 
%   P: p value 
%--------------------------------------------------------------------------


function [R,P] = fisherZTransform(r)

% apply Fisher's z-transformation and take the mean
r = r(~isnan(r));
z = 0.5 * log((1 + r) ./ (1 - r));
z_average = mean(0.5 * log((1 + r) ./ (1 - r)));

% apply a reverse Fisher's z-transformation to the averaged Z
R = (exp(2 * z_average) - 1) ./ (exp(2 * z_average) + 1);

%test for significance
% Compute standard error of the mean
se_Mean = std(z) / sqrt(length(z) - 1);

% Compute t-statistic
t_statistic = mean(z) / se_Mean;

% Degrees of freedom
df = length(z) - 1;

% Compute p-value
P = 2 * (1 - tcdf(abs(t_statistic), df)); % two-tailed test
end