using System;

namespace Inprotech.Infrastructure.Security
{
    [AttributeUsage(AttributeTargets.Method, AllowMultiple = true)]
    public class RequiresNameAuthorizationAttribute : Attribute
    {
        public static string[] CommonPropertyNames = {"nameKey", "nameId", "NameKey", "NameId"};
        
        public RequiresNameAuthorizationAttribute(AccessPermissionLevel minimumAccessPermission = AccessPermissionLevel.Select)
        {
            MinimumAccessPermission = minimumAccessPermission;
        }
        
        public AccessPermissionLevel MinimumAccessPermission { get; }
        
        public string PropertyName { get; set; }

        public string PropertyPath { get; set; }
    }
}