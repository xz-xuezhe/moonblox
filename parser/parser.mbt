
pub(all) enum Token {
  IDENT(String)
  STRING(String)
  NUMBER(Double)
  BOOL(Bool)
  LPAREN
  RPAREN
  LBRACKET
  RBRACKET
  LBRACE
  RBRACE
  COLON
  COMMA
} derive(Debug, Eq)

pub fn Token::kind(self : Token) -> TokenKind {
  match self {
    IDENT(_) => TK_IDENT
    STRING(_) => TK_STRING
    NUMBER(_) => TK_NUMBER
    BOOL(_) => TK_BOOL
    LPAREN => TK_LPAREN
    RPAREN => TK_RPAREN
    LBRACKET => TK_LBRACKET
    RBRACKET => TK_RBRACKET
    LBRACE => TK_LBRACE
    RBRACE => TK_RBRACE
    COLON => TK_COLON
    COMMA => TK_COMMA
  }
}

pub(all) enum TokenKind {
  TK_IDENT
  TK_STRING
  TK_NUMBER
  TK_BOOL
  TK_LPAREN
  TK_RPAREN
  TK_LBRACKET
  TK_RBRACKET
  TK_LBRACE
  TK_RBRACE
  TK_COLON
  TK_COMMA
}

pub impl Show for TokenKind with output(self, logger) {
  logger.write_string(
    match self {
      TK_IDENT => "IDENT"
      TK_STRING => "STRING"
      TK_NUMBER => "NUMBER"
      TK_BOOL => "BOOL"
      TK_LPAREN => "\"(\""
      TK_RPAREN => "\")\""
      TK_LBRACKET => "\"[\""
      TK_RBRACKET => "\"]\""
      TK_LBRACE => "\"{\""
      TK_RBRACE => "\"}\""
      TK_COLON => "\":\""
      TK_COMMA => "\",\""
    }
  )
}

pub impl Debug for TokenKind with to_repr(self) {
    match self {
      TK_IDENT => to_repr("IDENT")
      TK_STRING => to_repr("STRING")
      TK_NUMBER => to_repr("NUMBER")
      TK_BOOL => to_repr("BOOL")
      TK_LPAREN => to_repr("(")
      TK_RPAREN => to_repr(")")
      TK_LBRACKET => to_repr("[")
      TK_RBRACKET => to_repr("]")
      TK_LBRACE => to_repr("{")
      TK_RBRACE => to_repr("}")
      TK_COLON => to_repr(":")
      TK_COMMA => to_repr(",")
    }
}

pub suberror ParseError {
  UnexpectedToken(Token, (Int, Int), Array[TokenKind])
  UnexpectedEndOfInput(Int, Array[TokenKind])
} derive(Debug)

type YYObj = Error

priv suberror YYObj_Void

priv suberror YYObj_Map_String___ast_Value_ {
  YYObj_Map_String___ast_Value_(Map[String, @ast.Value])
}

priv suberror YYObj_Bool {
  YYObj_Bool(Bool)
}

priv suberror YYObj_Array__ast_Value_ {
  YYObj_Array__ast_Value_(Array[@ast.Value])
}

priv suberror YYObj_Array__String___ast_Value__ {
  YYObj_Array__String___ast_Value__(Array[(String, @ast.Value)])
}

priv suberror YYObj_Double {
  YYObj_Double(Double)
}

priv suberror YYObj_String {
  YYObj_String(String)
}

priv suberror YYObj__ast_Value {
  YYObj__ast_Value(@ast.Value)
}

priv suberror YYObj__String__Map_String___ast_Value__ {
  YYObj__String__Map_String___ast_Value__((String, Map[String, @ast.Value]))
}

priv suberror YYObj__String___ast_Value_ {
  YYObj__String___ast_Value_((String, @ast.Value))
}

type YYState = (YYSymbol) -> YYDecision

type YYAction = (Int, ArrayView[(YYObj, Int, Int)]) -> YYObj

priv enum YYDecision {
  Accept
  Shift(YYState)
  Reduce(Int, YYSymbol, YYAction)
  ReduceNoLookahead(Int, YYSymbol, YYAction)
  Error
}

priv enum YYSymbol {
  T_IDENT
  T_STRING
  T_NUMBER
  T_BOOL
  T_LPAREN
  T_RPAREN
  T_LBRACKET
  T_RBRACKET
  T_LBRACE
  T_RBRACE
  T_COLON
  T_COMMA
  NT_directive
  NT_args_opt
  NT_args
  NT_arg
  NT_value
  NT_array
  NT_values
  NT_record
  NT_record_fields
  NT_record_field
  EOI
}

// Workaround for EOI unused warning
fn init {
  match (EOI : YYSymbol) {
    EOI => ()
    _ => ()
  }
}

// file:///./parser.mbty
// 34|    name=IDENT LPAREN args=args_opt RPAREN { (name, args) }
fn yy_action_0(_last_pos : Int, _args : ArrayView[(YYObj, Int, Int)]) -> YYObj {
  guard _args[0].0 is YYObj_String(name)
  guard _args[2].0 is YYObj_Map_String___ast_Value_(args)
  YYObj__String__Map_String___ast_Value__({();  (name, args) })
}

// file:///./parser.mbty
// 73|    LBRACE RBRACE { Map([]) }
fn yy_action_1(_last_pos : Int, _args : ArrayView[(YYObj, Int, Int)]) -> YYObj {
  YYObj_Map_String___ast_Value_({();  Map([]) })
}

// file:///./parser.mbty
// 74|    LBRACE fields=record_fields RBRACE {
// 75|    let map : Map[String, @ast.Value] = Map([])
// 76|    for i = 0; i < fields.length(); i = i + 1 { map.set(fields[i].0, fields[i].1) }
// 77|    map
// 78|  }
fn yy_action_2(_last_pos : Int, _args : ArrayView[(YYObj, Int, Int)]) -> YYObj {
  guard _args[1].0 is YYObj_Array__String___ast_Value__(fields)
  YYObj_Map_String___ast_Value_({(); 
    let map : Map[String, @ast.Value] = Map([])
    for i = 0; i < fields.length(); i = i + 1 { map.set(fields[i].0, fields[i].1) }
    map
  })
}

// file:///./parser.mbty
// 82|    f=record_field COMMA rest=record_fields {
// 83|    let arr : Array[(String, @ast.Value)] = [f]
// 84|    for i = 0; i < rest.length(); i = i + 1 { arr.push(rest[i]) }
// 85|    arr
// 86|  }
fn yy_action_3(_last_pos : Int, _args : ArrayView[(YYObj, Int, Int)]) -> YYObj {
  guard _args[0].0 is YYObj__String___ast_Value_(f)
  guard _args[2].0 is YYObj_Array__String___ast_Value__(rest)
  YYObj_Array__String___ast_Value__({(); 
    let arr : Array[(String, @ast.Value)] = [f]
    for i = 0; i < rest.length(); i = i + 1 { arr.push(rest[i]) }
    arr
  })
}

// file:///./parser.mbty
// 81|    f=record_field { [f] }
fn yy_action_4(_last_pos : Int, _args : ArrayView[(YYObj, Int, Int)]) -> YYObj {
  guard _args[0].0 is YYObj__String___ast_Value_(f)
  YYObj_Array__String___ast_Value__({();  [f] })
}

// file:///./parser.mbty
// 61|    LBRACKET RBRACKET { [] }
fn yy_action_5(_last_pos : Int, _args : ArrayView[(YYObj, Int, Int)]) -> YYObj {
  YYObj_Array__ast_Value_({();  [] })
}

// file:///./parser.mbty
// 62|    LBRACKET vals=values RBRACKET { vals }
fn yy_action_6(_last_pos : Int, _args : ArrayView[(YYObj, Int, Int)]) -> YYObj {
  guard _args[1].0 is YYObj_Array__ast_Value_(vals)
  YYObj_Array__ast_Value_({();  vals })
}

// file:///./parser.mbty
// 38|    args=args { args }
fn yy_action_7(_last_pos : Int, _args : ArrayView[(YYObj, Int, Int)]) -> YYObj {
  guard _args[0].0 is YYObj_Map_String___ast_Value_(args)
  YYObj_Map_String___ast_Value_({();  args })
}

// file:///./parser.mbty
// 43|    a=arg COMMA rest=args { rest.set(a.0, a.1); rest }
fn yy_action_8(_last_pos : Int, _args : ArrayView[(YYObj, Int, Int)]) -> YYObj {
  guard _args[0].0 is YYObj__String___ast_Value_(a)
  guard _args[2].0 is YYObj_Map_String___ast_Value_(rest)
  YYObj_Map_String___ast_Value_({();  rest.set(a.0, a.1); rest })
}

// file:///./parser.mbty
// 42|    a=arg COMMA { let map : Map[String, @ast.Value] = Map([]); map.set(a.0, a.1); map }
fn yy_action_9(_last_pos : Int, _args : ArrayView[(YYObj, Int, Int)]) -> YYObj {
  guard _args[0].0 is YYObj__String___ast_Value_(a)
  YYObj_Map_String___ast_Value_({();  let map : Map[String, @ast.Value] = Map([]); map.set(a.0, a.1); map })
}

// file:///./parser.mbty
// 41|    a=arg { let map : Map[String, @ast.Value] = Map([]); map.set(a.0, a.1); map }
fn yy_action_10(_last_pos : Int, _args : ArrayView[(YYObj, Int, Int)]) -> YYObj {
  guard _args[0].0 is YYObj__String___ast_Value_(a)
  YYObj_Map_String___ast_Value_({();  let map : Map[String, @ast.Value] = Map([]); map.set(a.0, a.1); map })
}

// file:///./parser.mbty
// 46|    key=IDENT COLON val=value { (key, val) }
fn yy_action_11(_last_pos : Int, _args : ArrayView[(YYObj, Int, Int)]) -> YYObj {
  guard _args[0].0 is YYObj_String(key)
  guard _args[2].0 is YYObj__ast_Value(val)
  YYObj__String___ast_Value_({();  (key, val) })
}

// file:///./parser.mbty
// 47|    val=value { ("_", val) }
fn yy_action_12(_last_pos : Int, _args : ArrayView[(YYObj, Int, Int)]) -> YYObj {
  guard _args[0].0 is YYObj__ast_Value(val)
  YYObj__String___ast_Value_({();  ("_", val) })
}

// file:///./parser.mbty
// 50|    s=STRING { @ast.Value::Str(s) }
fn yy_action_13(_last_pos : Int, _args : ArrayView[(YYObj, Int, Int)]) -> YYObj {
  guard _args[0].0 is YYObj_String(s)
  YYObj__ast_Value({();  @ast.Value::Str(s) })
}

// file:///./parser.mbty
// 51|    n=NUMBER { @ast.Value::Number(n) }
fn yy_action_14(_last_pos : Int, _args : ArrayView[(YYObj, Int, Int)]) -> YYObj {
  guard _args[0].0 is YYObj_Double(n)
  YYObj__ast_Value({();  @ast.Value::Number(n) })
}

// file:///./parser.mbty
// 52|    b=BOOL { @ast.Value::Bool(b) }
fn yy_action_15(_last_pos : Int, _args : ArrayView[(YYObj, Int, Int)]) -> YYObj {
  guard _args[0].0 is YYObj_Bool(b)
  YYObj__ast_Value({();  @ast.Value::Bool(b) })
}

// file:///./parser.mbty
// 53|    arr=array { @ast.Value::Array(arr) }
fn yy_action_16(_last_pos : Int, _args : ArrayView[(YYObj, Int, Int)]) -> YYObj {
  guard _args[0].0 is YYObj_Array__ast_Value_(arr)
  YYObj__ast_Value({();  @ast.Value::Array(arr) })
}

// file:///./parser.mbty
// 54|    rec=record { @ast.Value::Record(rec) }
fn yy_action_17(_last_pos : Int, _args : ArrayView[(YYObj, Int, Int)]) -> YYObj {
  guard _args[0].0 is YYObj_Map_String___ast_Value_(rec)
  YYObj__ast_Value({();  @ast.Value::Record(rec) })
}

// file:///./parser.mbty
// 55|    name=IDENT LPAREN args=args_opt RPAREN {
// 56|    @ast.Value::Funcall(name, args)
// 57|  }
fn yy_action_18(_last_pos : Int, _args : ArrayView[(YYObj, Int, Int)]) -> YYObj {
  guard _args[0].0 is YYObj_String(name)
  guard _args[2].0 is YYObj_Map_String___ast_Value_(args)
  YYObj__ast_Value({(); 
    @ast.Value::Funcall(name, args)
  })
}

// file:///./parser.mbty
// 58|    name=IDENT { @ast.Value::Var(name) }
fn yy_action_19(_last_pos : Int, _args : ArrayView[(YYObj, Int, Int)]) -> YYObj {
  guard _args[0].0 is YYObj_String(name)
  YYObj__ast_Value({();  @ast.Value::Var(name) })
}

// file:///./parser.mbty
// 66|    v=value COMMA rest=values {
// 67|    let arr : Array[@ast.Value] = [v]
// 68|    for i = 0; i < rest.length(); i = i + 1 { arr.push(rest[i]) }
// 69|    arr
// 70|  }
fn yy_action_20(_last_pos : Int, _args : ArrayView[(YYObj, Int, Int)]) -> YYObj {
  guard _args[0].0 is YYObj__ast_Value(v)
  guard _args[2].0 is YYObj_Array__ast_Value_(rest)
  YYObj_Array__ast_Value_({(); 
    let arr : Array[@ast.Value] = [v]
    for i = 0; i < rest.length(); i = i + 1 { arr.push(rest[i]) }
    arr
  })
}

// file:///./parser.mbty
// 65|    v=value { [v] }
fn yy_action_21(_last_pos : Int, _args : ArrayView[(YYObj, Int, Int)]) -> YYObj {
  guard _args[0].0 is YYObj__ast_Value(v)
  YYObj_Array__ast_Value_({();  [v] })
}

// file:///./parser.mbty
// 89|    key=IDENT COLON val=value { (key, val) }
fn yy_action_22(_last_pos : Int, _args : ArrayView[(YYObj, Int, Int)]) -> YYObj {
  guard _args[0].0 is YYObj_String(key)
  guard _args[2].0 is YYObj__ast_Value(val)
  YYObj__String___ast_Value_({();  (key, val) })
}

// file:///./parser.mbty
// 37|    { Map([]) }
fn yy_action_23(_last_pos : Int, _args : ArrayView[(YYObj, Int, Int)]) -> YYObj {
  YYObj_Map_String___ast_Value_({();  Map([]) })
}

fn yy_input(token : Token, _start_pos : Int, _end_pos : Int) -> (YYSymbol, YYObj) {
  match token {
    IDENT(data) => (T_IDENT, YYObj_String(data))
    STRING(data) => (T_STRING, YYObj_String(data))
    NUMBER(data) => (T_NUMBER, YYObj_Double(data))
    BOOL(data) => (T_BOOL, YYObj_Bool(data))
    LPAREN => (T_LPAREN, YYObj_Void)
    RPAREN => (T_RPAREN, YYObj_Void)
    LBRACKET => (T_LBRACKET, YYObj_Void)
    RBRACKET => (T_RBRACKET, YYObj_Void)
    LBRACE => (T_LBRACE, YYObj_Void)
    RBRACE => (T_RBRACE, YYObj_Void)
    COLON => (T_COLON, YYObj_Void)
    COMMA => (T_COMMA, YYObj_Void)
  }
}

// [0, directive → • IDENT LPAREN args_opt RPAREN, $]
// [24, directive_prime → • directive, $]
fn yy_state_0(_lookahead : YYSymbol) -> YYDecision {
  match _lookahead {
    NT_directive => Shift(yy_state_1)
    T_IDENT => Shift(yy_state_2)
    _ => Error
  }
}

// [24, directive_prime → directive •, $]
fn yy_state_1(_lookahead : YYSymbol) -> YYDecision {
  Accept
}

// [0, directive → IDENT • LPAREN args_opt RPAREN, $]
fn yy_state_2(_lookahead : YYSymbol) -> YYDecision {
  match _lookahead {
    T_LPAREN => Shift(yy_state_3)
    _ => Error
  }
}

// [0, directive → IDENT LPAREN • args_opt RPAREN, $]
// [1, args_opt → •, RPAREN]
// [2, args_opt → • args, RPAREN]
// [3, args → • arg, RPAREN]
// [4, args → • arg COMMA, RPAREN]
// [5, args → • arg COMMA args, RPAREN]
// [6, arg → • IDENT COLON value, RPAREN / COMMA]
// [7, arg → • value, RPAREN / COMMA]
// [8, value → • STRING, RPAREN / COMMA]
// [9, value → • NUMBER, RPAREN / COMMA]
// [10, value → • BOOL, RPAREN / COMMA]
// [11, value → • array, RPAREN / COMMA]
// [12, value → • record, RPAREN / COMMA]
// [13, value → • IDENT LPAREN args_opt RPAREN, RPAREN / COMMA]
// [14, value → • IDENT, RPAREN / COMMA]
// [15, array → • LBRACKET RBRACKET, RPAREN / COMMA]
// [16, array → • LBRACKET values RBRACKET, RPAREN / COMMA]
// [19, record → • LBRACE RBRACE, RPAREN / COMMA]
// [20, record → • LBRACE record_fields RBRACE, RPAREN / COMMA]
fn yy_state_3(_lookahead : YYSymbol) -> YYDecision {
  match _lookahead {
    T_LBRACE => Shift(yy_state_4)
    T_LBRACKET => Shift(yy_state_8)
    NT_record => Shift(yy_state_16)
    NT_array => Shift(yy_state_17)
    T_BOOL => Shift(yy_state_18)
    T_NUMBER => Shift(yy_state_19)
    T_STRING => Shift(yy_state_20)
    NT_value => Shift(yy_state_21)
    T_IDENT => Shift(yy_state_22)
    NT_arg => Shift(yy_state_25)
    NT_args => Shift(yy_state_28)
    NT_args_opt => Shift(yy_state_38)
    T_RPAREN => Reduce(0, NT_args_opt, yy_action_23)
    _ => Error
  }
}

// [19, record → LBRACE • RBRACE, RPAREN / RBRACKET / RBRACE / COMMA]
// [20, record → LBRACE • record_fields RBRACE, RPAREN / RBRACKET / RBRACE / COMMA]
// [21, record_fields → • record_field, RBRACE]
// [22, record_fields → • record_field COMMA record_fields, RBRACE]
// [23, record_field → • IDENT COLON value, RBRACE / COMMA]
fn yy_state_4(_lookahead : YYSymbol) -> YYDecision {
  match _lookahead {
    T_IDENT => Shift(yy_state_5)
    NT_record_field => Shift(yy_state_32)
    NT_record_fields => Shift(yy_state_35)
    T_RBRACE => Shift(yy_state_37)
    _ => Error
  }
}

// [23, record_field → IDENT • COLON value, RBRACE / COMMA]
fn yy_state_5(_lookahead : YYSymbol) -> YYDecision {
  match _lookahead {
    T_COLON => Shift(yy_state_6)
    _ => Error
  }
}

// [8, value → • STRING, RBRACE / COMMA]
// [9, value → • NUMBER, RBRACE / COMMA]
// [10, value → • BOOL, RBRACE / COMMA]
// [11, value → • array, RBRACE / COMMA]
// [12, value → • record, RBRACE / COMMA]
// [13, value → • IDENT LPAREN args_opt RPAREN, RBRACE / COMMA]
// [14, value → • IDENT, RBRACE / COMMA]
// [15, array → • LBRACKET RBRACKET, RBRACE / COMMA]
// [16, array → • LBRACKET values RBRACKET, RBRACE / COMMA]
// [19, record → • LBRACE RBRACE, RBRACE / COMMA]
// [20, record → • LBRACE record_fields RBRACE, RBRACE / COMMA]
// [23, record_field → IDENT COLON • value, RBRACE / COMMA]
fn yy_state_6(_lookahead : YYSymbol) -> YYDecision {
  match _lookahead {
    T_LBRACE => Shift(yy_state_4)
    NT_value => Shift(yy_state_7)
    T_LBRACKET => Shift(yy_state_8)
    T_IDENT => Shift(yy_state_12)
    NT_record => Shift(yy_state_16)
    NT_array => Shift(yy_state_17)
    T_BOOL => Shift(yy_state_18)
    T_NUMBER => Shift(yy_state_19)
    T_STRING => Shift(yy_state_20)
    _ => Error
  }
}

// [23, record_field → IDENT COLON value •, RBRACE / COMMA]
fn yy_state_7(_lookahead : YYSymbol) -> YYDecision {
  ReduceNoLookahead(3, NT_record_field, yy_action_22)
}

// [8, value → • STRING, RBRACKET / COMMA]
// [9, value → • NUMBER, RBRACKET / COMMA]
// [10, value → • BOOL, RBRACKET / COMMA]
// [11, value → • array, RBRACKET / COMMA]
// [12, value → • record, RBRACKET / COMMA]
// [13, value → • IDENT LPAREN args_opt RPAREN, RBRACKET / COMMA]
// [14, value → • IDENT, RBRACKET / COMMA]
// [15, array → • LBRACKET RBRACKET, RBRACKET / COMMA]
// [15, array → LBRACKET • RBRACKET, RPAREN / RBRACKET / RBRACE / COMMA]
// [16, array → • LBRACKET values RBRACKET, RBRACKET / COMMA]
// [16, array → LBRACKET • values RBRACKET, RPAREN / RBRACKET / RBRACE / COMMA]
// [17, values → • value, RBRACKET]
// [18, values → • value COMMA values, RBRACKET]
// [19, record → • LBRACE RBRACE, RBRACKET / COMMA]
// [20, record → • LBRACE record_fields RBRACE, RBRACKET / COMMA]
fn yy_state_8(_lookahead : YYSymbol) -> YYDecision {
  match _lookahead {
    T_LBRACE => Shift(yy_state_4)
    T_LBRACKET => Shift(yy_state_8)
    NT_value => Shift(yy_state_9)
    T_IDENT => Shift(yy_state_12)
    NT_record => Shift(yy_state_16)
    NT_array => Shift(yy_state_17)
    T_BOOL => Shift(yy_state_18)
    T_NUMBER => Shift(yy_state_19)
    T_STRING => Shift(yy_state_20)
    NT_values => Shift(yy_state_29)
    T_RBRACKET => Shift(yy_state_31)
    _ => Error
  }
}

// [17, values → value •, RBRACKET]
// [18, values → value • COMMA values, RBRACKET]
fn yy_state_9(_lookahead : YYSymbol) -> YYDecision {
  match _lookahead {
    T_COMMA => Shift(yy_state_10)
    T_RBRACKET => Reduce(1, NT_values, yy_action_21)
    _ => Error
  }
}

// [8, value → • STRING, RBRACKET / COMMA]
// [9, value → • NUMBER, RBRACKET / COMMA]
// [10, value → • BOOL, RBRACKET / COMMA]
// [11, value → • array, RBRACKET / COMMA]
// [12, value → • record, RBRACKET / COMMA]
// [13, value → • IDENT LPAREN args_opt RPAREN, RBRACKET / COMMA]
// [14, value → • IDENT, RBRACKET / COMMA]
// [15, array → • LBRACKET RBRACKET, RBRACKET / COMMA]
// [16, array → • LBRACKET values RBRACKET, RBRACKET / COMMA]
// [17, values → • value, RBRACKET]
// [18, values → • value COMMA values, RBRACKET]
// [18, values → value COMMA • values, RBRACKET]
// [19, record → • LBRACE RBRACE, RBRACKET / COMMA]
// [20, record → • LBRACE record_fields RBRACE, RBRACKET / COMMA]
fn yy_state_10(_lookahead : YYSymbol) -> YYDecision {
  match _lookahead {
    T_LBRACE => Shift(yy_state_4)
    T_LBRACKET => Shift(yy_state_8)
    NT_value => Shift(yy_state_9)
    NT_values => Shift(yy_state_11)
    T_IDENT => Shift(yy_state_12)
    NT_record => Shift(yy_state_16)
    NT_array => Shift(yy_state_17)
    T_BOOL => Shift(yy_state_18)
    T_NUMBER => Shift(yy_state_19)
    T_STRING => Shift(yy_state_20)
    _ => Error
  }
}

// [18, values → value COMMA values •, RBRACKET]
fn yy_state_11(_lookahead : YYSymbol) -> YYDecision {
  ReduceNoLookahead(3, NT_values, yy_action_20)
}

// [13, value → IDENT • LPAREN args_opt RPAREN, RPAREN / RBRACKET / RBRACE / COMMA]
// [14, value → IDENT •, RPAREN / RBRACKET / RBRACE / COMMA]
fn yy_state_12(_lookahead : YYSymbol) -> YYDecision {
  match _lookahead {
    T_LPAREN => Shift(yy_state_13)
    T_RPAREN | T_RBRACKET | T_RBRACE | T_COMMA => Reduce(1, NT_value, yy_action_19)
    _ => Error
  }
}

// [1, args_opt → •, RPAREN]
// [2, args_opt → • args, RPAREN]
// [3, args → • arg, RPAREN]
// [4, args → • arg COMMA, RPAREN]
// [5, args → • arg COMMA args, RPAREN]
// [6, arg → • IDENT COLON value, RPAREN / COMMA]
// [7, arg → • value, RPAREN / COMMA]
// [8, value → • STRING, RPAREN / COMMA]
// [9, value → • NUMBER, RPAREN / COMMA]
// [10, value → • BOOL, RPAREN / COMMA]
// [11, value → • array, RPAREN / COMMA]
// [12, value → • record, RPAREN / COMMA]
// [13, value → • IDENT LPAREN args_opt RPAREN, RPAREN / COMMA]
// [13, value → IDENT LPAREN • args_opt RPAREN, RPAREN / RBRACKET / RBRACE / COMMA]
// [14, value → • IDENT, RPAREN / COMMA]
// [15, array → • LBRACKET RBRACKET, RPAREN / COMMA]
// [16, array → • LBRACKET values RBRACKET, RPAREN / COMMA]
// [19, record → • LBRACE RBRACE, RPAREN / COMMA]
// [20, record → • LBRACE record_fields RBRACE, RPAREN / COMMA]
fn yy_state_13(_lookahead : YYSymbol) -> YYDecision {
  match _lookahead {
    T_LBRACE => Shift(yy_state_4)
    T_LBRACKET => Shift(yy_state_8)
    NT_args_opt => Shift(yy_state_14)
    NT_record => Shift(yy_state_16)
    NT_array => Shift(yy_state_17)
    T_BOOL => Shift(yy_state_18)
    T_NUMBER => Shift(yy_state_19)
    T_STRING => Shift(yy_state_20)
    NT_value => Shift(yy_state_21)
    T_IDENT => Shift(yy_state_22)
    NT_arg => Shift(yy_state_25)
    NT_args => Shift(yy_state_28)
    T_RPAREN => Reduce(0, NT_args_opt, yy_action_23)
    _ => Error
  }
}

// [13, value → IDENT LPAREN args_opt • RPAREN, RPAREN / RBRACKET / RBRACE / COMMA]
fn yy_state_14(_lookahead : YYSymbol) -> YYDecision {
  match _lookahead {
    T_RPAREN => Shift(yy_state_15)
    _ => Error
  }
}

// [13, value → IDENT LPAREN args_opt RPAREN •, RPAREN / RBRACKET / RBRACE / COMMA]
fn yy_state_15(_lookahead : YYSymbol) -> YYDecision {
  ReduceNoLookahead(4, NT_value, yy_action_18)
}

// [12, value → record •, RPAREN / RBRACKET / RBRACE / COMMA]
fn yy_state_16(_lookahead : YYSymbol) -> YYDecision {
  ReduceNoLookahead(1, NT_value, yy_action_17)
}

// [11, value → array •, RPAREN / RBRACKET / RBRACE / COMMA]
fn yy_state_17(_lookahead : YYSymbol) -> YYDecision {
  ReduceNoLookahead(1, NT_value, yy_action_16)
}

// [10, value → BOOL •, RPAREN / RBRACKET / RBRACE / COMMA]
fn yy_state_18(_lookahead : YYSymbol) -> YYDecision {
  ReduceNoLookahead(1, NT_value, yy_action_15)
}

// [9, value → NUMBER •, RPAREN / RBRACKET / RBRACE / COMMA]
fn yy_state_19(_lookahead : YYSymbol) -> YYDecision {
  ReduceNoLookahead(1, NT_value, yy_action_14)
}

// [8, value → STRING •, RPAREN / RBRACKET / RBRACE / COMMA]
fn yy_state_20(_lookahead : YYSymbol) -> YYDecision {
  ReduceNoLookahead(1, NT_value, yy_action_13)
}

// [7, arg → value •, RPAREN / COMMA]
fn yy_state_21(_lookahead : YYSymbol) -> YYDecision {
  ReduceNoLookahead(1, NT_arg, yy_action_12)
}

// [6, arg → IDENT • COLON value, RPAREN / COMMA]
// [13, value → IDENT • LPAREN args_opt RPAREN, RPAREN / COMMA]
// [14, value → IDENT •, RPAREN / COMMA]
fn yy_state_22(_lookahead : YYSymbol) -> YYDecision {
  match _lookahead {
    T_LPAREN => Shift(yy_state_13)
    T_COLON => Shift(yy_state_23)
    T_RPAREN | T_COMMA => Reduce(1, NT_value, yy_action_19)
    _ => Error
  }
}

// [6, arg → IDENT COLON • value, RPAREN / COMMA]
// [8, value → • STRING, RPAREN / COMMA]
// [9, value → • NUMBER, RPAREN / COMMA]
// [10, value → • BOOL, RPAREN / COMMA]
// [11, value → • array, RPAREN / COMMA]
// [12, value → • record, RPAREN / COMMA]
// [13, value → • IDENT LPAREN args_opt RPAREN, RPAREN / COMMA]
// [14, value → • IDENT, RPAREN / COMMA]
// [15, array → • LBRACKET RBRACKET, RPAREN / COMMA]
// [16, array → • LBRACKET values RBRACKET, RPAREN / COMMA]
// [19, record → • LBRACE RBRACE, RPAREN / COMMA]
// [20, record → • LBRACE record_fields RBRACE, RPAREN / COMMA]
fn yy_state_23(_lookahead : YYSymbol) -> YYDecision {
  match _lookahead {
    T_LBRACE => Shift(yy_state_4)
    T_LBRACKET => Shift(yy_state_8)
    T_IDENT => Shift(yy_state_12)
    NT_record => Shift(yy_state_16)
    NT_array => Shift(yy_state_17)
    T_BOOL => Shift(yy_state_18)
    T_NUMBER => Shift(yy_state_19)
    T_STRING => Shift(yy_state_20)
    NT_value => Shift(yy_state_24)
    _ => Error
  }
}

// [6, arg → IDENT COLON value •, RPAREN / COMMA]
fn yy_state_24(_lookahead : YYSymbol) -> YYDecision {
  ReduceNoLookahead(3, NT_arg, yy_action_11)
}

// [3, args → arg •, RPAREN]
// [4, args → arg • COMMA, RPAREN]
// [5, args → arg • COMMA args, RPAREN]
fn yy_state_25(_lookahead : YYSymbol) -> YYDecision {
  match _lookahead {
    T_COMMA => Shift(yy_state_26)
    T_RPAREN => Reduce(1, NT_args, yy_action_10)
    _ => Error
  }
}

// [3, args → • arg, RPAREN]
// [4, args → • arg COMMA, RPAREN]
// [4, args → arg COMMA •, RPAREN]
// [5, args → • arg COMMA args, RPAREN]
// [5, args → arg COMMA • args, RPAREN]
// [6, arg → • IDENT COLON value, RPAREN / COMMA]
// [7, arg → • value, RPAREN / COMMA]
// [8, value → • STRING, RPAREN / COMMA]
// [9, value → • NUMBER, RPAREN / COMMA]
// [10, value → • BOOL, RPAREN / COMMA]
// [11, value → • array, RPAREN / COMMA]
// [12, value → • record, RPAREN / COMMA]
// [13, value → • IDENT LPAREN args_opt RPAREN, RPAREN / COMMA]
// [14, value → • IDENT, RPAREN / COMMA]
// [15, array → • LBRACKET RBRACKET, RPAREN / COMMA]
// [16, array → • LBRACKET values RBRACKET, RPAREN / COMMA]
// [19, record → • LBRACE RBRACE, RPAREN / COMMA]
// [20, record → • LBRACE record_fields RBRACE, RPAREN / COMMA]
fn yy_state_26(_lookahead : YYSymbol) -> YYDecision {
  match _lookahead {
    T_LBRACE => Shift(yy_state_4)
    T_LBRACKET => Shift(yy_state_8)
    NT_record => Shift(yy_state_16)
    NT_array => Shift(yy_state_17)
    T_BOOL => Shift(yy_state_18)
    T_NUMBER => Shift(yy_state_19)
    T_STRING => Shift(yy_state_20)
    NT_value => Shift(yy_state_21)
    T_IDENT => Shift(yy_state_22)
    NT_arg => Shift(yy_state_25)
    NT_args => Shift(yy_state_27)
    T_RPAREN => Reduce(2, NT_args, yy_action_9)
    _ => Error
  }
}

// [5, args → arg COMMA args •, RPAREN]
fn yy_state_27(_lookahead : YYSymbol) -> YYDecision {
  ReduceNoLookahead(3, NT_args, yy_action_8)
}

// [2, args_opt → args •, RPAREN]
fn yy_state_28(_lookahead : YYSymbol) -> YYDecision {
  ReduceNoLookahead(1, NT_args_opt, yy_action_7)
}

// [16, array → LBRACKET values • RBRACKET, RPAREN / RBRACKET / RBRACE / COMMA]
fn yy_state_29(_lookahead : YYSymbol) -> YYDecision {
  match _lookahead {
    T_RBRACKET => Shift(yy_state_30)
    _ => Error
  }
}

// [16, array → LBRACKET values RBRACKET •, RPAREN / RBRACKET / RBRACE / COMMA]
fn yy_state_30(_lookahead : YYSymbol) -> YYDecision {
  ReduceNoLookahead(3, NT_array, yy_action_6)
}

// [15, array → LBRACKET RBRACKET •, RPAREN / RBRACKET / RBRACE / COMMA]
fn yy_state_31(_lookahead : YYSymbol) -> YYDecision {
  ReduceNoLookahead(2, NT_array, yy_action_5)
}

// [21, record_fields → record_field •, RBRACE]
// [22, record_fields → record_field • COMMA record_fields, RBRACE]
fn yy_state_32(_lookahead : YYSymbol) -> YYDecision {
  match _lookahead {
    T_COMMA => Shift(yy_state_33)
    T_RBRACE => Reduce(1, NT_record_fields, yy_action_4)
    _ => Error
  }
}

// [21, record_fields → • record_field, RBRACE]
// [22, record_fields → • record_field COMMA record_fields, RBRACE]
// [22, record_fields → record_field COMMA • record_fields, RBRACE]
// [23, record_field → • IDENT COLON value, RBRACE / COMMA]
fn yy_state_33(_lookahead : YYSymbol) -> YYDecision {
  match _lookahead {
    T_IDENT => Shift(yy_state_5)
    NT_record_field => Shift(yy_state_32)
    NT_record_fields => Shift(yy_state_34)
    _ => Error
  }
}

// [22, record_fields → record_field COMMA record_fields •, RBRACE]
fn yy_state_34(_lookahead : YYSymbol) -> YYDecision {
  ReduceNoLookahead(3, NT_record_fields, yy_action_3)
}

// [20, record → LBRACE record_fields • RBRACE, RPAREN / RBRACKET / RBRACE / COMMA]
fn yy_state_35(_lookahead : YYSymbol) -> YYDecision {
  match _lookahead {
    T_RBRACE => Shift(yy_state_36)
    _ => Error
  }
}

// [20, record → LBRACE record_fields RBRACE •, RPAREN / RBRACKET / RBRACE / COMMA]
fn yy_state_36(_lookahead : YYSymbol) -> YYDecision {
  ReduceNoLookahead(3, NT_record, yy_action_2)
}

// [19, record → LBRACE RBRACE •, RPAREN / RBRACKET / RBRACE / COMMA]
fn yy_state_37(_lookahead : YYSymbol) -> YYDecision {
  ReduceNoLookahead(2, NT_record, yy_action_1)
}

// [0, directive → IDENT LPAREN args_opt • RPAREN, $]
fn yy_state_38(_lookahead : YYSymbol) -> YYDecision {
  match _lookahead {
    T_RPAREN => Shift(yy_state_39)
    _ => Error
  }
}

// [0, directive → IDENT LPAREN args_opt RPAREN •, $]
fn yy_state_39(_lookahead : YYSymbol) -> YYDecision {
  ReduceNoLookahead(4, NT_directive, yy_action_0)
}

fn[T] yy_parse(
  tokens : Array[(Token, Int, Int)],
  start : YYState,
  return_ : (YYObj) -> T,
  initial_pos? : Int,
) -> T raise ParseError {
  let mut cursor = 0
  let mut state_stack : @list.List[YYState] = @list.cons(start, @list.empty())
  let data_stack : Array[(YYObj, Int, Int)] = []
  let mut last_pos = initial_pos.unwrap_or(tokens[0].1)
  let mut state = start
  let mut lookahead : Option[(YYSymbol, (YYObj, Int, Int), Token?)] = None
  let mut last_shifted_state_stack = state_stack
  while true {
    let decision = match state(EOI) {
      ReduceNoLookahead(_) | Accept as t => t
      _ => {
        match lookahead {
          Some(la) => state(la.0)
          None => {
            if cursor < tokens.length() {
              let (token, start_pos, end_pos) = tokens[cursor]
              cursor += 1
              let (symbol, data) = yy_input(token, start_pos, end_pos)
              lookahead = Some((symbol, (data, start_pos, end_pos), Some(token)))
              state(symbol)
            } else {
              lookahead = Some((EOI, (YYObj_Void, last_pos, last_pos), None))
              state(EOI)
            }
          }
        }
      }
    }
    match decision {
      Accept => return return_(data_stack.unsafe_pop().0)
      Shift(next_state) => {
        guard lookahead is Some(la)
        data_stack.push(la.1)
        state_stack = @list.cons(next_state, state_stack)
        last_shifted_state_stack = state_stack
        state = next_state
        last_pos = la.1.2
        lookahead = None
      }
      Reduce(count, symbol, action)
      | ReduceNoLookahead(count, symbol, action) => {
        for count = count, symbol = symbol, action = action {
          let args = data_stack[data_stack.length() - count:]
          let data = action(last_pos, args)
          let (start_pos, end_pos) = if args.length() == 0 {
            (last_pos, last_pos)
          } else {
            (args[0].1, args[args.length() - 1].2)
          }
          for _ in 0..<count {
            ignore(data_stack.unsafe_pop())
            state_stack = state_stack.unsafe_tail()
          }
          state = state_stack.unsafe_head()
          data_stack.push((data, start_pos, end_pos))
          match state(symbol) {
            Accept => return return_(data_stack.unsafe_pop().0)
            Shift(next_state) => {
              state_stack = @list.cons(next_state, state_stack)
              state = next_state
              break ()
            }
            Reduce(count, symbol, action)
            | ReduceNoLookahead(count, symbol, action) => continue count, symbol, action
            _ => panic()
          }
        }
      }
      Error => {
        let (_, (_, start_pos, end_pos), token) = lookahead.unwrap()
        error(last_shifted_state_stack, token, (start_pos, end_pos))
      }
    }
  }
  panic()
}

fn error(stack : @list.List[YYState], token : Token?, loc : (Int, Int)) -> Unit raise ParseError {
  let expected = []
  fn try_add(symbol : YYSymbol, kind : TokenKind) {
    fn go(stack : @list.List[YYState]) {
      match stack {
        Empty => ()
        More(state, ..) => {
          match state(symbol) {
            Accept | Shift(_) => expected.push(kind)
            Reduce(count, symbol, _) | ReduceNoLookahead(count, symbol, _) => {
              fn inner_go(stack : @list.List[YYState], count, symbol) {
                let stack = stack.drop(count)
                guard stack is More(state, ..)
                match state(symbol) {
                  Shift(state) => go(@list.cons(state, stack))
                  Reduce(count, symbol, _) | ReduceNoLookahead(count, symbol, _) => inner_go(stack, count, symbol)
                  _ => panic()
                }
              }
              inner_go(stack, count, symbol)
            }
            Error => ()
          }
        }
      }
    }
    go(stack)
  }
  for term in ([(T_IDENT, TK_IDENT), (T_STRING, TK_STRING), (T_NUMBER, TK_NUMBER), (T_BOOL, TK_BOOL), (T_LPAREN, TK_LPAREN), (T_RPAREN, TK_RPAREN), (T_LBRACKET, TK_LBRACKET), (T_RBRACKET, TK_RBRACKET), (T_LBRACE, TK_LBRACE), (T_RBRACE, TK_RBRACE), (T_COLON, TK_COLON), (T_COMMA, TK_COMMA)] : Array[(YYSymbol, TokenKind)]) {
    try_add(term.0, term.1)
  }
  match token {
    None => raise UnexpectedEndOfInput(loc.1, expected)
    Some(token) => raise UnexpectedToken(token, loc, expected)
  }
}

pub fn directive(tokens : Array[(Token, Int, Int)], initial_pos? : Int) -> (String, Map[String, @ast.Value]) raise ParseError {
  yy_parse(
    tokens,
    yy_state_0,
    (it) => {
      guard it is YYObj__String__Map_String___ast_Value__(result)
      result
    },
    initial_pos?,
  )
}

