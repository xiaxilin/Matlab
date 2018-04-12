classdef univariateRT
    %univariateRT Summary of this class goes here
    %   Detailed explanation goes here    
    properties
        Xdata % observed value
        XDT   % observing date and time
        thV   % value threshold
        thP   % propotion threshold
        unit  % the unit of Xdata
        name  % the name of Xdata
        yearnum % number of years of the observation
        PureEvent % identified events exluding neigbouring records
        Mt
        pd % probability distribution
        testKS
        testChi
    end 
    methods
        function obj = univariateRT(Xtable,varargin)
            %univariateRT Construct an instance of this class
            % obj = univariateRT(Xtable,thP)
            % obj = univariateRT(Xtable,'V',thV)
            % obj = univariateRT(Xtable,'V',thV,daygap)            
            %   pass xdata and datetime
            if istable(Xtable)
                obj.XDT = table2array(Xtable(:,1));
                obj.Xdata = table2array(Xtable(:,2));
                ind = isnan(obj.Xdata);
                obj.Xdata(ind)=[];
                obj.XDT(ind)=[];
            end
            obj.yearnum = numel(obj.Xdata)/365.25;
            if isempty(varargin)
                obj.thP = 0.95;
            elseif numel(varargin)==1
                thPV = varargin{1};
                if thPV<1&&thPV>0
                    obj.thP = varargin{1};
                else
                    obj.thV = varargin{1};
                end
            else
                if strcmpi(varargin{1},'P')
                    obj.thP = varargin{2};
                elseif strcmpi(varargin{1},'V')
                    obj.thV = varargin{2};
                end
            end
            if numel(varargin)==3
                dayGap = varargin{3};
            else
                dayGap = 3;
            end
            if isempty(obj.thP)
                EP = (sum(obj.Xdata>=obj.thV)+1-0.44)/(numel(obj.Xdata)+0.12);
                obj.thP = 1-EP;
            end
            if isempty(obj.thV)
                obj.thV = quantile(obj.Xdata,obj.thP);
            end
            ind = obj.Xdata>=obj.thV;
%             obj.Mt = obj.yearnum/sum(ind);
            obj.PureEvent = ExtractDuplicateEvents(obj.XDT(ind),obj.Xdata(ind),dayGap);
            obj.Mt = obj.yearnum/height(obj.PureEvent);
        end
        
        function obj = distFit(obj,varargin)
            % varargin: distribution names 
            if isempty(varargin)
                distNames = {'GeneralizedExtremeValue'};
            else
                distNames = varargin;
            end
            distname = distNames{1};
            Xe_pure = obj.PureEvent.Event;
            obj.pd = fitdist(Xe_pure,distname);
            h = kstest(Xe_pure,'CDF',[Xe_pure, cdf(obj.pd,Xe_pure)]);
            obj.testKS = h;
            h = chi2gof(Xe_pure,'CDF',obj.pd);
            obj.testChi = h;
        end
        
        function Fx = CDF(obj,x)
            Fx = cdf(obj.pd,x);
        end
        
        function RTV = ReturnPeriod(obj,x)
            Fx = cdf(obj.pd,x);
            RTV = obj.Mt./(1-Fx);            
        end
        
        function x = iReturnPeriod(obj,t)
            Fx = 1-obj.Mt./t;
            x = icdf(obj.pd,Fx);
        end
        
    %% visualization
    function QQPlot(obj)
        hqq = qqplot(obj.PureEvent.Event,obj.pd);
        hqq(1).MarkerEdgeColor = 'r';
        hqq(2).Color = 'b';
        hqq(3).Color = 'b';
        xlabel('Theoretical Value')
        ylabel('Observed Value')
        title(['QQ Plot for ' obj.pd.DistributionName])
        ax = gca;
        ax.Box = 'on';
%         xsample = obj.PureEvent.Event;
    end
    
    function CDFPlot(obj)
        xsample = obj.PureEvent.Event;
        [~,x] = ecdf(xsample);
        ci = paramci(obj.pd);
        Fx_CI0 = cdf(obj.pd.DistributionName,x,ci(1,1),ci(1,2),ci(1,3));
        Fx_CI1 = cdf(obj.pd.DistributionName,x,ci(2,1),ci(2,2),ci(2,3));
        ecdf(xsample,'bounds','on');
        hold on
        plot(x,cdf(obj.pd,x),'r-')
        plot(x,[Fx_CI0,Fx_CI1],'r--')
        hold off
    end
    
    function RTPlot(obj,varargin)
        % RTPlot(obj,xrange,'bound')
        % xsample = RTPlot(obj,xrange)        
        xsample = obj.PureEvent.Event;
        [f,x,flo,fup]  = ecdf(xsample);
        if isempty(varargin)
            xrange = x;
        else
            xrange = varargin{1};  
        end
        
        if numel(varargin)>=2&&strcmpi(varargin{2},'bound')
            BoundFlag = true;
            lgdstr = {'Empirical','Theoretical','95% Theoretical CI'};
        else
            BoundFlag = false;
            lgdstr = {'Empirical','Theoretical'};        
        end
        ci = paramci(obj.pd);
        Fx_CI0 = cdf(obj.pd.DistributionName,xrange,ci(1,1),ci(1,2),ci(1,3));
        Fx_CI1 = cdf(obj.pd.DistributionName,xrange,ci(2,1),ci(2,2),ci(2,3));
        RT_e = obj.Mt./(1-[f,flo,fup]);
        RT_t = obj.Mt./(1-cdf(obj.pd,xrange));
        RT_t_up = obj.Mt./(1-Fx_CI0);
        RT_t_down = obj.Mt./(1-Fx_CI1);
        plot(x,RT_e(:,1),'r+')
        hold on
        plot(xrange,RT_t,'b','LineWidth',1.5)
        if BoundFlag
            plot(xrange,RT_t_up,'k--')
            plot(xrange,RT_t_down,'k--')
        end
%         plot(x,RT_e(:,2:3),'r--')
        hold off
%         xsample = [x RT_e];
        title(['Return Period of ' obj.name])
        xlabel([obj.name ': ' obj.unit])
        ylabel('Return period: year')
        ax = gca;
        if numel(varargin)==3&&strcmpi(varargin{3},'log')
            ax.YScale = 'log';
        end
        ax.XLim = [min(xrange) max(xrange)];
        ax.YLim = [min(RT_t) max(RT_t)];
        ax.Box = 'on';
        legend(lgdstr,'Location','southeast')
    end
    
    end
    
    methods(Static)
        function PureEvent = ExtractDuplicateEvents(Dates,Observations,Daygap)
            % PureEvent = ExtractDuplicateEvents remove the multiple events in the
            %   short duration defined by Daygap. The maximum value for each variable
            %   will be selected as the represent values in that duration.
            % Dates: datetime array gives the time of observations
            % Observations: martix with columns representing the variables
            % Daygap: integer give the duration of extraction
            % PureEvent: return value, a table of variable Date and Event
            [Dates,I] = sort(Dates);
            Observations = Observations(I,:);
            gaps = [Daygap+1;Dates(2:end)-Dates(1:end-1)];
            indGaps = gaps<=Daygap;
            Date = Dates;
            Event = Observations;
            for i=1:length(Dates)
                if indGaps(i)
                    Date(i) = Date(i-1);
                    Event(i,:) = max(Event(i-1:i,:));
                end
            end
            PureEvent = table(Date,Event);
            [~,ia,~] = unique(Date,'last');
            PureEvent = PureEvent(ia,:);
        end
    end
end

