-module(util).
-export([sum/1,sum/2,len/1,minimum/1,maximum/1]).


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



