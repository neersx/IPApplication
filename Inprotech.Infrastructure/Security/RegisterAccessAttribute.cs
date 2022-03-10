using System;

namespace Inprotech.Infrastructure.Security
{
    [AttributeUsage(AttributeTargets.Method)]
    public class RegisterAccessAttribute : Attribute
    {
        public static string[] CommonPropertyNames = {"caseKey", "caseId", "CaseKey", "CaseId"};

        public string PropertyName { get; set; }

        public string PropertyPath { get; set; }
    }
}