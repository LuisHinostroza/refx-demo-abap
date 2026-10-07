CLASS zcl_refx_refresh_log DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.

    "! Lee el log desde n8n y reemplaza el contenido de ZREFX_T_LOG.
    "! @parameter iv_url      | URL del webhook GET de n8n. Vacio = constante interna.
    "! @parameter rv_filas    | Numero de expedientes cargados.
    CLASS-METHODS refrescar
      IMPORTING iv_url         TYPE string OPTIONAL
      RETURNING VALUE(rv_filas) TYPE i
      RAISING   cx_static_check.

  PRIVATE SECTION.

    " ---------------------------------------------------------------
    " Ajusta esta URL a tu webhook GET de n8n antes de activar la clase
    " ---------------------------------------------------------------
    CONSTANTS c_url_log TYPE string
      VALUE 'https://luishinostrozag3.app.n8n.cloud/webhook/refx-log'.

    " Estructura espejo del JSON que devuelve n8n (claves en minuscula)
    TYPES: BEGIN OF ty_fila,
             expediente         TYPE string,
             mensaje_id         TYPE string,
             sistema_origen     TYPE string,
             id_documento       TYPE string,
             inmueble           TYPE string,
             unidad             TYPE string,
             arrendador         TYPE string,
             arrendatario       TYPE string,
             renta_origen       TYPE string,
             renta_contrato     TYPE string,
             moneda             TYPE string,
             fecha_ini_origen   TYPE string,
             fecha_ini_contrato TYPE string,
             estado             TYPE string,
             estado_txt         TYPE string,
             criticality        TYPE string,
             num_discrepancias  TYPE string,
             dictamen_ia        TYPE string,
             detalle_disc       TYPE string,
             validador          TYPE string,
             aprobador          TYPE string,
             motivo_rechazo     TYPE string,
             num_contrato       TYPE string,
             sociedad           TYPE string,
             pep                TYPE string,
             pep_desc           TYPE string,
             motivo_pep         TYPE string,
             recibido_en        TYPE string,
             actualizado_en     TYPE string,
           END OF ty_fila,
           tt_fila TYPE STANDARD TABLE OF ty_fila WITH EMPTY KEY.

    CLASS-METHODS leer_json
      IMPORTING iv_url         TYPE string
      RETURNING VALUE(rv_body) TYPE string
      RAISING   cx_static_check.

    CLASS-METHODS a_fecha
      IMPORTING iv_texto       TYPE string
      RETURNING VALUE(rv_dats) TYPE d.

    CLASS-METHODS a_timestamp
      IMPORTING iv_texto     TYPE string
      RETURNING VALUE(rv_ts) TYPE timestampl.

ENDCLASS.


CLASS zcl_refx_refresh_log IMPLEMENTATION.

  METHOD if_oo_adt_classrun~main.
    TRY.
        DATA(lv_filas) = refrescar( ).
        out->write( |Log actualizado. Expedientes cargados: { lv_filas }| ).
      CATCH cx_root INTO DATA(lx).
        out->write( |Error: { lx->get_text( ) }| ).
    ENDTRY.
  ENDMETHOD.


  METHOD refrescar.

    DATA(lv_url) = COND string( WHEN iv_url IS INITIAL THEN c_url_log ELSE iv_url ).

    DATA(lv_body) = leer_json( lv_url ).

    DATA lt_json TYPE tt_fila.
    xco_cp_json=>data->from_string( lv_body )->write_to( REF #( lt_json ) ).

    IF lt_json IS INITIAL.
      rv_filas = 0.
      RETURN.
    ENDIF.

    DATA lt_db TYPE STANDARD TABLE OF zrefx_t_log.

    LOOP AT lt_json INTO DATA(ls_json).

      APPEND VALUE #(
        expediente         = to_upper( ls_json-expediente )
        mensaje_id         = ls_json-mensaje_id
        sistema_origen     = ls_json-sistema_origen
        id_documento       = ls_json-id_documento
        inmueble           = ls_json-inmueble
        unidad             = ls_json-unidad
        arrendador         = ls_json-arrendador
        arrendatario       = ls_json-arrendatario
        renta_origen       = CONV decfloat34( ls_json-renta_origen )
        renta_contrato     = CONV decfloat34( ls_json-renta_contrato )
        moneda             = COND #( WHEN ls_json-moneda IS INITIAL
                                     THEN 'EUR' ELSE to_upper( ls_json-moneda ) )
        fecha_ini_origen   = a_fecha( ls_json-fecha_ini_origen )
        fecha_ini_contrato = a_fecha( ls_json-fecha_ini_contrato )
        estado             = ls_json-estado
        estado_txt         = ls_json-estado_txt
        criticality        = CONV int1( ls_json-criticality )
        num_discrepancias  = CONV int4( ls_json-num_discrepancias )
        dictamen_ia        = ls_json-dictamen_ia
        detalle_disc       = ls_json-detalle_disc
        validador          = ls_json-validador
        aprobador          = ls_json-aprobador
        motivo_rechazo     = ls_json-motivo_rechazo
        num_contrato       = ls_json-num_contrato
        sociedad           = ls_json-sociedad
        pep                = to_upper( ls_json-pep )
        pep_desc           = ls_json-pep_desc
        motivo_pep         = ls_json-motivo_pep
        recibido_en        = a_timestamp( ls_json-recibido_en )
        actualizado_en     = a_timestamp( ls_json-actualizado_en )
      ) TO lt_db.

    ENDLOOP.

    " Carga completa: borramos y volvemos a insertar para que el metodo
    " sea idempotente y no deje expedientes huerfanos entre ejecuciones.
    DELETE FROM zrefx_t_log.
    INSERT zrefx_t_log FROM TABLE @lt_db.
    COMMIT WORK.

    rv_filas = lines( lt_db ).

  ENDMETHOD.


  METHOD leer_json.

    DATA(lo_destino) = cl_http_destination_provider=>create_by_url( iv_url ).
    DATA(lo_cliente) = cl_web_http_client_manager=>create_by_http_destination( lo_destino ).

    DATA(lo_request) = lo_cliente->get_http_request( ).
    lo_request->set_header_field( i_name = 'Accept' i_value = 'application/json' ).

    DATA(lo_response) = lo_cliente->execute( if_web_http_client=>get ).
    DATA(lv_status)   = lo_response->get_status( ).
    rv_body           = lo_response->get_text( ).

    lo_cliente->close( ).

    IF lv_status-code <> 200.
      RAISE EXCEPTION NEW cx_abap_invalid_value(
        textid = 'n8n devolvio HTTP Error' ).
    ENDIF.

  ENDMETHOD.


  METHOD a_fecha.
    " Acepta '2026-02-01' o '20260201'
    DATA(lv_limpio) = replace( val = iv_texto sub = '-' with = '' occ = 0 ).
    IF strlen( lv_limpio ) = 8.
      rv_dats = lv_limpio.
    ENDIF.
  ENDMETHOD.


  METHOD a_timestamp.
    " Acepta '20261004153022' (14 posiciones)
    DATA(lv_limpio) = replace( val = iv_texto sub = '-' with = '' occ = 0 ).
    lv_limpio = replace( val = lv_limpio sub = ':' with = '' occ = 0 ).
    lv_limpio = replace( val = lv_limpio sub = 'T' with = '' occ = 0 ).
    IF strlen( lv_limpio ) >= 14.
      rv_ts = substring( val = lv_limpio off = 0 len = 14 ).
    ENDIF.
  ENDMETHOD.

ENDCLASS.

