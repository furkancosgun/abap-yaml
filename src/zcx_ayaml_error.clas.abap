CLASS zcx_ayaml_error DEFINITION PUBLIC INHERITING FROM cx_static_check CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_t100_message.

    DATA mv_msg TYPE string.

    METHODS constructor
      IMPORTING iv_msg TYPE string OPTIONAL.

    METHODS if_message~get_text REDEFINITION.

ENDCLASS.


CLASS zcx_ayaml_error IMPLEMENTATION.
  METHOD constructor.
    super->constructor( ).
    mv_msg = iv_msg.
    CLEAR if_t100_message~t100key.
    if_t100_message~t100key-msgid = '00'.
    if_t100_message~t100key-msgno = '001'.
    if_t100_message~t100key-attr1 = 'MV_MSG'.
  ENDMETHOD.

  METHOD if_message~get_text.
    IF mv_msg IS NOT INITIAL.
      result = mv_msg.
    ELSE.
      result = super->if_message~get_text( ).
    ENDIF.
  ENDMETHOD.
ENDCLASS.
