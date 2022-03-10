using System;

namespace Inprotech.Infrastructure.Security
{
    [AttributeUsage(AttributeTargets.Method, AllowMultiple = true)]
    public class RequiresCaseAuthorizationAttribute : Attribute
    {
        public static string[] CommonPropertyNames = {"caseKey", "caseId", "CaseKey", "CaseId"};
        
        public RequiresCaseAuthorizationAttribute(AccessPermissionLevel minimumAccessPermission = AccessPermissionLevel.Select)
        {
            MinimumAccessPermission = minimumAccessPermission;
        }
        
        public AccessPermissionLevel MinimumAccessPermission { get; }
        
        public string PropertyName { get; set; }

        public string PropertyPath { get; set; }
    }
}