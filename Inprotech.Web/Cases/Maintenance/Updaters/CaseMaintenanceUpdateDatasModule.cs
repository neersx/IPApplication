using Autofac;
using Inprotech.Web.Maintenance.Topics;

namespace Inprotech.Web.Cases.Maintenance.Updaters
{
    public class CaseMaintenanceUpdateDatasModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            builder.RegisterType<ActionsTopicDataUpdater>()
                   .Keyed<ITopicDataUpdater<InprotechKaizen.Model.Cases.Case>>(TopicGroups.Cases + KnownCaseMaintenanceTopics.Actions);
            builder.RegisterType<DesignElementsTopicUpdater>()
                   .Keyed<ITopicDataUpdater<InprotechKaizen.Model.Cases.Case>>(TopicGroups.Cases + KnownCaseMaintenanceTopics.DesignElements);
            builder.RegisterType<ChecklistQuestionsTopicUpdater>()
                   .Keyed<ITopicDataUpdater<InprotechKaizen.Model.Cases.Case>>(TopicGroups.Cases + KnownCaseMaintenanceTopics.ChecklistQuestions);
            builder.RegisterType<FileLocationsTopicUpdater>()
                   .Keyed<ITopicDataUpdater<InprotechKaizen.Model.Cases.Case>>(TopicGroups.Cases + KnownCaseMaintenanceTopics.FileLocations);
            builder.RegisterType<AffectedCasesTopicUpdater>()
                   .Keyed<ITopicDataUpdater<InprotechKaizen.Model.Cases.Case>>(TopicGroups.Cases + KnownCaseMaintenanceTopics.AffectedCases);
        }
    }
}
