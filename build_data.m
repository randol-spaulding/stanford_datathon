% This script reads the supplied files from countyhealthrankings.org into
% tables to be interpreted and exports the interpretations into a csv
% file
%
% author: Randol Spaulding
%
% Get the following data:
% State | County | Population |  OD Mortality % | % Adults Uninsured | 
% Healthcare Costs | Median Household Income
raw_2014 = readtable('2014_CHR.csv');
clean_2014 = raw_2014(:,[2:4,43,45,52,63]);
raw_2015 = readtable('2015_CHR.csv');
clean_2015 = raw_2015(:,[2:4,56,58,65,74]);
raw_2016 = readtable('2016_CHR2.csv');
clean_2016 = raw_2016(:,[2,3,32,42,49,54]);
raw_2016_2 = readtable('2016CHR_CSV_Analytic_Data_v2.csv');
pop_2016 = raw_2016_2(:,[2,295]);  % 2016 seperated population file
extra_meta = raw_2016_2(:,[93, 124,134,149,154,169,249,259,270, 285,295,350]);
raw_2017 = readtable('2017_CHR.csv');
clean_2017 = raw_2017(:,[2,3,32,41,48,52]);

% Shannon county in North Dakota changed names to Oglala Lakota in 2016
clean_2014.Var3{2417} = 'Oglala Lakota';
clean_2015.Var3{2417} = 'Oglala Lakota';

% First row contains names, delete those
% Last two rows are blanks, delete those
clean_2014(1,:) = [];
clean_2014((end-1):end,:) = [];
clean_2015(1,:) = [];
clean_2015((end-1):end,:) = [];
clean_2017(1,:) = [];

% Population list includes whole state population, which doesn't fit the
% format of our other data -> get rid of state row ids (0)
for i = 1:size(clean_2017,1)
    if pop_2016{i,1} == 0
        pop_2016(i,:) = [];
    end
end
pop_2016 = pop_2016(:,2);

% We need the tables to have the county rows lining up so we can join them
i = 1;
while i < size(clean_2017,1)
    % Delete rows if they don't appear in the final 2017 data (only 5)
    if ~strcmp(cell2mat(clean_2017{i,2}),cell2mat(clean_2016{i,2}))
        clean_2016(i,:) = [];
        clean_2015(i,:) = [];
        clean_2014(i,:) = [];
        pop_2016(i,:) = [];
    else
        i = i + 1;
    end
end

clean_2014.Properties.VariableNames(4) = {'Deaths_2014'};
clean_2015.Properties.VariableNames(4) = {'Deaths_2015'};
clean_2016.Properties.VariableNames(3) = {'Deaths_2016'};
clean_2017.Properties.VariableNames(3) = {'Deaths_2017'};
% Combine the overdose death info by year
deaths = [clean_2017(:,1:2), clean_2014(:,4), clean_2015(:,4), clean_2016(:,3), clean_2017(:,3)];
% Using 2017 stats for baseline comparisons (can be changed for specific
% scenarios)
costs = clean_2017(:,5);
uninsured = clean_2017(:,4);
income = clean_2017(:,6);
% Remove District of Columbia
deaths(314,:) = [];
costs(314,:) = [];
uninsured(314,:) = [];
income(314,:) = [];
delta_deaths = [deaths(:,1:2), array2table(zeros(size(deaths,1),6), 'VariableNames', ...
    {'delta_2014_2015', 'delta_2015_2016','delta_2016_2017',...
    'weighted_2014_2015', 'weighted_2015_2016', 'weighted_2016_2017'})];
state_info = zeros(50,3);
% Holds all the meta values by state
state_meta = zeros(50,12);
skipped = [];
current_state = 'Alabama';
current_state_id = 1;
current_state_county_num = 0;
for i = 1:size(deaths,1)
    if ~strcmp(current_state, deaths{i,1})
        state_info(current_state_id,:) = state_info(current_state_id,:)/current_state_county_num;
        state_meta(current_state_id) = state_meta(current_state_id)/current_state_county_num;
        current_state = deaths{i,1};
        current_state_county_num = 0;
        current_state_id = current_state_id + 1;
    end
    if strcmp(cell2mat(deaths{i,3}),'') || ...
        strcmp(cell2mat(deaths{i,4}),'') || ...
        isnan(deaths{i,5}) || ...
        strcmp(cell2mat(deaths{i,6}),'')
        
        skipped = [skipped; i];
        continue
    end
    % stupid line by line stuff because formatting
    delta_deaths{i,3} = str2double(deaths{i,3}{1});
    delta_deaths{i,4} = str2double(deaths{i,4}{1});
    delta_deaths{i,3} = delta_deaths{i,4} - delta_deaths{i,3};
    delta_deaths{i,4} = deaths{i,5} - delta_deaths{i,4};
    delta_deaths{i,5} = str2double(deaths{i,6}{1}) - deaths{i,5};
    % calculate weighted delta_death value by population
    delta_deaths{i,6} = str2double(clean_2014{i,3}) * delta_deaths{i,3};
    delta_deaths{i,7} = str2double(clean_2015{i,3}) * delta_deaths{i,4};
    delta_deaths{i,8} = str2double(pop_2016{i,1}) * delta_deaths{i,5};
    % summing everything up to be averaged by state level
    state_info(current_state_id,1) = state_info(current_state_id,1) + delta_deaths{i,6};
    state_info(current_state_id,2) = state_info(current_state_id,2) + delta_deaths{i,7};
    state_info(current_state_id,3) = state_info(current_state_id,3) + delta_deaths{i,8};
    current_state_county_num = current_state_county_num + 1;
    for f = 1:12
        temp = extra_meta{i,f};
        if iscell(temp)
            temp = str2double(temp{1});
        end
        if isnan(temp)
            continue
        end
        state_meta(current_state_id, f) = state_meta(current_state_id,f) + temp;
    end
end
state_info(50,:) = state_info(50,:)/current_state_county_num;
state_meta(50,:) = state_meta(50,:)/current_state_county_num;

% remove rows that were found to have NaN or empty values
delta_deaths(skipped,:) = [];

policies = readtable('policy_data.csv');
% find minimum value for optimal year (y + 2013)
[~, y] = min(state_info,[],2);
master = [policies(:,[1,2]), array2table(zeros(50,6), 'VariableNames', ...
    {'PainClinics_PainManagement', 'PrescribingGuidelines_Limits', ...
    'ProviderTraining', 'RescueDrugs', 'DrugMonitoringProgram', 'Other'})];
% policies associated with that optimal year -> optimal policies
for i = 1:50
    C = policies(i,(6*y(i)-3):(6*y(i)+2));
    % try a previous year if there were no policies that year
    if prod(policies{i,(6*y(i)-3):(6*y(i)+2)} == [0,0,0,0,0,0]) && y(i) ~= 1
        C = policies(i,(6*y(i)-3-1):(6*y(i)+2-1));
    end
    master(i, 3:8) = C;
end

master = [master, array2table(state_meta,'VariableNames',extra_meta.Properties.VariableNames)];
writetable(master,'optimal_policies.csv')
        