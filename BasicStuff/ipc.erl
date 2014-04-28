%Author: Anuja
%Functionality: generic function to calculate min or max of values
-module(ipc).
-export([start/0, p1/1 , p2/1, calculate/0]).


p1(PIDS)-> 
receive
	Val1 ->
	     %io:format("In p1: Received Value ~p ~n", [Val1]),
	     Val2 = 1.333,
	     %io:format("Now Sending value ~p ~n", [Val2]),
	     lists:foreach(fun(Pid) -> Pid ! Val2 end, PIDS),
	     er_calculate ! {self(), min, Val1, Val2}
end.

p2(PIDS)-> 
Val1 = 1.3334,
lists:foreach(fun(Pid) -> Pid ! Val1 end, PIDS),
receive
	
	Val ->
	   %io:format("In p2: Received Value ~p ~n ", [Val]),
	   er_calculate ! {self(), min, Val1, Val}
	   
end.

calculate() ->
	  %  io:format("In calculate function");
receive
	start ->
	      io:format("Received start ~n");
	{Pid_proc, Function,Val1, Val2} ->
		io:format(" Received message from ~p. Function is ~p. VLalues are ~p ~p ~n", [Pid_proc, Function, Val1, Val2]),
		case Function of 
	  	  min -> 
		     	 Min = erlang:min(Val1, Val2),
		  	 io:format("Minimum value for ~p is ~p ~n", [Pid_proc, Min]);
	   	  max -> 
		      Max = erlang:max(Val1, Val2),
		      io:format("Maximum value for ~p is ~p ~n", [Pid_proc, Max])
		 end,
		  
	calculate()
end.

start() ->
PIDS1 = [er_ping1],
PIDS2 = [er_ping],
register(er_ping, spawn(ipc, p1, [PIDS1])),
register(er_ping1, spawn(ipc, p2, [PIDS2])),
register(er_calculate, spawn(ipc,calculate,[])).
