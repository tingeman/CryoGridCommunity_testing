%========================================================================
% Test harmonic air temperature Forcing class
% T. Ingeman-Nielsen, Dec 2021
%========================================================================

classdef TEST__FORCING_harmonic_Tair < TESTCASE
    
    properties
        run_flag = true;                               % Set this to false to skip the step that runs the model
        result_path = './results/';                    % with trailing backslash
        run_name = 'test_FORCING_harmonic_Tair';       % parameter file name and result directory 
        run_modes = {'yml'};                           % list the run modes to include ('xls' and/or 'yml')
    end
    
    methods 

        function initialize(self)
            % conduct parent class initialization
            initialize@TESTCASE(self)
        end


        function [air_temperature, nominal_air_temperature] = get_data(self)
            % convert output
            [result_yml] = analyze_display.usableOUT(self.yml_out.out);
            
            forcing = provide(self, 'forcing', self.yml_provider);
            forcing = forcing.finalize_init(NaN);

            my_tile = {};
            
            % get air_temperature for final output times
            air_temperature = zeros(1,length(result_yml.TIMESTAMP));
            for k = 1:length(result_yml.TIMESTAMP)
                my_tile.t = result_yml.TIMESTAMP(k);
                f = forcing.interpolate_forcing(my_tile);
                air_temperature(k) = f.TEMP.Tair;
            end
            
            % get air_temperature for nominal forcing time series
            nominal_air_temperature = zeros(1,length(forcing.DATA.timeForcing));
            for k = 1:length(forcing.DATA.timeForcing)
                my_tile.t = forcing.DATA.timeForcing(k);
                f = forcing.interpolate_forcing(my_tile);
                nominal_air_temperature(k) = f.TEMP.Tair;
            end
        end


        function assert(self)
            [result_yml] = analyze_display.usableOUT(self.yml_out.out);
            [air_temperature, nominal_air_temperature] = get_data(self);

            % Throw an error if the two results are not identical to within 2 degC
            assert(all(all(air_temperature(30:end)-result_yml.T(1,30:end) <= 0.2)))  
            disp('=============================================')
            disp([mfilename ': Test passed.'])
            disp('Ground surface temperature is similar to ')
            disp('air temperature to within <= 0.2 degC') 
            disp('(tested after 30 days initial spin-up)')
            disp('=============================================')
            
            forcing = provide(self, 'forcing', self.yml_provider);
            at_max = forcing.PARA.amplitude+forcing.PARA.maat;
            assert(abs(max(nominal_air_temperature)-at_max)<=0.01)
            %disp('=============================================')
            disp([mfilename ': Test passed.'])
            disp('Maximum air temperature is as expected.')
            disp('=============================================')
        end


        function plot(self)
            % No plotting defined
            [result_yml] = analyze_display.usableOUT(self.yml_out.out);
            [air_temperature, nominal_air_temperature] = get_data(self);

            figure;
            plot(result_yml.TIMESTAMP, air_temperature)
            hold on;
            plot(result_yml.TIMESTAMP, result_yml.T(1,:))

            figure;
            plot(result_yml.TIMESTAMP(30:end), air_temperature(30:end)-result_yml.T(1,30:end))
        end

    end
        
    
end
