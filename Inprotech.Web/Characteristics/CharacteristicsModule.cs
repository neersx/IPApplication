using Autofac;

namespace Inprotech.Web.Characteristics
{
    public class CharacteristicsModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<ValidateCharacteristicsValidator>().As<IValidateCharacteristicsValidator>();
            builder.RegisterType<ValidCharacteristicsReader>().As<IValidCharacteristicsReader>();
        }
    }
}