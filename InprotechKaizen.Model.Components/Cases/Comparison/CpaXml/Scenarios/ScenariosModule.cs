using Autofac;

namespace InprotechKaizen.Model.Components.Cases.Comparison.CpaXml.Scenarios
{
    public class ScenariosModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<CompareEventsScenario>().As<IComparisonScenarioResolver>();
            builder.RegisterType<CompareNamesScenario>().As<IComparisonScenarioResolver>();
            builder.RegisterType<CompareRelatedCasesScenario>().As<IComparisonScenarioResolver>();
            builder.RegisterType<CompareNumbersScenario>().As<IComparisonScenarioResolver>();
            builder.RegisterType<CompareGoodsServicesScenario>().As<IComparisonScenarioResolver>();
            builder.RegisterType<CompareCaseHeaderScenario>().As<IComparisonScenarioResolver>();
            builder.RegisterType<CompareMatchingNumberEventScenario>().As<IComparisonScenarioResolver>();
            builder.RegisterType<CompareVerifiedRelatedCasesScenario>().As<IComparisonScenarioResolver>();
            builder.RegisterType<CompareTypeOfMarkScenerio>().As<IComparisonScenarioResolver>();
        }
    }
}
