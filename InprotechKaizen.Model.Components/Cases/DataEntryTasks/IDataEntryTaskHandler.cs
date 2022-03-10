using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Rules;

namespace InprotechKaizen.Model.Components.Cases.DataEntryTasks
{
    public interface IDataEntryTaskHandler
    {
        string Name { get; }
    }

    public interface IDataEntryTaskHandler<T1> : IDataEntryTaskHandler
    {
        DataEntryTaskHandlerOutput Validate(Case @case, DataEntryTask dataEntryTask, T1 data);
        DataEntryTaskHandlerOutput ApplyChanges(Case @case, DataEntryTask dataEntryTask, T1 data);
    }
}