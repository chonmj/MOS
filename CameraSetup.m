function varargout = CameraSetup(varargin)
% CAMERASETUP MATLAB code for CameraSetup.fig
%      CAMERASETUP, by itself, creates a new CAMERASETUP or raises the existing
%      singleton*.
%
%      H = CAMERASETUP returns the handle to a new CAMERASETUP or the handle to
%      the existing singleton*.
%
%      CAMERASETUP('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in CAMERASETUP.M with the given input arguments.
%
%      CAMERASETUP('Property','Value',...) creates a new CAMERASETUP or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before CameraSetup_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to CameraSetup_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help CameraSetup

% Last Modified by GUIDE v2.5 01-Oct-2018 17:46:57

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @CameraSetup_OpeningFcn, ...
                   'gui_OutputFcn',  @CameraSetup_OutputFcn, ...
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


% --- Executes just before CameraSetup is made visible.
function CameraSetup_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to CameraSetup (see VARARGIN)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to MOSS_calibration (see VARARGIN)

% get default device information
imaqout=imaqfind;
imaqhw=imaqhwinfo;
deviceID=imaqout.DeviceID;
cameraFormat=imaqout.VideoFormat;
adapterName=imaqhw.InstalledAdaptors{deviceID};

% Setting up video feed
axes(handles.axes_camera_cal); 
camera_obj =videoinput(adapterName, deviceID, cameraFormat);
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
handles.camera_src.Brightness = 0; 
handles.camera_src.GainMode = 'Manual';
handles.camera_src.Gain = (handles.camera_gain_max)/2; 
% handles.camera_src.ExposureMode = 'Manual';
% handles.camera_src.Exposure = (handles.camera_exposure_max + handles.camera_exposure_min)/2; 
% editted by ZRAO
handles.camera_src.ShutterMode = 'Manual';
handles.camera_src.Shutter = (handles.camera_shutter_max + handles.camera_shutter_min)/2;
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

% Choose default command line output for CameraSetup
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes CameraSetup wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = CameraSetup_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
