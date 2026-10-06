@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'RE-FX Demo - KPIs por estado'
@Metadata.allowExtensions: true
define view entity ZREFX_I_LOG_KPI
  as select from zrefx_t_log
{
  key estado                              as Estado,
      max( estado_txt )                   as EstadoTxt,
      max( criticality )                  as Criticality,
      count( * )                          as NumExpedientes,
      sum( num_discrepancias )            as TotalDiscrepancias
}
group by
  estado
