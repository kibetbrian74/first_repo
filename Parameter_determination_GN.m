%% Part 1
% Gauss Newton Requires prior knowledge on errors during data collection
% Standard errors are used as errors
% We are working with Training data for this part
%% Data Import
observed = Syst1_Clarke1880;
reference = Syst2_wgs84;

errors_observed = double(stde1(observed));
% Errors in system 1
ex_obs = errors_observed(1,1);
ey_obs = errors_observed(1,2);
ez_obs = errors_observed(1,3);
error_matrix1 = [0, 0, 0, ex_obs, 0, -ez_obs, ey_obs;...
    0, 0, 0, ey_obs, ez_obs, 0, -ex_obs;...
    0, 0, 0, ez_obs, -ey_obs, ex_obs, 0];
%% Part 2: Design Matrix
% Get the dimensions of the observed matrix
rows_o = size(observed,1);
% Loop through each row of 'matrix'
for i = 1:rows_o
    % Assign values from 'matrix' to 'A' at specified columns using 'indices'
    Agn((3*i-2):3*i,1:7) = [1, 0, 0, observed(i, 1), 0, -observed(i, 3), observed(i, 2);...
        0, 1, 0, observed(i, 2), observed(i, 3), 0, -observed(i, 2);...
        0, 0, 1, observed(i, 3), -observed(i, 2), observed(i, 1), 0];
    A1gn((3*i-2):3*i,1:7) = Agn((3*i-2):3*i,1:7) - error_matrix1;
end
%% Error-free coordinates of observed data 
% Extract elements from column 4 in groups of three
column4 = A1gn(:, 4);
% Reshape the extracted column into a 26 by 3 matrix
observed_data1 = reshape(column4, 3, 26)';
%% Reference Data
% Calculating and correcting errors in the reference data
% Errors in System 2
errors_reference = double(std(reference));
ex_ref = errors_reference(1,1);
ey_ref = errors_reference(1,2);
ez_ref = errors_reference(1,3);
error_matrix2 = [0, 0, 0, ex_ref, 0, -ez_ref, ey_ref;...
    0, 0, 0, ey_ref, ez_ref, 0, -ex_ref;...
    0, 0, 0, ez_ref, -ey_ref, ex_ref, 0];
% Number of rows in the reference data
rows_ref = size(reference,1);
% Loop through the reference matrix
for i = 1:rows_o
    % Assign values from 'matrix' to 'A' at specified columns using 'indices'
    Lgn((3*i-2):3*i,1:7) = [1, 0, 0, reference(i, 1), 0, -reference(i, 3), reference(i, 2);...
        0, 1, 0, reference(i, 2), reference(i, 3), 0, -reference(i, 2);...
        0, 0, 1, reference(i, 3), -reference(i, 2), reference(i, 1), 0];
    L1gn((3*i-2):3*i,1:7) = Lgn((3*i-2):3*i,1:7) - error_matrix2;
end
%% Error-free coordinates of reference data 
% Reshape the extracted column4 of 78 by 1 matrix into a 26 by 3 matrix
column4 = L1gn(:, 4);
% Reshape the extracted column4 of 78 by 1 matrix into a 26 by 3 matrix
reference_data1 = reshape(column4, 3, 26)';

%% Part 3: Parameter Determination
points1 = observed_data1;
points2 = reference_data1;
% Define initial transformation parameters
initial_pars = [0;0;0;0;0;0;1];

%function that computes the residuals btwn transformed points
transformed_points = @(params) transform_points(params, points1, points2);

%Use lsqnonlin to estimate the transformation parameters
options = optimoptions('lsqnonlin','Display','iter');
optimized_params = lsqnonlin(transformed_points,initial_pars,[],[],options);

%Optimized parameters
tx = optimized_params(1);
ty = optimized_params(2);
tz = optimized_params(3);
rx = optimized_params(4)*206265;
ry = optimized_params(5)*206265;
rz = optimized_params(6)*206265;
scale = optimized_params(7);

% Display Estimated Parameters
disp('Estimated Transformation Parameters:');
disp(['Translation(tx,ty,tz): ',num2str([tx,ty,tz])]);
disp(['Rotations(rx,ry,rz): ',num2str([rx,ry,rz])]);
disp(['Scale factor: ',num2str(scale)]);

%% Part 4

% Calculate the residuals
residuals = transformed_points(optimized_params);

% Calculate the standard errors of the estimated parameters
n = length(points1);
step_size = 1e-6; % Small step size for finite differences
std_errors = zeros(size(optimized_params));

for i = 1:length(optimized_params)
    perturbed_params = optimized_params;
    perturbed_params(i) = perturbed_params(i) + step_size;
    
    perturbed_residuals = transformed_points(perturbed_params);
    
    % Calculate the partial derivative using finite differences
    partial_derivative = (perturbed_residuals - residuals) / step_size;
    
    % Calculate the standard error for this parameter
    std_errors(i) = std(partial_derivative) / sqrt(n);
end

% Converting for rotations and scale errors
std_errorsgn(4) = std_errors(4)/206265;
std_errorsgn(5) = std_errors(5)/206265;
std_errorsgn(6) = std_errors(6)/206265;
std_errorsgn(7) = std_errors(7)/1000000;

disp('Standard Errors:');
disp(['Standard Error (tx): ', num2str(std_errors(1))]);
disp(['Standard Error (ty): ', num2str(std_errors(2))]);
disp(['Standard Error (tz): ', num2str(std_errors(3))]);
disp(['Standard Error (rx): ', num2str(std_errorsgn(4))]);
disp(['Standard Error (ry): ', num2str(std_errorsgn(5))]);
disp(['Standard Error (rz): ', num2str(std_errorsgn(6))]);
disp(['Standard Error (scale): ', num2str(std_errorsgn(7))]);

%% Objective 2: Coordinate Prediction
trans_params = [tx;ty;tz;scale;rx;ry;rz];

%% Part 5: Transform Non-common Points

% Non-common points in System 1
system1 = System1_Clarke1880; % Replace with your non-common points

% Transform non-common points from System 1 to System 2 using the estimated parameters
transformed_points = transform_coordinates(System1_Clarke1880,trans_params);

%% Part 6: Calculate Standard Errors, RMSE, and Standard Deviation

% Calculate the residuals for non-common points
residuals2 = System2_wgs84 - transformed_points;

% Calculate the standard errors for non-common points
non_common_std_errors = zeros(size(residuals2));
n_non_common = size(residuals2, 1);

for i = 1:n_non_common
    perturbed_points2 = System2_wgs84;
    perturbed_points2(i, :) = perturbed_points2(i, :) + step_size;
    
    perturbed_residuals = perturbed_points2 - transformed_points;
    
    % Calculate the partial derivative using finite differences
    partial_derivative = (perturbed_residuals - residuals2) / step_size;
    
    % Calculate the standard error for each dimension (x, y, z) separately
    non_common_std_errors(i, 1) = std(partial_derivative(:, 1));
    non_common_std_errors(i, 2) = std(partial_derivative(:, 2));
    non_common_std_errors(i, 3) = std(partial_derivative(:, 3));
end

% Calculate RMSE for non-common points
non_common_rmse = sqrt(sum(sum(residuals2.^2)) / n_non_common);
non_common_rmse = non_common_rmse/1000000;

% Calculate standard deviation for non-common points
non_common_std_deviation = std(reshape(residuals2, [], 1));
non_common_std_deviation = non_common_std_deviation/1000000;

% Display results
disp('Transformed Non-common Points:');
disp(transformed_points);

disp('Standard Errors for Transformed Non-common Points (X, Y, Z):');
disp(non_common_std_errors);

disp(['RMSE for Transformed Non-common Points: ', num2str(non_common_rmse)]);
disp(['Standard Deviation for Transformed Non-common Points: ', num2str(non_common_std_deviation)]);

%% Clear Temporary Variables
clearvars errors_observed ex_obs ey_obs ez_obs error_matrix1 rows_o i;
clearvars column4 observed_data1 errors_reference ex_ref ey_ref ez_ref;
clearvars error_matrix2 rows_ref i column4 reference_data1 points1 points2 initial_pars;
clearvars transformed_points options optimized_params tx ty tz rx ry rz scale;
clearvars n std_errors i perturbed_params perturbed_params(i);
clearvars perturbed_residuals partial_derivative std_errors(i) std_errorsgn;
clearvars std_errorgn(4) std_errorsgn(5) std_errorsgn(6) std_errorsgn(7);
