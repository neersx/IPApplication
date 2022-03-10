using System;
using System.Collections.Concurrent;

namespace InprotechKaizen.Model.Components.Cases.DataEntryTasks
{
    public static class DataEntryTaskHandlerInfoCache
    {
        static readonly ConcurrentDictionary<Type, DataEntryTaskHandlerInfo> Cache =
            new ConcurrentDictionary<Type, DataEntryTaskHandlerInfo>();

        public static DataEntryTaskHandlerInfo Resolve(IDataEntryTaskHandler handler)
        {
            if(handler == null) throw new ArgumentNullException("handler");

            var handlerType = handler.GetType();
            return Cache.GetOrAdd(handlerType, t => DataEntryTaskHandlerInfo.For(handler));
        }
    }
}