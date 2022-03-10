using Autofac;

namespace Inprotech.Web.Configuration.Core
{
    public class CoreModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<Characteristics>().As<ICharacteristics>();
            builder.RegisterType<InstructionTypeDetailsValidator>().As<IInstructionTypeDetailsValidator>();
            builder.RegisterType<CharacteristicsSaveModel>().As<ICharacteristicsSaveModel>();
            builder.RegisterType<InstructionsSaveModel>().As<IInstructionsSaveModel>();
            builder.RegisterType<InstructionTypeSaveModel>().As<IInstructionTypeSaveModel>();

            builder.RegisterType<StatusSupport>().As<IStatusSupport>();
            builder.RegisterType<NameTypeValidator>().As<INameTypeValidator>();
            builder.RegisterType<DataItemMaintenance>().As<IDataItemMaintenance>();

            builder.RegisterType<LanguageResolver>().As<ILanguageResolver>();
        }
    }
}
