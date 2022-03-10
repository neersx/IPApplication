using Dependable;

namespace Inprotech.Tests.Extensions
{
    public static class DependableActivityExt
    {
        public static string TypeAndMethod(this SingleActivity activity)
        {
            return activity.Type.Name + "." + activity.Name;
        }
    }
}