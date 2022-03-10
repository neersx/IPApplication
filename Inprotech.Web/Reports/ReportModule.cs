using Autofac;
using InprotechKaizen.Model.Components.Reporting;

namespace Inprotech.Web.Reports
{
    public class ReportModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            builder.RegisterType<BillingWorksheetManager>()
                   .Keyed<IReportsManager>(ReportsTypes.BillingWorksheet);
        }
    }
}
