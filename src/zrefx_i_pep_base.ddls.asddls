@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'RE-FX Demo - Base de imputacion PEP'
define view entity ZREFX_I_PEP_BASE
  as select from zrefx_t_log
{
  key expediente                                             as Expediente,

      cast( case when pep <> '' then 'OK'
                                else 'KO' end
            as abap.char(2) )                                as Situacion,

      cast( case when pep <> '' then 'PEP derivado'
                                else 'Sin regla de derivacion' end
            as abap.char(40) )                               as SituacionTxt,

      cast( case when pep <> '' then 3
                                else 1 end
            as abap.int1 )                                   as Criticality
}
