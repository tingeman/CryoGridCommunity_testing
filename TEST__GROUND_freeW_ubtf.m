%========================================================================
% Test yaml provider against excel provider for GROUND_freew_ubtf class
% T. Ingeman-Nielsen, Dec 2021
%========================================================================

classdef TEST__GROUND_freeW_ubtf < TESTCASE
    
    properties
        run_flag = true;     % Set this to false to skip the step that runs the model
        result_path = './results/';   % with trailing backslash
        run_name = 'test_GROUND_freeW_ubtf';       % parameter file name and result directory 
        run_modes = {'xls', 'yml'};   % list the run modes to include ('xls' and/or 'yml')
    end
    
    methods 

        function initialize(self)
            required_files = {'./forcing/CG_Beaufort_81_880_short_crop_1yr.mat'};             % comma-separated cell array of files that must be present
            repository = 'http://files.arctic.byg.dtu.dk/files/CryoGrid/CryoGridTesting/forcing/';    % repository from which to download files if they do not exist
            get_required_files(required_files, repository);   % get required files if missing
            
            % conduct parent class initialization
            initialize@TESTCASE(self)
        end


        function assert(self)
            % convert output
            [result_xls] = analyze_display.usableOUT(self.xls_out.out);
            [result_yml] = analyze_display.usableOUT(self.yml_out.out);
            
            % Throw an error if the two results are not identical to within 1e-6
            assert(all(all(result_xls.T-result_yml.T <= 1e-6)))  
            disp('=============================================')
            disp([mfilename ': Test passed.'])
            disp('Calculated results are identical to <= 1e-6')
            disp('=============================================')
        end


        function plot(self)
            % No plotting defined
        end

    end
        
    
end
