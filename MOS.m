function varargout = MOS(varargin)
% MOS MATLAB code for MOS.fig
%      MOS, by itself, creates a new MOS or raises the existing
%      singleton*.
%
%      H = MOS returns the handle to a new MOS or the handle to
%      the existing singleton*.
%
%      MOS('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MOS.M with the given input arguments.
%
%      MOS('Property','Value',...) creates a new MOS or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before MOS_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to MOS_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help MOS

% Last Modified by GUIDE v2.5 19-Dec-2016 12:50:10

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @MOS_OpeningFcn, ...
                   'gui_OutputFcn',  @MOS_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before MOS is made visible.
function MOS_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to MOS (see VARARGIN)

% Choose default command line output for MOS
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UI Setup 
handles.tabGroup = uitabgroup('Parent',handles.uipanel_parent,'TabLocation','top'); 
handles.tab_camera = uitab('Parent', handles.tabGroup, 'Title', 'Camera Feed');
handles.tab_graphs = uitab('Parent', handles.tabGroup, 'Title', 'Distance and Intensity');
set(handles.uipanel_feed,'Parent',handles.tab_camera);
set(handles.uipanel_graph,'Parent',handles.tab_graphs);
set(handles.uipanel_feed,'position',get(handles.uipanel_parent,'position'));
set(handles.uipanel_graph,'position',get(handles.uipanel_parent,'position'));

%% legal disclaimer popup
% load disclaimer text file
try 
    disclaimer=importdata('Disclaimer.txt');
    h=msgbox(disclaimer,'Legal Information');
    waitfor(h);
catch
    % display this hardcoded message if disclaimer file is not found.
    h = msgbox({'Copyright 2016, Brown University, Providence, RI.',
'All Rights Reserved',
'',
'Permission to use this software must be obtained from Brown University. It may not be distributed or incorporated into a commercial product. The name of Brown University cannot be used in advertising or publicity pertaining to the software without specific, written prior permission.'  
'',
'BROWN UNIVERSITY DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE, INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR ANY PARTICULAR PURPOSE.  IN NO EVENT SHALL BROWN UNIVERSITY BE LIABLE FOR ANY SPECIAL, INDIRECT OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.'},...
'Legal Information'); 
waitfor(h);
end

%% Camera set-up
load('camerainfo.mat');
camera_obj =videoinput('pointgrey', 1, 'F7_Mono12_2048x1536_Mode0');
camera_src = getselectedsource(camera_obj);
camera_src_info = propinfo(camera_src); 

handles.camera_obj = camera_obj; 
handles.camera_src = camera_src; 
handles.camera_src_info = camera_src_info; 

% Loading settings (or default) 
global camera_gain;
% global camera_exposure; 
global threshold; 
global camera_shutter; 
 
if exist('mos_session_data.mat')==2 
     load('mos_session_data.mat')
     handles.save_directory = directory; 
     handles.save_filename = filename; 
     camera_gain = save_gain; 
     threshold = save_threshold;
%      camera_exposure = save_exposure; 
     camera_shutter = save_shutter; 
else
    defaultfolder = userpath; 
%     defaultfolder = defaultfolder(1:end-1);
    handles.save_directory = defaultfolder;
    handles.save_filename = 'data_1'; 
    camera_gain = camera_src_info.Gain.ConstraintValue(2)/2; 
%     camera_exposure = (camera_src_info.Exposure.ConstraintValue(2)+camera_src_info.Exposure.ConstraintValue(1))/2;
    threshold = 5;
    camera_shutter = (camera_src_info.Shutter.ConstraintValue(2)+camera_src_info.Shutter.ConstraintValue(1))/2;
end

handles.camera_src.Brightness = 0; 
handles.camera_src.FrameRateMode = 'Manual';
% handles.camera_src.FrameRate = 60; 
handles.camera_src.ShutterMode = 'Manual';
handles.camera_src.GainMode = 'Manual';
% handles.camera_src.ExposureMode = 'Manual';
handles.camera_src.Gain = camera_gain; 
% handles.camera_src.Exposure = camera_exposure; 
handles.camera_src.Shutter = camera_shutter;  
handles.stop_pressed = false;
handles.previewing = false;

% Setting up video feed
vidRes = handles.camera_obj.VideoResolution; 
imageRes = fliplr(vidRes); 
handles.max_box_size = min(imageRes)/4; 
x = [1,imageRes(2)]; 
y = [1,imageRes(1)];
handles.max_x = x(2);
handles.max_y = y(2); 

% Update handles
guidata(hObject, handles);

% --- Outputs from this function are returned to the command line.
function varargout = MOS_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes when user attempts to close figure_mos.
function figure_mos_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure_mos (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%writing the session data file 
directory = handles.save_directory; 
filename = handles.save_filename; 
global camera_gain;
% global camera_exposure; 
global threshold 
global camera_shutter;
save_gain = camera_gain; 
% save_exposure = camera_exposure;
save_threshold = threshold; 
save_shutter = camera_shutter; 
save mos_session_data.mat directory filename save_gain save_threshold save_shutter;

%Close the figure
delete(hObject);


% --------------------------------------------------------------------
function menu_file_Callback(hObject, eventdata, handles)
% hObject    handle to menu_file (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function menu_program_Callback(hObject, eventdata, handles)
% hObject    handle to menu_program (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function menu_about_Callback(hObject, eventdata, handles)
% hObject    handle to menu_about (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% --------------------------------------------------------------------
function menu_docs_Callback(hObject, eventdata, handles)
% hObject    handle to menu_docs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function menu_boxes_Callback(hObject, eventdata, handles)
% hObject    handle to menu_boxes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    prompt = {'Enter number of boxes (2 to 8):'};
    dlg_title = 'Input';
    num_lines = 1;
    defaultans = {'2'};
    answer = inputdlg(prompt,dlg_title,num_lines,defaultans);
    if isempty(answer) return; end
    num_boxes = str2num(answer{1});
    while (isnan(num_boxes) | num_boxes<2 | num_boxes > 8 | rem(num_boxes,1) ~= 0)
        prompt = {sprintf('Enter number of boxes. \n(Must be integer between 2 and 8):')};
        answer = inputdlg(prompt,dlg_title,num_lines,defaultans);
        num_boxes = str2num(answer{1});
    end

    handles.num_boxes = num_boxes;
    
    global camera_shutter;
%     global camera_exposure;
    global threshold 
    global camera_gain; 
    %Refresh mos settings
    handles.camera_src.Brightness = 0; 
    handles.camera_src.FrameRateMode = 'Manual';
    handles.camera_src.FrameRate = 60; 
    handles.camera_src.ShutterMode = 'Manual';
    handles.camera_src.GainMode = 'Manual';
%     handles.camera_src.ExposureMode = 'Manual';

    handles.camera_src.Shutter = camera_shutter;  
%     handles.camera_src.Exposure = camera_exposure; 
%     handles.camera_src.threshold= threshold; 
    handles.camera_src.Gain = camera_gain; 


    %get a single frame to display
    triggerconfig(handles.camera_obj,'manual');
    start(handles.camera_obj);
    trigger(handles.camera_obj);
    a = getdata(handles.camera_obj,1);
    stop(handles.camera_obj);
    
    %restore to original state
    triggerconfig(handles.camera_obj,'immediate');
    axes(handles.axes_camera);
    
    %display single frame
    imshow(a);

    %find spots - seems to not work, need to refine
    [xcoord,ycoord,num_detected] = my_findlaser(a);
   %placeholder code
    xcoord = zeros(handles.num_boxes); 
    ycoord = zeros(handles.num_boxes);
    
    %default box size
    initial_box_size = 100;
    half_size = initial_box_size/2;
    set(handles.slider_box_size, 'value', initial_box_size/handles.max_box_size);
    fcn1 = makeConstrainToRectFcn('imrect',[1,handles.max_x],[1,handles.max_y]);
    xcoord = xcoord + initial_box_size; 
    ycoord = ycoord + initial_box_size; 
    
    % at some point reincorporate check between number specified and number
    % present
    rectangle = cell(handles.num_boxes,1);
    for j = 1:handles.num_boxes
          h = imrect(gca,[round(xcoord(j)-half_size),round(ycoord(j)-half_size),initial_box_size,initial_box_size]);%[xmin ymin width height].
          setPositionConstraintFcn(h,fcn1);
          h.setFixedAspectRatioMode(true);
          color = seven_colors(j);
          setColor(h,color);
          rectangle{j} = h; 
    end
    handles.rectangle = rectangle;
    handles.fcn1 = fcn1;
    guidata(hObject, handles);
    
    %enable start
    set(handles.slider_box_size,'Enable','on');
    % set(handles.uipushtool_select_boxes,'Enable','off');
    set(handles.menu_boxes,'Enable','off');
    %set(handles.uipushtool_start,'Enable','on');
    set(handles.menu_start,'Enable','on');

% --------------------------------------------------------------------
function menu_start_Callback(hObject, eventdata, handles)
% hObject    handle to menu_start (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    try 
        handles.save_directory; 
    catch ME 
        warndlg('Invalid saving directory. Please choose directory again.','Error');
        return;
    end

    prompt = {'Run Time (in seconds):','Delay Time (in seconds):','Subfolder:'};
    dlg_title = 'Input';
    num_lines = 1;
    defaultans = {'','',update_filename(handles.save_filename)};
    answer = inputdlg(prompt,dlg_title,num_lines,defaultans);
    if isempty(answer) return; end
    while (isempty(answer{3}))
        answer = inputdlg(prompt,dlg_title,num_lines,defaultans);
    end
    handles.run_time = str2double(answer{1});
    handles.delay_time = str2double(answer{2});
    handles.save_filename = answer{3};
    
    %make a subfolder containing all the surface images 
    mkdir(handles.save_directory,handles.save_filename);
    
    %save complete filename and path for the update function
    handles.datafile = strcat(handles.save_directory,'\',handles.save_filename,'\','Data.txt');
    handles.datacsv = strcat(handles.save_directory,'\',handles.save_filename,'\','Data.csv');
    
    %write titles to file
     datafileID = fopen(handles.datafile,'w');
     fprintf(datafileID, 'time, avg distance\n[1...n] x_centroid, y_centroid, integrated intensity, intensity_centroid\n');
     fclose(datafileID);
    
     csvID = fopen(handles.datacsv,'w');
     fprintf(csvID, 'time [s], avg_distance [px]\n');
     fclose(csvID);
        
    %preview laser 
    hold(handles.axes_camera,'on');
    axes(handles.axes_camera);
    handles.camera_obj.ReturnedColorSpace = 'grayscale';
    vidRes = handles.camera_obj.VideoResolution;
    imageRes = fliplr(vidRes);
    hImage = imshow(zeros(imageRes));
    axis image;
    preview(handles.camera_obj, hImage);
    handles.previewing = true;
    handles.hImage = hImage;

    %set app data for distance(d[]), imrects and intensities
    d = [];
    intensity = cell(handles.num_boxes,1);
    for j = 1 : handles.num_boxes
        intensity{j} = [];
    end
    setappdata(hImage,'PrevIntensity',intensity);
    time = [];
    setappdata(hImage,'PrevTime',time);
    
      %rectangle management
    sort_along_x = zeros(1,handles.num_boxes);
    for j = 1 : handles.num_boxes 
        pos = handles.rectangle{j}.getPosition();
        sort_along_x(j) = pos(1);
    end
    [~,index] = sort(sort_along_x);
    handles.rectangle = handles.rectangle(index);

    for i = 1 : handles.num_boxes
        temp_pos = handles.rectangle{i}.getPosition();
        delete(handles.rectangle{i});
        color = seven_colors(i);
        handles.rectangle{i} = rectangle('Position',temp_pos,'EdgeColor',color);
    end
      guidata(hObject,handles);
      
    tic;
    setappdata(hImage,'HandleToImrect',handles.rectangle);
    setappdata(hImage,'UpdatePreviewWindowFcn',@MOS_update);
    setappdata(hImage,'PrevDistance',d);
    setappdata(hImage,'HandleToAxes',handles);

    run_time_num = str2double(handles.run_time);
    if ~isnan(handles.run_time) && (handles.run_time > 0) 
        pause(handles.run_time);
        uipushtool_stop_ClickedCallback(handles.uipushtool_stop, eventdata, handles)        
    else 
        handles.run_time = [];
    end

    %enable stop; disable start/box size
    %set(handles.uipushtool_start,'Enable','off');
    set(handles.menu_start,'Enable','off');
    set(handles.slider_box_size,'Enable','off');
    %set(handles.uipushtool_stop,'Enable','on');
    set(handles.menu_stop,'Enable','on');

% --------------------------------------------------------------------
function menu_stop_Callback(hObject, eventdata, handles)
% hObject    handle to menu_stop (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    stoppreview(handles.camera_obj);
    handles.stop_pressed = true;
    handles.previewing = false;
    
    %blank the run time string in the ui
    %set(handles.text_current_run_time, 'String', '');
    
    rectPos = cell(handles.num_boxes,1);
    for j = 1:handles.num_boxes
          rectPos{j} = handles.rectangle{j}.Position; 
          %delete(handles.rectangle{j});
    end
    %save new rectangle data
    hold(handles.axes_camera,'off');
    axes(handles.axes_camera);
%     rectangle = cell(handles.num_boxes,1);
%     for j = 1:handles.num_boxes
%           h = imrect(gca,[round(rectPos{j}(1)),round(rectPos{j}(2)),round(rectPos{j}(3)),round(rectPos{j}(4))]);%[xmin ymin width height].
%           setPositionConstraintFcn(h,handles.fcn1);
%           h.setFixedAspectRatioMode(true);
%           color = seven_colors(j);
%           setColor(h,color);
%           rectangle{j} = h; 
%     end
    
    %handles.rectangle = rectangle; 
    
    %enable select boxes
    %set(handles.uipushtool_stop,'Enable','off');
    set(handles.menu_stop,'Enable','off');
    %set(handles.uipushtool_select_boxes,'Enable','on');
    set(handles.menu_boxes,'Enable','on');
    
    guidata(hObject, handles);
    
% --------------------------------------------------------------------
function menu_save_Callback(hObject, eventdata, handles)
% hObject    handle to menu_save (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    save_directory = uigetdir();
    handles.save_directory = save_directory;
    guidata(hObject,handles);

% --- Executes on slider movement.
function slider_box_size_Callback(hObject, eventdata, handles)
% hObject    handle to slider_box_size (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
    scale = get(handles.slider_box_size,'Value');
    new_size = scale*handles.max_box_size;
    temp = size(handles.rectangle);
    num_boxes = temp(1);
    for i = 1 : num_boxes
        pos = handles.rectangle{i}.getPosition();
        handles.rectangle{i}.setConstrainedPosition([pos(1), pos(2), new_size, new_size]);
    end
    guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function slider_box_size_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider_box_size (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --------------------------------------------------------------------
function menu_calibrate_Callback(hObject, eventdata, handles)
% hObject    handle to menu_calibrate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    MOSS_calibration;

% --------------------------------------------------------------------
function menu_exit_Callback(hObject, eventdata, handles)
% hObject    handle to menu_exit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    close all;
