@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'RE-FX Demo - Expedientes'
@Metadata.allowExtensions: true
@Search.searchable: true
define view entity ZREFX_I_LOG
  as select from zrefx_t_log
{
      @Search.defaultSearchElement: true
  key expediente                                        as Expediente,

      mensaje_id                                        as MensajeId,
      sistema_origen                                    as SistemaOrigen,
      id_documento                                      as IdDocumento,

      @Search.defaultSearchElement: true
      inmueble                                          as Inmueble,
      unidad                                            as Unidad,
      arrendador                                        as Arrendador,
      @Search.defaultSearchElement: true
      arrendatario                                      as Arrendatario,

      @Semantics.amount.currencyCode: 'Moneda'
      renta_origen                                      as RentaOrigen,
      @Semantics.amount.currencyCode: 'Moneda'
      renta_contrato                                    as RentaContrato,
      moneda                                            as Moneda,

      fecha_ini_origen                                  as FechaIniOrigen,
      fecha_ini_contrato                                as FechaIniContrato,

      estado                                            as Estado,
      estado_txt                                        as EstadoTxt,
      criticality                                       as Criticality,

      num_discrepancias                                 as NumDiscrepancias,
      dictamen_ia                                       as DictamenIA,
      detalle_disc                                      as DetalleDiscrepancias,

      validador                                         as Validador,
      aprobador                                         as Aprobador,
      motivo_rechazo                                    as MotivoRechazo,
      num_contrato                                      as NumContrato,

      sociedad                                          as Sociedad,
      pep                                               as Pep,
      pep_desc                                          as PepDesc,
      motivo_pep                                        as MotivoPep,

      recibido_en                                       as RecibidoEn,
      actualizado_en                                    as ActualizadoEn,

      // --- banderas derivadas para filtros y tarjetas del OVP ---
      case when estado = '50' then 1 else 0 end         as EsCreado,
      case when estado = '60' or estado = '70'
           then 1 else 0 end                            as EsRechazado,
      case when estado = '30' or estado = '40'
           then 1 else 0 end                            as EsPendiente,
      case when estado = '90' then 1 else 0 end         as EsError,
      case when estado = '80' then 1 else 0 end         as EsSinPep,
      case when pep <> '' then 1 else 0 end             as PepDerivado,
      cast( 1 as abap.int4 )                            as Contador
}
