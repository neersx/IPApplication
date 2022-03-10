using System;

namespace Inprotech.Infrastructure.Formatting
{
    [AttributeUsage(AttributeTargets.Method | AttributeTargets.Class, AllowMultiple = true)]
    public class UseHeaderContentTypeAttribute : Attribute
    {
    }
}
