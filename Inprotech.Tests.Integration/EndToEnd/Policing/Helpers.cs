using System;
using System.Linq;
using InprotechKaizen.Model.Configuration.SiteControl;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Tests.Integration.EndToEnd.Policing
{
    static class Helpers
    {
        static int _secs = 1;

        internal static DateTime UniqueDateTime(DateTime? dateTime = null)
        {
            return (dateTime ?? DateTime.Today).AddSeconds(_secs++);
        }

        internal static void SetPolicingServerOff(IDbContext dbContext)
        {
            var siteControl = dbContext.Set<SiteControl>()
                                       .Single(_ => _.ControlId == Infrastructure.SiteControls.PoliceContinuously);

            siteControl.BooleanValue = false;
            dbContext.SaveChanges();
        }

        internal static string GetCaseRefLink(string irn)
        {
            irn = irn.Replace("#", "%23");
            return "default.aspx?caseref=" + irn;
        }

        internal static string FormatIso8601OrNull(string dateString)
        {
            if (string.IsNullOrWhiteSpace(dateString))
                return null;

            if (DateTime.TryParse(dateString, out var result))
                return result.ToString("yyyy-MM-dd");

            return dateString;
        }

        internal static string AsIso8601OrNull(this string dateString)
        {
            return FormatIso8601OrNull(dateString);
        }
        
        internal static string AsIso8601OrNull(this DateTime date)
        {
            return date.ToString("yyyy-MM-dd");
        }

        internal static string AsIso8601OrNull(this DateTime? date)
        {
            return date?.ToString("yyyy-MM-dd");
        }
    }
}