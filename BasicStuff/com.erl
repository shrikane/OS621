

-module(com).
-define(server_node, node@umbcCSEE).

%% ====================================================================
%% API functions
%% ====================================================================
-export([ start/0, initProc/2, process/3, segfile/2]).



%% ====================================================================
%% Internal functions
%% ====================================================================


start() ->
ProcNum =50,
segfile("./data.dat",ProcNum div 2),
initProc(ProcNum,ProcNum),
     Msg =[1,88,99].
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
    {ok, Binary} = file:read_file(FileName),
    Lines = string:tokens(erlang:binary_to_list(Binary), "\n"),
    io:format("~p~n",[Lines]),
    MyLists = [ lists:sublist(Lines, X, (length(Lines) div (N))) || X <- lists:seq(1,length(Lines),(length(Lines) div (N))) ],
    io:format("~p~n", [MyLists] ),
    io:format("~p~n", [length(MyLists)]),
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

%creates neighbour's list for ring toplology 
getRoutingTable(Max,N) ->
		erase("Next"),
		erase("Pre"),
   	   io:format("Next: ~p ~n", [N+1]),
 	    io:format("Pre: ~p ~n", [N-1]),
	     put("Next",N+1),
	     put("Pre",N-1),
	      if
	      Max == N -> erase("Next") , put("Next",0) ;
	      N == 0 -> erase("Pre"), put("Pre", N);
	      true -> Q=1
	      end,     
	 Route = [get("Pre"),get("Next")].

listAppneder(0,Route) ->
lists:append(Route, [0]);

listAppneder(N,Route) ->
Route1 = lists:append(Route, [N]),
listAppneder(N-1,Route1).

%creates neighbour's list for mesh toplology 
getRoutingTableMesh(Max,N) ->
X = listAppneder(Max,[]),
X1 = lists:delete(N, X),
io:format("Route: ~w ~n", [X1]).

% get fragment as per id
getFrag(FragId) ->
 FileName =string:concat("./seg/F_",integer_to_list(FragId)),
	       io:format("Frag Id: ~p ~n", [FragId]),
 	      %io:format("Reading frag from: ~p  ~n ",[FileName]),
              {ok, Binary} = file:read_file(FileName),
	     
	      Lines1 = string:tokens(erlang:binary_to_list(Binary), "\n|,"),
		Lines = lists:map(fun(X) -> {Int, _} = string:to_float(X), Int end, Lines1).


%exit condition for proc
process(-1,N,Topology) ->
    true;


% Topology = whcih topology we need to use
% Limit process number at start it is equal to max number of process
process(Limit,N,Topology) ->
	       FragId = (Limit rem 10)+1,
	       Lines = getFrag(FragId),
	      if
	      Topology ==1 -> Route = getRoutingTable(N,Limit) ;
	      true -> Route = getRoutingTableMesh(N,Limit)
	      end,
	       
	       put("Neighbour",Route),
	       Data =[random:uniform(10) || _ <- lists:seq(1, 10)],
	       put("frag", Lines),
	       put("FragId",(Limit+1) rem N),
	       io:format("Neighbour are: ~w  ~n ",[get("Neighbour")]),
	       io:format("Keys: ~p  ~n ",[get("frag")]),
	       Newcount = Limit -1,
	       %threadoperation(get("frag"),get("Neighbour")),
	      % io:format(" NewCount: ~p ~n", [Newcount]),
	       initProc(Newcount,N),
	 %end. 
		
	 receive 	  
	 Msg ->
	  io:format("Keys in rec: ~p  ~n ",[get("frag")])
    end.


initProc(-1,N) -> 
%io:format("NP_id: ~p  ~n ",[]),
true;

% function to grgister process
initProc(Limit,N) ->  
    % io:format("Limit is ~p ~n ", [Limit]),
     Processname = list_to_atom(string:concat( "P_" ,integer_to_list(Limit))),
     register(Processname ,spawn_link(com , process , [Limit,N,0])),

io:format("Forked ~p ~n",[Processname]).
     

%Anuja's code starts here.
initialise(Pidlist, Function) ->
	lists:foreach(fun(Pid) -> Pid ! {initialise, Function} end, Pidlist).	       		      

startprocessing(Pidlist, Function) ->
	lists:foreach(fun(Pid) ->
		timer:send_after(50000, Pid, {timer, Function}) end, Pidlist).
	%lists:foreach(fun(Pid) -> Pid ! {timer, Function} end, Pidlist).	       		      
	

% Calculate sum of elements in list
sum(List) -> 
   sum(List, 0).

sum([Head|Tail], Result) -> 
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
threadoperation(Pids, Mydata) ->
	receive 
		{initialise, Function} ->	
			%io:format("Initialising ~p ~n",[self()]),
			case Function of 
				min ->
					Min = minimum(Mydata),
					put("Function", Min),
					io:format("Local min is ~p ~n", [Min]);
				%	io:format("Local value of ~p is ~p ~n", [Function, get("function")]);
				max ->
					Max = maximum(Mydata),
					put("Function", Max),
					io:format("Local max is ~p ~n", [Max]);
					%io:format("Local value of ~p is ~p ~n", [Function, get("function")]);
				average ->
					Sum = sum(Mydata),
					Size = len(Mydata), 
					put("localsum",Sum),
					put("localsize", Size)
			end,
			
			put("numNodes", len(Pids)),
			io:format("Number of nodes ~p ~n", [len(Pids)]),
			threadoperation(Pids, Mydata);
		
		{calculate,Function} ->
	     		io:format("Received message to calculate ~p ~n ", [Function]),
			random:seed(now()),
			Random = random:uniform(get("numNodes")),
			io:format("Random:~p ",[Random]),
			Pid = lists:nth(random:uniform(get("numNodes")), Pids), % Select a random node to exchange value
			io:format("Sending information to ~p ~n", [Pid]),
			case Function of
			  min ->
				Min = get(Function),
				Pid ! {self(), request, Function, Min};
			  max ->
				Max = get(Function),
				Pid ! {self(), request, Function, Max};
			  average ->
	      			Pid ! {self(),request, Function, get("localsum"), get("localsize")}
			  end,
					
			threadoperation(Pids, Mydata);


		{Pid, request, Function, Sum, Size} ->
			io:format("~p Got a request from ~p to calculate ~p. Received sum is ~p. Received size is ~p ~n", [self(),Pid, Function, Sum, Size]),
	      		Pid ! {self(),reply, Function, get("localsum"), get("localsize")},% send a reply message with local values	
			er_calculate ! {self(), Function, get("localsum"), Sum, get("localsize"), Size},
			threadoperation(Pids, Mydata);	
	      	  
		{Pid, request, Function, Value} ->
			%io:format("~p Received a reply from ~p with its local values: ~p ~p  ~n", [self(), Pid, Sum, Size]),
			case Function of
				min ->
					er_calculate ! {self(), Function, get(Function), Value},
					Pid ! {self(), reply, Function, get(Function)};
				max ->
					er_calculate ! {self(), Function, get(Function), Value},
					Pid ! {self(), reply, Function, get(Function)}
			end,
			%io:format("~p: New local sum  is ~p. New local Size is ~p ~n ", [ self(), get("localsum"), get("localsize")]), 
			threadoperation(Pids, Mydata);

		{Pid, reply, Function, Sum, Size} ->
			io:format("~p Received a reply from ~p with its local values: ~p ~p  ~n", [self(), Pid, Sum, Size]),
			er_calculate ! {self(), Function, get("localsum"), Sum, get("localsize"),Size},
			io:format("~p: New local sum  is ~p. New local Size is ~p ~n ", [ self(), get("localsum"), get("localsize")]), 
			threadoperation(Pids, Mydata);
		{Pid, reply, Function, Value} ->
			case Function of
				min ->
					er_calculate ! {self(), Function, get(Function), Value};
				max ->
					er_calculate ! {self(), Function, get(Function), Value}
			end,	
					threadoperation(Pids, Mydata);
		{update, Function, Value} ->
			erase(Function),
			put(Function, Value),
			threadoperation(Pids, Mydata);
		{update, Function, localsum, SumValue, localsize, SizeValue} ->
			erase("localsum"),
			put("localsum", SumValue),
			erase("localsize"),
			put("localsize", SizeValue),
			threadoperation(Pids, Mydata);
		{timer, Function} ->
			io:format("~p Started processing....",[self()]),
			self() ! {calculate, Function},
			timer:send_after(100,self(), {timer, Function}),
			threadoperation(Pids, Mydata)
				
			 
				     					
	end.


calculate() ->
	  
receive
	%start ->
	  %    io:format("Received start ~n");
	{Pid_proc, Function,Value1, Value2} ->
		io:format(" Received message from ~p. Function is ~p. Data is ~p ~p~n", [Pid_proc, Function, Value1, Value2]),
		case Function of 
	  	  min -> 
		     	 Min = erlang:min(Value1, Value2), 	 
			 io:format("Minimum value at ~p is ~p ~n", [Pid_proc, Min]),
			 Pid_proc ! {update, Function, Min};
	   	  max -> 
		        Max = erlang:max(Value1, Value2),
		        io:format("Maximum value at ~p is ~p ~n", [Pid_proc, Max]),
			Pid_proc ! {update, Function, Max}
		  end;
	{Pid_proc, Function, Sum1, Sum2, Size1, Size2} ->
		case Function of 
		 average ->
			Sum = Sum1 + Sum2,
			Size = Size1 + Size2,
			Pid_proc ! {update,Function, localsum, Sum, localsize, Size}
		end,	
		  
	calculate()
end.


     
     
     
    
    
    
