test_dir = '.';
close_figures = true;

% get all test m-files
test_mfile_list = dir(fullfile(test_dir, 'TEST_*.m'));

% filter for TESTCASE classes
test_cases = struct;
for k = 1:length(test_mfile_list)
    [filepath,name,ext] = fileparts(test_mfile_list(k).name);
    if exist(name, 'class')
        % only keep if file contains a class definition
        test = feval(name);
        if isa(test, 'TESTCASE')
            % only store if it is a TESTCASE instance
            test_cases(k).name = name;
        end
    end
end

t_start = datetime(datestr(now));

% run all identified tests
for k = 1:length(test_cases)
    test = feval(test_cases(k).name);
    disp(' ')
    disp(' ')
    disp('=====================================================')
    disp(['TEST CASE: ' test_cases(k).name])
    disp('=====================================================')
    try
        run_all(test);
        test_cases(k).assertion_OK = true;
        test_cases(k).Exception = [];
    catch ME
        disp(' ')
        disp(getReport(ME))
        disp(' ')
        disp('=====================================================')
        disp(['TEST CASE: ' test_cases(k).name])
        disp('>> ASSERTION FAILED!')
        disp('=====================================================')
        test_cases(k).assertion_OK = false;
        test_cases(k).Exception = ME;
    end
    if close_figures
        close all;
    end
end

disp(' ')
disp(' ')

deltatime = datetime(datestr(now))-t_start;
fprintf('Total elapsed time for all tests: ');
disp(deltatime);

% Report on successes and failures
passed_count = sum([test_cases.assertion_OK]);
not_passed_count = sum(~[test_cases.assertion_OK]);

disp(' ')
disp(' ')
if not_passed_count == 0
    disp('SUCCESS: All test cases passed!')
else
    disp([num2str(passed_count) ' test casses passed.'])
    disp(['WARNING: ' num2str(not_passed_count) ' test casses did not pass:'])
    failed_cases = test_cases(~[test_cases.assertion_OK]);
    for k = 1:not_passed_count
        disp(['  ' failed_cases(k).name ' did not pass.'])
    end
end







