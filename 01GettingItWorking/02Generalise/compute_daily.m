clearvars

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% first draft of generalised 2D+1 ST analysis
%Corwin Wright, c.wright@bath.ac.uk, 20200624
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% settings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%minimum phase change to be meaningful (as

%data to analyse
Settings.DayScale         = datenum(2008,1,127);
Settings.Granules         = [56];

% Settings.DayScale       = datenum(2010,10,16);
% Settings.Granules     = [186];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% processing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for iDay=1:1:numel(Settings.DayScale)

  Date = Settings.DayScale(iDay);
  
  for iGranule=1:1:numel(Settings.Granules)
    
    Gid = Settings.Granules(iGranule);
  
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% load data as a granule-pair
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %get granule
    Airs  = cat_struct(prep_airs_3d(Date,Gid,  'PreSmooth',[3,3,1]),   ...
                       prep_airs_3d(Date,Gid+1,'PreSmooth',[3,3,1]), ...
                       2,{'MetaData','Source','ret_z'});
                     
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% 3dst the granule-pair
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    ST3D = gwanalyse_airs_3d(Airs);

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% 2D+1 ST the granule pair
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   
    %do a *****full***** 2D ST at each height
    textprogressbar('STing levels ')
    for iLevel=1:1:numel(Airs.ret_z)
      ST = gwanalyse_airs_2d(Airs,Airs.ret_z(iLevel),'FullST',true,'c',[1,1].*.5);
      
      %store
      if iLevel == 1; STStore = ST.ST; freqs = ST.freqs;
      else            STStore = cat(5,STStore,ST.ST);
      end
      textprogressbar(iLevel./numel(Airs.ret_z).*100)
    end
    clear iLevel ST
    textprogressbar('!')
    
    %convert to complex cospectra
    CC = STStore;
    textprogressbar('CCing levels ')
    for iLevel=1:1:numel(Airs.ret_z)-2
      textprogressbar(iLevel./(numel(Airs.ret_z)-1).*100)
      CC(:,:,:,:,iLevel) = CC(:,:,:,:,iLevel) .* conj(CC(:,:,:,:,iLevel+2));
    end; clear iLevel
    textprogressbar('!')
    
    %remove extraneous level, and produce new height scale
    CC   = CC(:,:,:,:,1:end-1); 
    NewZ = Airs.ret_z(1:end-1) + diff(Airs.ret_z);
    dZ   = diff(Airs.ret_z)+ circshift(diff(Airs.ret_z),1);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% find the strongest signal for each pixel and work out the vertical wavelength
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
    
    %identify strongest spectral signal for each voxel
    sz = size(CC);
    CC = reshape(CC,sz(1)*sz(2),sz(3)*sz(4)*sz(5));
    [~,MaxIdx] = max(abs(CC),[],1);
    [idxX,idxY] = ind2sub(sz([1,2]),MaxIdx);
    CC = reshape(CC,sz);
    idxX = reshape(idxX,sz(3:end)); idxY = reshape(idxY,sz(3:end)); 
    
    %pull this signal out of the array
    for iX=1:1:sz(3);
      for iY=1:1:sz(4);
        for iZ=1:1:sz(5)
          CC(1,1,iX,iY,iZ) = CC(idxX(iX,iY,iZ),idxY(iX,iY,iZ),iX,iY,iZ);   
        end
      end
    end
    clear iX iY MaxIdx iZ
    CC = squeeze(CC(1,1,:,:,:));
    
    %convert each levels CC values to covarying amplitude and phase
    AllA  = sqrt(abs(CC));
    AlldP = angle(   CC);
    
    %convert phase change to wavelength
    sz = size(AlldP);
    Lambda = permute(repmat(dZ,1,sz(1),sz(2)),[2,3,1])./AlldP.*2*pi;
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% interpolate onto the same shape as the other ST outputs
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%        

    
    
% % % %     stop
% % % %     F1 = Lambda.*NaN; f1 = freqs{1};
% % % %     F2 = Lambda.*NaN; f2 = freqs{2};
% % % %     sz = size(Lambda);
% % % %     for iX=1:1:sz(1);
% % % %       for iY=1:1:sz(2);
% % % %         for iZ=1:1:sz(3)
% % % %           F1(iX,iY,iZ) = f1(idxX(iX,iY,iZ));
% % % %           F2(iX,iY,iZ) = f2(idxY(iX,iY,iZ));
% % % %         end
% % % %       end
% % % %     end
% % % %     clear f1 f2 iX iY iZ
    
    
  end
end