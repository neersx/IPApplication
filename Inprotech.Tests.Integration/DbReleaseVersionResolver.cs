using System.Linq;
using Inprotech.Infrastructure;
using InprotechKaizen.Model.Configuration.SiteControl;

namespace Inprotech.Tests.Integration
{
    public class DbReleaseVersionResolver
    {
        public int ResolveDbReleaseLevel()
        {
            var releaseLevel = DbHelpers.DbSetup.Do(x =>
            {
                var raw = (from sc in x.DbContext.Set<SiteControl>()
                           where sc.ControlId == SiteControls.DBReleaseVersion
                           select sc.StringValue).Single();

                return raw.ToLower()
                          .Replace("release", string.Empty)
                          .Replace("beta", string.Empty)
                          .Replace("preview", string.Empty)
                          .Trim();
            });

            if (int.TryParse(releaseLevel, out int r))
                return r;

            return -1;
        }
    }
}