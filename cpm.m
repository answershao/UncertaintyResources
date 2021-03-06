function [CPM, cpm_start_time, cpm_end_time] = cpm(d, E)
%m为活动数
%L为项目数
%R为局部资源种类数。
%紧后活动集succeedset
%紧前活动集foreset
m = length(d);
L = 1;  % 只计算一个项目的关键路径
foreset = find_forestset(E,m);
cpm_start_time=zeros(L,m);
cpm_end_time=zeros(L,m);%初始化开始时间与结束时间
%求CPM工期
for i=2:m
    predecessors=foreset(i,:);  % activity的紧前活动 [1 0 0 0 0]
    max_endtime = 0;
    for x = 1:length(predecessors)  % 寻找紧前活动中最大的endtime
        if (predecessors(x) ~= 0 && cpm_end_time(predecessors(x))>max_endtime)
            max_endtime = cpm_end_time(predecessors(x));
        end
    end
    cpm_start_time(i)=max_endtime;  %紧前活动的最大完工时间
    cpm_end_time(i)=cpm_start_time(i)+d(i);
end  
CPM = max(cpm_end_time);
end
