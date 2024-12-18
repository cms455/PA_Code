function [sum_C, saturations_by_type, concentrations_by_type, w_avg_by_type] = spectral_unmixing(epsilon, recon_data_w, ...
    type_names, Nx, Ny)

num_wavelength = size(epsilon,1);
num_type = size(epsilon,2);
concentrations_by_type = zeros(num_type,Nx,Ny);

concentrations_by_type = calc_gen_nnls(recon_data_w, epsilon, num_wavelength,num_type,Nx,Ny);


concentrations_by_type(concentrations_by_type < 0) = 1e-9;

% Calculate the total concentration
sum_C = squeeze(sum(concentrations_by_type, 1));
sum_C = reshape(sum_C, 1, Nx, Ny); 
sum_C(sum_C == 0) = 1e-9;

saturations_by_type = concentrations_by_type./ sum_C;

w_avg_by_type = squeeze(sum(saturations_by_type.*(sum_C.^2)))/(sum(sum_C.^2,'all'));
end
