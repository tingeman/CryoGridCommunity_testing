%========================================================================
% Test case for dirichlet upper and lower boundaries
% T. Ingeman-Nielsen, Dec 2021
%========================================================================

classdef TEST__dirichlet_UB_LB < TESTCASE
    
    properties
        run_flag = true;                         % Set this to false to skip the step that runs the model
        result_path = './results/';              % with trailing backslash
        run_name = 'test_dirichlet_UB_LB';       % parameter file name and result directory 
        run_modes = {'yml'};                     % list the run modes to include ('xls' and/or 'yml')
    end
    
    methods 

        function initialize(self)
            required_files = {'./forcing/Constant_Tair=10C.mat'};               % comma-separated cell array of files that must be present
            repository = 'http://files.arctic.byg.dtu.dk/files/CryoGrid/CryoGridTesting/forcing/';    % repository from which to download files if they do not exist
            get_required_files(required_files, repository);   % get required files if missing
            
            % conduct parent class initialization
            initialize@TESTCASE(self)
        end


        function assert(self)
            if any(strcmpi('yml', self.run_modes))
                out = self.yml_out.out;
            elseif any(strcmpi('xls', self.run_modes))
                out = self.xls_out.out;
            end

            depths = cumsum(out.STRATIGRAPHY{1}{1}.STATVAR.layerThick) - out.STRATIGRAPHY{1}{1}.STATVAR.layerThick(1)/2;
            nominal_temperature = (0-10)/(1-0)*depths + 10;
            
            % Throw an error if the two results are not identical 
            assert(all(all(abs(out.STRATIGRAPHY{end}{1}.STATVAR.T-nominal_temperature) <= 2e-2)))  
            disp('=================================================================')
            disp([mfilename ': Test passed.'])
            disp('Calculated results are identical to analytical to within <= 2e-2')
            disp('=================================================================')
        end


        function plot(self)
            if any(strcmpi('yml', self.run_modes))
                out = self.yml_out.out;
            elseif any(strcmpi('xls', self.run_modes))
                out = self.xls_out.out;
            end

            depths = cumsum(out.STRATIGRAPHY{1}{1}.STATVAR.layerThick) - out.STRATIGRAPHY{1}{1}.STATVAR.layerThick(1)/2;

            figure

            plot(out.STRATIGRAPHY{1}{1}.STATVAR.T, depths)
            hold on
            plot(out.STRATIGRAPHY{end}{1}.STATVAR.T, depths)
            set(gca, 'YDir','reverse')
            xlabel('Temperature [degC]', 'Interpreter', 'none') 
            ylabel('Depth [m]', 'Interpreter', 'none') 
        end

    end
end
