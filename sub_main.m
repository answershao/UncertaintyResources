function [summary_info_save] = sub_main(folder, statistic_CD, num_j, L, skill_count, normalization)
global T cycles resource_cate Simul_Num

% allocate_source_rules_set = {'shsl', 'mas1', 'lcbr'};
% activity_rules_set = {'lst1', 'slst', 'slft'};
allocate_source_rules_set = {'shsl'};
activity_rules_set = {'slft'};

summary_info_save = cell(length(activity_rules_set) * length(allocate_source_rules_set), 12);

for outer_i = 1:length(activity_rules_set)
    activity_rules = activity_rules_set{outer_i};
    
    for outer_j = 1:length(allocate_source_rules_set)
        allocate_source_rules = allocate_source_rules_set{outer_j};
        tic
        t = clock;
        TTC = [];
        seq = 0;
        result_saves_file = cell(50, 12);
        
        for file = 1:5
            [R, r, d, E, delay, ad, people, forestset] = extract_project_info(file, L, num_j);
            [skill_cate, GlobalSourceRequest, Lgs, original_skill_num] = generate_global_info(L, num_j, r, people, skill_count);
            %             [CPM, cpm_start_time, cpm_end_time, original_local_start_times, original_local_end_times, UF, original_total_duration] = calculate_cpm(activity_rules, statistic_CD, d, E, L, R, r,num_j, ad, skill_count,skill_cate,GlobalSourceRequest,Lgs,forestset);
            LST = zeros(L, Simul_Num, num_j); %������ʼʱ��
            LFT = zeros(L, Simul_Num, num_j); %��������ʱ��
            CPM = zeros(Simul_Num, L);
            cpm_start_time = zeros(L, Simul_Num, num_j);
            cpm_end_time = zeros(L, Simul_Num, num_j);
            UF = zeros(Simul_Num, 1);
            
            for num = 1:Simul_Num %�������              
                for i = 1:L
                    % sprintf('�ؼ�·�����ڽ���:%d / %d',i, L)
                    [CPM(num, i), cpm_start_time(i, num, :), cpm_end_time(i, num, :)] = cpm(statistic_CD(:, num, i), E(:, :, i));
                    sprintf('��ʼ�ֲ����Ƚ���:%d / %d', i, L)
                    %дPAȷ��������ȹ�����д���ݷ��湤�ھ�ֵ��õ�SLFT���ȹ���
                    [lst, lft] = find_PR_slft_slst(num_j, statistic_CD(:, num, i), E(:, :, i), cpm_end_time(i, num, :)); %-���湤��-ÿ�η������ɵĻ��LST,LFT
                    LST(i, num, :) = lst;
                    LFT(i, num, :) = lft;
%                 for project = 1:L
                    global_cpm_start_time(i,:) = cpm_start_time(i, num, :) + ad(i);
                    global_cpm_end_time(i,:) = cpm_end_time(i, num, :) + ad(i);%����Ŀ�п���ȫ����Դʱ����Ҫ������Ŀ�ĵ���ʱ��
                    inter_GCPD(i) = max(global_cpm_end_time(i,:));
                end
                GCPD(num) = max(inter_GCPD);%ȫ�ֹؼ�·��ʱ��
                UF(num) = find_UF(GCPD(num), statistic_CD(:, num, :), skill_count,skill_cate,GlobalSourceRequest,Lgs);%��ǰ�ó�һ��������UF
            end
            
            for cycle = 1:cycles %������� 2
                
                for num = 1:Simul_Num %������� 5
                    original_local_start_times = zeros(Simul_Num, num_j, L); %�˴��ĳ�ʼ��ʼʱ����֮ǰ��һ����Ҫ���¸��ݾֲ����ȹ���ȷ��
                    original_local_end_times = zeros(Simul_Num, num_j, L);
                    
                    for i = 1:L % CPLEX����
                        sprintf('��ʼ�ֲ����Ƚ���:%d / %d', i, L)
                        %LST��Ҫ���з����־
                        if activity_rules == 'lst1'
                            [original_local_start_time, original_local_end_time] = locals_lst(num_j, R(:, :, i), r(:, :, i), statistic_CD(:, num, i), LST(i, num, :), LFT(i, num, :), forestset, ad(1, i));
                        elseif activity_rules == 'slst'
                            [original_local_start_time, original_local_end_time] = locals_slst(num_j, R(:, :, i), r(:, :, i), statistic_CD(:, num, i), LST(i, num, :), LFT(i, num, :), forestset, ad(1, i));
                        elseif activity_rules == 'slft'
                            [original_local_start_time, original_local_end_time] = locals_slft(num_j, R(:, :, i), r(:, :, i), statistic_CD(:, num, i), LFT(i, num, :), forestset, ad(1, i));
                        end
                        
                        original_local_start_times(num, :, i) = original_local_start_time + 1;
                        original_local_end_times(num, :, i) = original_local_end_time + 1;
                    end
                    
                    realitic_start_times = original_local_start_times - 1;
                    realitic_end_times = original_local_end_times - 1;
                    original_total_duration = max(realitic_end_times, [], 2); %��ʼ�ֲ����ȸ���Ŀ�������ֵ��
                    
                    %% CAȫ��Э�����߽���
                    L1 = find_L1(GlobalSourceRequest); %�ҵ�������Ҫȫ����Դ�Ļ
                    % ������ı���
                    iter_Lgs = Lgs;
                    iter_skill_num = original_skill_num; %ȫ����Դ������
                    temp_R = R; % �ֲ���Դ������
                    iter_d = statistic_CD(:, num, :); % ���ڱ仯����
                    iter_d2 = d; %save ÿ�η�����Ļʵ�ʹ��ں�δ����Ļ���������ڼ���
                    iter_local_start_times = squeeze(original_local_start_times(num, :, :))';
                    iter_local_end_times = squeeze(original_local_end_times(num, :, :))';
                    % ѭ��
                    allocated_set = {}; chosen_results = []; iter_RN = zeros(1, people); %��Դ-ʱ�����
                    
                    for time = 1:T
                        sprintf('��ǰѭ��:%d-%d-%d', cycle, seq + 1, time)
                        L2 = find_L2(L1, iter_local_start_times, time, allocated_set); % ��ǰʱ����Ҫȫ����Դ�ĻL2
                        
                        if ~isempty(L2)
                            %����ĿPAΪ��λ �ȸ���PA����ȫ���У�������Ŀ��Ų�ͬ
                            %ȷ������Ŀ���֮���ٶԲ�ͬ��Ŀ����µĻ��������ʽ˳��ȷ��
                            %����ͬһ����ĿPA�г���2���ͬʱ��ʼ�������ȷ����˭�ȿ�ʼ��
                            [LP, yb, box_pro] = find_LP(L2); %yb---�ҵ���ǰ��ͻʱ�̵���Ŀ����������Ŀ�ĳ�ͻ���������
                            %LP��ͬ��Ŀ���治ͬ��,yb��Ŀ��ţ�box_pro���Ӧ����Ŀ���
                            %�Ѹ�����Ŀ�Ļ����дһ��Ԫ����ϣ�Ȼ����6�־���˳��ʱ������ÿ�εľ���˳��ͬ����Ӧ�ϲ���Ӧ���
                            %% variable neighborhood descent(VND)
                            [satisfy_pro, iter_not] = find_L5_2(LP, GlobalSourceRequest, skill_cate, skill_count, iter_skill_num);
                            %% 1.L4�ռ���%L4�ǿռ���˵����ǰ����Ŀ���ϼ��ܿ�����
                            % iter_not
                            if ~isempty(iter_not)
                                [iter_local_start_times, iter_local_end_times] = find_act_not(iter_not, time, r, temp_R, iter_d, forestset, iter_local_start_times, iter_local_end_times);
                                chosen_results{time} = [];
                                [allocated_set, iter_Lgs, iter_skill_num] = Release(time, chosen_results, allocated_set, Lgs, iter_Lgs, iter_skill_num);
                            end
                            
                            %% 2. L4���ǿռ������ܻ����count_1=0�������е���Ŀ����������һ�ּ��ܿ�����
                            % satisfy_pro ��Ŀ��
                            allocate_pro = size(satisfy_pro, 1); %�жϿ��Է������Ŀ������5����Ŀ��ֻ��3�����Ա����䣬���������±任������
                            order_rand = randperm(allocate_pro); %�������21543
                            s1 = satisfy_pro(order_rand, :);
                            S1 = conbine_cell_to_row(s1);
                            [S_obj, results, Real_Available_skill_cates, temp_Lgs_s, temp_d2, later_start_times, later_end_times, temp_RN_s, later_local_duration, finally_total_duration] = find_obj(allocate_source_rules, S1, time, ad, delay, CPM(num, :), r, temp_R, forestset, skill_cate, GlobalSourceRequest, iter_Lgs, iter_skill_num, iter_d, iter_d2, iter_local_start_times, iter_local_end_times, iter_RN);
                            %S_obj ��ʼ��Ŀ˳���Ӧ�ĳ�ʼ����main�й�
                            i_pro = 1; %��һ��λ�õ���Ŀ
                            count = 0; %���ڼ�¼ѭ�����ο��Եó������ʼ��Ľ�
                            
                            if size(satisfy_pro, 1) == 1
                                all_total_delay = S_obj;
                            else
                                %% ����˳��
                                while i_pro < allocate_pro
                                    count = count + 1;
                                    a = order_rand(1, i_pro); %a = 1
                                    order_rand(1, i_pro) = order_rand(1, i_pro + 1); %b = 2
                                    order_rand(1, i_pro + 1) = a; %iter_S1 = [2 1 3],Note:���ҵ��Ľⶼ��L4/L5��ռ���Ľ⣬�µ�˳��
                                    s1 = satisfy_pro(order_rand, :);
                                    S1 = conbine_cell_to_row(s1); %�ϲ�Ϊһ��
                                    % ��� S_cur
                                    [S_cur, results, Real_Available_skill_cates, temp_Lgs_s, temp_d2, later_start_times, later_end_times, temp_RN_s, later_local_duration, finally_total_duration] = find_obj(allocate_source_rules, S1, time, ad, delay, CPM(num, :), r, temp_R, forestset, skill_cate, GlobalSourceRequest, iter_Lgs, iter_skill_num, iter_d, iter_d2, iter_local_start_times, iter_local_end_times, iter_RN);
                                    
                                    if S_cur >= S_obj %���½�ȳ�ʼ����������һ����������
                                        i_pro = i_pro + 1;
                                    else %���ǰ������ʼ�⣬��Ϊ�µĳ�ʼ��
                                        i_pro = 1; %������λ��Ϊ1����������
                                        S_obj = S_cur; %����obj
                                        %���浱ǰʱ�̷���Ļ������Ļ����Щ��δ����Ļ����Щ
                                    end
                                    
                                end
                                
                                all_total_delay = S_cur; %break��������
                            end
                            
                            % printf('', count)
                            %% ������һ����Ŀ��ֵ������ѡһ����������Ǻ����ĸ��£���Ҫ������ѡ�����Ŀ˳���������Ϊ������Ŀ1�����ˣ�������δ���¹���
                            %����Ŀ1��1-2��1-3�������ˣ�����2-3û�У����Լ��ܿ�����Ϊ1��
                            %���Ժ����ĸ�����Ҫ��Ӧ����
                            pos = 1;
                            iter_Lgs = temp_Lgs_s(skill_count * (pos - 1) + 1:skill_count * pos, :); %ѡ�������˳�����Դ����ֵ����
                            iter_skill_num = Real_Available_skill_cates(pos, :); %ѡ�������˳��ļ��ܿ�����
                            % iter_R                  = temp_Rs(:,:,:,pos);
                            % % �ֲ���Դ
                            iter_d = temp_d2; % ѡ�������˳���ʵ�ʹ���
                            iter_local_start_times = later_start_times(L * (pos - 1) + 1:L * pos, :); %ѡ�������˳��Ŀ�ʼʱ��
                            iter_local_end_times = later_end_times(L * (pos - 1) + 1:L * pos, :); %ѡ�������˳��Ľ���ʱ��
                            iter_RN = temp_RN_s(pos, :);
                            Best_duration = later_local_duration(pos, :); % ��õĹ���
                            finally_duration = max(Best_duration);
                            %  if ~isempty(results)
                            chosen_result = results{pos};
                            chosen_results{time} = chosen_result;
                        end
                        
                        %%  �ж����õ�ȫ����Դ��һʱ���Ƿ���ͷ�
                        [allocated_set, iter_Lgs, iter_skill_num] = Release(time, chosen_results, allocated_set, Lgs, iter_Lgs, iter_skill_num);
                        
                        if length(allocated_set) == length(L1) && max(max(iter_local_start_times)) <= time
                            break
                        end
                        
                    end
                    
                    Real_EveryTime_GS_n = [];
                    %% save
                    [average_delay_duration, all_total_delay] = find_average_delay(CPM, finally_total_duration, ad, L, delay); %���ƽ����Ŀ���ڡ������ڳɱ�
                    result_save = {people, original_skill_num, UF, CPM, original_total_duration, finally_total_duration, average_delay_duration, finally_duration, all_total_delay, ad, delay, time};
                    TTC = [TTC; all_total_delay];
                    seq = seq + 1;
                    result_saves_file(seq, :) = result_save; %����ÿ���������ж�ε���Ϣ
                end
                
            end
            
        end
        
        toc
        % result_save       [1, 12] result_save_sims  [50,12] TTC
        % [50, 1]
        save_ETTC = roundn ((sum(TTC)) / (file * cycle * Simul_Num), -2); %50�����еľ�ֵ
        summary_info = cell(1, 12);
        summary_info{1} = num2str(save_ETTC);
        summary_info{2} = toc / (Simul_Num * cycles * 5);
        summary_info{3} = num2str(L);
        summary_info{4} = num2str(num_j - 2);
        summary_info{5} = normalization;
        summary_info{6} = activity_rules;
        summary_info{7} = allocate_source_rules;
        
        result_saves_file = [result_saves_file; summary_info];
        save(strcat(folder, '\', num2str(L), '_', num2str(num_j - 2), '_', normalization, '_', activity_rules, '_', allocate_source_rules, '.mat'), 'result_saves_file');
        sprintf('�����ļ�')
        
        % summary_info_save
        summary_info_save(3 * (outer_i - 1) + outer_j, :) = summary_info;
    end
    
end

end