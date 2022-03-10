using System;
using System.Linq;
using System.Reflection;
using System.Web.Http;
using Inprotech.Infrastructure.Security;

namespace Inprotech.Tests.Web
{
    public static class TaskSecurity
    {
        public static bool Secures<T>(ApplicationTask applicationTask) where T : ApiController
        {
            return typeof(T)
                   .GetCustomAttributes(typeof(RequiresAccessToAttribute))
                   .Cast<RequiresAccessToAttribute>()
                   .Any(_ => _.Task == applicationTask);
        }

        public static bool Secures<T>(ApplicationTask applicationTask, ApplicationTaskAccessLevel level) where T : ApiController
        {
            return typeof(T)
                   .GetCustomAttributes(typeof(RequiresAccessToAttribute))
                   .Cast<RequiresAccessToAttribute>()
                   .Any(_ => _.Task == applicationTask && _.Level == level);
        }

        public static bool Secures<T>(string methodName, ApplicationTask applicationTask) where T : ApiController
        {
            var methodInfo = typeof(T).GetMethods()
                                      .SingleOrDefault(_ => _.Name == methodName);

            if (methodInfo == null)
            {
                throw new Exception($"{methodName} not found in {typeof(T).Name}.  Did you recently change a method name?");
            }

            return methodInfo.GetCustomAttributes(typeof(RequiresAccessToAttribute))
                             .Cast<RequiresAccessToAttribute>()
                             .Any(_ => _.Task == applicationTask);
        }

        public static bool Secures<T>(string methodName, ApplicationTask applicationTask, ApplicationTaskAccessLevel level) where T : ApiController
        {
            var methodInfo = typeof(T).GetMethods()
                                      .SingleOrDefault(_ => _.Name == methodName);

            if (methodInfo == null)
            {
                throw new Exception($"{methodName} not found in {typeof(T).Name}.  Did you recently change a method name?");
            }

            return methodInfo.GetCustomAttributes(typeof(RequiresAccessToAttribute))
                             .Cast<RequiresAccessToAttribute>()
                             .Any(_ => _.Task == applicationTask && _.Level == level);
        }
    }
}