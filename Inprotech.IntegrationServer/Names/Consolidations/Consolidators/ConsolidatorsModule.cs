using Autofac;

namespace Inprotech.IntegrationServer.Names.Consolidations.Consolidators
{
    public class ConsolidatorsModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<ClientDetailsConsolidator>().As<INameConsolidator>();
            builder.RegisterType<CreditorConsolidator>().As<INameConsolidator>();
            builder.RegisterType<IndividualConsolidator>().As<INameConsolidator>();
            builder.RegisterType<NameAddressConsolidator>().As<INameConsolidator>();
            builder.RegisterType<NameTelecomConsolidator>().As<INameConsolidator>();
            builder.RegisterType<NameFilesInConsolidator>().As<INameConsolidator>();
            builder.RegisterType<NameMainContactConsolidator>().As<INameConsolidator>();
            builder.RegisterType<NameAliasConsolidator>().As<INameConsolidator>();
            builder.RegisterType<NameImageConsolidator>().As<INameConsolidator>();
            builder.RegisterType<NameTextConsolidator>().As<INameConsolidator>();
            builder.RegisterType<AssociatedNameConsolidator>().As<INameConsolidator>();
            builder.RegisterType<DiscountConsolidator>().As<INameConsolidator>();
            builder.RegisterType<NameInstructionsConsolidator>().As<INameConsolidator>();
            builder.RegisterType<NameLanguageConsolidator>().As<INameConsolidator>();
            builder.RegisterType<OrganisationConsolidator>().As<INameConsolidator>();
            builder.RegisterType<NameMarginProfileConsolidator>().As<INameConsolidator>();
            builder.RegisterType<NameTypeClassificationConsolidator>().As<INameConsolidator>();
            builder.RegisterType<SpecialNameConsolidator>().As<INameConsolidator>();
            builder.RegisterType<TransactionHeaderConsolidator>().As<INameConsolidator>();
            builder.RegisterType<AccountsConsolidator>().As<INameConsolidator>();
            builder.RegisterType<BankConsolidator>().As<INameConsolidator>();
            builder.RegisterType<AccessAccountNamesConsolidator>().As<INameConsolidator>();
            builder.RegisterType<EmployeeReminderConsolidator>().As<INameConsolidator>();
            builder.RegisterType<DiaryConsolidator>().As<INameConsolidator>();
            builder.RegisterType<CaseNameConsolidator>().As<INameConsolidator>();
            builder.RegisterType<FeesCalculationsConsolidator>().As<INameConsolidator>();
            builder.RegisterType<AllOtherReferencesConsolidator>().As<INameConsolidator>();
        }
    }
}