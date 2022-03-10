using Autofac;
using InprotechKaizen.Model.Components.Accounting.Wip;

namespace InprotechKaizen.Model.Components.Accounting.Time
{
    public class TimeModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);
            builder.RegisterType<PostTimeCommand>().As<IPostTimeCommand>();
            builder.RegisterType<TimesheetList>().As<ITimesheetList>();
            builder.RegisterType<WipCosting>().As<IWipCosting>();
            builder.RegisterType<TimeSplitter>().As<ITimeSplitter>();
            builder.RegisterType<WipDebtorSelector>().As<IWipDebtorSelector>();
            builder.RegisterType<ValueTime>().As<IValueTime>();
            builder.RegisterType<ChainUpdater>().As<IChainUpdater>();
            builder.RegisterType<DiaryTimerUpdater>().As<IDiaryTimerUpdater>();
            builder.RegisterType<DebtorSplitUpdater>().As<IDebtorSplitUpdater>();
            builder.RegisterType<DebtorWipSplitter>().As<IDebtorWipSplitter>();
            builder.RegisterType<GetWipCostCommand>().As<IGetWipCostCommand>();
        }
    }
}
