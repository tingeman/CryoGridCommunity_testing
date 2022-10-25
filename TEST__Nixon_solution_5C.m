%========================================================================
% Test CryoGrid calculate thaw front depth against Nixon solution.
% T. Ingeman-Nielsen, Dec 2021
%========================================================================

classdef TEST__Nixon_solution_5C < TESTCASE
    
    properties
        run_flag = true;     % Set this to false to skip the step that runs the model
        result_path = './results/';   % with trailing backslash
        run_name = 'test_Nixon_solution_5C';       % parameter file name and result directory 
        run_modes = {'yml'};   % list the run modes to include ('xls' and/or 'yml')
        plot_times
    end
    
    methods 

        function initialize(self)
            self.yml_const_file = 'CONSTANTS_YAML';
            % conduct parent class initialization
            initialize@TESTCASE(self)
        end

        
        function [alpha_eq7, alpha_eq8, alpha_eq10] = get_Nixon_solution(self)
            provider = self.yml_provider;
            tile = self.yml_tile;
            out = self.yml_out.out;
            
            t = tile.FORCING.DATA.timeForcing-tile.FORCING.DATA.timeForcing(1);
            t = t*tile.CONST.day_sec;

            %% Nixon solution
            
            % L = \rho_d * Lf * (w - w_u)/100
            %   = Lf * (\theta - \theta_u)
            %
            % L:      Volumetric latent heat of fusion [kJ/m3]
            % Lf:     mass latent heat of fusion [kJ/kg] 
            % \rho_d: dry soil density [kg/m3]
            % w:      gravimetric water content
            % w_u:    gravimetric unfrozen water content
            % \theta: volumetric water content
            % \theta_u: volumetric unforzen water content
            
            
            % X = \alpha * sqrt(t)
            %
            % where alpha is given by the equality:
            %
            % sqrt(pi)*(alpha./(2*sqrt(alpha_u))).*exp((alpha.^2)/(4.*alpha_u)).*erf(alpha/(2*sqrt(alpha_u))) = Ste
            %
            % and needs a numerical solution.
            %
            % Ste = c_vu*Ts*(L)^-1
            % \alpha_u: unfrozen thermal diffusivity
            % c_vu:     unfrozen volumetric heat capacity
            % Ts:       applied constant surface temperature
            
            % Frozen ground is assumed at 0C
            % Ts is the surface temperature
            
            Ts = tile.FORCING.PARA.T_ub;
            Lf = provider.CONST.L_f;

            ground = tile.TOP_CLASS;
            theta = ground.STATVAR.waterIce(1) ./ (ground.STATVAR.layerThick(1) .* ground.STATVAR.area(1));
            theta_u = 0;   % Assume all is frozen at initial time
            c_vu = (provider.CONST.c_w .* ground.STATVAR.waterIce(1) ./ (ground.STATVAR.layerThick(1) .* ground.STATVAR.area(1)) + ...
                    provider.CONST.c_m .* ground.STATVAR.mineral(1) ./ (ground.STATVAR.layerThick(1) .* ground.STATVAR.area(1)) + ...
                    provider.CONST.c_o .* ground.STATVAR.organic(1) ./ (ground.STATVAR.layerThick(1) .* ground.STATVAR.area(1)));
            k = ground.STATVAR.thermCond(1);
            alpha_u = k./c_vu;
            
            L = Lf * (theta-theta_u);
            Ste = c_vu.*Ts.*(1./L);

            syms f(alph)
            f(alph) = sqrt(pi)*(alph./(2*sqrt(alpha_u))).*exp((alph.^2)/(4.*alpha_u)).*erf(alph/(2*sqrt(alpha_u)))-Ste;
            sol = vpasolve(f,alph,[0, 1]);
            alpha_eq7 = sol;
            alpha_eq8 = 2.*sqrt(alpha_u).*sqrt(Ste/2).*sqrt(1-Ste/8);
            alpha_eq10 = 2.*sqrt(alpha_u).*sqrt(Ste/2);     % Original Stefan solution
            %Nixon_X = alpha_eq10 * sqrt(t);
            %t = t/tile.CONST.day_sec;
        end


        function ys = find_zero(self, xi, yi, exclude_zeros)
            % Finds zero crossings in the xi elements (e.g. ground temperature) and interpolates
            % the depth of the zero crossing based on the distances in yi.
            %
            % The standard use of np.sign will also identify zeros as a sign change, so
            % if a node is exactly 0.000 (which could happen e.g. during freezing
            % there would be two immediately successive crossings.
            %
            % Using the flag exclude_zeros=True will exclude these double indices.
            % [1, 0, -1, 0, -1, 1]  ->   id = [0, 4]
            % [-1, 0, 1, 0, 1, -1]  ->   id = [1, 2, 3, 4]
            % ...such that interpolation can be done from nodes id to id+1
            % In context of active layers, this means that the freezing front is
            % identified at the top of a 0C interval.
            %
            % There may be still some issues with [1, 0, 1] type situations, which may have to be handled.
            
            if nargin < 4
                exclude_zeros=true;
            end
            
            if exclude_zeros
                % This code will check for xi elements equal zero, and
                mydiff = diff(sign(xi));

                for id = 1:length(mydiff)
                    if (xi(id) == 0) && (xi(id + 1) < 0)
                        mydiff(id) = 0;
                    elseif (xi(id) < 0) && (xi(id + 1) == 0)
                        mydiff(id) = 0;
                    end
                end
                idx = find(mydiff);   % find nonzero elements
            else
                idx = find(diff(sign(xi)))+1;
                % In this call a change from positive to zero is also counted as a sign change!
                % this version is not very useful for ALT estimation...
            end

            if isempty(idx)
                ys = 0;
            else
                ys = zeros(size(idx));
                for ix = 1:length(idx)
                    y0 = (yi(idx(ix)) * (xi(idx(ix)+1) - 0) + yi(idx(ix)+1) * (0 - xi(idx(ix)))) / (xi(idx(ix)+1) - xi(idx(ix)));
                    ys(ix) = y0;
                end
            end
        end


        function ys = find_zero_cg(self, xi, yi)
            % Finds zero crossings by identifying zero-valued nodes
            % and interpolating between the node above and below.
           
            
            mydiff = diff(sign(xi));
            idx = find(mydiff);
            %idx = find(xi==0);
            
            if isempty(idx)
                ys = 0;
            else
                ys = zeros(size(idx));
                for ix = 1:length(idx)
                    if idx(ix) == 1
                        y0 = yi(1);
                    elseif xi(idx(ix))==0
                        y0 = (yi(idx(ix)-1) * (xi(idx(ix)+1) - 0) + yi(idx(ix)+1) * (0 - xi(idx(ix)-1))) / (xi(idx(ix)+1) - xi(idx(ix)-1));
                    else
                        y0 = (yi(idx(ix)) * (xi(idx(ix)+1) - 0) + yi(idx(ix)+1) * (0 - xi(idx(ix)))) / (xi(idx(ix)+1) - xi(idx(ix)));
                    end
                    ys(ix) = y0;
                end
            end
        end
        




        function thaw_d = get_cg_thawdepth(self, use_cg_fix)
            if nargin < 2
                use_cg_fix = true;
            end

            out = self.yml_out.out;
            depths = cumsum(out.STRATIGRAPHY{1}{1}.STATVAR.layerThick) - out.STRATIGRAPHY{1}{1}.STATVAR.layerThick(1)/2;

            thaw_d = zeros(size(out.TIMESTAMP));

            if use_cg_fix
                disp('Using CryoGrid zero-cell FIX')
            end
               
            
            for k = 1:length(thaw_d)
                T = out.STRATIGRAPHY{k}{1}.STATVAR.T;
                if use_cg_fix
                    zc = self.find_zero_cg(T, depths); 
                else
                    zc = self.find_zero(T, depths, true);   
                end
                thaw_d(k) = zc(1);
            end
        end


        function assert(self)
%             msg = ['Not implemented yet! Test Stefan solution output, \n' ...
%                    'and implement frost-front detection in CryoGrid \n' ...
%                    'output. Plot Stefan depth against CryoGrid result.'];
%             error(msg)
% 
%             [t, depths, Stefan_X] = get_Stefan_solution(self);
%             

%             % convert output
%             [result_xls] = analyze_display.usableOUT(self.xls_out.out);
%             [result_yml] = analyze_display.usableOUT(self.yml_out.out);
%             
%             % Throw an error if the two results are not identical to within 1e-6
%             assert(all(all(result_xls.T-result_yml.T <= 1e-6)))  
%             disp('=============================================')
%             disp([mfilename ': Test passed.'])
%             disp('Calculated results are identical to <= 1e-6')
%             disp('=============================================')
        end


        function plot(self)
            if any(strcmpi('yml', self.run_modes))
                out = self.yml_out.out;
            elseif any(strcmpi('xls', self.run_modes))
                out = self.xls_out.out;
            end

            depths = cumsum(out.STRATIGRAPHY{1}{1}.STATVAR.layerThick) - out.STRATIGRAPHY{1}{1}.STATVAR.layerThick(1)/2;
            t = out.TIMESTAMP-out.TIMESTAMP(1);

            use_cg_fix = true;
            td = self.get_cg_thawdepth(use_cg_fix);
            
            [alpha_eq7, alpha_eq8, alpha_eq10] = self.get_Nixon_solution();

            figure

            plot(out.STRATIGRAPHY{end}{1}.STATVAR.T, depths, '.-k')
            set(gca, 'YDir','reverse')
            ylabel('Depth [m]', 'Interpreter', 'none') 
            xlabel('Temperature [degC]', 'Interpreter', 'none') 
            ylim([0,20])

            figure

            h1 = plot(t, td, '-k', 'LineWidth', 1);
            hold on
            h2 = plot(t, alpha_eq7*sqrt(t*24*3600), '-r', 'LineWidth', 1);
            h3 = plot(t, alpha_eq8*sqrt(t*24*3600), '--r', 'LineWidth', 1);
            h4 = plot(t, alpha_eq10*sqrt(t*24*3600), ':r', 'LineWidth', 1);
            set(gca, 'YDir','reverse')
            ylabel('Thaw depth [m]', 'Interpreter', 'none') 
            xlabel('Time [days]', 'Interpreter', 'none') 
            legend([h1, h2, h3, h4], {'Numerical', 'Analytical (eq7)', 'Analytical (eq8)', 'Analytical (eq10)'}, 'Location', 'northeast')

            exportgraphics(gcf,[self.run_name '.png'],'Resolution',300)
        end

    end
        
    
end
