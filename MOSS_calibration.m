function varargout = MOSS_calibration(varargin)
% MOSS_CALIBRATION MATLAB code for MOSS_calibration.fig
%      MOSS_CALIBRATION, by itself, creates a new MOSS_CALIBRATION or raises the existing
%      singleton*.
%
%      H = MOSS_CALIBRATION returns the handle to a new MOSS_CALIBRATION or the handle to
%      the existing singleton*.
%
%      MOSS_CALIBRATION('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MOSS_CALIBRATION.M with the given input arguments.
%
%      MOSS_CALIBRATION('Property','Value',...) creates a new MOSS_CALIBRATION or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before MOSS_calibration_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to MOSS_calibration_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help MOSS_calibration

% Last Modified by GUIDE v2.5 19-Dec-2016 13:08:45

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @MOSS_calibration_OpeningFcn, ...
                   'gui_OutputFcn',  @MOSS_calibration_OutputFcn, ...
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


% --- Executes just before MOSS_calibration is made visible.
function MOSS_calibration_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to MOSS_calibration (see VARARGIN)

% Setting up video feed
axes(handles.axes_camera_cal); 
% camera_obj = videoinput('pointgrey',1,'F7_Mono8_1928x1448_Mode0');
camera_obj =videoinput('pointgrey', 1, 'F7_Mono16_2048x1536_Mode0');
camera_src = getselectedsource(camera_obj);
camera_src_info = propinfo(camera_src);

handles.vidobj = camera_obj; 
handles.camera_src = camera_src; 
handles.stopped = 0; %set to false

% Initializing camera properties
handles.camera_gain_max = camera_src_info.Gain.ConstraintValue(2);

% handles.camera_exposure_min = camera_src_info.Exposure.ConstraintValue(1); 
% handles.camera_exposure_max = camera_src_info.Exposure.ConstraintValue(2); 
% handles.camera_exposure_range = handles.camera_exposure_max - handles.camera_exposure_min;
% editted by ZRAO

handles.camera_shutter_min = camera_src_info.Shutter.ConstraintValue(1); 
handles.camera_shutter_max = camera_src_info.Shutter.ConstraintValue(2); 
handles.camera_shutter_range = handles.camera_shutter_max - handles.camera_shutter_min; 
% Initial values
try load('mos_session_data.mat')
    handles.camera_src.Gain=save_gain;
    handles.camera_src.Shutter=save_shutter;
catch
handles.camera_src.Gain = (handles.camera_gain_max)/2; 
handles.camera_src.Shutter = (handles.camera_shutter_max + handles.camera_shutter_min)/2;

end
handles.camera_src.Brightness = 0; 
handles.camera_src.GainMode = 'Manual';
% handles.camera_src.ExposureMode = 'Manual';
% handles.camera_src.Exposure = (handles.camera_exposure_max + handles.camera_exposure_min)/2; 
% editted by ZRAO
handles.camera_src.ShutterMode = 'Manual';
handles.camera_src.FrameRateMode = 'Manual';
handles.camera_src.FrameRate = 60; 

% Updating slider 
set(handles.slider_gain, 'value', handles.camera_src.Gain/handles.camera_gain_max); 
set(handles.slider_shutter, 'value', (handles.camera_src.Shutter-handles.camera_shutter_min)/handles.camera_shutter_range);

% set(handles.slider_exposure, 'value', (handles.camera_src.Exposure-handles.camera_exposure_min)/handles.camera_exposure_range);
% editted by ZRAO

% Displaying camera feed
camera_obj.ReturnedColorSpace = 'grayscale';
vidRes = camera_obj.VideoResolution; 

imageRes = fliplr(vidRes); 
hImage = imshow(zeros(imageRes)); 
axis image; 
preview(camera_obj, hImage); 

x = [1,imageRes(2)];
y = [1,imageRes(1)]; 

% Setting up scanning line 
h1 = imline(gca, [1,1;x(2),y(2)]);
fcn1 = makeConstrainToRectFcn('imline',[1,x(2)],[1,y(2)]); 
setPositionConstraintFcn(h1,fcn1); 

setappdata(hImage,'UpdatePreviewWindowFcn',@update_calibration);
setappdata(hImage,'HandleToImline',h1);
setappdata(hImage,'HandleToAxes',handles); 

% Choose default command line output for MOSS_calibration
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes MOSS_calibration wait for user response (see UIRESUME)
% uiwait(handles.figure_calibrate_moss);


% --- Outputs from this function are returned to the command line.
function varargout = MOSS_calibration_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on slider movement.
function slider_gain_Callback(hObject, eventdata, handles)
% hObject    handle to slider_gain (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
    scale = get(handles.slider_gain,'Value');
    handles.camera_src.Gain = scale*handles.camera_gain_max; 

% --- Executes during object creation, after setting all properties.
function slider_gain_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider_gain (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on button press in pushbutton_exit_calibrate.
function pushbutton_exit_calibrate_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_exit_calibrate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    
    handles.stopped = 1; 
    handles.stopped;
    stoppreview(handles.vidobj);
    save_gain=handles.slider_gain.Value*handles.camera_gain_max;
    save_threshold=handles.slider_exposure.Value*255;
    save_shutter=handles.slider_shutter.Value*handles.camera_shutter_range+handles.camera_shutter_min;
    
%     scale*handles.camera_shutter_range + handles.camera_shutter_min; 
    
    % save camera settings to file. edited by mchon
    save('mos_session_data.mat','save_gain','save_threshold','save_shutter','-append')
%     global camera_gain;
%     global camera_exposure;
% edited by ZRAO

%     global camera_shutter; 
    camera_gain = handles.camera_src.Gain;
%     camera_exposure = handles.camera_src.Exposure;
    camera_shutter = handles.camera_src.Shutter;
    close(handles.figure_calibrate_moss);


% --- Executes when user attempts to close figure_calibrate_moss.
function figure_calibrate_moss_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure_calibrate_moss (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
delete(hObject);


% --- Executes on slider movement.
function slider_exposure_Callback(hObject, eventdata, handles)
% hObject    handle to slider_exposure (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider

% %     scale = get(handles.slider_exposure,'Value');
% %     handles.camera_src.Exposure = scale*handles.camera_exposure_range + handles.camera_exposure_min; 
    scale = get(handles.slider_exposure,'Value'); 
    global threshold;
    threshold = scale*255;
    
    
% --- Executes during object creation, after setting all properties.
function slider_exposure_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider_exposure (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

% --- Executes on slider movement.
function slider_shutter_Callback(hObject, eventdata, handles)
% hObject    handle to slider_shutter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
    scale = get(handles.slider_shutter,'Value');
    handles.camera_src.Shutter = scale*handles.camera_shutter_range + handles.camera_shutter_min; 

% --- Executes during object creation, after setting all properties.
function slider_shutter_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider_shutter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

