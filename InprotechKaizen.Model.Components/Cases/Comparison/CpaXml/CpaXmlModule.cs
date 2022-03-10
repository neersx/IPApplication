using Autofac;

namespace InprotechKaizen.Model.Components.Cases.Comparison.CpaXml
{
    public class CpaXmlModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<CpaXmlComparison>().As<ICpaXmlComparison>();
            builder.RegisterType<CpaXmlCaseDetailsLoader>().As<ICpaXmlCaseDetailsLoader>();
        }
    }
}