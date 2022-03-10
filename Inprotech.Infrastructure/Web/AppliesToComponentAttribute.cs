using System;

namespace Inprotech.Infrastructure.Web
{
    [AttributeUsage(AttributeTargets.Method | AttributeTargets.Class)]
    public class AppliesToComponentAttribute : Attribute
    {
        public AppliesToComponentAttribute(string componentName)
        {
            ComponentName = componentName;
        }

        public string ComponentName { get; }
    }
}
