using Autofac;
using Inprotech.Web.Cases.SummaryPreview;

namespace Inprotech.Web.Cases.Summary
{
    public class SummaryModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<CaseHeaderInfo>().As<ICaseHeaderInfo>();
        }
    }
}