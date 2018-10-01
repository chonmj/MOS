function update_calibration(obj,event,hImage)
% This callback function updates the displayed frame and the histogram.

% Copyright 2007 The MathWorks, Inc.

% Display the current image frame. 
%% added by ZR 
    global threshold;
    im = event.Data;
    imMask = im > threshold;
%     imMaskSize = bwareaopen(imMask);
    masked = im .* uint8(imMask);

     set(hImage, 'CData', masked); % Display the current image frame.

% im = event.Data;
% imMaskSize = bwareaopen(im,100);
% masked = im .* uint8(imMaskSize);
% 
%      set(hImage, 'CData', masked); % Display the current image frame.

%%
% set(hImage, 'CData', event.Data);

% Select the second subplot on the figure for the histogram.
h = getappdata(hImage,'HandleToImline');
handles = getappdata(hImage,'HandleToAxes');
    axes(handles.axes_intensity_cal);

    % Calculate intensity over
    pos = getPosition(h);
%    improfile(event.Data, floor(pos(:,1)'), floor(pos(:,2)'));
    improfile(masked, floor(pos(:,1)'), floor(pos(:,2)'));
    
    axis([0,((pos(1,1)-pos(2,1))^2 + (pos(1,2)-pos(2,2))^2)^0.5,0,255]);

    %Refresh display
drawnow; 
%    pause(.1);
