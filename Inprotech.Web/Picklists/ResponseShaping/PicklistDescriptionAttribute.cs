using System;
using System.ComponentModel;

namespace Inprotech.Web.Picklists.ResponseShaping
{
    [AttributeUsage(AttributeTargets.Property | AttributeTargets.Field)]
    public class PicklistDescriptionAttribute : DisplayNameAttribute
    {
        public PicklistDescriptionAttribute(string name = null) : base(name ?? "Description")
        {
        }
    }
}