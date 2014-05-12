

-module(gossip).
-import(util,[sum/1,sum/2,len/1,minimum/1,maximum/1]).
-import (segment,[segfile/2,for/3]).
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
start(ProcNum,Topology,Itr,FilePath,Function) ->
Pid = spawn(gossip, calculate, []),
io:format("PID: ~p~n",[Pid]),
global:register_name(er_calculate, Pid),
segfile(FilePath,ProcNum div 2),
{ok, Filenames} = file:list_dir("./seg/"),
Frags = length(Filenames),

initProc(ProcNum,ProcNum,Topology,Function,Frags,Itr).
     %Msg =[1,88,99].
     %whereis('P_2') ! Msg.



%Main Function for threads
threadoperation(Pids, Mydata,SegId, Processname,Itr) ->
	
	put("Pid",Pids),
	put("Data",Mydata),
	put("segId",segId),
	io:format("Initialising ~p ~n",[self()]),
	
	
	receive 
		{initialise, Function} ->	
			io:format("Initialising ~p ~n",[self()]),
			case Function of 
				min ->
					Min = minimum(Mydata),
					put("Function", Min),
					io:format("Local min is ~p ~n", [Min]);
				%	io:format("Local value of ~p is ~p ~n", [Function, get("function")])
				max ->
					Max = maximum(Mydata),
					put("Function", Max);
					%io:format("Local max is ~p ~n", [Max]);
					%io:format("Local value of ~p is ~p ~n", [Function, get("function")]);
				average ->
				   io:format("Local Data is ~p ~n", [Mydata]),
					Sum = sum(Mydata),
					Size = len(Mydata), 
					put("localsum",Sum),
					put("localsize", Size)
			end,
			
			put("numNodes", length(Pids)),
			%io:format("Number of nodes ~p ~n", [len(Pids)]),
			threadoperation(Pids, Mydata,SegId, Processname,Itr);
		
		{calculate,Function} ->
	     	io:format("Received message to calculate ~p ~n ", [Function]),
			random:seed(now()),
			Random = random:uniform(get("numNodes")),
			%io:format("Random:~p ",[Random]),
			Pid = lists:nth(random:uniform(get("numNodes")), Pids), % Select a random node to exchange value
			%io:format("Sending information to ~p ~n", [Pid]),
			case Function of
			  min ->
				Min = get("Function"),
				%io:format("Sending msg to :~p ",[Pid]),
				global:send(Pid,{Processname, request, Function, Min});
				%Pid ! {self(), request, Function, Min};
			  max ->
				Max = get("Function"),
				global:send(Pid,{Processname, request, Function, Max});
				%Pid ! {self(), request, Function, Max};
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
			io:format("~p Got a request from ~p to calculate ~p. Received sum is ~p. Received size is ~p ~n", [self(),Pid, Function, Sum, Size]),
	      		global:send(Pid, {Processname,reply, Function, get("localsum"), get("localsize")}),% send a reply message with local values	
			global:send(er_calculate, {Processname, Function, get("localsum"), Sum, get("localsize"), Size}),
			threadoperation(Pids, Mydata,SegId,Processname,Itr);	
	      	  
		{Pid, request, Function, Value} ->
			%io:format("~p Received a reply from ~p with its local values: ~p ~p  ~n", [self(), Pid, Sum, Size]),
			case Function of
				min ->
				%io:format("Value is : ~p  ~n", [Value]),
				%io:format("Self value : ~p  ~n", [get("Function")]) ,
				%io:format("er_calc ~p  ~n", [whereis(er_calculate)]),
				
					global:send(er_calculate, {Processname, Function, get("Function"), Value}),
					global:send(Pid, {Processname, reply, Function, get("Function")});
				max ->
					global:send(er_calculate, {Processname, Function, get("Function"), Value}),
					global:send(Pid, {Processname, reply, Function, get("Function")})
			end,
			%io:format("~p: New local sum  is ~p. New local Size is ~p ~n ", [ self(), get("localsum"), get("localsize")]), 
			threadoperation(Pids, Mydata,SegId,Processname,Itr);

		{Pid, reply, Function, Sum, Size} ->
			%io:format("~p Received a reply from ~p with its local values: ~p ~p  ~n", [self(), Pid, Sum, Size]),
			global:send(er_calculate, {Processname, Function, get("localsum"), Sum, get("localsize"),Size}),
			%io:format("~p: New local sum  is ~p. New local Size is ~p ~n ", [ self(), get("localsum"), get("localsize")]), 
			threadoperation(Pids, Mydata,SegId,Processname,Itr);
		{Pid, reply, Function, Value} ->
			case Function of
				min ->
				%io:format("In reply ,Value is : ~p  ~n", [Value]),
				%io:format("In reply :Self value : ~p  ~n", [get("Function")]) ,
				%io:format("er_calculate : ~p  ~n", [whereis(er_calculate)]) ,
				
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
			threadoperation(Pids, Mydata,SegId,Processname,Itr);
		{timer, Function} ->
			%io:format("~p Started processing....",[self()]),
			global:send(Processname, {calculate, Function}),
			timer:send_after(500,self(), {timer, Function}),
			threadoperation(Pids, Mydata,SegId,Processname,Itr)			     					
	end.

calculate() ->
	  	io:format("Received start ~n"),
	  	
receive
	%start ->
	  %   io:format("Received start ~n");
	{Pid_proc, Function,Value1, Value2} ->
		%io:format(" Received message from ~p. Function is ~p. Data is ~p ~p~n", [Pid_proc, Function, Value1, Value2]),
		case Function of 
	  	  min -> 
		     	 Min = erlang:min(Value1, Value2), 	 
			 io:format("FINAL Minimum value at ~p is ~p ~n", [Pid_proc, Min]),
			 global:send(Pid_proc, {update, Function, Min}),
			 calculate();
	   	  max -> 
		        Max = erlang:max(Value1, Value2),
		        io:format("FINAL Maximum value at ~p is ~p ~n", [Pid_proc, Max]),
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




     
     
     
    
    
    

