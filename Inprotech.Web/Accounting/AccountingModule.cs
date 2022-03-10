using Autofac;
using Inprotech.Infrastructure;
using Inprotech.Web.Accounting.Charge;
using Inprotech.Web.Accounting.Time;
using Inprotech.Web.Accounting.Time.Timers;
using Inprotech.Web.Accounting.VatReturns;
using Inprotech.Web.Accounting.Work;
using InprotechKaizen.Model.Components.Accounting.Time;
using InprotechKaizen.Model.Components.Accounting.Wip;
using InprotechKaizen.Model.Components.Profiles;

namespace Inprotech.Web.Accounting
{
    public class AccountingModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            builder.RegisterType<HmrcAuthenticator>().As<IHmrcAuthenticator>();
            builder.RegisterType<HmrcSettingsResolver>().As<IHmrcSettingsResolver>();
            builder.RegisterType<HmrcClient>().As<IHmrcClient>();
            builder.RegisterType<VatReturnStore>().As<IVatReturnStore>();
            builder.RegisterType<VatReturnsExporter>().As<IVatReturnsExporter>();
            builder.RegisterType<PdfDocument>().As<IPdfDocument>();
            builder.RegisterType<UserPreferenceManager>().As<IUserPreferenceManager>();
            builder.RegisterType<TimesheetList>().As<ITimesheetList>();
            builder.RegisterType<TimeSummaryProvider>().As<ITimeSummaryProvider>();
            builder.RegisterType<CaseSummaryNamesProvider>().As<ICaseSummaryNamesProvider>();
            builder.RegisterType<FraudPreventionHeaders>().As<IFraudPreventionHeaders>();
            builder.RegisterType<AccountingProvider>().As<IAccountingProvider>();
            builder.RegisterType<HmrcTokenResolver>().As<IHmrcTokenResolver>();
            builder.RegisterType<WipCosting>().As<IWipCosting>();
            builder.RegisterType<WipDefaulting>().As<IWipDefaulting>();
            builder.RegisterType<RecentCasesProvider>().As<IRecentCasesProvider>();
            builder.RegisterType<WipWarnings>().As<IWipWarnings>();
            builder.RegisterType<NameCreditLimitCheck>().As<INameCreditLimitCheck>();
            builder.RegisterType<DiaryDatesReader>().As<IDiaryDatesReader>();
            builder.RegisterType<BudgetWarnings>().As<IBudgetWarnings>();
            builder.RegisterType<DiaryUpdate>().As<IDiaryUpdate>();
            builder.RegisterType<WipWarningCheck>().As<IWipWarningCheck>();
            builder.RegisterType<TimerUpdate>().As<ITimerUpdate>();
            builder.RegisterType<PrepaymentWarningCheck>().As<IPrepaymentWarningCheck>();
            builder.RegisterType<BillingCapCheck>().As<IBillingCapCheck>();
            builder.RegisterType<TimeSearchService>().As<ITimeSearchService>();
            builder.RegisterType<ViewAccessAllowedStaffResolver>().As<IViewAccessAllowedStaffResolver>();
            builder.RegisterType<RatesCommand>().As<IRatesCommand>();
            builder.RegisterType<WipStatusEvaluator>().As<IWipStatusEvaluator>();
            builder.RegisterType<PostedWipAdjustor>().As<IPostedWipAdjustor>();
            
            builder.RegisterType<TimeSplitter>().As<ITimeSplitter>();
            builder.RegisterType<WipDebtorSelector>().As<IWipDebtorSelector>();
            builder.RegisterType<ValueTime>().As<IValueTime>();
            builder.RegisterType<ChainUpdater>().As<IChainUpdater>();
            builder.RegisterType<DiaryTimerUpdater>().As<IDiaryTimerUpdater>();
            builder.RegisterType<DebtorSplitUpdater>().As<IDebtorSplitUpdater>();
            builder.RegisterType<WipAdjustments>().As<IWipAdjustments>();
            builder.RegisterType<WipDisbursements>().As<IWipDisbursements>();
            builder.RegisterType<DebtorWipSplitter>().As<IDebtorWipSplitter>();
        }
    }
}