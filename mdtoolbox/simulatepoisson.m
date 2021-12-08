function [event_time, interarrival_time] = simulatepoisson(time_width, rate)
%% simulatepoisson
% simulates event- and inter-arrival times of Poisson process using the given time-width and rate
%
%% Example
%# [event_time, interarrival_time] = simulatepoisson(1, 100);
%# numel(event_time)
%# plotevent(event_time);
%
%% References
% Simulation, New York, Academic Press.
% Sheldon M. Ross, Chapter 5.
%

%% simulation
event_time = 0;
t = 0;

while true
  t = t - (1./rate) * log(rand);
  if t > time_width
    break
  end
  event_time = [event_time; t];
end

interarrival_time = diff(event_time);

% delete t=0 from event_time
event_time(1) = [];

