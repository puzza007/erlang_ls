%%==============================================================================
%% Code Navigation
%%==============================================================================
-module(els_code_navigation).

%%==============================================================================
%% Exports
%%==============================================================================

%% API
-export([ goto_definition/2 ]).

%%==============================================================================
%% Includes
%%==============================================================================
-include("erlang_ls.hrl").

%%==============================================================================
%% API
%%==============================================================================

-spec goto_definition(uri(), poi()) ->
   {ok, uri(), poi()} | {error, any()}.
goto_definition( _Uri
               , #{ kind := Kind, data := {M, F, A} }
               ) when Kind =:= application;
                      Kind =:= implicit_fun;
                      Kind =:= import_entry ->
  case els_utils:find_module(M) of
    {ok, Uri}      -> find(Uri, function, {F, A});
    {error, Error} -> {error, Error}
  end;
goto_definition( Uri
               , #{ kind := Kind, data := {F, A}}
               ) when Kind =:= application;
                      Kind =:= implicit_fun;
                      Kind =:= exports_entry ->
  find(Uri, function, {F, A});
goto_definition(_Uri, #{ kind := behaviour, data := Behaviour }) ->
  case els_utils:find_module(Behaviour) of
    {ok, Uri}      -> find(Uri, module, Behaviour);
    {error, Error} -> {error, Error}
  end;
goto_definition(Uri, #{ kind := macro, data := Define }) ->
  find(Uri, define, Define);
goto_definition(Uri, #{ kind := record_access
                      , data := {Record, _}}) ->
  find(Uri, record, Record);
goto_definition(Uri, #{ kind := record_expr, data := Record }) ->
  find(Uri, record, Record);
goto_definition(_Uri, #{ kind := Kind, data := Include }
               ) when Kind =:= include;
                      Kind =:= include_lib ->
  %% TODO: Index header definitions as well
  FileName = filename:basename(Include),
  M = list_to_atom(FileName),
  case els_utils:find_module(M) of
    {ok, Uri}      -> {ok, Uri, beginning()};
    {error, Error} -> {error, Error}
  end;
goto_definition(Uri, #{ kind := type_application, data := {Type, _} }) ->
  find(Uri, type_definition, Type);
goto_definition(_Filename, _) ->
  {error, not_found}.

-spec find(uri() | [uri()], poi_kind(), any()) ->
   {ok, uri(), poi()} | {error, not_found}.
find([], _Kind, _Data) ->
  {error, not_found};
find([Uri|Uris0], Kind, Data) ->
  case els_db:find(documents, Uri) of
    {ok, Document} ->
      POIs = els_document:points_of_interest(Document, [Kind], Data),
      case POIs of
        [] ->
          find(lists:usort(include_uris(Document) ++ Uris0), Kind, Data);
        Definitions ->
          {ok, Uri, lists:last(Definitions)}
      end;
    {error, not_found} ->
      find(Uris0, Kind, Data)
  end;
find(Uri, Kind, Data) ->
  find([Uri], Kind, Data).

-spec include_uris(els_document:document()) -> [uri()].
include_uris(Document) ->
  POIs = els_document:points_of_interest( Document
                                              , [include, include_lib]),
  lists:foldl(fun add_include_uri/2, [], POIs).

-spec add_include_uri(poi(), [uri()]) -> [uri()].
add_include_uri(#{ data := String }, Acc) ->
  FileName = filename:basename(String),
  M = list_to_atom(FileName),
  case els_utils:find_module(M, hrl) of
    {ok, Uri}       -> [Uri | Acc];
    {error, _Error} -> Acc
  end.

-spec beginning() -> #{range => #{from => {1, 1}, to => {1, 1}}}.
beginning() ->
  #{range => #{from => {1, 1}, to => {1, 1}}}.

%% TODO: Handle multiple header files with the same name?
