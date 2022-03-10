using System;

namespace Inprotech.Infrastructure.Security
{
    [AttributeUsage(AttributeTargets.Method)]
    public class AuthorizeCriteriaPurposeCodeTaskSecurityAttribute : Attribute
    {
        public static string[] CommonPropertyNames = { "purposeCode" };
        public string PropertyName { get; set; }
    }
}