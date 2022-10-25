%========================================================================
% Test case for dirichlet fixed upper and lower boundaries
% T. Ingeman-Nielsen, Dec 2021
%========================================================================

classdef TEST__FORCING_ubT_lbT_fixed < TESTCASE
    
    properties
        run_flag = true;                         % Set this to false to skip the step that runs the model
        result_path = './results/';              % with trailing backslash
        run_name = 'test_FORCING_ubT_lbT_fixed'; % parameter file name and result directory 
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

        function [depths, nominal_T] = get_steady_state_T(self)
            out = self.yml_out.out;
            depths = cumsum(out.STRATIGRAPHY{1}{1}.STATVAR.layerThick) - out.STRATIGRAPHY{1}{1}.STATVAR.layerThick(1)/2;

            %% Analytical steady state temperature distribution
            
            Tinit = 0;
            Tstep = 10;
            d0 = 0;
            d1 = 1;
            
            nominal_T = (Tinit-Tstep)/(d1-d0)*depths + Tstep;
        end
           

        function assert(self)
            if any(strcmpi('yml', self.run_modes))
                out = self.yml_out.out;
            elseif any(strcmpi('xls', self.run_modes))
                out = self.xls_out.out;
            end

            [depths, nominal_T] = get_steady_state_T(self);

            % Throw an error if the two results are not identical to within 2 degC
            assert(all(all(out.STRATIGRAPHY{end}{1}.STATVAR.T-nominal_T <= 1e-2)))  
            disp('===============================================================')
            disp([mfilename ': Test passed.'])
            disp('Numerical and analytical results are identicial to <= 1e-2C')
            disp('===============================================================')
        end


        function plot(self)
            if any(strcmpi('yml', self.run_modes))
                out = self.yml_out.out;
            elseif any(strcmpi('xls', self.run_modes))
                out = self.xls_out.out;
            end

            [depths, nominal_T] = get_steady_state_T(self);

            figure
        
            h1 = plot(out.STRATIGRAPHY{end}{1}.STATVAR.T, depths, 'ok', 'LineWidth', 1, 'MarkerSize',5);
            hold on
            h2 = plot(nominal_T, depths, '-k', 'LineWidth', 1.5);
            max_err = max(abs(out.STRATIGRAPHY{end}{1}.STATVAR.T-nominal_T));
        
            legend([h1, h2], {'Numerical', 'Analytical'}, 'Location', 'southeast')
            ylim([0,1])
            xlim([0,10])
        
            set(gca,'XAxisLocation','top','YAxisLocation','left','ydir','reverse');
            xlabel('Temperature [degC]', 'Interpreter', 'none') 
            ylabel('Depth [m]', 'Interpreter', 'none') 
        end

    end
end
