%%Author: Anuja Kench, Yin 
%%Implementation of Gossip Algorithm to perform variuos computational tasks like Min, Max, Average

-module(gossip).
-import(util,[sum/1,sum/2,len/1,minimum/1,maximum/1, log2/1]).
-import (segment,[segfile/2]).
-import (network,[getRoutingTable/2,getRoutingTableMesh/2,listAppneder/2]).
-import (createProc,[getFrag/1,initProc/5]).

%% ====================================================================
%% API functions
%% ====================================================================
-export([start/5, threadoperation/4,calculate/0]).



%% ====================================================================
%% Internal functions
%% ====================================================================

% Number of Process , Topology Type
% Topology =1 is Ring
% Topology =0 is Mesh	
% FilePath input data file
% Function min,max,avg ,update , read 


%% Main function
start(ProcNum,Topology,Itr,FilePath,Function) ->
Pid = spawn(gossip, calculate, []),
%io:format("PID: ~p~n",[Pid]),
global:register_name(er_calculate, Pid), %Register calculate process
segfile(FilePath,ProcNum div random:uniform(ProcNum)),
{ok, Filenames} = file:list_dir("./seg/"),
Frags = length(Filenames),
initProc(ProcNum,ProcNum,Topology,Function,Frags). %Call the initialising function




%Main Function for threads
threadoperation(Pids, Mydata,SegId, Processname) ->
	
	put("Pid",Pids),
	put("Data",Mydata),
	put("segId",segId),
		
		receive 
		{initialise, Function} ->	
			io:format("Initialising ~p ~n",[Processname]),
			case Function of 
				min ->
					Min = minimum(Mydata),
					put("Function", Min);
					%io:format("Local min is ~p ~n", [Min]);
				
				max ->
					Max = maximum(Mydata),
					put("Function", Max);
					%io:format("Local max is ~p ~n", [Max]);
					
				average ->
					Sum = sum(Mydata),
					Size = len(Mydata), 
					put("localsum",Sum),
					put("localsize", Size)
			end,
			
			put("numNodes", length(Pids)),
			Converge = trunc(log2(length(Pids))),
		 	Counter = 0,
			put("converge", Converge),
			put("counter", Counter),			
			ConvergedValue = 0,
			put("converged", ConvergedValue),
			threadoperation(Pids, Mydata,SegId, Processname);
		
		{calculate,Function} ->
	     		%io:format("Received message to calculate ~p ~n ", [Function]),
			random:seed(now()),
			Random = random:uniform(get("numNodes")),
			Pid = lists:nth(random:uniform(get("numNodes")), Pids), % Select a random node to exchange value
			case Function of
			  min ->
				Min = get("Function"),
				%io:format("Sending msg to :~p ",[Pid]),
				global:send(Pid,{Processname, request, Function, Min});
				
			  max ->
				Max = get("Function"),
				global:send(Pid,{Processname, request, Function, Max});
				
			  average ->
	      		  	global:send (Pid , {Processname,request, Function, get("localsum"), get("localsize")})
			  end,
					
			threadoperation(Pids, Mydata,SegId, Processname);


		{Pid, request, Function, Sum, Size} ->
		        global:send(Pid, {Processname,reply, Function, get("localsum"), get("localsize")}),% send a reply message with local values	
			global:send(er_calculate, {Processname, Function, get("localsum"), Sum, get("localsize"), Size}),
			threadoperation(Pids, Mydata,SegId,Processname);	
	      	  
		{Pid, request, Function, Value} ->
		        LocalValue = get("Function"),
			 CounterValue = get("counter"),
			 ConvergeValue = get("converge"),
			 if Value == LocalValue ->
				if CounterValue == ConvergeValue ->
			     		ConvergedValue = 1,
					put("converged", ConvergedValue);
			     
                          	true ->
					Counter = CounterValue + 1,
                             		erase("counter"),
                             		put("counter", Counter)
                       	  	end;
 		      	true ->
                            Count = 0,
			    erase("counter"),
                            put("counter", Count)
		      end,

			case Function of
				min ->
					global:send(er_calculate, {Processname, Function, get("Function"), Value}),
					global:send(Pid, {Processname, reply, Function, get("Function")});
				max ->
					global:send(er_calculate, {Processname, Function, get("Function"), Value}),
					global:send(Pid, {Processname, reply, Function, get("Function")})
			end,
			%io:format("~p: New local sum  is ~p. New local Size is ~p ~n ", [ self(), get("localsum"), get("localsize")]), 
			threadoperation(Pids, Mydata,SegId,Processname);

		{Pid, reply, Function, Sum, Size} ->
		       


			
			global:send(er_calculate, {Processname, Function, get("localsum"), Sum, get("localsize"),Size}),
			
			threadoperation(Pids, Mydata,SegId,Processname);
		{Pid, reply, Function, Value} ->
			case Function of
				min ->
				
					global:send(er_calculate, {Processname, Function, get("Function"), Value});
				max ->
					global:send(er_calculate, {Processname, Function, get("Function"), Value})
			end,	
					threadoperation(Pids, Mydata,SegId,Processname);
		{update, Function, Value} ->
			erase("Function"),
			put("Function", Value),
			threadoperation(Pids, Mydata,SegId, Processname);
		{update, Function, localsum, SumValue, localsize, SizeValue} ->
			erase("localsum"),
			put("localsum", SumValue),
			erase("localsize"),
			put("localsize", SizeValue),
			LocalAverage = SumValue / SizeValue,
			io:format("Average at node ~p is ~p ~n", [Processname, LocalAverage]),
			threadoperation(Pids, Mydata,SegId,Processname);
		{timer, Function} ->
			%io:format("Stared Processing"),
			ConvergedValue = get("converged"),
			if ConvergedValue == 1 ->
			   io:format("~p has converged. Converged Value for ~p is ~p ~n", [Processname, Function, get("Function")]);
			true ->
				global:send(Processname, {calculate, Function}),
			     	timer:send_after(500,self(), {timer, Function})
			end,
			threadoperation(Pids, Mydata,SegId,Processname)
						     					
	end.

calculate() ->
	  		  	
receive
	%start ->
	  %   io:format("Received start ~n");
	{Pid_proc, Function,Value1, Value2} ->
		%io:format(" Received message from ~p. Function is ~p. Data is ~p ~p~n", [Pid_proc, Function, Value1, Value2]),
		case Function of 
	  	  min -> 
		     	 Min = erlang:min(Value1, Value2), 	 
			 %io:format("Minimum value at ~p is ~p ~n", [Pid_proc, Min]),
			 global:send(Pid_proc, {update, Function, Min}),
			 calculate();
	   	  max -> 
		        Max = erlang:max(Value1, Value2),
		        %io:format("FINAL Maximum value at ~p is ~p ~n", [Pid_proc, Max]),
			global:send(Pid_proc, {update, Function, Max}),
			calculate()
		  end;
	{Pid_proc, Function, Sum1, Sum2, Size1, Size2} ->
		case Function of 
		 average ->
			Sum = Sum1 + Sum2,
			Size = Size1 + Size2,
			global:send(Pid_proc, {update,Function, localsum, Sum, localsize, Size}),
			calculate()
		end,	
		  
	calculate()
	end.




     
     
     
    
    
    

