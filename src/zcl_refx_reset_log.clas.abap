CLASS zcl_refx_reset_log DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.

    "! Vacia por completo ZREFX_T_LOG. Pensado para dejar el monitor
    "! en blanco antes de una demo.
    "! @parameter rv_borradas | Numero de expedientes eliminados.
    CLASS-METHODS vaciar
      RETURNING VALUE(rv_borradas) TYPE i.

ENDCLASS.


CLASS zcl_refx_reset_log IMPLEMENTATION.

  METHOD if_oo_adt_classrun~main.
    DATA(lv_n) = vaciar( ).
    out->write( |Monitor reiniciado. Expedientes eliminados: { lv_n }| ).
  ENDMETHOD.


  METHOD vaciar.

    SELECT COUNT(*) FROM zrefx_t_log INTO @rv_borradas.

    DELETE FROM zrefx_t_log.
    COMMIT WORK.

  ENDMETHOD.

ENDCLASS.

