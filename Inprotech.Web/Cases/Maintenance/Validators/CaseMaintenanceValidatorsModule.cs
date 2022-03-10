using Autofac;
using Inprotech.Web.Maintenance.Topics;
using InprotechKaizen.Model.Cases;

namespace Inprotech.Web.Cases.Maintenance.Validators
{
    public class CaseMaintenanceValidatorsModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            builder.RegisterType<ActionsTopicValidator>()
                   .Keyed<ITopicValidator<Case>>(TopicGroups.Cases + KnownCaseMaintenanceTopics.Actions);
            builder.RegisterType<DesignElementsTopicValidator>()
                   .Keyed<ITopicValidator<Case>>(TopicGroups.Cases + KnownCaseMaintenanceTopics.DesignElements);
            builder.RegisterType<ChecklistQuestionsTopicValidator>()
                   .Keyed<ITopicValidator<Case>>(TopicGroups.Cases + KnownCaseMaintenanceTopics.ChecklistQuestions);
            builder.RegisterType<FileLocationsTopicValidator>()
                   .Keyed<ITopicValidator<Case>>(TopicGroups.Cases + KnownCaseMaintenanceTopics.FileLocations);
            builder.RegisterType<AffectedCasesTopicValidator>()
                   .Keyed<ITopicValidator<Case>>(TopicGroups.Cases + KnownCaseMaintenanceTopics.AffectedCases);
        }
    }
}