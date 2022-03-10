using System;
using System.Threading.Tasks;
using Inprotech.Contracts;

namespace Inprotech.Infrastructure.Extensions
{
    public static class TaskExtensions
    {
        public static Task<T> OnException<T>(
            this Task<T> task,
            Func<AggregateException, T> handler,
            ILogger logger = null)
        {
            if(task == null) throw new ArgumentNullException("task");

            return task.ContinueWith(
                                     t =>
                                     {
                                         if(t.Status != TaskStatus.Faulted)
                                             return t.Result;

                                         if(logger != null)
                                             logger.Exception(t.Exception);

                                         return handler(t.Exception);
                                     },
                                     TaskContinuationOptions.ExecuteSynchronously);
        }
    }
}