function MOS_update(obj,event,hImage)
% This callback function updates the displayed frame and the histogram.

% Copyright 2007 The MathWorks, Inc.

% Display the current image frame. 
    global threshold;
    im = event.Data;
    imMask = im > threshold;
%     imMaskSize = bwareaopen(imMask);
    masked = im .* uint8(imMask);

     set(hImage, 'CData', masked); % Display the current image frame.

% set(hImage, 'CData', event.Data);


d = getappdata(hImage,'PrevDistance');
intensity = getappdata(hImage,'PrevIntensity');
time = getappdata(hImage,'PrevTime');
rectangle = getappdata(hImage,'HandleToImrect');

handles = getappdata(hImage,'HandleToAxes');

%updating time checks
time = [time;toc];
setappdata(hImage,'PrevTime',time);
set(handles.text_time_display, 'String', num2str(toc));

temp_rect = rectangle{1};
temp_pos = temp_rect.Position;
box_size = temp_pos(3);
num_boxes = fix(handles.num_boxes);
% frame = event.Data;
frame = masked;

x = ones(num_boxes,1);
y = ones(num_boxes,1);
posBounds = zeros(num_boxes,1);

for i = 1 : num_boxes
    pos = round(rectangle{i}.Position);

    box_size = round(box_size);
    half_box_size = round(box_size/2);
    patch = frame(pos(2):pos(2)+box_size, pos(1):pos(1)+box_size);
    peak = max(patch(:));
    [peak_y, peak_x] = find(patch == peak);
    peak_y = round(mean(peak_y)) + pos(2);
    peak_x = round(mean(peak_x)) + pos(1);    
    y_low = constrain(peak_y-half_box_size,handles.max_y);
    y_high = constrain(peak_y+half_box_size,handles.max_y);
    x_low = constrain(peak_x-half_box_size,handles.max_x);
    x_high = constrain(peak_x+half_box_size,handles.max_x);
    new_patch = frame(y_low:y_high, x_low:x_high);
    
    %[a,b] = find_centroid(new_patch);
    [x_cen_1,y_cen_1] = find_centroid(new_patch);
    x_cen_1 = x_cen_1 + peak_x - half_box_size;
    y_cen_1 = y_cen_1 + peak_y - half_box_size;
    new_y_low = constrain(y_cen_1-half_box_size,handles.max_y);
    new_y_high = constrain(y_cen_1+half_box_size,handles.max_y);
    new_x_low = constrain(x_cen_1-half_box_size,handles.max_x);
    new_x_high = constrain(x_cen_1+half_box_size,handles.max_x);
    new_patch_2 = frame(fix(new_y_low):fix(new_y_high), fix(new_x_low):fix(new_x_high));
    
    [a,b] = find_centroid(new_patch_2);
    
    x(i) = x_cen_1-half_box_size+a;
    y(i) = y_cen_1-half_box_size+b;
    
%     %Bounds on rectangles -> centroids too close to edge for accurate
%     %measurement     
%     if (x(i) < half_box_size) 
%         x(i)= half_box_size + 1;       
%         posBounds(i) = posBounds(i) + 1;
%     elseif (x(i) > handles.max_x - half_box_size) 
%         x(i) = handles.max_x - half_box_size - 1;
%         posBounds(i) = posBounds(i) + 1;
%     end 
%     
%     if (y(i) < half_box_size) 
%         y(i)= half_box_size + 1;
%         posBounds(i) = posBounds(i) + 2;
%     elseif (y(i) > handles.max_y - half_box_size) 
%         y(i) = handles.max_y - half_box_size - 1;
%         posBounds(i) = posBounds(i) + 2;
%     end 

    % Final posbound options are 0,1,2,3 
    % 0 -> no boundary issues
    % 1 -> x was adjusted 
    % 2 -> y was adjusted
    % 3 -> x and y were adjusted 
    
end

%change box positions in preview
axes(handles.axes_camera);  
for i = 1 : num_boxes
    rectangle{i}.Position= [x(i)-half_box_size, y(i)-half_box_size, box_size, box_size];    
end

% Select the second subplot on the figure for the distance
axes(handles.axes_distance);
d = [d avg_dist(x,y)];
setappdata(hImage,'PrevDistance',d);
%if strcmp(get(handles.uitoggletool_plot_live,'State'), 'on')
       plot(time,d,'r','linewidth',2);
       drawnow;  
%end

%pos, is a 1-by-4 array [xmin ymin width height].
%draw intensity
axes(handles.axes_intensity);
% frame = event.Data;
frame = masked;

for i = 1 : num_boxes
    pos = round(rectangle{i}.Position);
    area = frame(pos(2):pos(2)+pos(4), pos(1):pos(1)+pos(3)); 
    integrated_intensity = sum(sum(area));
    intensity{i} = [intensity{i} integrated_intensity];  
    color = seven_colors(i);
    %if strcmp(get(handles.uitoggletool_plot_live,'State'), 'on')
       plot(time,intensity{i},color,'linewidth',2);
       drawnow;  
    %end
    if i ~= num_boxes        
        hold on;
    else
        hold off;
    end        
end

setappdata(hImage,'PrevIntensity',intensity);  

%write to files
dlmwrite(handles.datafile, [time(end),d(end)],'-append','delimiter',' ','roffset',1,'precision','%.2f');
dlmwrite(handles.datacsv, [time(end),d(end), intensity{1}(end), intensity{2}(end)],'-append','delimiter',',','precision','%.2f');
    for i = 1 : num_boxes
        temp_intensity = intensity{i};
        if (posBounds(i) == 0) 
            dlmwrite(handles.datafile, [strjoin({'[',num2str(i),']'},''),' ',num2str(x(i)),' ',num2str(y(i)),' ',num2str(temp_intensity(end)),' ',num2str(frame(round(y(i)),round(x(i))))],'-append','delimiter',''); 
        elseif (posBounds(i) == 1)
            dlmwrite(handles.datafile, [strjoin({'[',num2str(i),']'},''),' ',num2str(x(i)),'*',' ',num2str(y(i)),' ',num2str(temp_intensity(end)),' ',num2str(frame(round(y(i)),round(x(i))))],'-append','delimiter',''); 
        elseif (posBounds(i) == 2)
            dlmwrite(handles.datafile, [strjoin({'[',num2str(i),']'},''),' ',num2str(x(i)),' ',num2str(y(i)),'*',' ',num2str(temp_intensity(end)),' ',num2str(frame(round(y(i)),round(x(i))))],'-append','delimiter',''); 
        elseif (posBounds(i) == 3)
            dlmwrite(handles.datafile, [strjoin({'[',num2str(i),']'},''),' ',num2str(x(i)),'*',' ',num2str(y(i)),'*',' ',num2str(temp_intensity(end)),' ',num2str(frame(round(y(i)),round(x(i))))],'-append','delimiter',''); 
        end
    end
pause(handles.delay_time);