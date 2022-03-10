using Autofac;

namespace InprotechKaizen.Model.Components.Accounting.Billing.Items.Persistence
{
    public class PersistenceModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<NewOpenItem>()
                   .As<INewDraftBill>();

            builder.RegisterType<MergedOpenItemsPersistence>()
                   .As<INewDraftBill>();
            
            builder.RegisterType<UpdateOpenItem>()
                   .As<IUpdateDraftBill>();

            builder.RegisterType<OpenItemPersistence>()
                   .As<INewDraftBill>()
                   .As<IUpdateDraftBill>();

            builder.RegisterType<SplitWipItemsPersistence>()
                   .As<INewDraftBill>()
                   .As<IUpdateDraftBill>();
            
            builder.RegisterType<DraftWipDetailPersistence>()
                   .As<INewDraftBill>()
                   .As<IUpdateDraftBill>();

            builder.RegisterType<SaveDraftWipAsPostedWip>()
                   .Keyed<ISaveOpenItemDraftWip>(TypeOfDraftWipPersistence.WipSplitMultiDebtor);
            builder.RegisterType<SaveDraftWip>()
                   .Keyed<ISaveOpenItemDraftWip>(TypeOfDraftWipPersistence.Default);

            builder.RegisterType<OpenItemTaxPersistence>()
                   .As<INewDraftBill>()
                   .As<IUpdateDraftBill>();

            builder.RegisterType<BillCreditsPersistence>()
                   .As<INewDraftBill>()
                   .As<IUpdateDraftBill>();
            
            builder.RegisterType<OpenItemCopyToPersistence>()
                   .As<INewDraftBill>()
                   .As<IUpdateDraftBill>();
            
            builder.RegisterType<BillLinePersistence>()
                   .As<INewDraftBill>()
                   .As<IUpdateDraftBill>();

            builder.RegisterType<OpenItemXmlPersistence>()
                   .As<INewDraftBill>()
                   .As<IUpdateDraftBill>();

            builder.RegisterType<BilledItemsPersistence>()
                   .As<INewDraftBill>()
                   .As<IUpdateDraftBill>();

            builder.RegisterType<DebtorHistoryPersistence>()
                   .As<INewDraftBill>()
                   .As<IUpdateDraftBill>();

            builder.RegisterType<ChangeAlertPersistence>()
                   .As<INewDraftBill>()
                   .As<IUpdateDraftBill>();
            
            builder.RegisterType<DraftWipManagementCommands>().As<IDraftWipManagementCommands>();
            builder.RegisterType<DraftBillManagementCommands>().As<IDraftBillManagementCommands>();
            builder.RegisterType<ChangeAlertGeneratorCommands>().As<IChangeAlertGeneratorCommands>();

            builder.RegisterType<BilledItems>().As<IBilledItems>();
            builder.RegisterType<ExactNameAddressSnapshot>().As<IExactNameAddressSnapshot>();

            builder.RegisterType<FinaliseOpenItem>()
                   .As<IFinaliseDraftBill>();

            builder.RegisterType<GenerateBillThenSendForReview>()
                   .As<IFinaliseDraftBill>();
            
            builder.RegisterType<Orchestrator>().As<IOrchestrator>();
        }
    }
}
