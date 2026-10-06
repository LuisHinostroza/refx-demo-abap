@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'RE-FX Demo - KPIs de imputacion PEP'
@Metadata.allowExtensions: true
define view entity ZREFX_I_PEP_KPI
  as select from ZREFX_I_PEP_BASE
{
  key Situacion,
  key SituacionTxt,
      max( Criticality )   as Criticality,
      count( * )           as NumExpedientes
}
group by
  Situacion,
  SituacionTxt
