using System.Linq;
using System.Web.Http.Filters;

namespace Inprotech.Infrastructure.ResponseShaping.Picklists
{
    public static class PicklistPayloadDataExtensions
    {
        public static PicklistPayloadAttribute PicklistPayloadAttribute(this HttpActionExecutedContext context)
        {
            return context.ActionContext.ActionDescriptor.GetCustomAttributes<PicklistPayloadAttribute>().SingleOrDefault();
        }

        public static PicklistMaintainabilityActionsAttribute PicklistMaintainabilityActionsAttribute(this HttpActionExecutedContext context)
        {
            return context.ActionContext.ActionDescriptor.GetCustomAttributes<PicklistMaintainabilityActionsAttribute>().SingleOrDefault();
        }
    }
}
