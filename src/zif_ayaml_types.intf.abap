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

  TYPES ty_t_nodes      TYPE SORTED TABLE OF ty_s_node WITH UNIQUE KEY path name.
  TYPES ty_t_nodes_flat TYPE STANDARD TABLE OF ty_s_node WITH DEFAULT KEY.
  TYPES ty_t_string     TYPE STANDARD TABLE OF string WITH DEFAULT KEY.

  TYPES ty_token_type   TYPE string.

  CONSTANTS:
    BEGIN OF cs_token_type,
      doc_start      TYPE ty_token_type VALUE 'DOC_START',
      doc_end        TYPE ty_token_type VALUE 'DOC_END',
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

  TYPES ty_t_tokens TYPE STANDARD TABLE OF ty_s_token WITH DEFAULT KEY.

  TYPES ty_format   TYPE string.

  CONSTANTS:
    BEGIN OF cs_format,
      default    TYPE ty_format VALUE 'default',
      camel_case TYPE ty_format VALUE 'camel_case',
      snake_case TYPE ty_format VALUE 'snake_case',
      lower_case TYPE ty_format VALUE 'lower_case',
      upper_case TYPE ty_format VALUE 'upper_case',
    END OF cs_format.

ENDINTERFACE.
