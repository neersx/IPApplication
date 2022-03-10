using System;

namespace InprotechKaizen.Model.Components.Cases.DataEntryTasks
{
    public class DataEntryTaskHandlerResult
    {
        public DataEntryTaskHandlerResult(string handlerName, DataEntryTaskHandlerOutput output)
        {
            if(output == null) throw new ArgumentNullException("output");
            if(string.IsNullOrWhiteSpace(handlerName)) throw new ArgumentException("A valid handlerName is required.");

            HandlerName = handlerName;
            Output = output;
        }

        public string HandlerName { get; private set; }
        public DataEntryTaskHandlerOutput Output { get; set; }
    }
}