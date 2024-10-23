% MATLAB Code to show SVD inconsistency due to eigenvector sign

m = 4;
n = 4;
A = rand(m, n);

ATA = A' * A;
AAT = A * A';

[V, D_V] = eig(ATA); % V contains the right singular vectors
[U, D_U] = eig(AAT); % U contains the left singular vectors

singular_values = sqrt(diag(D_V));

S = diag(singular_values);
A_reconstructed = U * S * V';

disp('Original matrix A:');
disp(A);
disp('Reconstructed matrix A using U * S * V^T (without fixing signs):');
disp(A_reconstructed);

% Compute the error
error = norm(A - A_reconstructed);
disp(['Error without fixing signs: ', num2str(error)]);
disp('--------------------------------------------------');

% MATLAB Code to fix SVD sign inconsistency

m_1 = 4;
n_1 = 4;
A_1 = rand(m, n);

ATA_1 = A_1' * A_1;
AAT_1 = A_1 * A_1';

[V, D_V] = eig(ATA_1); % V contains the right singular vectors
[U, D_U] = eig(AAT_1); % U contains the left singular vectors

singular_values = sqrt(diag(D_V));

for i = 1:n
    if sign(U(:, i)' * A_1 * V(:, i)) < 0
        U(:, i) = -U(:, i); % Flip the sign of U to match the signs
    end
end

S_1 = diag(singular_values);
A_corrected = U * S_1 * V';

disp('Original matrix A:');
disp(A_1);
disp('Reconstructed matrix A using U * S * V^T (after fixing signs):');
disp(A_corrected);

error_corrected = norm(A_1 - A_corrected);
disp(['Error after fixing signs: ', num2str(error_corrected)]);