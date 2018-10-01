function new_name = update_filename(old_name)
    index_array = strfind(old_name, '_');
    
    if isempty(index_array)
        new_name = strcat(old_name,'_1');
    else
        size_array = size(index_array);
        num_occur = size_array(2);
        index = index_array(num_occur);
        end_index = length(old_name);
        old_number = str2num(old_name(index+1:end_index));
        if isempty(old_number)
            new_name = strcat(old_name,'_1');
        else
            new_name = strcat(old_name(1:index),num2str(old_number+1));
        end
    end         
end