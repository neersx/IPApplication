using Autofac;
using Inprotech.Web.Configuration.ValidCombinations;
using Inprotech.Web.Search.Case;
using Inprotech.Web.Search.Name;

namespace Inprotech.Web.Picklists
{
    public class PicklistsModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<InstructionTypesPicklistMaintenance>().As<IInstructionTypesPicklistMaintenance>();
            builder.RegisterType<InstructionsPicklistMaintenance>().As<IInstructionsPicklistMaintenance>();
            builder.RegisterType<PropertyTypesPicklistMaintenance>().As<IPropertyTypesPicklistMaintenance>();
            builder.RegisterType<BasisPicklistMaintenance>().As<IBasisPicklistMaintenance>();
            builder.RegisterType<SubTypesPicklistMaintenance>().As<ISubTypesPicklistMaintenance>();
            builder.RegisterType<ActionsPicklistMaintenance>().As<IActionsPicklistMaintenance>();
            builder.RegisterType<EventsPicklistMaintenance>().As<IEventsPicklistMaintenance>();
            builder.RegisterType<ChecklistPickListMaintenance>().As<IChecklistPicklistMaintenance>();
            builder.RegisterType<CaseCategoriesPicklistMaintenance>().As<ICaseCategoriesPicklistMaintenance>();
            builder.RegisterType<RelationshipPicklistMaintenance>().As<IRelationshipPicklistMaintenance>();
            builder.RegisterType<CaseTypesPicklistMaintenance>().As<ICaseTypesPicklistMaintenance>();
            builder.RegisterType<TableCodePicklistMaintenance>().As<ITableCodePicklistMaintenance>();
            builder.RegisterType<EventCategoryPicklistMaintenance>().As<IEventCategoryPicklistMaintenance>();
            builder.RegisterType<TagsPicklistMaintenance>().As<ITagsPicklistMaintenance>();
            builder.RegisterType<NameTypeGroupsPicklistMaintenance>().As<INameTypeGroupsPicklistMaintenance>();
            builder.RegisterType<DataItemGroupPicklistMaintenance>().As<IDataItemGroupPicklistMaintenance>();
            builder.RegisterType<DateOfLawPicklistMaintenance>().As<IDateOfLawPicklistMaintenance>();
            builder.RegisterType<ClassItemsPicklistMaintenance>().As<IClassItemsPicklistMaintenance>();
            builder.RegisterType<ValidActionsController>().AsSelf();
            builder.RegisterType<ValidPropertyTypesController>().AsSelf();
            builder.RegisterType<ValidBasisController>().AsSelf();
            builder.RegisterType<EventMatcher>().As<IEventMatcher>();
            builder.RegisterType<ListCase>().As<IListCase>();
            builder.RegisterType<ListName>().As<IListName>();
            builder.RegisterType<WipTemplateMatcher>().As<IWipTemplateMatcher>();
            builder.RegisterType<SearchGroupPicklistMaintenance>().As<ISearchGroupPicklistMaintenance>();
            builder.RegisterType<ColumnGroupPicklistMaintenance>().As<IColumnGroupPicklistMaintenance>();
            builder.RegisterType<CaseListMaintenance>().As<ICaseListMaintenance>();
            builder.RegisterType<FilePartPicklistMaintenance>().As<IFilePartPicklistMaintenance>();
            builder.RegisterType<CaseEventMatcher>().As<ICaseEventMatcher>();
        }
    }
}
