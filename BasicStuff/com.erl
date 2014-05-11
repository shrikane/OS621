

-module(com).
-define(server_node, node@umbcCSEE).

%% ====================================================================
%% API functions
%% ====================================================================
-export([ start/5, initProc/5,  segfile/2,  listAppneder/2, threadoperation/3, calculate/0]).



%% ====================================================================
%% Internal functions
%% ====================================================================

% Number of Process , Topology Type
% Topology =1 is Ring
% Topology =0 is Mesh	
% FilePath input data file
% Function min,max,avg ,update , read 
start(ProcNum,Topology,Itr,FilePath,Function) ->
register(er_calculate, spawn(com, calculate, [])),
segfile(FilePath,10),
{ok, Filenames} = file:list_dir("./seg/"),
Frags = length(Filenames) -1 ,
io:format("~p~n",[Frags]),
initProc(ProcNum,ProcNum,Topology,Function,Frags),
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



initProc(-1,N,Topology,Function,Frag) -> 
%io:format("NP_id: ~p  ~n ",[]),
Pids =listAppneder(N,[]),
startprocessing(Pids, Function);


initProc(Limit,N,Topology,Function,Frag) ->  
    
     Processname = list_to_atom(string:concat( "P_" ,integer_to_list(Limit))),
       FragId = (Limit rem Frag) +1,
       
	      Lines = getFrag(FragId),
	      %io:format("Data ~p ~n ", [Lines]),
	      if
	      Topology == 1  -> Route = getRoutingTable(N,Limit) ;
	      true -> Route = getRoutingTableMesh(N,Limit)
	      end,
	   %io:format("Adding route is ~p ~n ", [Route]),   
     register(Processname ,spawn_link(com , threadoperation , [Route,Lines,FragId])),
     Processname ! { initialise, Function},
     initProc(Limit-1,N,Topology,Function,Frag).

%io:format("Forked ~p ~n",[Processname]).
     


initialise(Pidlist, Function) ->
	lists:foreach(fun(Pid) -> Pid ! {initialise, Function} end, Pidlist).	       		      

startprocessing(Pidlist, Function) ->
	lists:foreach(fun(Pid) ->
		timer:send_after(500, Pid, {timer, Function}) end, Pidlist).
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
threadoperation(Pids, Mydata,SegId) ->
	
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
					put("localsize", Size)
			end,
			
			put("numNodes", length(Pids)),
			%io:format("Number of nodes ~p ~n", [len(Pids)]),
			threadoperation(Pids, Mydata,SegId);
		
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
				Pid ! {self(), request, Function, Min};
			  max ->
				Max = get("Function"),
				Pid ! {self(), request, Function, Max};
			  average ->
	      			Pid ! {self(),request, Function, get("localsum"), get("localsize")}
			  end,
					
			threadoperation(Pids, Mydata,SegId);


		{Pid, request, Function, Sum, Size} ->
			%io:format("~p Got a request from ~p to calculate ~p. Received sum is ~p. Received size is ~p ~n", [self(),Pid, Function, Sum, Size]),
	      		Pid ! {self(),reply, Function, get("localsum"), get("localsize")},% send a reply message with local values	
			er_calculate ! {self(), Function, get("localsum"), Sum, get("localsize"), Size},
			threadoperation(Pids, Mydata,SegId);	
	      	  
		{Pid, request, Function, Value} ->
			%io:format("~p Received a reply from ~p with its local values: ~p ~p  ~n", [self(), Pid, Sum, Size]),
			case Function of
				min ->
				%io:format("Value is : ~p  ~n", [Value]),
				%io:format("Self value : ~p  ~n", [get("Function")]) ,
				%io:format("er_calc ~p  ~n", [whereis(er_calculate)]),
				
					whereis(er_calculate) ! {self(), Function, get("Function"), Value},
					Pid ! {self(), reply, Function, get("Function")};
				max ->
					er_calculate ! {self(), Function, get("Function"), Value},
					Pid ! {self(), reply, Function, get("Function")}
			end,
			%io:format("~p: New local sum  is ~p. New local Size is ~p ~n ", [ self(), get("localsum"), get("localsize")]), 
			threadoperation(Pids, Mydata,SegId);

		{Pid, reply, Function, Sum, Size} ->
			%io:format("~p Received a reply from ~p with its local values: ~p ~p  ~n", [self(), Pid, Sum, Size]),
			er_calculate ! {self(), Function, get("localsum"), Sum, get("localsize"),Size},
			%io:format("~p: New local sum  is ~p. New local Size is ~p ~n ", [ self(), get("localsum"), get("localsize")]), 
			threadoperation(Pids, Mydata,SegId);
		{Pid, reply, Function, Value} ->
			case Function of
				min ->
				%io:format("In reply ,Value is : ~p  ~n", [Value]),
				%io:format("In reply :Self value : ~p  ~n", [get("Function")]) ,
				%io:format("er_calculate : ~p  ~n", [whereis(er_calculate)]) ,
				
					whereis(er_calculate) ! {self(), Function, get("Function"), Value};
				max ->
					er_calculate ! {self(), Function, get("Function"), Value}
			end,	
					threadoperation(Pids, Mydata,SegId);
		{update, Function, Value} ->
			erase("Function"),
			put("Function", Value),
			threadoperation(Pids, Mydata,SegId);
		{update, Function, localsum, SumValue, localsize, SizeValue} ->
			erase("localsum"),
			put("localsum", SumValue),
			erase("localsize"),
			put("localsize", SizeValue),
			threadoperation(Pids, Mydata,SegId);
		{timer, Function} ->
			io:format("~p Started processing....",[self()]),
			self() ! {calculate, Function},
			timer:send_after(100,self(), {timer, Function}),
			threadoperation(Pids, Mydata,SegId)
				
			 
				     					
	end.


calculate() ->
	  	io:format("Received start ~n"),
receive
	%start ->
	  %    io:format("Received start ~n");
	{Pid_proc, Function,Value1, Value2} ->
		io:format(" Received message from ~p. Function is ~p. Data is ~p ~p~n", [Pid_proc, Function, Value1, Value2]),
		case Function of 
	  	  min -> 
		     	 Min = erlang:min(Value1, Value2), 	 
			 io:format("Minimum value at ~p is ~p ~n", [Pid_proc, Min]),
			 Pid_proc ! {update, Function, Min},
			 calculate();
	   	  max -> 
		        Max = erlang:max(Value1, Value2),
		        io:format("Maximum value at ~p is ~p ~n", [Pid_proc, Max]),
			Pid_proc ! {update, Function, Max},
			calculate()
		  end;
	{Pid_proc, Function, Sum1, Sum2, Size1, Size2} ->
		case Function of 
		 average ->
			Sum = Sum1 + Sum2,
			Size = Size1 + Size2,
			Pid_proc ! {update,Function, localsum, Sum, localsize, Size},
			calculate()
		end,	
		  
	calculate()
	end.



     
     
     
    
    
    

