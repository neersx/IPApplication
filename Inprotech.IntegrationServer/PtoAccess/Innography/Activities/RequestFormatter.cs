
using System;

namespace Inprotech.IntegrationServer.PtoAccess.Innography.Activities
{
    public static class RequestFormatter
    {
        public static string DateOrNull(this DateTime? date)
        {
            return date?.ToString("yyyy-MM-dd");
        }
    }
}
