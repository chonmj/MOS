function dist = avg_dist(x_list,y_list)
    num = numel(x_list);
    total_dist = 0;
    for i = 1 : num-1
        points = [x_list(i),y_list(i); x_list(i+1),y_list(i+1)];
        total_dist = total_dist + pdist(points);
    end
    dist = total_dist/(num-1);
end