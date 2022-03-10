using Autofac;

namespace InprotechKaizen.Model.Components.Cases.Comparison.Comparers
{
    public class ComparerModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<NamesComparer>().As<ISpecificComparer>();
            builder.RegisterType<NumbersComparer>().As<ISpecificComparer>();
            builder.RegisterType<CaseHeaderComparer>().As<ISpecificComparer>();
            builder.RegisterType<GoodsServicesComparer>().As<ISpecificComparer>();
            builder.RegisterType<TypeOfMarkComparer>().As<ISpecificComparer>();
           
            // The below RelatedCasesComparers writes to the same Result property,
            // they are mutually exclusive, based on different CpaXmlComparisonScenario
            builder.RegisterType<ParentRelatedCasesComparer>().As<ISpecificComparer>();
            builder.RegisterType<VerifiedParentRelatedCasesComparer>().As<ISpecificComparer>();

            builder.RegisterType<ClassStringComparer>().As<IClassStringComparer>();
            builder.RegisterType<UseDateComparer>().As<IUseDateComparer>();
            
            builder.RegisterType<DatesAligner>().As<IDatesAligner>();
            builder.RegisterType<RelatedCaseFinder>().As<IRelatedCaseFinder>();
            builder.RegisterType<RelatedCaseResultBuilder>().As<IRelatedCaseResultBuilder>();

            builder.RegisterType<EventsComparer>().AsImplementedInterfaces();

            builder.RegisterType<GoodServicesProviderSelector>().As<IGoodsServicesProviderSelector>();
            builder.RegisterType<DefaultGoodsServicesProvider>().As<IGoodsServicesProvider>();
            builder.RegisterType<InnographyGoodsServicesProvider>()
                   .Keyed<IGoodsServicesProvider>("IpOneData");

            builder.RegisterType<GoodServicesDataResolverSelector>().As<IGoodsServicesDataResolverSelector>();
            builder.RegisterType<DefaultGoodsServicesDataResolver>().As<IGoodsServicesDataResolver>();
            builder.RegisterType<InnographyGoodsServicesDataResolver>()
                   .Keyed<IGoodsServicesDataResolver>("IpOneData");
        }
    }
}