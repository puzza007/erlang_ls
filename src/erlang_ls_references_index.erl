-module(erlang_ls_references_index).

-behaviour(erlang_ls_index).

-compile({no_auto_import, [get/1]}).

-export([ index/1
        , setup/0
        ]).

-export([get/2]).

-type key() :: {module(), atom()}.
-type ref() :: #{uri := erlang_ls_uri:uri(), range := erlang_ls_poi:range()}.

-export_type([key/0]).

%%==============================================================================
%% erlang_ls_index functions
%%==============================================================================

-spec setup() -> ok.
setup() ->
  ok.

-spec index(erlang_ls_document:document()) -> ok.
index(Document) ->
  Uri  = erlang_ls_document:uri(Document),
  POIs = erlang_ls_document:points_of_interest(Document),
  [register_usage(Uri, POI) || POI <- POIs],
  ok.

%%==============================================================================
%% External functions
%%==============================================================================

-spec get(erlang_ls_uri:uri(), erlang_ls_poi:poi()) -> [ref()].
get(Uri, #{info := {Type, MFA}})
  when Type =:= application; Type =:= implicit_fun; Type =:= function ->
  Key = key(Uri, MFA),
  ordsets:to_list(get(Key));
get(_, _) ->
  [].

%%==============================================================================
%% Internal functions
%%==============================================================================

-spec register_usage(erlang_ls_uri:uri(), erlang_ls_poi:poi()) -> ok.
register_usage(Uri, #{info := {Type, MFA}, range := Range})
  when Type =:= application; Type =:= implicit_fun ->
  Key = key(Uri, MFA),
  Ref = #{uri => Uri, range => Range},
  add(Key, Ref),
  ok;
register_usage(_File, _POI) ->
  ok.

-spec get(key()) -> ordsets:ordset(ref()).
get(Key) ->
  case erlang_ls_db:find(references_index, Key) of
    not_found  -> ordsets:new();
    {ok, Refs} -> Refs
  end.

-spec add(key(), ref()) -> ok.
add(Key, Value) ->
  Refs = ordsets:add_element(Value, get(Key)),
  ok = erlang_ls_db:store(references_index, Key, Refs).

-spec key(erlang_ls_uri:uri(), {module(), atom(), arity()} | {atom(), arity()}) ->
  key().
key(_Uri, {M, F, _A}) ->
  {M, F};
key(Uri, {F, _A}) ->
  Module = erlang_ls_uri:module(Uri),
  {Module, F}.