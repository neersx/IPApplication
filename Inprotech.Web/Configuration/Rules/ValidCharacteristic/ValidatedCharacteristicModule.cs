using Autofac;

namespace Inprotech.Web.Configuration.Rules.ValidCharacteristic
{
    public class ValidatedCharacteristicModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<ValidatedActionCharacteristic>().As<IValidatedActionCharacteristic>();
            builder.RegisterType<ValidatedBasisCharacteristic>().As<IValidatedBasisCharacteristic>();
            builder.RegisterType<ValidatedCaseCategoryCharacteristic>().As<IValidatedCaseCategoryCharacteristic>();
            builder.RegisterType<ValidatedCaseTypeCharacteristic>().As<IValidatedCaseTypeCharacteristic>();
            builder.RegisterType<ValidatedJurisdictionCharacteristic>().As<IValidatedJurisdictionCharacteristic>();
            builder.RegisterType<ValidatedOfficeCharacteristic>().As<IValidatedOfficeCharacteristic>();
            builder.RegisterType<ValidatedPropertyTypeCharacteristic>().As<IValidatedPropertyTypeCharacteristic>();
            builder.RegisterType<ValidatedSubTypeCharacteristic>().As<IValidatedSubTypeCharacteristic>();
            builder.RegisterType<ValidatedDefaultDateOfLawCharacteristic>().As<IValidatedDefaultDateOfLawCharacteristic>();
            builder.RegisterType<ValidatedProgramCharacteristic>().As<IValidatedProgramCharacteristic>();
            builder.RegisterType<ValidatedProfileCharacteristic>().As<IValidatedProfileCharacteristic>();
        }
    }
}
