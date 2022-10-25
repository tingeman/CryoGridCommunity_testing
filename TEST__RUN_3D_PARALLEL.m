%========================================================================
% Test yaml provider against excel provider
% T. Ingeman-Nielsen, Dec 2021
%========================================================================

classdef TEST__RUN_3D_PARALLEL < TESTCASE
    
    properties
        run_flag = true;     % Set this to false to skip the step that runs the model
        result_path = './results/';   % with trailing backslash
        run_name = 'test_RUN_3D_PARALLEL';       % parameter file name and result directory 
        run_modes = {'yml'};          % list the run modes to include ('xls' and/or 'yml')
    end
    
    methods 

        function initialize(self)
            required_files = {'./forcing/CG_Beaufort_81_880_short_crop_1yr.mat'};             % comma-separated cell array of files that must be present
            repository = 'http://files.arctic.byg.dtu.dk/files/CryoGrid/CryoGridTesting/forcing/';    % repository from which to download files if they do not exist
            get_required_files(required_files, repository);   % get required files if missing
            
            % conduct parent class initialization
            initialize@TESTCASE(self)
        end

        
        function get_out(self, run_name)
            % override stored run_name to load the results from
            % the first tile calculated.
            run_name = [self.run_name '_1'];
            get_out@TESTCASE(self, run_name)
        end


        function assert(self)
            % convert output
            out = self.yml_out.out;
            [result] = analyze_display.usableOUT(out);
            
            
            % Throw an error if the two results are not identical to within 1e-6
            assert(~isempty(result.T))  
            disp('=============================================')
            disp([mfilename ': Test passed.'])
            disp('Output contains data.')
            disp('=============================================')
        end


        function plot(self)
            run_info = provide(self, 'run_info');
            forcing = provide(self, 'forcing');
            
            out = self.yml_out.out;
            
            figure;
            legend_text = {};
            
            for tid = 1:run_info.PARA.number_of_tiles
                
                filename = get_filename(out, forcing.PARA.end_time, self.result_path, [self.run_name '_' num2str(tid)]);
    
                if exist(filename, "file")
                    % load results
                    out = load(filename);
    
                    % convert output
                    out = out.out;
                    %[result] = analyze_display.usableOUT(out);

                    depths = cumsum(out.STRATIGRAPHY{1}{1}.STATVAR.layerThick) - ... 
                                    out.STRATIGRAPHY{1}{1}.STATVAR.layerThick(1)/2;
    
                    plot(out.STRATIGRAPHY{end}{1}.STATVAR.T, depths)    % second class because first class is SNOW
                    hold on
                    legend_text{tid} = ['TILE ' num2str(tid)];
                end
            end
    
            legend(legend_text, 'location', 'NW')
    
            set(gca, 'YDir','reverse')
            xlabel('Temperature [degC]', 'Interpreter', 'none') 
            ylabel('Depth [m]', 'Interpreter', 'none') 
        end

    end
        
    
end
