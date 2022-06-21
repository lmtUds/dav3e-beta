% This file is part of DAVE, a MATLAB toolbox for data evaluation.
% Copyright (C) 2018-2019 Saarland University, Author: Manuel Bastuck
% Website/Contact: www.lmt.uni-saarland.de, info@lmt.uni-saarland.de
% 
% The author thanks Tobias Baur, Tizian Schneider, and Jannis Morsch
% for their contributions.
% 
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU Affero General Public License as published
% by the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU Affero General Public License for more details.
% 
% You should have received a copy of the GNU Affero General Public License
% along with this program.  If not, see <http://www.gnu.org/licenses/>. 

function updateFun = correlation(parent,project,dataprocessingblock)
    populateGui(parent,project,dataprocessingblock);
    updateFun = @()populateGui(parent,project,dataprocessingblock);
end

function populateGui(parent,project,dataprocessingblock)
   try 
        tar = project.currentModel.fullModelData.target;
        groupings = cat2num(project.currentModel.fullModelData.groupings);
        groupingCaptions = project.currentModel.fullModelData.groupingCaptions;
        selFeat = project.currentModel.fullModelData.selectedFeatures;
        dat = project.currentModel.fullModelData.data;
        featCap = project.currentModel.fullModelData.featureCaptions;
        rank = project.currentModel.processingChain.blocks.getByCaption('automated Selection').parameters.getByCaption('rank').value;
    
        mymap = customClrMap();

        limit = 9;
        gas = cell(limit * numel(selFeat),1);
        features = cell(limit * numel(selFeat),1);
        correlation = zeros(limit * numel(selFeat),1);
        for j=1:limit
            for i = 1:numel(selFeat)
                gas{(j-1)*numel(selFeat)+i,1} = groupingCaptions{j};
                str = strsplit(featCap(rank(i)),'default/');
                newStr = strrep(str(2),'_','-');
                features{(j-1)*numel(selFeat)+i,1} = char(i+100+" "+newStr);
                correlation((j-1)*numel(selFeat)+i,1) = abs(corr(dat(:,rank(i)), groupings(:,j)));
            end
        end

        tbl = table(gas,features,correlation);

        h = heatmap(parent,tbl,'features','gas','ColorVariable','correlation',...
                'ColorLimits',[0 1],'Colormap',mymap);
        h.Layout.Column = 1; h.Layout.Row = 1;
    catch
        disp('Could not display correlation details page')
    end
%     errorTr = dataprocessingblock.parameters.getByCaption('error').value.training(:,:);
%     errorTrstd = dataprocessingblock.parameters.getByCaption('error').value.stdTraining(:,:);
%     errorV = dataprocessingblock.parameters.getByCaption('error').value.validation(:,:);
%     errorVstd = dataprocessingblock.parameters.getByCaption('error').value.stdValidation(:,:);
%     errorTe = dataprocessingblock.parameters.getByCaption('error').value.testing(:,:);
%     nCompPLSR = dataprocessingblock.parameters.getByCaption('projectedData').value.nComp;
%     if isempty(errorTr)
%         errorTr=[0];
%     elseif isempty(errorV)
%         errorV=[0];
%     end
%     x = 1:1:size(errorTr,2);
%     plot(elements.hAx,x,errorTr(nCompPLSR,:),'k',x,errorV(nCompPLSR,:),'r',x,errorTe(nCompPLSR,:),'b');
%     xlabel(elements.hAx,'nFeatures');
%     ylabel(elements.hAx,'RMSE');
%     legend(elements.hAx,'Training','Validation','Testing');
%     numFeat=dataprocessingblock.parameters.getByCaption('numFeat').value;
%     errTraining=errorTr(nCompPLSR,numFeat);
%     errTrSTD = errorTrstd(nCompPLSR,numFeat);
%     errValidation=errorV(nCompPLSR,numFeat);
%     errVaSTD = errorVstd(nCompPLSR,numFeat);
%     errTesting=errorTe(end,numFeat);
%     fprintf('numFeat: %.1f \n nCompPLSR: %.1f \n errorTraining: %.2f \n errorTrainingStd: %.2f \n errorValidation: %.2f \n errorValidationStd: %.2f \n errorTesting: %.2f \n',...
%         numFeat, nCompPLSR, errTraining, errTrSTD, errValidation, errVaSTD, errTesting);
end

function clrMap = customClrMap()
    clrMap = [1,0.00196078442968428,0.00196078442968428;...
             1,0.00981164071708918,0.00196850392967463;...
             1,0.0176623761653900,0.00197622366249561;...
             1,0.0255129914730787,0.00198394316248596;...
             1,0.0333634838461876,0.00199166289530695;...
             1,0.0412138551473618,0.00199938239529729;...
             1,0.0490641072392464,0.00200710212811828;...
             1,0.0569142363965511,0.00201482162810862;...
             1,0.0647642463445664,0.00202254136092961;...
             1,0.0726141333580017,0.00203026086091995;...
             1,0.0804639011621475,0.00203798059374094;...
             1,0.0883135423064232,0.00204570009373128;...
             1,0.0961630716919899,0.00205341982655227;...
             1,0.104012474417686,0.00206113932654262;...
             1,0.111861757934093,0.00206885905936360;...
             1,0.119710914790630,0.00207657855935395;...
             1,0.127559959888458,0.00208429829217494;...
             1,0.135408878326416,0.00209201802499592;...
             1,0.143257677555084,0.00209973752498627;...
             1,0.151106357574463,0.00210745725780726;...
             1,0.158954903483391,0.00211517675779760;...
             1,0.166803345084190,0.00212289649061859;...
             1,0.174651652574539,0.00213061599060893;...
             1,0.182499840855598,0.00213833572342992;...
             1,0.190347924828529,0.00214605522342026;...
             1,0.198195874691010,0.00215377495624125;...
             1,0.206043705344200,0.00216149445623159;...
             1,0.213891401886940,0.00216921418905258;...
             1,0.221738994121552,0.00217693368904293;...
             1,0.229586467146873,0.00218465342186391;...
             1,0.237433806061745,0.00219237292185426;...
             1,0.245281025767326,0.00220009265467525;...
             1,0.253128141164780,0.00220781238749623;...
             1,0.260975122451782,0.00221553188748658;...
             1,0.268821984529495,0.00222325162030756;...
             1,0.276668697595596,0.00223097112029791;...
             1,0.284515321254730,0.00223869085311890;...
             1,0.292361825704575,0.00224641035310924;...
             1,0.300208210945129,0.00225413008593023;...
             1,0.308054447174072,0.00226184958592057;...
             1,0.315900593996048,0.00226956931874156;...
             1,0.323746591806412,0.00227728881873190;...
             1,0.331592500209808,0.00228500855155289;...
             1,0.339438259601593,0.00229272805154324;...
             1,0.347283929586411,0.00230044778436422;...
             1,0.355129450559616,0.00230816728435457;...
             1,0.362974852323532,0.00231588701717556;...
             1,0.370820134878159,0.00232360651716590;...
             1,0.378665298223496,0.00233132624998689;...
             1,0.386510342359543,0.00233904598280787;...
             1,0.394355267286301,0.00234676548279822;...
             1,0.402200073003769,0.00235448521561921;...
             1,0.410044759511948,0.00236220471560955;...
             1,0.417889326810837,0.00236992444843054;...
             1,0.425733745098114,0.00237764394842088;...
             1,0.433578073978424,0.00238536368124187;...
             1,0.441422253847122,0.00239308318123221;...
             1,0.449266344308853,0.00240080291405320;...
             1,0.457110285758972,0.00240852241404355;...
             1,0.464954137802124,0.00241624214686453;...
             1,0.472797840833664,0.00242396164685488;...
             1,0.480641424655914,0.00243168137967587;...
             1,0.488484889268875,0.00243940087966621;...
             1,0.496328264474869,0.00244712061248720;...
             1,0.504171490669251,0.00245484034530818;...
             1,0.512014567852020,0.00246255984529853;...
             1,0.519857585430145,0.00247027957811952;...
             1,0.527700424194336,0.00247799907810986;...
             1,0.535543203353882,0.00248571881093085;...
             1,0.543385803699493,0.00249343831092119;...
             1,0.551228284835815,0.00250115804374218;...
             1,0.559070706367493,0.00250887754373252;...
             1,0.566912949085236,0.00251659727655351;...
             1,0.574755072593689,0.00252431677654386;...
             1,0.582597076892853,0.00253203650936484;...
             1,0.590438961982727,0.00253975600935519;...
             1,0.598280787467957,0.00254747574217618;...
             1,0.606122434139252,0.00255519524216652;...
             1,0.613963961601257,0.00256291497498751;...
             1,0.621805369853973,0.00257063447497785;...
             1,0.629646658897400,0.00257835420779884;...
             1,0.637487828731537,0.00258607394061983;...
             1,0.645328879356384,0.00259379344061017;...
             1,0.653169810771942,0.00260151317343116;...
             1,0.661010622978210,0.00260923267342150;...
             1,0.668851315975189,0.00261695240624249;...
             1,0.676691830158234,0.00262467190623283;...
             1,0.684532284736633,0.00263239163905382;...
             1,0.692372620105743,0.00264011113904417;...
             1,0.700212836265564,0.00264783087186515;...
             1,0.708052873611450,0.00265555037185550;...
             1,0.715892851352692,0.00266327010467649;...
             1,0.723732709884644,0.00267098960466683;...
             1,0.731572389602661,0.00267870933748782;...
             1,0.739412009716034,0.00268642883747816;...
             1,0.747251451015472,0.00269414857029915;...
             1,0.755090832710266,0.00270186830312014;...
             1,0.762930035591126,0.00270958780311048;...
             1,0.770769178867340,0.00271730753593147;...
             1,0.778608143329620,0.00272502703592181;...
             1,0.786447048187256,0.00273274676874280;...
             1,0.794285774230957,0.00274046626873314;...
             1,0.802124381065369,0.00274818600155413;...
             1,0.809962928295136,0.00275590550154448;...
             1,0.817801296710968,0.00276362523436546;...
             1,0.825639545917511,0.00277134473435581;...
             1,0.833477675914764,0.00277906446717680;...
             1,0.841315686702728,0.00278678396716714;...
             1,0.849153637886047,0.00279450369998813;...
             1,0.856991410255432,0.00280222319997847;...
             1,0.864829063415527,0.00280994293279946;...
             1,0.872666597366333,0.00281766243278980;...
             1,0.880504012107849,0.00282538216561079;...
             1,0.888341307640076,0.00283310189843178;...
             1,0.896178483963013,0.00284082139842212;...
             1,0.904015541076660,0.00284854113124311;...
             1,0.911852478981018,0.00285626063123345;...
             1,0.919689238071442,0.00286398036405444;...
             1,0.927525937557221,0.00287169986404479;...
             1,0.935362517833710,0.00287941959686577;...
             1,0.943198978900909,0.00288713909685612;...
             1,0.951035261154175,0.00289485882967711;...
             1,0.958871483802795,0.00290257832966745;...
             1,0.966707587242127,0.00291029806248844;...
             1,0.974543511867523,0.00291801756247878;...
             1,0.982379376888275,0.00292573729529977;...
             1,0.990215122699738,0.00293345679529011;...
             1,0.998050689697266,0.00294117652811110;...
             0.998035371303558,1,0.00294889626093209;...
             0.990200042724609,1,0.00295661576092243;...
             0.982364773750305,1,0.00296433549374342;...
             0.974529683589935,1,0.00297205499373376;...
             0.966694712638855,1,0.00297977472655475;...
             0.958859801292419,1,0.00298749422654510;...
             0.951025068759918,1,0.00299521395936608;...
             0.943190455436707,1,0.00300293345935643;...
             0.935355901718140,1,0.00301065319217742;...
             0.927521526813507,1,0.00301837269216776;...
             0.919687271118164,1,0.00302609242498875;...
             0.911853134632111,1,0.00303381192497909;...
             0.904019117355347,1,0.00304153165780008;...
             0.896185219287872,1,0.00304925115779042;...
             0.888351440429688,1,0.00305697089061141;...
             0.880517780780792,1,0.00306469062343240;...
             0.872684240341187,1,0.00307241012342274;...
             0.864850819110870,1,0.00308012985624373;...
             0.857017517089844,1,0.00308784935623407;...
             0.849184334278107,1,0.00309556908905506;...
             0.841351270675659,1,0.00310328858904541;...
             0.833518326282501,1,0.00311100832186639;...
             0.825685501098633,1,0.00311872782185674;...
             0.817852854728699,1,0.00312644755467773;...
             0.810020267963409,1,0.00313416705466807;...
             0.802187800407410,1,0.00314188678748906;...
             0.794355452060700,1,0.00314960628747940;...
             0.786523282527924,1,0.00315732602030039;...
             0.778691172599793,1,0.00316504552029073;...
             0.770859241485596,1,0.00317276525311172;...
             0.763027369976044,1,0.00318048475310206;...
             0.755195617675781,1,0.00318820448592305;...
             0.747364044189453,1,0.00319592421874404;...
             0.739532589912415,1,0.00320364371873438;...
             0.731701195240021,1,0.00321136345155537;...
             0.723869979381561,1,0.00321908295154572;...
             0.716038823127747,1,0.00322680268436670;...
             0.708207845687866,1,0.00323452218435705;...
             0.700376987457275,1,0.00324224191717803;...
             0.692546188831329,1,0.00324996141716838;...
             0.684715569019318,1,0.00325768114998937;...
             0.676885068416596,1,0.00326540064997971;...
             0.669054687023163,1,0.00327312038280070;...
             0.661224424839020,1,0.00328083988279104;...
             0.653394281864166,1,0.00328855961561203;...
             0.645564198493958,1,0.00329627911560237;...
             0.637734293937683,1,0.00330399884842336;...
             0.629904508590698,1,0.00331171858124435;...
             0.622074842453003,1,0.00331943808123469;...
             0.614245295524597,1,0.00332715781405568;...
             0.606415927410126,1,0.00333487731404603;...
             0.598586618900299,1,0.00334259704686701;...
             0.590757429599762,1,0.00335031654685736;...
             0.582928359508514,1,0.00335803627967834;...
             0.575099408626556,1,0.00336575577966869;...
             0.567270576953888,1,0.00337347551248968;...
             0.559441924095154,1,0.00338119501248002;...
             0.551613330841065,1,0.00338891474530101;...
             0.543784856796265,1,0.00339663424529135;...
             0.535956561565399,1,0.00340435397811234;...
             0.528128325939179,1,0.00341207347810268;...
             0.520300269126892,1,0.00341979321092367;...
             0.512472271919251,1,0.00342751271091402;...
             0.504644393920898,1,0.00343523244373500;...
             0.496816694736481,1,0.00344295217655599;...
             0.488989084959030,1,0.00345067167654634;...
             0.481161594390869,1,0.00345839140936732;...
             0.473334223031998,1,0.00346611090935767;...
             0.465507000684738,1,0.00347383064217865;...
             0.457679867744446,1,0.00348155014216900;...
             0.449852883815765,1,0.00348926987498999;...
             0.442025989294052,1,0.00349698937498033;...
             0.434199243783951,1,0.00350470910780132;...
             0.426372587680817,1,0.00351242860779166;...
             0.418546080589294,1,0.00352014834061265;...
             0.410719692707062,1,0.00352786784060299;...
             0.402893394231796,1,0.00353558757342398;...
             0.395067244768143,1,0.00354330707341433;...
             0.387241214513779,1,0.00355102680623531;...
             0.379415303468704,1,0.00355874653905630;...
             0.371589511632919,1,0.00356646603904665;...
             0.363763839006424,1,0.00357418577186763;...
             0.355938315391541,1,0.00358190527185798;...
             0.348112881183624,1,0.00358962500467896;...
             0.340287566184998,1,0.00359734450466931;...
             0.332462370395660,1,0.00360506423749030;...
             0.324637323617935,1,0.00361278373748064;...
             0.316812366247177,1,0.00362050347030163;...
             0.308987557888031,1,0.00362822297029197;...
             0.301162868738174,1,0.00363594270311296;...
             0.293338268995285,1,0.00364366220310330;...
             0.285513818264008,1,0.00365138193592429;...
             0.277689486742020,1,0.00365910143591464;...
             0.269865274429321,1,0.00366682116873562;...
             0.262041181325913,1,0.00367454066872597;...
             0.254217207431793,1,0.00368226040154696;...
             0.246393337845802,1,0.00368998013436794;...
             0.238569617271423,1,0.00369769963435829;...
             0.230746001005173,1,0.00370541936717927;...
             0.222922518849373,1,0.00371313886716962;...
             0.215099141001701,1,0.00372085859999061;...
             0.207275897264481,1,0.00372857809998095;...
             0.199452772736549,1,0.00373629783280194;...
             0.191629767417908,1,0.00374401733279228;...
             0.183806881308556,1,0.00375173706561327;...
             0.175984114408493,1,0.00375945656560361;...
             0.168161481618881,1,0.00376717629842460;...
             0.160338953137398,1,0.00377489579841495;...
             0.152516558766365,1,0.00378261553123593;...
             0.144694283604622,1,0.00379033503122628;...
             0.136872112751007,1,0.00379805476404727;...
             0.129050076007843,1,0.00380577449686825;...
             0.121228165924549,1,0.00381349399685860;...
             0.113406375050545,1,0.00382121372967958;...
             0.105584703385830,1,0.00382893322966993;...
             0.0977631509304047,1,0.00383665296249092;...
             0.0899417176842690,1,0.00384437246248126;...
             0.0821204110980034,1,0.00385209219530225;...
             0.0742992162704468,1,0.00385981169529259;...
             0.0664781481027603,1,0.00386753142811358;...
             0.0586572065949440,1,0.00387525092810392;...
             0.0508363805711269,1,0.00388297066092491;...
             0.0430156737565994,1,0.00389069016091526;...
             0.0351950898766518,1,0.00389840989373624;...
             0.0273746289312840,1,0.00390612939372659;...
             0.0195542890578508,1,0.00391384912654758;...
             0.0117340683937073,1,0.00392156885936856];
end