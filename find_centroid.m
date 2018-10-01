% The box approach
function [x, y] = find_centroid(frame)
    [y_size, x_size] = size(frame);
    x_total = 0;
    y_total = 0;
    weight_total = sum(sum(frame));

    for i = 1 : x_size
        x_total = x_total + i*sum(frame(:,i));
    end
    
    for j = 1 : y_size
        y_total = y_total + j*sum(frame(j,:));
    end
    x = x_total/weight_total;
    y = y_total/weight_total;
end