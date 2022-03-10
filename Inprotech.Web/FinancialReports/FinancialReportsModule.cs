using Autofac;
using Inprotech.Web.FinancialReports.AgeDebtorAnalysis;
using Inprotech.Web.FinancialReports.RevenueAnalysis;

namespace Inprotech.Web.FinancialReports
{
    public class FinancialReportsModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            builder.RegisterType<RevenueAnalysisReportDataProvider>().As<IRevenueAnalysisReportDataProvider>();
            builder.RegisterType<AgedDebtorsReportDataProvider>().As<IAgedDebtorsReportDataProvider>();
        }
    }
}