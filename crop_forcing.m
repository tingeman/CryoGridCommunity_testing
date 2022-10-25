% Script to crop all fields of a forcing dataset
%
% 1. Set the input filename and path (forcing file)
% 2. Set the output filename and path (forcing file)
% 3. Specify the start date
% 4. Specify the number of years to include (default = 1)
% 5. Run script
%
% T. Ingeman-Nielsen, December 2020

forcing_in =  'C:\thin\02_Code\Matlab\CryoGRID\CryoGridTesting\forcing\CG_Beaufort_81_880_short.mat';
forcing_out = 'C:\thin\02_Code\Matlab\CryoGRID\CryoGridTesting\forcing\CG_Beaufort_81_880_short_crop_1yr.mat';

startdate = datenum('01.07.1980','dd.mm.yyyy');
nyears = 1;

load(forcing_in)
id1 = find(FORCING.data.t_span>=startdate,1);
id2 = find(FORCING.data.t_span<=startdate+nyears*365,1,'last');

disp(['Start date: ' datestr(FORCING.data.t_span(1))]);
disp(['Crop start: ' datestr(FORCING.data.t_span(id1))]);
disp(['Crop end:   ' datestr(FORCING.data.t_span(id2))]);
disp(['End date:   ' datestr(FORCING.data.t_span(end))]);
disp(' ');

fnames = fieldnames(FORCING.data);

for k = 1:length(fnames)
    if isnumeric(FORCING.data.(fnames{k})(1:10)) && length(FORCING.data.(fnames{k}))>id2
        disp(['Cropping field: ' fnames{k}])
        FORCING.data.(fnames{k}) = FORCING.data.(fnames{k})(id1:id2);
    end
end

disp(' ');
disp(['Forcing data cropped: ' datestr(FORCING.data.t_span(1)) ...
      ' to ' datestr(FORCING.data.t_span(end))]);
  
save(forcing_out, 'FORCING')
disp(['Forcing data saved to: ' forcing_out]);


