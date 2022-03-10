using Autofac;

namespace Inprotech.Web.CaseComparison
{
    public class CaseComparisonModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            builder.RegisterType<CaseImageComparison>().AsImplementedInterfaces();
        }
    }
}