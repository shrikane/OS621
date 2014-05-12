%%Author: Anuja Kench, Yin 
%%Implementation of Gossip Algorithm to perform variuos computational tasks like Min, Max, Average

-module(gossip).
-import(util,[sum/1,sum/2,len/1,minimum/1,maximum/1, log2/1]).
-import (segment,[segfile/2, for/3]).
-import (network,[getRoutingTable/2,getRoutingTableMesh/2,listAppneder/2]).
-import (createProc,[getFrag/1,initProc/6]).

%% ====================================================================
%% API functions
%% ====================================================================
-export([start/5, threadoperation/5,calculate/0]).



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
io:format("PID: ~p~n",[Pid]),
global:register_name(er_calculate, Pid),
segfile(FilePath,ProcNum div 2),
{ok, Filenames} = file:list_dir("./seg/"),
Frags = length(Filenames),
initProc(ProcNum,ProcNum,Topology,Function,Frags,Itr). %Call the initialising function



%Main Function for threads
threadoperation(Pids, Mydata,SegId, Processname,Itr) ->
	
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
			io:format("NuNodes are ~p ~n", [get("numNodes")]),
			Converge = 200/2,
			io:format("converge at ~p ~n", [Converge]),
			Counter = 0,
			put("converge", Converge),
			put("counter", Counter),			
			ConvergedValue = 0,
			put("converged", ConvergedValue),
			threadoperation(Pids, Mydata,SegId, Processname, Itr);
		
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
					
			threadoperation(Pids, Mydata,SegId, Processname,Itr);
		%% yin's code
		 {read, RequestSegId, Source} ->
		         io:format("Current Process is ~p~n Received a read request from ~p with ID ~p~n", [self(),Source, RequestSegId]),
%		         io:format("Registered: ~p~n",[registered()]),
		     OldValue = get("Iteration"),
                     io:format("Itr number: ~p~n",[OldValue]),
		       if OldValue > 0 ->
		         Id = atom_to_list(RequestSegId),
		         IntegerId = list_to_integer(Id),
		         io:format("Requested Id is ~p~n",[Id]),
		         io:format("My Id lists is ~w~n",[get("segId")]),
		         io:format("True or false: ~p~n",[lists:member(Id, [get("segId")])]),
				 case lists:member(IntegerId, [get("segId")]) of
				     true ->
					 MyValue = get("Data"),
					 %Source ! {readreply, self(), MyValue };
					 global:send(Source, {readreply, self(), MyValue });
				     false ->
					% io:format("Itr number: ~p~n",[OldValue]),
					 NeighborNum = random:uniform(get("numNodes")),
					 io:format("Not found local, send a rumor to neighor! The random number is ~p~n",[NeighborNum]),
					 RandomNeighbor = lists:nth(NeighborNum, Pids),
				%	RandomNeighbor ! {read, RequestSegId, Source}	  
				global:send(RandomNeighbor,{read,RequestSegId,Source})
				     end,
			erase("Iteration"),
			NewValue = OldValue -1,
			put("Iteration", NewValue),
				   io:format("new iteration number is ~w~n",[get("Iteration")])
			       
				   end,
	                 	threadoperation(Pids, Mydata, SegId, Processname, Itr);
		
		 {readreply,From, Values} ->
		io:format("Your read request has a reply: ~p from ~p~n",[Values, From]);
		
		  {write, TargetSegmentation, UpdatedValues} ->
		 %      OldItr = get("Iteration"),
		% io:format("Itr number: ~p~n",[OldItr]),
		  %    if OldItr > 0 ->
		       YourRequestSegId = atom_to_list(TargetSegmentation),
                        YourIntegerId = list_to_integer(YourRequestSegId),
		       case lists:member(YourIntegerId, [get("segId")]) of
			   true ->
			       io:format("*****************Current thread ~p should be update!*****************~n
			       Before update the file has the value: ~p~n*****************************************~n",[self(),get("Data")]),
			       erase("Data"),
			       put("Data", UpdatedValues),
			       io:format("****************Requested Id: ~p has been updated to:****************~n
			       ~p ~n***********************************~n",[YourIntegerId, get("Data")]);
			   false ->
			       for(1,Itr,fun(Index) ->
                                 io:format("Itr number: ~p~n",[Index]),
                                 NeighborNum2 = random:uniform(get("numNodes")),
                                 io:format("Not found local, send a rumor to neighor! The random number is ~p~n",[NeighborNum2]),
                                 RandomNeighbor2 = lists:nth(NeighborNum2, Pids),
			       %RandomNeighbor2 ! {write, TargetSegmentation, UpdatedValues}
			       global:send(RandomNeighbor2,{write, TargetSegmentation, UpdatedValues})
					    end)
		       end,
		threadoperation(Pids, Mydata,SegId, Processname, Itr);
		%% Yin's code ends here

		{Pid, request, Function, Sum, Size} ->
		        NewAverage = Sum / Size,
			LocalAverage= get("localsum") / get("localsize"),
			 CounterValue = get("counter"),
			 ConvergeValue = get("converge"),
			 %io:format("Local Average is ~p New Average is ~p ~n", [LocalAverage, NewAverage]),
			 Delta = abs(NewAverage - LocalAverage), 
			 %io:format("Delta is ~p ~n", [Delta]),
			if Delta  =< 5.0 ->
				if CounterValue == ConvergeValue ->
			     		ConvergedValue = 1,
					put("converged", ConvergedValue),
			  		io:format("Converged value for ~p at ~p is ~p ~n", [Function,Processname,LocalAverage]);	 
			     
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

			global:send(Pid, {Processname,reply, Function, get("localsum"), get("localsize")}),% send a reply message with local values	
			global:send(er_calculate, {Processname, Function, get("localsum"), Sum, get("localsize"), Size}),
			threadoperation(Pids, Mydata,SegId,Processname,Itr);	
	      	  
		{Pid, request, Function, Value} ->
		        LocalValue = get("Function"),
			 CounterValue = get("counter"),
			 ConvergeValue = get("converge"),
			 if Value == LocalValue ->
				if CounterValue == ConvergeValue ->
			     		ConvergedValue = 1,
					put("converged", ConvergedValue),
					io:format("Converged Value for ~p at ~p is ~p ~n", [Function, Processname, LocalValue]);			 
			     
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
			threadoperation(Pids, Mydata,SegId,Processname,Itr);

		{Pid, reply, Function, Sum, Size} ->
		       


			
			global:send(er_calculate, {Processname, Function, get("localsum"), Sum, get("localsize"),Size}),
			%io:format("~p: New local sum  is ~p. New local Size is ~p ~n ", [ self(), get("localsum"), get("localsize")]), 
			threadoperation(Pids, Mydata,SegId,Processname,Itr);
		{Pid, reply, Function, Value} ->
			case Function of
				min ->
				
					global:send(er_calculate, {Processname, Function, get("Function"), Value});
				max ->
					global:send(er_calculate, {Processname, Function, get("Function"), Value})
			end,	
					threadoperation(Pids, Mydata,SegId,Processname,Itr);
		{update, Function, Value} ->
			erase("Function"),
			put("Function", Value),
			threadoperation(Pids, Mydata,SegId, Processname,Itr);
		{update, Function, localsum, SumValue, localsize, SizeValue} ->
			erase("localsum"),
			put("localsum", SumValue),
			erase("localsize"),
			put("localsize", SizeValue),
			LocalAverage = SumValue / SizeValue,
			%io:format("Average at node ~p is ~p ~n", [Processname, LocalAverage]),
			threadoperation(Pids, Mydata,SegId,Processname, Itr);
		{timer, Function} ->
			%io:format("Stared Processing"),
			ConvergedValue = get("converged"),
			if ConvergedValue == 1 ->
			   io:format("~p has converged.~n", [Processname]);
			true ->
				global:send(Processname, {calculate, Function}),
			     	timer:send_after(500,self(), {timer, Function})
				%threadoperation(Pids, Mydata,SegId,Processname, Itr)
			end,
			threadoperation(Pids, Mydata,SegId,Processname, Itr)
						     					
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




     
     
     
    
    
    

