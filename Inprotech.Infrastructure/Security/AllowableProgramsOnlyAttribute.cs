using System;

namespace Inprotech.Infrastructure.Security
{
    [AttributeUsage(AttributeTargets.Method)]
    public class AllowableProgramsOnlyAttribute : Attribute
    {
        public static string[] _commonPropertyNames = { "programId" };

        public string PropertyName { get; set; }
    }
}