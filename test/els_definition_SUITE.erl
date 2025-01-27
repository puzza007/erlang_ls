%%==============================================================================
%% Unit Tests for Code Navigation
%%==============================================================================
-module(els_definition_SUITE).

%% CT Callbacks
-export([ all/0
        , init_per_suite/1
        , end_per_suite/1
        , init_per_testcase/2
        , end_per_testcase/2
        , groups/0
        , suite/0
        ]).

%% Test cases
-export([ application_local/1
        , application_remote/1
        , behaviour/1
        , definition_after_closing/1
        , duplicate_definition/1
        , export_entry/1
        , fun_local/1
        , fun_remote/1
        , import_entry/1
        , include/1
        , include_lib/1
        , macro/1
        , macro_lowercase/1
        , macro_included/1
        , macro_with_args/1
        , macro_with_args_included/1
        , record_access/1
        , record_access_included/1
        , record_expr/1
        , record_expr_included/1
        , type_application/1
        ]).

%%==============================================================================
%% Includes
%%==============================================================================
-include_lib("common_test/include/ct.hrl").
-include_lib("stdlib/include/assert.hrl").

%%==============================================================================
%% Types
%%==============================================================================
-type config() :: [{atom(), any()}].

%%==============================================================================
%% CT Callbacks
%%==============================================================================
-spec all() -> [atom()].
all() ->
  [{group, tcp}, {group, stdio}].

-spec groups() -> [atom()].
groups() ->
  els_test_utils:groups(?MODULE).

-spec init_per_suite(config()) -> config().
init_per_suite(Config) ->
  els_test_utils:init_per_suite(Config).

-spec end_per_suite(config()) -> ok.
end_per_suite(Config) ->
  els_test_utils:end_per_suite(Config).

-spec init_per_testcase(atom(), config()) -> config().
init_per_testcase(TestCase, Config) ->
  els_test_utils:init_per_testcase(TestCase, Config).

-spec end_per_testcase(atom(), config()) -> ok.
end_per_testcase(TestCase, Config) ->
  els_test_utils:end_per_testcase(TestCase, Config).

-spec suite() -> [tuple()].
suite() ->
  [{timetrap, {seconds, 30}}].

%%==============================================================================
%% Testcases
%%==============================================================================
-spec application_local(config()) -> ok.
application_local(Config) ->
  Uri = ?config(code_navigation_uri, Config),
  Def = els_client:definition(Uri, 22, 5),
  #{result := #{range := Range, uri := DefUri}} = Def,
  ?assertEqual(Uri, DefUri),
  ?assertEqual( els_protocol:range(#{from => {25, 1}, to => {25, 11}})
              , Range),
  ok.

-spec application_remote(config()) -> ok.
application_remote(Config) ->
  Uri = ?config(code_navigation_uri, Config),
  Def = els_client:definition(Uri, 32, 13),
  #{result := #{range := Range, uri := DefUri}} = Def,
  ?assertEqual(?config(code_navigation_extra_uri, Config), DefUri),
  ?assertEqual( els_protocol:range(#{from => {5, 1}, to => {5, 3}})
              , Range),
  ok.

-spec behaviour(config()) -> ok.
behaviour(Config) ->
  Uri = ?config(code_navigation_uri, Config),
  Def = els_client:definition(Uri, 3, 16),
  #{result := #{range := Range, uri := DefUri}} = Def,
  ?assertEqual(?config(behaviour_uri, Config), DefUri),
  ?assertEqual( els_protocol:range(#{from => {1, 2}, to => {1, 2}})
              , Range),
  ok.

%% Issue #191: Definition not found after document is closed
-spec definition_after_closing(config()) -> ok.
definition_after_closing(Config) ->
  Uri      = ?config(code_navigation_uri, Config),
  ExtraUri = ?config(code_navigation_extra_uri, Config),
  Def      = els_client:definition(Uri, 32, 13),
  #{result := #{range := Range, uri := DefUri}} = Def,
  ?assertEqual(ExtraUri, DefUri),
  ?assertEqual( els_protocol:range(#{from => {5, 1}, to => {5, 3}})
              , Range),

  %% Close file, get definition
  ok   = els_client:did_close(ExtraUri),
  Def1 = els_client:definition(Uri, 32, 13),
  #{result := #{range := Range, uri := DefUri}} = Def1,
  ok.

-spec duplicate_definition(config()) -> ok.
duplicate_definition(Config) ->
  Uri = ?config(code_navigation_uri, Config),
  Def = els_client:definition(Uri, 57, 5),
  #{result := #{range := Range, uri := DefUri}} = Def,
  ?assertEqual(Uri, DefUri),
  ?assertEqual( els_protocol:range(#{from => {60, 1}, to => {60, 11}})
              , Range),
  ok.

-spec export_entry(config()) -> ok.
export_entry(Config) ->
  Uri = ?config(code_navigation_uri, Config),
  Def = els_client:definition(Uri, 8, 15),
  #{result := #{range := Range, uri := DefUri}} = Def,
  ?assertEqual(Uri, DefUri),
  ?assertEqual( els_protocol:range(#{from => {28, 1}, to => {28, 11}})
              , Range),
  ok.

-spec fun_local(config()) -> ok.
fun_local(Config) ->
  Uri = ?config(code_navigation_uri, Config),
  Def = els_client:definition(Uri, 51, 16),
  #{result := #{range := Range, uri := DefUri}} = Def,
  ?assertEqual(Uri, DefUri),
  ?assertEqual( els_protocol:range(#{from => {25, 1}, to => {25, 11}})
              , Range),
  ok.

-spec fun_remote(config()) -> ok.
fun_remote(Config) ->
  Uri = ?config(code_navigation_uri, Config),
  Def = els_client:definition(Uri, 52, 14),
  #{result := #{range := Range, uri := DefUri}} = Def,
  ?assertEqual(?config(code_navigation_extra_uri, Config), DefUri),
  ?assertEqual( els_protocol:range(#{from => {5, 1}, to => {5, 3}})
              , Range),
  ok.

-spec import_entry(config()) -> ok.
import_entry(Config) ->
  Uri = ?config(code_navigation_uri, Config),
  Def = els_client:definition(Uri, 10, 34),
  #{result := #{range := Range, uri := DefUri}} = Def,
  ?assertEqual(?config(code_navigation_extra_uri, Config), DefUri),
  ?assertEqual( els_protocol:range(#{from => {5, 1}, to => {5, 3}})
              , Range),
  ok.

-spec include(config()) -> ok.
include(Config) ->
  Uri = ?config(code_navigation_uri, Config),
  Def = els_client:definition(Uri, 12, 20),
  #{result := #{range := Range, uri := DefUri}} = Def,
  ?assertEqual(?config(include_uri, Config), DefUri),
  ?assertEqual( els_protocol:range(#{from => {1, 1}, to => {1, 1}})
              , Range),
  ok.

-spec include_lib(config()) -> ok.
include_lib(Config) ->
  Uri = ?config(code_navigation_uri, Config),
  Def = els_client:definition(Uri, 13, 22),
  #{result := #{range := Range, uri := DefUri}} = Def,
  ?assertEqual(?config(include_uri, Config), DefUri),
  ?assertEqual( els_protocol:range(#{from => {1, 1}, to => {1, 1}})
              , Range),
  ok.

-spec macro(config()) -> ok.
macro(Config) ->
  Uri = ?config(code_navigation_uri, Config),
  Def = els_client:definition(Uri, 26, 5),
  #{result := #{range := Range, uri := DefUri}} = Def,
  ?assertEqual(Uri, DefUri),
  ?assertEqual( els_protocol:range(#{from => {18, 1}, to => {18, 1}})
              , Range),
  ok.

-spec macro_lowercase(config()) -> ok.
macro_lowercase(Config) ->
  Uri = ?config(code_navigation_uri, Config),
  Def = els_client:definition(Uri, 48, 3),
  #{result := #{range := Range, uri := DefUri}} = Def,
  ?assertEqual(Uri, DefUri),
  ?assertEqual( els_protocol:range(#{from => {45, 1}, to => {45, 1}})
              , Range),
  ok.

-spec macro_included(config()) -> ok.
macro_included(Config) ->
  Uri = ?config(code_navigation_uri, Config),
  Def = els_client:definition(Uri, 53, 19),
  #{result := #{range := Range, uri := DefUri}} = Def,
  ?assertEqual(?config(include_uri, Config), DefUri),
  ?assertEqual( els_protocol:range(#{from => {3, 1}, to => {3, 1}})
              , Range),
  ok.

-spec macro_with_args(config()) -> ok.
macro_with_args(Config) ->
  Uri = ?config(code_navigation_uri, Config),
  Def = els_client:definition(Uri, 40, 9),
  #{result := #{range := Range, uri := DefUri}} = Def,
  ?assertEqual(Uri, DefUri),
  ?assertEqual( els_protocol:range(#{from => {19, 1}, to => {19, 1}})
              , Range),
  ok.

-spec macro_with_args_included(config()) -> ok.
macro_with_args_included(Config) ->
  Uri = ?config(code_navigation_uri, Config),
  Def = els_client:definition(Uri, 43, 9),
  #{result := #{uri := DefUri}} = Def,
  ?assertEqual( <<"assert.hrl">>
              , filename:basename(els_uri:path(DefUri))),
  %% Do not assert on line number to avoid binding to a specific OTP version
  ok.

-spec record_access(config()) -> ok.
record_access(Config) ->
  Uri = ?config(code_navigation_uri, Config),
  Def = els_client:definition(Uri, 33, 11),
  #{result := #{range := Range, uri := DefUri}} = Def,
  ?assertEqual(Uri, DefUri),
  ?assertEqual( els_protocol:range(#{from => {16, 1}, to => {16, 1}})
              , Range),
  ok.

-spec record_access_included(config()) -> ok.
record_access_included(Config) ->
  Uri = ?config(code_navigation_uri, Config),
  Def = els_client:definition(Uri, 53, 30),
  #{result := #{range := Range, uri := DefUri}} = Def,
  ?assertEqual(?config(include_uri, Config), DefUri),
  ?assertEqual( els_protocol:range(#{from => {1, 1}, to => {1, 1}})
              , Range),
  ok.

%% TODO: Additional constructors for POI
%% TODO: Navigation should return POI, not range
-spec record_expr(config()) -> ok.
record_expr(Config) ->
  Uri = ?config(code_navigation_uri, Config),
  Def = els_client:definition(Uri, 34, 13),
  #{result := #{range := Range, uri := DefUri}} = Def,
  ?assertEqual(Uri, DefUri),
  ?assertEqual( els_protocol:range(#{from => {16, 1}, to => {16, 1}})
              , Range),
  ok.

-spec record_expr_included(config()) -> ok.
record_expr_included(Config) ->
  Uri = ?config(code_navigation_uri, Config),
  Def = els_client:definition(Uri, 52, 43),
  #{result := #{range := Range, uri := DefUri}} = Def,
  ?assertEqual(?config(include_uri, Config), DefUri),
  ?assertEqual( els_protocol:range(#{from => {1, 1}, to => {1, 1}})
              , Range),
  ok.

-spec type_application(config()) -> ok.
type_application(Config) ->
  Uri = ?config(code_navigation_uri, Config),
  Def = els_client:definition(Uri, 55, 25),
  #{result := #{range := Range, uri := DefUri}} = Def,
  ?assertEqual(Uri, DefUri),
  ?assertEqual( els_protocol:range(#{from => {37, 2}, to => {37, 2}})
              , Range),
  ok.
