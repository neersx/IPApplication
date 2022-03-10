using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using Newtonsoft.Json;

namespace InprotechKaizen.Model.Components.Cases.DataEntryTasks
{
    public class DataEntryTaskHandlerInputFormatter : IDataEntryTaskHandlerInputFormatter
    {
        readonly IEnumerable<IDataEntryTaskHandler> _handlers;

        public DataEntryTaskHandlerInputFormatter(IEnumerable<IDataEntryTaskHandler> handlers)
        {
            if (handlers == null) throw new ArgumentNullException("handlers");
            _handlers = handlers;
        }

        public KeyValuePair<string, object>[] Format(KeyValuePair<string, string>[] inputs)
        {
            var handlersMap = _handlers.ToDictionary(h => h.Name, h => h);

            return inputs.Where(i => handlersMap.ContainsKey(i.Key))
                         .Select(i =>
                                 {
                                     var handler = handlersMap[i.Key];
                                     var handlerInfo = DataEntryTaskHandlerInfoCache.Resolve(handler);
                                     var input = DeserializeInput(handlerInfo.InputType, i.Value);
                                     return new KeyValuePair<string, object>(i.Key, input);
                                 })
                         .ToArray();
        }

        static object DeserializeInput(Type inputType, string data)
        {
            if (string.IsNullOrWhiteSpace(data))
                return null;

            var setting = new JsonSerializerSettings {DateFormatString = "yyyy-MM-dd"};
            var serializer = JsonSerializer.Create(setting);
            return serializer.Deserialize(new StringReader(data), inputType);
        }
    }
}