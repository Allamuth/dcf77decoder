%% get signal
[signal , fs] = audioread( %%file of SDR recording of DCF77 found at 77.5kHz in the greater region around Germany%% );

signal = abs(hilbert(signal));   %% stripping the carrier frequency
signal=signal/max(signal);       %% normalizing soundlevel

threshold=0.25;
signal=abs(signal)>threshold;

bits = [];                       %% vector of bits
a = 0;
b = 0;
i = 0;


for i = 1:length(signal)
  
  if (signal(i) == 1)                        %% count highs
    b=b+1;
  elseif (signal(i) == 0 && b < (1.7 * fs))  %% sync sequence not found
    b = 0;
  elseif (signal(i) == 0 && b > (1.7 * fs))  %% found sync sequence
    b = 0;
    for i = i:length(signal)
      
      if signal(i) == 0                      %% count lows
        a=a+1;
        if (b < (1.7 * fs) && signal(i-1) == 1)
            b = 0;
        elseif (b > (1.7 * fs) && signal(i-1) == 1)
            break;
        end
      end
      
      if (signal(i) == 1)                   %% count highs
        b=b+1;
        if (a <= (0.12 * fs) && signal(i-1) == 0)       %% zero bit found
            bits = [bits, 0];
            a = 0;
        elseif (a >= (0.16 * fs) && signal(i-1) == 0 )    %% one bit found
            bits = [bits, 1];
            a = 0;
        end
      end
    end
  end
  
  if signal(i) == 0  && b > (1.7 * fs) && length(bits) == 59             %% end loop if second sync sequence and all needed bits are found
    break;
  elseif signal(i) == 0  && b > 1.7 * fs && length(bits) < 59            %% start again if there was false-positive occurrence of sync sequence
    bits = zeros(1,59);
    b = 0;
  end
end

minute=sum(bits(22:28).*[1 2 4 8 10 20 40]);
hour=sum(bits(30:35).*[1 2 4 8 10 20]);
day=sum(bits(37:42).*[1 2 4 8 10 20]);
weekday_num=sum(bits(43:45).*[1 2 4]);
switch (weekday_num)
  case 1
    weekday = "Monday";
  case 2
    weekday = "Tuesday";
  case 3
    weekday = "Wednesday";
  case 4
    weekday = "Thursday";
  case 5
    weekday = "Friday";
  case 6
    weekday = "Saturday";
  case 7
    weekday = "Sunday";
endswitch
month=sum(bits(46:50).*[1 2 4 8 10]);
year=sum(bits(51:58).*[1 2 4 8 10 20 40 80]);
if bits(18) == 0 && bits(19) == 1
  timezone = "MEZ";
elseif bits(18) == 1 && bits(19) == 0
  timezone = "MESZ";
else
  timezone + "ERROR";
end

date = strcat( weekday, " ", num2str(year), "-", num2str(month), "-", num2str(day), "T", num2str(hour), ":", num2str(minute), timezone); %% generate date ISO 8601 like

disp(date);  %% display date
