%Author: Anuja
%Functionality: Min-Max Calculation
 
-module(ipc).
-import(dict).
-export([start/0, threadoperation/2, calculate/0]).

initialise([Pidlist]) ->
	lists:foreach(fun(Pid) -> Pid ! initialise end, Pidlist).	       		      

threadoperation([Pids], Myvalue) ->
	receive 
		initialise ->	
			%io:format("Initialising ~p ~n",[self()]),
			put("min",[Myvalue]),
			put("max",[Myvalue]),
			threadoperation([Pids], Myvalue);
		{calculate,Function, Value} ->
	      		er_calculate ! {self(), Function, Myvalue, Value},
	      		lists:foreach(fun(Pid) -> Pid ! {calculate,Function,Myvalue} end, Pids),
	      		threadoperation([Pids],Myvalue);
		{update, Function, Value} ->
			% io:format("~p: Got updated value: ~p", [self(),Value]),
			 erase(Function),
			 put(Function, Value),
			 threadoperation([Pids], get(Function))		      	  
				     					
	end.


calculate() ->
	  
receive
	%start ->
	  %    io:format("Received start ~n");
	{Pid_proc, Function,Val1, Val2} ->
		%io:format(" Received message from ~p. Function is ~p. VLalues are ~p ~p ~n", [Pid_proc, Function, Val1, Val2]),
		case Function of 
	  	  min -> 
		     	 Min = erlang:min(Val1, Val2), 	 
			 io:format("Minimum value at ~p is ~p ~n", [Pid_proc, Min]),
			 Pid_proc ! {update, Function, [Min]};
	   	  max -> 
		        Max = erlang:max(Val1, Val2),
		        io:format("Maximum value at ~p is ~p ~n", [Pid_proc, Max]),
			Pid_proc ! {update, Function, Max}
		      
		  end,
		  
	calculate()
end.

start() ->

Pidlist = [er_ping1,er_ping3,er_ping2,er_ping4,er_ping5,er_ping6,er_ping7,er_ping8,er_ping9,er_ping10,er_ping11,er_ping12, er_ping13,er_ping14, er_ping15],

Pids1 = [er_ping4,er_ping3,er_ping2,er_ping5,er_ping6,er_ping7,er_ping8,er_ping9,er_ping10,er_ping11,er_ping12, er_ping13,er_ping14, er_ping15],
Pids2 = [er_ping1,er_ping3,er_ping4,er_ping5,er_ping6,er_ping7,er_ping8,er_ping9,er_ping10,er_ping11,er_ping12, er_ping13,er_ping14, er_ping15],
Pids3 = [er_ping1,er_ping4,er_ping2,er_ping5,er_ping6,er_ping7,er_ping8,er_ping9,er_ping10,er_ping11,er_ping12, er_ping13,er_ping14, er_ping15],
Pids4 = [er_ping1,er_ping3,er_ping2,er_ping5,er_ping6,er_ping7,er_ping8,er_ping9,er_ping10,er_ping11,er_ping12, er_ping13,er_ping14, er_ping15],
Pids5 = [er_ping1,er_ping3,er_ping4,er_ping2,er_ping6,er_ping7,er_ping8,er_ping9,er_ping10,er_ping11,er_ping12, er_ping13,er_ping14, er_ping15],
Pids6 = [er_ping1,er_ping3,er_ping4,er_ping5,er_ping2,er_ping7,er_ping8,er_ping9,er_ping10,er_ping11,er_ping12, er_ping13,er_ping14, er_ping15],
Pids7 = [er_ping1,er_ping3,er_ping4,er_ping5,er_ping6,er_ping2,er_ping8,er_ping9,er_ping10,er_ping11,er_ping12, er_ping13,er_ping14, er_ping15],
Pids8 = [er_ping1,er_ping3,er_ping4,er_ping5,er_ping6,er_ping7,er_ping2,er_ping9,er_ping10,er_ping11,er_ping12, er_ping13,er_ping14, er_ping15],
Pids9 = [er_ping1,er_ping3,er_ping4,er_ping5,er_ping6,er_ping7,er_ping8,er_ping2,er_ping10,er_ping11,er_ping12, er_ping13,er_ping14, er_ping15],
Pids10 = [er_ping1,er_ping3,er_ping4,er_ping5,er_ping6,er_ping7,er_ping8,er_ping9,er_ping2,er_ping11,er_ping12, er_ping13,er_ping14, er_ping15],
Pids11 = [er_ping1,er_ping3,er_ping4,er_ping5,er_ping6,er_ping7,er_ping8,er_ping9,er_ping10,er_ping2,er_ping12, er_ping13,er_ping14, er_ping15],
Pids12 = [er_ping1,er_ping3,er_ping4,er_ping5,er_ping6,er_ping7,er_ping8,er_ping9,er_ping10,er_ping11,er_ping2, er_ping13,er_ping14, er_ping15],
Pids13 = [er_ping1,er_ping3,er_ping4,er_ping5,er_ping6,er_ping7,er_ping8,er_ping9,er_ping10,er_ping11,er_ping12, er_ping2,er_ping14, er_ping15],
Pids14 = [er_ping1,er_ping3,er_ping4,er_ping5,er_ping6,er_ping7,er_ping8,er_ping9,er_ping10,er_ping11,er_ping12, er_ping13,er_ping2, er_ping15],
Pids15 = [er_ping1,er_ping3,er_ping4,er_ping5,er_ping6,er_ping7,er_ping8,er_ping9,er_ping10,er_ping11,er_ping12, er_ping13,er_ping14, er_ping12],

Val1 = 1.2345,
Val2 = 2.3456,
Val3 = 3.3456,

Val4 = 4.3456,
Val5 = 5.3456,
Val6 = 6.3456,
Val7 = 7.3456,
Val8 = 8.3456,
Val9 = 9.3456,
Val10 = 10.3456,
Val11 = 11.3456,
Val12 = 12.3456,
Val13 = 13.3456,
Val14 = 14.3456,
Val15 = 15.3456,

register(er_ping1, spawn(ipc,  threadoperation, [[Pids1], Val1])),
register(er_ping2, spawn(ipc, threadoperation, [[Pids2], Val2])),
register(er_ping3, spawn(ipc, threadoperation, [[Pids3], Val3])),
register(er_ping4, spawn(ipc, threadoperation, [[Pids4], Val4])),
register(er_ping5, spawn(ipc, threadoperation, [[Pids5], Val5])),
register(er_ping6, spawn(ipc, threadoperation, [[Pids6], Val6])),
register(er_ping7, spawn(ipc, threadoperation, [[Pids7], Val7])),
register(er_ping8, spawn(ipc, threadoperation, [[Pids8], Val8])),
register(er_ping9, spawn(ipc, threadoperation, [[Pids9], Val9])),
register(er_ping10, spawn(ipc, threadoperation, [[Pids10], Val10])),
register(er_ping11, spawn(ipc, threadoperation, [[Pids11], Val11])),
register(er_ping12, spawn(ipc, threadoperation, [[Pids12], Val12])),
register(er_ping13, spawn(ipc, threadoperation, [[Pids13], Val13])),
register(er_ping14, spawn(ipc, threadoperation, [[Pids14], Val14])),
register(er_ping15, spawn(ipc, threadoperation, [[Pids15], Val15])),

register(er_calculate, spawn(ipc, calculate, [])),
initialise([Pidlist]),
er_ping1 ! {calculate, min, Val2}.