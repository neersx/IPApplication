using System;

namespace Inprotech.Web.Picklists.ResponseShaping
{
    [AttributeUsage(AttributeTargets.Property | AttributeTargets.Field)]
    public class DisplayOrderAttribute : Attribute
    {
        public readonly int Order;

        public DisplayOrderAttribute(int order)
        {
            Order = order;
        }
    }
}