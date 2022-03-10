using System;
using System.Linq;
using System.Linq.Expressions;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Rules;

namespace InprotechKaizen.Model.Components.Cases.DataEntryTasks
{
    public class DataEntryTaskHandlerInfo
    {
        public Func<object, Case, DataEntryTask, object, DataEntryTaskHandlerOutput> ValidateThunk { get; private set; }

        public Func<object, Case, DataEntryTask, object, DataEntryTaskHandlerOutput> ApplyChangesThunk
        {
            get;
            private set;
        }

        public Type InputType { get; private set; }

        public static DataEntryTaskHandlerInfo For(IDataEntryTaskHandler handler)
        {
            if(handler == null) throw new ArgumentNullException("handler");

            var genericHandlerType =
                handler.GetType().GetInterfaces().Single(
                                                         t =>
                                                         t.IsGenericType &&
                                                         t.GetGenericTypeDefinition() == typeof(IDataEntryTaskHandler<>));

            return new DataEntryTaskHandlerInfo
                   {
                       ValidateThunk = BuildThunkedCallsite("Validate", genericHandlerType),
                       ApplyChangesThunk = BuildThunkedCallsite("ApplyChanges", genericHandlerType),
                       InputType = genericHandlerType.GetGenericArguments()[0]
                   };
        }

        static Func<object, Case, DataEntryTask, object, DataEntryTaskHandlerOutput> BuildThunkedCallsite(
            string methodName,
            Type genericHandlerType)
        {
            var inputType = genericHandlerType.GetGenericArguments()[0];
            var handlerParameter = Expression.Parameter(typeof(object));
            var caseParameter = Expression.Parameter(typeof(Case));
            var dataEntryTaskParameter = Expression.Parameter(typeof(DataEntryTask));
            var dataParameter = Expression.Parameter(typeof(object));
            var castedHandler = Expression.Convert(handlerParameter, genericHandlerType);
            var castedData = Expression.Convert(dataParameter, inputType);

            var call =
                Expression.Call(castedHandler, methodName, null, caseParameter, dataEntryTaskParameter, castedData);

            var lambda = Expression.Lambda<Func<object, Case, DataEntryTask, object, DataEntryTaskHandlerOutput>>(
                                                                                                                  call,
                                                                                                                  handlerParameter,
                                                                                                                  caseParameter,
                                                                                                                  dataEntryTaskParameter,
                                                                                                                  dataParameter);
            return lambda.Compile();
        }
    }
}