using System;

namespace Inprotech.Infrastructure.Web
{
    [AttributeUsage(AttributeTargets.Class | AttributeTargets.Method, AllowMultiple = false)]
    public class PreallocateSessionAccessTokenAttribute : Attribute
    {
    }
}
