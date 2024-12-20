%> @file spectral_unmixing_simulation.m
%> @brief Performs complete simulation and unmixing for PA saturation.
%> @author Calvin Smith
%> @date 12-20-24
%> @details 
%> Simulates a photoacoustic measurement and unmixing of tissues for one wavelength set. 
%> - Create an arbitrary shape/tissues and define the concentration of the different types of biomarkers.
%> - Construct the pressure wave generated by a laser of wavelength using the formula:
%>   P(w, x, y) = Epsilon(w, t) * C(type, x, y).
%>     - P: Pressure
%>     - Epsilon: Absorption coefficients by wavelength and type
%>     - C: Concentration
%> - Then measure using a transducer with spacing `dx` for `Nx` transducers (future versions will make this customizable).
%> - Add different noise levels to the sensor data, and reconstruct the noisy sensor data.
%> - Perform spectral unmixing on the reconstructed data and store the calculated concentrations and simulations.
%>
%> @param mask A boolean mask of size (Nx, Ny) that defines the shape of the tissue to simulate.
%> @param epsilon A (num_wavelength, num_types) matrix of absorption coefficients. Must match the order of `concentrations`.
%> @param wavelengths A 1D array of wavelengths (e.g., [770, 780]). Must match the size of `epsilon`.
%> @param concentrations An array of size (unique_c*num_iter, num_types) defining the relative saturations 
%>        of each type in the generated pressure mask.
%> @param type_names A cell array of names (e.g., {'Hb', 'HbO'}). Order must match `epsilon` and `concentrations`.
%> @param noise_levels A 1D array specifying the percentages of noise strength.
%> @param noise_strength A scalar value for the maximum noise strength.
%> @param Nx Number of X pixels.
%> @param Ny Number of Y pixels.
%> @param dx Size of each X pixel in meters.
%> @param dy Size of each Y pixel in meters.
%> @param plot_flag_pressures Boolean flag. If true, plots each pressure (use for testing).
%> @param plot_flag_concentrations Boolean flag to plot figures for each noise and concentration for all types and wavelengths.
%> @param plot_flag_saturations Boolean flag to plot figures for each noise and saturation for all types and wavelengths.
%> @param save_flag Boolean flag. If true, saves `specunmix_noise_c_data` to the specified folder.
%> @param folder_path The folder path to save data. If it doesn’t exist, it will be created.
%> @return specunmix_noise_c_data A cell array of shape {n, c, 4}. 
%>         Each (n, c) coordinate stores:
%>         - `sum_C`: Total concentration maps.
%>         - `saturations_by_type`: Saturation maps by type.
%>         - `concentrations_by_type`: Concentration maps by type.
%>         - `w_avg_by_type`: Scalar average maps.
%> @return noisy_sensor_data_holder Holds all the noisy sensor data for testing to confirm appropriate noise levels.

function [specunmix_noise_c_data, noisy_sensor_data_holder] = spectral_unmixing_simulation(mask, epsilon, wavelengths, concentrations, ...
  type_names, noise_levels, noise_strength, Nx, Ny, dx,dy, plot_flag_pressures, plot_flag_recon, plot_flag_concentrations, plot_flag_saturations, save_flag, folder_path) 
% DESCRIPTION:
% Simulates a photoacoustic measurement and unmixing of tissues for one wavelength set. Create an
% arbitrary shape/tissues and define the concentration of the different
% types of biomarker. Construct the pressure wave generated by a laser of
% wavelength using the formula:
% P(w, x, y) = Epsilon(w, t) * C(type, x, y). P = Pressure, Epsilon =
% Absorption Coefficients by wavelength and type, C = Concentration
% Then measure using a transducer of spacing dx for Nx transducers(future version will update this to be customizeable)
% Add different noise levels to the sensor data, and then reconstruct the
% noisy sensor data.
% Perform Spectral Unmixing on the reconstructed data and store the
% calculated concentrations and simulations.
%
% INPUTS:
% mask  -  a boolean mask of size(Nx, Ny) that is the shape of the tissue to simulate 
% epsilon - a (num_wavelength, num_types) matrix of the absorption coefficients. must be in order that the types are specified in concentrations
% wavelengths - 1D array of the wavelengths, ex:[770,780], this must be the same size as epsilon
% concentrations - an array of size (unique_c*num_iter, num_types).concentrations defines the relative saturations of each type in the generated pressure mask
% type_names - a "CELL" array of names, ex : {'Hb', 'HbO'}. The order is important must match with epsilon and concentrations
% noise_levels - 1D array of percentages of noise_strength
% noise_strength - scalar value for the max noise strength
% Nx - Number of X Pixels
% Ny - Number of Y Pixels
% dx - size of each x pixel in meters
% dy - size of each y pixel in meters
% plot_flag_pressures - boolean, if true plots each pressure. Only use for testing!
% plot_flag_concentrations - plots figures for each noise and concentration of all the types and wavelengths
% plot_flag_saturations - plots figures for each noise and staurations of all the types and wavelengths
% save_flag - saves specunmix_noise_c_data to the folder
% folder_path - the folder path to save data, if doesn't exit makes it
%
% OUTPUTS:
% specunmix_noise_c_data - a cell array of shape {n,c,4} where for each
% (n,c) coordinate there it stores su_concentration_data = {sum_C, saturations_by_type, concentrations_by_type, w_avg_by_type};
% each of these stores the data (num_type, Nx, Ny) which contains the maps
% for each. For example saturations_by_type(1, :,:) for Hb, an HbO is the
% saturation map of Hb. This holds for all of thme except w_avg_by_type
% which is a map of scalars.
% noisy_sensor_data_holder - Holds all the noisy sensor data for testing to
% confirm that the noise level is appropriate.

if nargin < 1
    mask = zeros(200,200);
    mask = mask + makeDisc(200,200, 100, 100, 4);
end
if nargin <2
    epsilon = [1361 636; 1075 710]; %770-780
end
if nargin <3
    wavelengths = [770,780];
end
if nargin <4 
    concentrations = [0.25,0.75; 0.5, 0.5;];
end
if nargin <5
    type_names = {'Hb', 'HbO'};
end
if nargin < 6
    noise_levels = [0,0.05];
end
if nargin < 7
    noise_strength = 50;
end
if nargin < 8
    Nx = 200;
end
if nargin < 9
    Ny = 200;
end
if nargin < 10
    dx = 1e-6;
end
if nargin < 11
    dy = 1e-6;
end
if nargin < 12 
     plot_flag_pressures = false;
end
if nargin < 13
     plot_flag_concentrations = true;
end
if nargin < 14
     plot_flag_saturations = true;
end
if nargin < 15
    save_flag = true;
end
if nargin <16
    folder_path = '/Users/calvinsmith/Bouma_lab/PA_project/PA_Saturation/PA_saturation_data/';
end

num_wavelength = length(wavelengths);
num_noise = length(noise_levels);
num_concentrations = size(concentrations, 1);
num_type = size(concentrations,2);

noise_simple = noise_strength*noise_levels;

%Pressure mask is of size(num_concentrations, num_wavelength, # x pixels, # y pixels)
pressure_mask = convert_mask_to_pressure(mask, epsilon, concentrations, type_names, wavelengths, Nx, Ny, plot_flag_pressures);

%Run first iteration to find sensor_data size (hack)
p_mask = squeeze(pressure_mask(1, 1, :,:));
test_sensor_data = calculate_sensor_data_for_mask(p_mask, Nx, dx, Ny, dy);
num_transducers = size(test_sensor_data,1);
num_time = size(test_sensor_data,2);

% Build data holder sets
sensor_data_holder = zeros(num_wavelength, num_concentrations, num_transducers , num_time );
noisy_sensor_data_holder = zeros(num_noise,num_wavelength, num_concentrations, num_transducers, num_time);
recon_image_holder = zeros(num_noise,num_wavelength, num_concentrations, Nx, Ny);

% Generate all the sensor data for no noise and store in sensor_data_holder
for w = 1:num_wavelength
    for c=1:num_concentrations
        p_mask = squeeze(pressure_mask(w, c, :,:));
        sensor_data = calculate_sensor_data_for_mask(p_mask, Nx, dx, Ny, dy);
        sensor_data_holder(w,c,:,:) = sensor_data;

    end
end


% Loop through noise level, wavelength, concentration and add noise
% Once noise added reconstruct the sensor data and store the reconstructed
% images in recon_image_holder.
for n= 1:num_noise
    for w = 1:num_wavelength
        for c=1:num_concentrations
            sensor_data = squeeze(sensor_data_holder(w,c,:,:));
            noise = noise_levels(n);
            noise_map = noise_strength*noise*randn(num_transducers,num_time);
            noisy_sensor_data = sensor_data + noise_map;
            noisy_sensor_data_holder(n,w,c,:,:) = noisy_sensor_data;
            recon_image_holder(n,w,c,:,:) = reconstruct_image_k_wave(noisy_sensor_data, Nx, Ny, dx, dy);

        end
    end

end

% Plot the reconstructed images
if plot_flag_recon
   for n= 1:num_noise
        figure;
        count = 1;
        max_pressure = max(recon_image_holder(n,:,:,:,:),[],'all');
        for w = 1:num_wavelength
            for c=1:num_concentrations
            subplot(num_wavelength, num_concentrations,count)
            imagesc(squeeze(recon_image_holder(n,w,c,:,:)));
            colormap;
            colorbar;
            clim([0,max_pressure]);
            title(sprintf('Reconstructed at N= %d, wv = %d, c= %d', noise_simple(n), wavelengths(w), c));
            count = count + 1;
           
            end
        end
    end
end

% Initialize specunmix_noise_c_data
specunmix_noise_c_data = cell(num_noise, num_concentrations,4);
% Build the specunmix_noise_c_data as a cell array for each noise and
% concentration level.
for n = 1:num_noise
    for c=1:num_concentrations
        recon_data_w = squeeze(recon_image_holder(n,:,c,:,:));
        [sum_C, saturations_by_type, concentrations_by_type, w_avg_by_type] = spectral_unmixing(epsilon, recon_data_w,type_names, Nx, Ny);
        su_concentration_data = {sum_C, saturations_by_type, concentrations_by_type, w_avg_by_type};
        specunmix_noise_c_data(n,c,:) = su_concentration_data;
    end
end

% Plot the concentrations
if plot_flag_concentrations
for n = 1:num_noise
    for c=1:num_concentrations
        figure;
        su_concentration_data = specunmix_noise_c_data(n,c,:);
        concentrations_by_type = su_concentration_data{3};
        max_val = max(concentrations_by_type,[],'all');
        for t =1:num_type
            subplot(1,num_type, t);
            c_map = squeeze(concentrations_by_type(t,:,:));
            imagesc(c_map);
            title(sprintf('%s Concentration, c = %d, n = %d ', type_names{t}, c, noise_simple(n)));
            colormap;
            colorbar;
            clim([0,max_val]);
            xlabel('X-Axis');
            ylabel('Y-Axis');

        end
    end
end

end 

% Plot the saturations
if plot_flag_saturations
for n = 1:num_noise
    for c=1:num_concentrations
        figure;
        su_concentration_data = specunmix_noise_c_data(n,c,:);
        saturations_by_type = su_concentration_data{2};
        max_val = max(saturations_by_type,[],'all');
        for t =1:num_type
            subplot(1,num_type, t);
            c_map = squeeze(saturations_by_type(t,:,:));
            imagesc(c_map);
            title(sprintf('%s Saturation, c = %d, n = %d ', type_names{t}, c, noise_simple(n)));
            colormap;
            colorbar;
            clim([0,max_val]);
            xlabel('X-Axis');
            ylabel('Y-Axis');

        end
    end
end

end

% Save the data 
if save_flag
    % add a rand id to identify similar times
    rand_id = num2str(round(1000*rand(1)));
    timestamp = datestr(datetime('now'), 'yyyymmdd');
    timestamp = [timestamp,'_', rand_id];
    wavelength_name = '';
    for w =1:num_wavelength
        wavelength_name = [wavelength_name,num2str(wavelengths(w))] ;
    end
    % add the datetime to str
    if ~exist(folder_path, 'dir')
        mkdir(folder_path);
    end
    su_file_name = [folder_path,'spectral_unmixing_data_',wavelength_name, '_', timestamp, '.mat'];
    save(su_file_name,'specunmix_noise_c_data');

end





