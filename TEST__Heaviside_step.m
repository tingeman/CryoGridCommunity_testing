%========================================================================
% Test CryoGrid calculate thaw front depth against Stefan solution.
% T. Ingeman-Nielsen, Dec 2021
%========================================================================

classdef TEST__Heaviside_step < TESTCASE
    
    properties
        run_flag = false;     % Set this to false to skip the step that runs the model
        result_path = './results/';   % with trailing backslash
        run_name = 'test_heaviside_step';       % parameter file name and result directory 
        run_modes = {'yml'};   % list the run modes to include ('xls' and/or 'yml')
        plot_times
    end
    
    methods 

        function initialize(self)
            required_files = {'./forcing/Constant_Tair=10C.mat'};              % comma-separated cell array of files that must be present
            repository = 'http://files.arctic.byg.dtu.dk/files/CryoGrid/CryoGridTesting/forcing/';    % repository from which to download files if they do not exist
            get_required_files(required_files, repository);   % get required files if missing
            
            % define timestamps to plot/compare
            self.plot_times = [1, 1+30, 1+100, 1+365, 1+(2*365), 1+(5*365)];

            % conduct parent class initialization
            initialize@TESTCASE(self)
        end

        
        function [t, depths, T_heaviside] = get_T_heaviside(self)
            out = self.yml_out.out;
            depths = cumsum(out.STRATIGRAPHY{1}{1}.STATVAR.layerThick) - out.STRATIGRAPHY{1}{1}.STATVAR.layerThick(1)/2;
                     
            %% Analytical Heaviside step function
            
            t = (out.TIMESTAMP-out.TIMESTAMP(1))*24*3600;  % Time in seconds since step
            C = out.STRATIGRAPHY{end}{1}.CONST.c_m;
            k = out.STRATIGRAPHY{end}{1}.CONST.k_m;
            
            Tinit = 1;
            Tstep = 10;
            
            T_heaviside = zeros(length(depths), length(self.plot_times));
            
            for jj = 1:length(self.plot_times)
                T_heaviside(:,jj) = (Tstep-Tinit)*erfc(sqrt((C*depths.^2)/(4*k*t(self.plot_times(jj))))) + Tinit;
            end
        end


        function assert(self)
            out = self.yml_out.out;
            [t, depths, T_heaviside] = get_T_heaviside(self);
            

            % Throw an error if the two results are not identical to within 1e-6
            assert(all(all(abs(out.STRATIGRAPHY{self.plot_times(end)}{1}.STATVAR.T - ...
                               T_heaviside(:,length(self.plot_times))) <= 1e-2)))  
            disp('=================================================================')
            disp([mfilename ': Test passed.'])
            disp('Calculated results are identical to analytical to within <= 1e-2')
            disp('=================================================================')
        end


        function plot(self)
            out = self.yml_out.out;
            [t, depths, T_heaviside] = get_T_heaviside(self);

            figure
        
            max_err = zeros('like', self.plot_times);
            for jj = 1:length(self.plot_times)
                h1 = plot(out.STRATIGRAPHY{self.plot_times(jj)}{1}.STATVAR.T(1:4:end), depths(1:4:end), 'ok', 'LineWidth', 1, 'MarkerSize',5);
                hold on
                h2 = plot(T_heaviside(:,jj), depths, '-k', 'LineWidth', 1.5);
                max_err(jj) = max(abs(out.STRATIGRAPHY{self.plot_times(jj)}{1}.STATVAR.T-T_heaviside(:,jj)));
            end
            legend([h1, h2], {'Numerical', 'Analytical'}, 'Location', 'southeast')
            
            ylim([0,20])
            xlim([0,10])
        
            set(gca,'XAxisLocation','top','YAxisLocation','left','ydir','reverse');
            xlabel('Temperature [degC]', 'Interpreter', 'none') 
            ylabel('Depth [m]', 'Interpreter', 'none') 
            
            h = text(1.2,1, 't=0s');
            h1 = text(1.6,3.2, 't=24h');
            h2 = text(1.8,5.8, 't=100d');
            h3 = text(2.6,10, 't=1yr');
            h4 = text(4.7,12, 't=2yr');
            h5 = text(5.9,14, 't=5yr');
        
            exportgraphics(gcf,'test_heaviside_step.png','Resolution',300)

        end

    end
        
    
end
