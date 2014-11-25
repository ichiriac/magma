
inner_statement:
    function_declaration_statement        { /* inner_statement */ $$ = $1; }
  | class_declaration_statement           { /* inner_statement */ $$ = $1; }
  | T_HALT_COMPILER '(' ')' ';'           { /* inner_statement */ this.compile_error("__HALT_COMPILER() can only be used from the outermost scope"); }
  | statement                             { /* inner_statement */ $$ = $1; }
;


statement:
    '{' inner_statement* '}'          { /* statement */ $$ = $2; }
  | T_IF parenthesis_expr 
      statement 
      elseif_list 
      else_single                         { /* statement */ $$ = ['if', $2, $3, $4, $5]; }
  | T_IF parenthesis_expr ':' 
    inner_statement* 
    new_elseif_list 
    new_else_single 
    T_ENDIF ';'                           { $$ = ['if', $2, $4, $5, $6]; }
  | T_WHILE parenthesis_expr 
    while_statement                       { $$ = ['while', $2, $3]; }
  | T_DO statement 
    T_WHILE parenthesis_expr ';'          { $$ = ['do', $4, $2]; }
  | T_FOR '(' 
    for_expr ';' 
    for_expr ';' 
    for_expr ')' for_statement            { $$ = ['for', $3, $5, $7, $9]; }
  | T_SWITCH 
    parenthesis_expr 
    switch_case_list                      { $$ = ['switch', $2, $3]; }
  | T_BREAK ';'                           { $$ = ['break', null]; }
  | T_BREAK expr ';'                      { $$ = ['break', $2]; }
  | T_CONTINUE ';'                        { $$ = ['continue', null]; }
  | T_CONTINUE expr ';'                   { $$ = ['continue', $2]; }
  | T_RETURN ';'                          { $$ = ['return', null]; }
  | T_RETURN expr ';'                     { $$ = ['return', $2]; }
  | yield_expr ';'                        { $$ = ['yield', $1]; }
  | T_GLOBAL global_var_list ';'          { $$ = ['global', $2]; }
  | T_STATIC static_var_list ';'          { $$ = ['static', $2]; }
  | T_ECHO echo_expr_list ';'             { $$ = ['call', 'echo', $2]; }
  | T_INLINE_HTML                         { $$ = ['call', 'echo', [['string', $1]]]; }
  | expr ';'                              { $$ = $1; }
  | T_UNSET '(' unset_variables ')' ';'   { $$ = ['call', 'unset', $3]; }
  | T_FOREACH 
    '(' 
      variable T_AS foreach_variable 
      foreach_optional_arg 
    ')' foreach_statement                 {
      $$ = {
        type: 'common.T_FOREACH',
        source: $3,
        item: $5,
        alias: $6,
        statement: $8
      };
    }
  | T_FOREACH 
    '(' 
      expr_without_variable T_AS foreach_variable 
      foreach_optional_arg 
    ')' foreach_statement                 { $$ = ['foreach', $3, $5, $6, $8]; }
  | T_DECLARE '(' declare_list ')' 
    declare_statement                     { $$ = ['declare', $3, $5]; }
  | ';' /* empty statement */             { $$ = false; }
  | T_TRY '{' inner_statement* '}' 
    catch_statement 
    finally_statement                     { $$ = ['try', $3, $5, $6]; }
  | T_THROW expr ';'                      { $$ = ['throw', $2]; }
  | T_GOTO T_STRING ';'                   { this.compile_error("LABELS and GOTO statements are not supported"); }
  | T_STRING ':'                          { /* statement */ this.compile_error("LABELS and GOTO statements are not supported"); }
;


catch_statement:
    /* empty */                                   { /* catch_statement */ $$ = false; }
  | additional_catch additional_catches           { /* catch_statement */
    if ($2) {
      $$ = $2; $2.unshift($1);
    } else {
      $$ = [$1];
    }
  }
;

finally_statement:
    T_FINALLY '{' inner_statement* '}'        { /* finally_statement */ $$ = $3; }
  | /* empty */                                   { /* finally_statement */ $$ = false; }
;

additional_catches:
    non_empty_additional_catches                  { /* additional_catches */ $$ = $1; }
  | /* empty */                                   { /* additional_catches */ $$ = false; }
;

non_empty_additional_catches:
    non_empty_additional_catches additional_catch     { $$ = $1; $1.push($2); }
  | additional_catch                                  { $$ = [$1]; }
;

additional_catch:
  T_CATCH '(' 
    fully_qualified_class_name const_variable 
  ')' '{' 
    inner_statement* 
  '}'                                                 { /* additional_catch */ $$ = ['catch', $3, $4, $7]; }
;

unset_variables:
    unset_variables ',' unset_variable                { /* unset_variables */ $$ = $1; $1.push($3); }
  | unset_variable                                    { /* unset_variables */ $$ = [$1]; }
;

unset_variable:
  variable                                        { $$ = $1; }
;

declare_statement:
    statement                                     { $$ = [$1]; }
  | ':' inner_statement* T_ENDDECLARE ';'     { $$ = $2; }
;


declare_list:
    T_STRING '=' static_scalar                    { $$ = [[$1, $3]]; }
  | declare_list ',' 
    T_STRING '=' static_scalar                    { $$ = $1; $1.push([$3, $5]); }
;


assignment_list:
  assignment_list_element                         { $$ = [$1]; }
  | assignment_list ',' assignment_list_element   { $$ = $1; $1.push($3); }
;

assignment_list_element:
    variable                                      { $$ = $1; }
  | T_LIST '('  assignment_list ')'               { $$ = ['list', $3]; }
;