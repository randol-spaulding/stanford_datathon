% Given that the data has been interpreted into optimal_policies.csv

master = readtable('optimal_policies.csv');

policy_data = master{:,3:8};
meta_data = master{:,9:20};

P = zeros(13,5);
B = zeros(13,5);
% for each policy
for p = 1:6
    p_v = policy_data(:,p);
    % some states had 2 of one type of policy, map -> 1
    for i = 1:50
        if p_v(i) > 1
            p_v(i) = 1;
        end
    end
    p_v = categorical(p_v);
    % multinomial logistic regression
    [b,dev,stats] = mnrfit(meta_data,p_v,'model','hierarchical');
    P(:,p) = stats.p;
    B(:,p) = b;
end
P = P(2:end,:);
B = B(2:end,:);
final_model_P = array2table(P,'VariableNames', master.Properties.VariableNames(3:8),...
                            'RowNames', master.Properties.VariableNames(9:20));
final_model_B = array2table(B,'VariableNames', master.Properties.VariableNames(3:8),...
                            'RowNames', master.Properties.VariableNames(9:20));
% export... isn't saving the rows. They're included in the repo.                        
writetable(final_model_P,'final_model_P.csv')
writetable(final_model_B,'final_model_B.csv')
