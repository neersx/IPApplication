using Autofac;
using InprotechKaizen.Model.Components.Cases.CriticalDates;

namespace InprotechKaizen.Model.Components.Cases
{
    class CasesModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<CaseStatusReader>().AsImplementedInterfaces();
            builder.RegisterType<GlobalNameChangeReader>().AsImplementedInterfaces();
            builder.RegisterType<GlobalNameChangeMonitor>().AsImplementedInterfaces();
            builder.RegisterType<PolicingStatusReader>().AsImplementedInterfaces();
            builder.RegisterType<PolicingStatusMonitor>().AsImplementedInterfaces();
            builder.RegisterType<PolicingChangeCaseIdProvider>().AsImplementedInterfaces().SingleInstance();
            builder.RegisterType<GlobalNameChangeCaseIdProvider>().AsImplementedInterfaces().SingleInstance();
            builder.RegisterType<CurrentNames>().As<ICurrentNames>();
            builder.RegisterType<CaseNameAddressResolver>().As<ICaseNameAddressResolver>();
            builder.RegisterType<CaseIndexesSearch>().As<ICaseIndexesSearch>();
            builder.RegisterType<ImportanceLevelResolver>().As<IImportanceLevelResolver>();
            builder.RegisterType<ExternalPatentInfoLinkResolver>().As<IExternalPatentInfoLinkResolver>();
            builder.RegisterType<DerivedAttention>().As<IDerivedAttention>();
            builder.RegisterType<NextRenewalDatesResolver>().As<INextRenewalDatesResolver>();
            builder.RegisterType<CaseHeaderPartial>().As<ICaseHeaderPartial>();
            builder.RegisterType<CpaXmlData>().As<ICpaXmlData>();
            builder.RegisterType<GlobalNameChangeCommand>().As<IGlobalNameChangeCommand>();
            builder.RegisterType<CaseTextResolver>().As<ICaseTextResolver>();
        }
    }
}
