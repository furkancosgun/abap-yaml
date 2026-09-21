INTERFACE zif_ayaml_types PUBLIC.

  TYPES ty_node_type TYPE c LENGTH 4.

  CONSTANTS:
    BEGIN OF cs_type,
      null     TYPE ty_node_type VALUE 'null',
      boolean  TYPE ty_node_type VALUE 'bool',
      number   TYPE ty_node_type VALUE 'num',
      string   TYPE ty_node_type VALUE 'str',
      date     TYPE ty_node_type VALUE 'date',
      mapping  TYPE ty_node_type VALUE 'map',
      sequence TYPE ty_node_type VALUE 'seq',
    END OF cs_type.

  TYPES:
    BEGIN OF ty_s_node,
      path  TYPE string,
      name  TYPE string,
      type  TYPE ty_node_type,
      value TYPE string,
      index TYPE i,
      order TYPE i,
    END OF ty_s_node.

  TYPES ty_t_nodes  TYPE STANDARD TABLE OF ty_s_node WITH NON-UNIQUE KEY path name
                 WITH NON-UNIQUE SORTED KEY path_key COMPONENTS path.
  TYPES ty_t_string TYPE STANDARD TABLE OF string WITH EMPTY KEY.

  TYPES ty_token_type TYPE string.

  CONSTANTS:
    BEGIN OF cs_token_type,
      doc_start      TYPE ty_token_type VALUE 'DOC_START',
      doc_end        TYPE ty_token_type VALUE 'DOC_END',
      directive      TYPE ty_token_type VALUE 'DIRECTIVE',
      comment        TYPE ty_token_type VALUE 'COMMENT',
      map_key        TYPE ty_token_type VALUE 'MAP_KEY',
      map_val        TYPE ty_token_type VALUE 'MAP_VAL',
      seq_entry      TYPE ty_token_type VALUE 'SEQ_ENTRY',
      flow_map_start TYPE ty_token_type VALUE 'FLOW_MAP_START',
      flow_map_end   TYPE ty_token_type VALUE 'FLOW_MAP_END',
      flow_seq_start TYPE ty_token_type VALUE 'FLOW_SEQ_START',
      flow_seq_end   TYPE ty_token_type VALUE 'FLOW_SEQ_END',
      flow_entry     TYPE ty_token_type VALUE 'FLOW_ENTRY',
      anchor         TYPE ty_token_type VALUE 'ANCHOR',
      alias          TYPE ty_token_type VALUE 'ALIAS',
      literal        TYPE ty_token_type VALUE 'LITERAL',
      folded         TYPE ty_token_type VALUE 'FOLDED',
      scalar         TYPE ty_token_type VALUE 'SCALAR',
      eof            TYPE ty_token_type VALUE 'EOF',
    END OF cs_token_type.

  TYPES:
    BEGIN OF ty_s_token,
      type       TYPE ty_token_type,
      value      TYPE string,
      line       TYPE i,
      column     TYPE i,
      indent_num TYPE i,
    END OF ty_s_token.

  TYPES ty_t_tokens TYPE STANDARD TABLE OF ty_s_token WITH EMPTY KEY.

ENDINTERFACE.
