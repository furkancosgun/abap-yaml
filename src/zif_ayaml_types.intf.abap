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

ENDINTERFACE.
