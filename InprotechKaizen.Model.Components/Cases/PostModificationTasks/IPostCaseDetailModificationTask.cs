using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Rules;

namespace InprotechKaizen.Model.Components.Cases.PostModificationTasks
{
    public interface IPostCaseDetailModificationTask
    {
        PostCaseDetailModificationTaskResult Run(
            Case @case,
            DataEntryTask dataEntryTask,
            AvailableEventToConsider[] eventsToConsider);
    }
}