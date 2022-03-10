using Autofac;

namespace InprotechKaizen.Model.Components.Cases.Comparison.DataMapping.Mappers
{
    public class MapperModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<EventsMapper>()
                   .As<IComparisonScenarioMapper>()
                   .WithMetadata("ComparisonType", ComparisonType.Events);

            builder.RegisterType<NamesMapper>()
                   .As<IComparisonScenarioMapper>()
                   .WithMetadata("ComparisonType", ComparisonType.Names);

            builder.RegisterType<RelatedCasesMapper>()
                   .As<IComparisonScenarioMapper>()
                   .WithMetadata("ComparisonType", ComparisonType.RelatedCases);

            builder.RegisterType<VerifiedRelatedCasesMapper>()
                   .As<IComparisonScenarioMapper>()
                   .WithMetadata("ComparisonType", ComparisonType.VerifiedRelatedCases);
            
            builder.RegisterType<NumbersMapper>()
                   .As<IComparisonScenarioMapper>()
                   .WithMetadata("ComparisonType", ComparisonType.OfficialNumbers);

            builder.RegisterType<MatchingNumberEventMapper>()
                   .As<IComparisonScenarioMapper>()
                   .WithMetadata("ComparisonType", ComparisonType.MatchingNumberEvents);

            builder.RegisterType<TypeOfMarkMapper>()
                   .As<IComparisonScenarioMapper>()
                   .WithMetadata("ComparisonType", ComparisonType.TypeOfMark);

            builder.RegisterType<MapperSelector>().As<IMapperSelector>();

            builder.RegisterType<CommonEventMapper>().As<ICommonEventMapper>();
        }
    }
}