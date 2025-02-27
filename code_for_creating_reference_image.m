base_folder = '.\hydrophone measurments\';
addpath(base_folder);
files = dir('hydrophone measurments\');
base_name = 'single_data';
name_to_add = 'both regular';
pitch = 0.218e-3;
N = 1024;
pitch_half = pitch/2;
dz = 0.25e-3;
z_max_gs = 50e-3;
z = 30e-3:dz:50e-3;
z_flipped = flip(z);
x_half = -(N-1)*pitch_half/2:pitch_half:N*pitch_half/2;
x_full_gs = -(512-1)*pitch/2:pitch:512*pitch/2;
range_x = round(9.5e-3 / pitch_half);
x_for_image = (-range_x * pitch_half):pitch_half:range_x*pitch_half;
x = -9:0.15:9;
size_cut = round(size(z,2)/4);
shift_cut =  round(3e-3/dz);
z_flipped_cut = z_flipped(1,2 * size_cut - shift_cut:end - shift_cut);
z_cut = z(1,size_cut:3 * size_cut + 1);
Frequancy = 4.464e6; 
v = 1490; % water in room temperature m/sec (in body  v = 1540)
Wavelength = v/Frequancy;
clear E_FSP1_z0;
first = 3;
for index=1:numel(files)
    file_ = files(index);
    if file_.isdir && ~contains(file_.name,'.')
        files_inner = dir([base_folder file_.name]);
        
        for inner_index=1:numel(files_inner)
            inner_file = files_inner(inner_index);
            inner_file.name
            if contains(inner_file.name,base_name)
                data = load([base_folder file_.name '\' inner_file.name]);
                pattern = double(data.source(1,:));
                patterns = padarray(pattern,[0 256],0,'both');
                [amps, new_transducer] = calculateGS(patterns,false);
                new_transducer = amps .* exp(1i * new_transducer);

                new_transducer = padarray(new_transducer,[0 ((1024 - 128) / 2)]);
                new_transducer = new_transducer(1,256:768 -1);
                new_transducer = imresize(new_transducer,2,'box');
                new_transducer = new_transducer(1,1:N);
                index = 1;
                for z0 = z
                %     [E_FSP1_z0(index,:)] = FSP_X_near(Transducer,z0,N,pitch,Wavelength);
                    %[E_FSP1_z0(index,:)] = FSP_X_near(new_transducer,z0,N,pitch_half,Wavelength);
                
                    [E_FSP1_z0(index,:)] = FSP_X_near(new_transducer,z0,N,pitch_half,Wavelength);
                    index = index + 1;
                    z0;
                end
                I_FSP1_z0 = abs(E_FSP1_z0).^2;
                line_gs = abs(FSP_X_near(new_transducer,40e-3,N,pitch_half,Wavelength)).^2;
                line_gs = line_gs(512 - range_x:512 + range_x);
                line_gs = line_gs / max(line_gs);
                I_FSP1_z0 = I_FSP1_z0(:,512 - range_x:512 + range_x);
                figure
                imagesc(x_for_image * 1e3,z * 1e3,I_FSP1_z0); 
                axis  tight square; axis on; colormap hot%jet
                %xlabel('x [mm]', FontSize=16); ylabel('z [mm]',FontSize=16);
                set(gca,'FontSize',20)

                hgexport(gcf, [[base_folder file_.name '\cw image' ]], hgexport('factorystyle'), 'Format', 'tiff');
    
                figure
                plot(x_for_image * 1e3,line_gs);% xlabel('x [mm]', FontSize=16); ylabel('z [mm]',FontSize=16);
                set(gca,'FontSize',20)
                hgexport(gcf, [[base_folder file_.name '\gs line' ]], hgexport('factorystyle'), 'Format', 'tiff');

                index;
            end
            if contains(inner_file.name,'results') && ~contains(inner_file.name,'ppt')
                to_add = 'net';
                if contains(inner_file.name,'gs')
                    to_add = 'gs';
                end
                clear data
                data = load([base_folder file_.name '\' inner_file.name]);
                data=squeeze(data.(['data_' to_add])); 
                
                clear P
                for m=1:size(data,1)
                     for n=1:size(data,2)
                         if ~isempty(data(m,n).signal)
                %              P(m,n)=max(data(m,n).signal)-min(data(m,n).signal);
                %              P(m,n) = P(m,n)/2;
                             P(m,n)=min(data(m,n).signal);
                             if abs(P(m,n))>15000
                                P(m,n) = 15000;
                             end


                %              P(m,n)=max(data(m,n).signal);
                %              P(m,n)=sum(abs(data(m,n).signal))/10000;
                %              P(m,n)=sqrt(mean(data(m,n).signal.^2));
                         else 
                             P(m,n)=nan;
                %              Result(m,n) = nan;
                         end
                     end
                end
                sum(P(isnan(P)))
                P(isnan(P)) = 0;
                P = abs(P).^2;         

                if contains(file_.name,"3 focus test 2") && strcmp(to_add,'gs')
%                     for m=2:size(data,1) - 1
%                      for n=2:size(data,2) - 1
%                         if abs(P(m,n)) < 100000
%                             l = abs([ P(m+1,n) P(m+1,n+1) P(m,n+1) P(m+1,n-1) P(m - 1,n) P(m-1,n + 1) P(m,n-1) P(m-1,n-1)]);
%                            P(m,n) = mean(l( l > 100000));
%                         end
%                      end
%                     end
                    P = imfill(P,'holes');
                    P = medfilt2(P,[4,4]);
                else           
                    P = medfilt2(P);
                end
                if strcmp(to_add,'net')
                    data_net = P;
                else
                    data_gs = P;
                end
                figure
                imagesc(x,z_flipped * 1e3,P')
                axis tight equal; axis on; colormap hot%jet
                set(gca,'FontSize',20)
                hgexport(gcf, [[base_folder file_.name '\final image' to_add ]], hgexport('factorystyle'), 'Format', 'tiff');
                figure
                line = P(:,round(size(data,2)/2));
                line = line/max(line);
                plot(x,line'); 
                set(gca,'FontSize',20)
                hgexport(gcf, [[base_folder file_.name '\final line' to_add ]], hgexport('factorystyle'), 'Format', 'tiff');
                index;
            end
        end
        close all
        I_FSP1_z0 = I_FSP1_z0 ./ max(max(I_FSP1_z0));
        figure
        %subplot(2,3,1)
        imagesc(x_for_image * 1e3,z * 1e3,I_FSP1_z0); axis square;axis on;colormap hot;
        if first > 0
            a = gca;
            xlabel('x [mm]','FontSize',26); ylabel('z [mm]','FontSize',26);
            a.FontSize = 26;
            pos1 = get(a,'Position');
            colorbar('eastoutside')
            set(a,'Position',pos1)
        else
            set(gca,'xticklabel',[])
            set(gca,'yticklabel',[])
        end
        hgexport(gcf, [[base_folder file_.name '\cw image']], hgexport('factorystyle'), 'Format', 'tiff');

        figure
        imagesc(x,z_flipped * 1e3,data_gs')
        axis square; axis on; colormap hot%je

        set(gca,'xticklabel',[])
        set(gca,'yticklabel',[])
        hgexport(gcf, [[base_folder file_.name '\gs image' ]], hgexport('factorystyle'), 'Format', 'tiff');
        figure
        imagesc(x,z_flipped * 1e3,data_net')
        axis square; axis on; colormap hot%je        
        set(gca,'xticklabel',[])
        set(gca,'yticklabel',[])       
        hgexport(gcf, [[base_folder file_.name '\USDL image' ]], hgexport('factorystyle'), 'Format', 'tiff');        
        figure
        line = data_gs(:,round(size(data_gs,2)/2));
        line = line - min(line);
        line = line ./ max(line);
        plot(x,line','LineWidth',2); axis tight square; axis on;
        a = gca;    
        a.FontSize = 26;
        xlabel('x [mm]','FontSize',26); ylabel('Intensity [a.u]', FontSize=26);
        hold on
        line = data_net(:,round(size(data_net,2)/2));
        line = line - min(line);
        line = line ./ max(line);
        plot(x,line', 'LineWidth',2);
        hgexport(gcf, [[base_folder file_.name '\cross section']], hgexport('factorystyle'), 'Format', 'tiff');
        
        % generate images after cut
        fig = figure;
        fig.Position = [100 100 700 400];
        I_FSP1_z0 = I_FSP1_z0(size_cut:3 * size_cut + 1,:);
        %subplot(2,3,1)
        imagesc(x_for_image * 1e3,z_cut * 1e3,I_FSP1_z0);
        if first > 0 
            a = gca;
            xlabel('x [mm]','FontSize',26); ylabel('z [mm]','FontSize',26);
            a.FontSize = 26;
            pos1 = get(a,'Position');
            colorbar('eastoutside')
            set(a,'Position',pos1)
        else
            set(gca,'xticklabel',[])
            set(gca,'yticklabel',[])
        end
        axis equal tight;axis on;colormap hot;
        hgexport(gcf, [[base_folder file_.name '\cw image cut']], hgexport('factorystyle'), 'Format', 'tiff');
        data_gs_cut_center = data_gs(:,size_cut:3 * size_cut + 1);
        fig = figure;
        fig.Position = [100 100 700 400];
        imagesc(x,z_flipped_cut * 1e3,data_gs_cut_center')
        axis equal tight;axis on; colormap hot%je

        set(gca,'xticklabel',[])
        set(gca,'yticklabel',[])
        hgexport(gcf, [[base_folder file_.name '\gs image cut center']], hgexport('factorystyle'), 'Format', 'tiff');
        
        data_gs = data_gs(:,1 + shift_cut:2 * size_cut + shift_cut);
        fig = figure;
        fig.Position = [100 100 700 400];
        imagesc(x,z_flipped_cut * 1e3,data_gs')
        axis equal tight;axis on; colormap hot%je

        set(gca,'xticklabel',[])
        set(gca,'yticklabel',[])
        hgexport(gcf, [[base_folder file_.name '\gs image cut']], hgexport('factorystyle'), 'Format', 'tiff');
        
        data_net = data_net(:,1 + shift_cut:2 * size_cut + shift_cut);
        fig = figure;
        fig.Position = [100 100 700 400];
        imagesc(x,z_flipped_cut * 1e3,data_net')
        axis equal tight;axis on; colormap hot%je        
        set(gca,'xticklabel',[])
        set(gca,'yticklabel',[])       
        hgexport(gcf, [[base_folder file_.name '\USDL image cut']], hgexport('factorystyle'), 'Format', 'tiff');        
        fig = figure;
        fig.Position = [100 100 700 400];
        line = data_gs_cut_center(:,round(size(data_gs_cut_center,2)/2));
        line = line - min(line);
        line = line ./ max(line);
        plot(x,line','LineWidth',2); axis tight square; axis on;
        a = gca;    
        a.FontSize = 26;
        xlabel('x [mm]','FontSize',26); ylabel('Intensity [a.u]', FontSize=26);
        hold on
        line = data_net(:,round(size(data_net,2)/2));
        line = line - min(line);
        line = line ./ max(line);
        plot(x,line', 'LineWidth',2);
        hgexport(gcf, [[base_folder file_.name '\cross section cut']], hgexport('factorystyle'), 'Format', 'tiff');

        first = first - 1;

    end
end
   close all

