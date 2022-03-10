using System.Collections.Generic;

namespace InprotechKaizen.Model.Components.Cases.DataEntryTasks
{
    public interface IDataEntryTaskHandlerInputFormatter
    {
        KeyValuePair<string, object>[] Format(KeyValuePair<string, string>[] inputs);
    }
}