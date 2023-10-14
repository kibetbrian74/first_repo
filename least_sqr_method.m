%% Part 1
% We are working with Training data for this part
%% Design Matrix
% Get the dimensions of the observed matrix
rows_o = size(observed,1);
% Loop through each row of 'matrix'
for i = 1:rows_o
    % Assign values from 'matrix' to 'A' at specified columns using 'indices'
    A((3*i-2):3*i,1:7) = [1, 0, 0, observed(i, 1), 0, -observed(i, 3), observed(i, 2);...
        0, 1, 0, observed(i, 2), observed(i, 3), 0, -observed(i, 2);...
        0, 0, 1, observed(i, 3), -observed(i, 2), observed(i, 1), 0];
    A1((3*i-2):3*i,1:7) = A((3*i-2):3*i,1:7);
end
%% Error-free coordinates of observed data 
% Extract elements from column 4 in groups of three
column4 = A1(:, 4);
% Reshape the extracted column into a 26 by 3 matrix
observed_data1 = reshape(column4, 3, 26)';
%% Reference Data
% Number of rows in the reference data
rows_ref = size(reference,1);
% Loop through the reference matrix
for i = 1:rows_o
    % Assign values from 'matrix' to 'A' at specified columns using 'indices'
    Lls((3*i-2):3*i,1:7) = [1, 0, 0, reference(i, 1), 0, -reference(i, 3), reference(i, 2);...
        0, 1, 0, reference(i, 2), reference(i, 3), 0, -reference(i, 2);...
        0, 0, 1, reference(i, 3), -reference(i, 2), reference(i, 1), 0];
    L1ls((3*i-2):3*i,1:7) = Lls((3*i-2):3*i,1:7);
end
%% Error-free coordinates of reference data 
% Reshape the extracted column4 of 78 by 1 matrix into a 26 by 3 matrix
column4 = L1ls(:, 4);
% Reshape the extracted column4 of 78 by 1 matrix into a 26 by 3 matrix
reference_data1 = reshape(column4, 3, 26)';

%% Part 2: Parameter Determination
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
disp('Estimated Transformation Parameters2:');
disp(['Translation(tx,ty,tz)2: ',num2str([tx,ty,tz])]);
disp(['Rotations(rx,ry,rz)2: ',num2str([rx,ry,rz])]);
disp(['Scale factor2: ',num2str(scale)]);

%% Part 3

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
% Converting the rotations and scale errors
std_errorsls(4) = std_errors(4)/206265;
std_errorsls(5) = std_errors(5)/206265;
std_errorsls(6) = std_errors(6)/206265;
std_errorsls(7) = std_errors(7)/1000000;

disp('Standard Errors:');
disp(['Standard Error (tx)2: ', num2str(std_errors(1))]);
disp(['Standard Error (ty)2: ', num2str(std_errors(2))]);
disp(['Standard Error (tz)2: ', num2str(std_errors(3))]);
disp(['Standard Error (rx)2: ', num2str(std_errorsls(4))]);
disp(['Standard Error (ry)2: ', num2str(std_errorsls(5))]);
disp(['Standard Error (rz)2: ', num2str(std_errorsls(6))]);
disp(['Standard Error (scale)2: ', num2str(std_errorsls(7))]);

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
clearvars rows_o i column4;
clearvars observed_data1 rows_ref i column4 reference_data1 points1 points2 initial_pars;
clearvars transformed_points options optimized_params tx ty tz rx ry rz scale;
clearvars n std_errors i perturbed_params perturbed_params(i);
clearvars perturbed_residuals partial_derivative std_errors(i) std_errorsls;
clearvars std_errorls(4) std_errorsls(5) std_errorsls(6) std_errorsls(7);