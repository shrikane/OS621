

-module(com).
-define(server_node, node@umbcCSEE).

%% ====================================================================
%% API functions
%% ====================================================================
-export([ start/5, initProc/6,  segfile/2,  listAppneder/2, threadoperation/4, calculate/0]).



%% ====================================================================
%% Internal functions
%% ====================================================================

% Number of Process , Topology Type
% Topology =1 is Ring
% Topology =0 is Mesh	
% FilePath input data file
% Function min,max,avg ,update , read 
start(ProcNum,Topology,Itr,FilePath,Function) ->
global:register_name(er_calculate, spawn(com, calculate, [])),
segfile(FilePath,ProcNum div random:uniform(ProcNum)),
{ok, Filenames} = file:list_dir("./seg/"),
Frags = length(Filenames),
io:format("~p~n",[Frags]),
initProc(ProcNum,ProcNum,Topology,Function,Frags,Itr).
     %whereis('P_2') ! Msg.

%%  author: Yin Huang
%%  Input: 1. filename to be segmented for example: ""./data/data.dat"
%%         2. Size of the chunk (all equal) so the number of fragments = size of data / size of the chunk.
%%  Output: same size chunks of the original file written to ./seg/F_index
%%  Note:   output directory is hard coded as under ./seg so you need to mkdir seg under current directory 



for(Max, Max, F) ->
    [F(Max)];
for(I, Max,F) ->
    [F(I)|for(I+1,Max, F)].

segfile(FileName,N) ->
    filelib:ensure_dir("seg/"),
    {ok,ChildFiles} = file:list_dir_all("seg"),
    lists:foreach(fun(Files)->file:delete(string:concat("seg/",Files)) end, ChildFiles),
    file:del_dir("seg"),
    file:make_dir("seg"),
    {ok, Binary} = file:read_file(FileName),
    Lines = string:tokens(erlang:binary_to_list(Binary), "\n"),
    %io:format("~p~n",[Lines]),
    MyLists = [ lists:sublist(Lines, X, (length(Lines) div (N))) || X <- lists:seq(1,length(Lines),(length(Lines) div (N))) ],
    %io:format("~p~n", [MyLists] ),
    %io:format("~p~n", [length(MyLists)]),
    %io:format("~p~n",[lists:nth(2,MyLists)]),
     for(1,length(MyLists), fun(Index) ->
				    filewrite(string:concat("./seg/F_", integer_to_list(Index)),lists:nth(Index,MyLists)),
	                           io:format("~p has been written to ~p ~n", [FileName,string:concat("./seg/F_", integer_to_list(Index)) ])
					end
	).

%%    for(1,length(MyLists), fun(Index) ->
%%	       {ok, O} = file:open(string:concat("./seg/F_", integer_to_list(Index)),write),
%%	       io:format(O, "~s~n",[lists:nth(Index, MyLists)]),
%%	       file:close(O),
%%	       io:format("~p has been written to ~p ~n", [FileName,string:concat("./seg/F_", integer_to_list(Index)) ])
%%		   end
%%	       ).
  



filewrite(File, L) ->
   case file:open(File, [write]) of
      {ok, Device} ->
         lists:foreach(fun(Line) -> writeline(Device, Line) end, L),
         file:close(Device)
   end.
writeline(Device, Line) -> writeline(Device, Line, os:type()).

writeline(Device, Line, {win32,_}) -> io:fwrite(Device, "~s\r\n", [Line]);
writeline(Device, Line, _) -> io:fwrite(Device, "~s\n", [Line]).

%%  author: Shrinivas Kane
%%  Input: 1. Process ID number
%%         2. Number of process to be spawn


getRoutingTable(Max,N) ->
		erase("Next"),
		erase("Pre"),
   	   %io:format("Next: ~p ~n", [list_to_atom(string:concat( "P_" ,integer_to_list(N+1)))]),
 	   %io:format("Pre: ~p ~n", [list_to_atom(string:concat( "P_" ,integer_to_list(N-1)))]),
	     put("Next",list_to_atom(string:concat( "P_" ,integer_to_list(N+1)))),
	     put("Pre",list_to_atom(string:concat( "P_" ,integer_to_list(N-1)))),
	      if
	      Max == N -> erase("Next") , put("Next",list_to_atom(string:concat( "P_" ,integer_to_list(0)))) ;
	      N == 0 -> erase("Pre"), put("Pre", list_to_atom(string:concat( "P_" ,integer_to_list(N))));
	      true -> Q=1
	      end,     
	 Route = [get("Pre"),get("Next")].

listAppneder(0,Route) ->
lists:append(Route, [list_to_atom(string:concat( "P_" ,integer_to_list(0)))]);

listAppneder(N,Route) ->
Route1 = lists:append(Route, [list_to_atom(string:concat( "P_" ,integer_to_list(N)))]),
listAppneder(N-1,Route1).

getRoutingTableMesh(Max,N) ->
X = listAppneder(Max,[]),
X1 = lists:delete(list_to_atom(string:concat( "P_" ,integer_to_list(N))), X).
%io:format("Route: ~w ~n", [X1]).


getFrag(FragId) ->
 FileName =string:concat("./seg/F_",integer_to_list(FragId)),
	       io:format("Frag Id: ~p ~n", [FragId]),
 	      %io:format("Reading frag from: ~p  ~n ",[FileName]),
              {ok, Binary} = file:read_file(FileName),
	     
	      Lines1 = string:tokens(erlang:binary_to_list(Binary), "\n|,"),
		Lines = lists:map(fun(X) -> {Int, _} = string:to_float(X), Int end, Lines1).



initProc(-1,N,Topology,Function,Frag, Itr) -> 
%io:format("NP_id: ~p  ~n ",[]),
Pids =listAppneder(N,[]),
startprocessing(Pids, Function,Itr);


initProc(Limit,N,Topology,Function,Frag,Itr) ->  
    
     Processname = list_to_atom(string:concat( "P_" ,integer_to_list(Limit))),
     put("registeredName", Processname),
     io:format("name: ~p~n", [get("registeredName")]), 
     NumNode = length(nodes())+1,
    Evaluation = (Limit rem NumNode),
	 NodeList = nodes(),
	 	io:format("Number of Nodes connected to me ~p ~n ", [NumNode]),
	 	io:format(" Nodes connected to me ~p ~n ", [NodeList]),
       FragId = (Limit rem Frag) +1,
       
	      Lines = getFrag(FragId),
	      %io:format("Data ~p ~n ", [Lines]),
	      if
	      Topology == 1  -> Route = getRoutingTable(N,Limit) ;
	      true -> Route = getRoutingTableMesh(N,Limit)
	      end,
	   %io:format("Adding route is ~p ~n ", [Route]), 
	   
	   
	   if
	     Evaluation == 0  -> global:register_name(Processname ,spawn_link(com , threadoperation , [Route,Lines,FragId, Processname]));
	     true ->  global:register_name(Processname ,spawn_link( lists:nth( Evaluation , nodes()),com , threadoperation , [Route,Lines,FragId, Processname]))
     end,
     %register(Processname ,spawn_link(com , threadoperation , [Route,Lines,FragId])),
    global:send( Processname , { initialise, Function}),
     initProc(Limit-1,N,Topology,Function,Frag,Itr).

%io:format("Forked ~p ~n",[Processname]).
     


initialise(Pidlist, Function) ->
	lists:foreach(fun(Pid) -> global:send(Pid, {initialise, Function}) end, Pidlist).	       		      

startprocessing(Pidlist, Function, Itr) ->
	case Function of
		read ->
                 InitialPid = string:strip(io:get_line("Please enter the start process Id say P_#>:"), right, $\n),
	       SegId = string:strip(io:get_line("Please enter the segmentation file Id say #>:"), right, $\n),
	       io:format("MyId is ~p~n",[InitialPid]),                                                                                   
	       MyDestination =  list_to_atom(InitialPid),                                                                                          
	       io:format("MyDestination is ~p~n",[whereis(MyDestination)]),                                                                      	               
	        io:format("initialize the request to ~p for ~p ~n",[InitialPid,SegId]), 
	       TargetSegId = list_to_atom(SegId),
	       io:format("Registered: ~p~n",[registered()]),
	       global:send(MyDestination, {read, TargetSegId, MyDestination});
	       
	       write ->
	        YourTargetPid = string:strip(io:get_line("Please enter the start process Id say P_#>:"), right, $\n),
	       YourTargetSegId = string:strip(io:get_line("Please enter the segmentation file Id say #>:"), right, $\n),
	       NewValues = string:strip(io:get_line("Please enter the new value for the segmentation say 0.2,0.3,0.4>:"), right, $\n),
	       NewDestination = list_to_atom(YourTargetPid),
	       TargetSegId2 = list_to_atom(YourTargetSegId),
	       NewValues2 = list_to_atom(NewValues),
	          %NewDestination ! {write, TargetSegId2, NewValues2};
	         global:send(NewDestination,{write, TargetSegId2,NewValues2});
	         
	         _Else ->
	lists:foreach(fun(Pid) ->
		global:send( Pid, {timer, Function}) end, Pidlist)
		end.
	%lists:foreach(fun(Pid) -> Pid ! {timer, Function} end, Pidlist).	       		      
	

% Calculate sum of elements in list
sum(List) -> 
   sum(List, 0).

sum([Head|Tail], Result) -> 
   io:format("Head: ~p ~n ", [Head]),
   io:format("Result: ~p ~n ", [Result]),	
   sum(Tail, Head + Result); 

sum([], Result) ->
   Result.

%Calculate length of list
len([]) -> 0;
len([_|Tail]) -> 1 + len(Tail).


%Calculate minimum element in the list
minimum([Head|Tail]) -> minimum2(Tail,Head).
 
minimum2([], Min) -> Min;
minimum2([Head|Tail], Min) when Head < Min -> minimum2(Tail,Head);
minimum2([_|Tail], Min) -> minimum2(Tail, Min).

%Calculate maximum element in the list
maximum([Head|Tail]) -> maximum2(Tail,Head).
 
maximum2([], Max) -> Max;
maximum2([Head|Tail], Max) when Head > Max -> maximum2(Tail,Head);
maximum2([_|Tail], Max) -> maximum2(Tail, Max).


%Main Function for threads
threadoperation(Pids, Mydata,SegId, Processname, Itr) ->
	
	put("Pid",Pids),
	put("Data",Mydata),
	put("segId",SegId),
	put("Iteration",Itr),
	
	receive 
		{initialise, Function} ->	
			%io:format("Initialising ~p ~n",[self()]),
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
					put("localsize", Size);
			        _Else ->
			        % do nothing for the write or read initialization otherwise error occurs
			        	io:format("")
			end,
			
			put("numNodes", length(Pids)),
			%io:format("Number of nodes ~p ~n", [len(Pids)]),
			threadoperation(Pids, Mydata,SegId, Processname, Itr);
		
		{calculate,Function} ->
	     		%io:format("Received message to calculate ~p ~n ", [Function]),
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


		{Pid, request, Function, Sum, Size} ->
			%io:format("~p Got a request from ~p to calculate ~p. Received sum is ~p. Received size is ~p ~n", [self(),Pid, Function, Sum, Size]),
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
		%*************Below is added by Yin
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
		threadoperation(Pids, Mydata,SegId, ProcessName, Itr);
		
		
		%*******************************************
					
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
	  %    io:format("Received start ~n");
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



     
     
     
    
    
    
