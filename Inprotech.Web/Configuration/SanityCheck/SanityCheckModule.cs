using Autofac;
using Inprotech.Web.Configuration.Rules;
using InprotechKaizen.Model.Rules;

namespace Inprotech.Web.Configuration.SanityCheck
{
    public class SanityCheckModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<SanityCheckCaseCharacteristicsValidator>()
                   .Keyed<ICharacteristicsValidator>(CriteriaPurposeCodes.SanityCheck)
                   .AsImplementedInterfaces();
        }
    }
}