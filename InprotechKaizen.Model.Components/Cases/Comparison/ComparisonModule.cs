using System.Diagnostics.CodeAnalysis;
using Autofac;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases.Comparison.Updaters;
using InprotechKaizen.Model.Components.Policing;

namespace InprotechKaizen.Model.Components.Cases.Comparison
{
    public class ComparisonModule : Module
    {
        [SuppressMessage("Microsoft.Maintainability", "CA1506:AvoidExcessiveClassCoupling")]
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<CaseComparer>().As<ICaseComparer>();
            builder.RegisterType<CaseSecurity>().As<ICaseSecurity>();
            builder.RegisterType<ComparisonPreprocessor>().As<IComparisonPreprocessor>();
            builder.RegisterType<ComparisonUpdater>().As<IComparisonUpdater>();
            builder.RegisterType<CaseUpdater>().As<ICaseUpdater>();
            builder.RegisterType<OfficialNumberUpdater>().As<IOfficialNumberUpdater>();
            builder.RegisterType<CaseNameUpdator>().As<ICaseNameUpdator>();
            builder.RegisterType<CurrentOfficialNumberUpdater>().As<ICurrentOfficialNumberUpdater>();
            builder.RegisterType<EventUpdater>().As<IEventUpdater>();
            builder.RegisterType<PolicingUtility>().As<IPolicingUtility>();
            builder.RegisterType<GoodsServicesUpdater>().As<IGoodsServicesUpdater>();
            builder.RegisterType<CaseComparisonEvent>().As<ICaseComparisonEvent>();
            builder.RegisterType<CaseImageImporter>().AsImplementedInterfaces();
            builder.RegisterType<CaseImagePngConverter>().AsImplementedInterfaces();
            builder.RegisterType<IntegrationFileImageWriter>().AsImplementedInterfaces();
            builder.RegisterType<CaseImageSequenceNumberReorderer>().AsImplementedInterfaces();
            builder.RegisterType<BatchPolicingRequest>().AsImplementedInterfaces();
        }
    }
}
