%========================================================================
% BASE class for test cases
% T. Ingeman-Nielsen, Dec 2021
%========================================================================

classdef TESTCASE < matlab.mixin.Copyable
    
    properties (Abstract)
        % These properties MUST be defined by sub-classes
        run_flag                     % Set this to false to skip the step that runs the model
        result_path                  % with trailing backslash
        run_name                     % parameter file name and result directory 
        run_modes                    % cell array of strings with the run modes to include ('xls' and/or 'yml')
    end

    properties
        % These properties will be inherited from BASE class
        yml_const_file = 'CONSTANTS_YAML'
        xls_const_file = 'CONSTANTS_excel'
        yml_provider                         % populated by methods
        yml_run_info                         % populated by methods
        yml_tile                             % populated by methods
        yml_out                              % populated by methods
        xls_provider                         % populated by methods
        xls_run_info                         % populated by methods
        xls_tile                             % populated by methods
        xls_out                              % populated by methods
    end
    
    methods 
        function run_all(self)
            initialize(self)
            run(self)
            get_out(self)
            assert(self)
            plot(self)
        end

        function initialize(self)
            set_CryoGridPath;

            if any(strcmpi('yml', self.run_modes))
                % Setup yml provider
                constant_file = self.yml_const_file; %file with constants
                init_format = 'YAML';
                
                self.yml_provider = PROVIDER;
                self.yml_provider = assign_paths(self.yml_provider, init_format, self.run_name, self.result_path, constant_file);
                self.yml_provider = read_const(self.yml_provider);
                self.yml_provider = read_parameters(self.yml_provider);
                [self.yml_run_info, self.yml_provider] = run_model(self.yml_provider);
                [self.yml_run_info, self.yml_tile] = setup_run(self.yml_run_info);
            end

            if any(strcmpi('xls', self.run_modes))
                % Setup Excel provider
                constant_file = self.xls_const_file;
                init_format = 'EXCEL';
                
                self.xls_provider = PROVIDER;
                self.xls_provider = assign_paths(self.xls_provider, init_format, self.run_name, self.result_path, constant_file);
                self.xls_provider = read_const(self.xls_provider);
                self.xls_provider = read_parameters(self.xls_provider);
                [self.xls_run_info, self.xls_provider] = run_model(self.xls_provider);
                [self.xls_run_info, self.xls_tile] = setup_run(self.xls_run_info);
            end
        end


        function run(self)
            if any(strcmpi('xls', self.run_modes))
                disp('Running model based on EXCEL parameter file')
                [self.xls_tile] = run_model(self.xls_tile);
            end

            if any(strcmpi('yml', self.run_modes))
                disp('Running model based on YAML parameter file')
                [self.yml_tile] = run_model(self.yml_tile);
            end
        end

        function provider = get_provider(self)
            switch self.run_modes{1}
                case 'xls'
                    provider = self.xls_provider;
                case 'yml'
                    provider = self.yml_provider;
            end
        end

        function this_instance = provide(self, what, provider)
            if ~exist('provider', 'var')
                provider = get_provider(self);
            end
            
            switch what
                case {'run_info'}
                    switch self.run_modes{1}
                        case 'xls'
                            this_instance = self.xls_run_info;
                        case 'yml'
                            this_instance = self.yml_run_info;
                    end                  
                case {'tile'}
                    this_instance = copy(provider.CLASSES.(provider.RUN_INFO_CLASS.PARA.([what '_class'])){provider.RUN_INFO_CLASS.PARA.([what '_class_index'])});
                case {'forcing', 'out'}
                    tile = provide(self, 'tile', provider);
                    this_instance = copy(provider.CLASSES.(tile.PARA.([what '_class'])){tile.PARA.([what '_class_index'])});
                otherwise
                    error(['Class type "' what '" is not supported in TESTCASE.provide method.'])
            end
        end


        function get_out(self, run_name)
            if ~exist('run_name', 'var')
                % run_name was not specifically passed, use stored value
                run_name = self.run_name;
            end

            if any(strcmpi('xls', self.run_modes))
                provider = self.xls_provider;
                forcing = provide(self, 'forcing', provider);
                out = provide(self, 'out', provider);

                end_time = forcing.PARA.end_time;
                if isempty(end_time)
                    fmat = load(fullfile(forcing.PARA.forcing_path, forcing.PARA.filename));
                    end_time = fmat.FORCING.data.t_span(end);
                end

                xls_filename = get_filename(out, end_time, self.result_path, run_name);  
                self.xls_out = load(xls_filename);
            end

            if any(strcmpi('yml', self.run_modes))
                provider = self.yml_provider;
                forcing = provide(self, 'forcing', provider);
                out = provide(self, 'out', provider);

                end_time = forcing.PARA.end_time;
                if isempty(end_time)
                    fmat = load(fullfile(forcing.PARA.forcing_path, forcing.PARA.filename));
                    end_time = fmat.FORCING.data.t_span(end);
                end

                yml_filename = get_filename(out, end_time, self.result_path, run_name);  
                self.yml_out = load(yml_filename);
            end
        end


        function assert(self)
        end


        function plot(self)
        end

    end
        
    
end
