using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Common;
using Inprotech.Web.Configuration.Core;
using InprotechKaizen.Model.Configuration.SiteControl;

namespace Inprotech.Tests.Web.Configuration.Core
{
    public static class SiteControlBuilderWrapper
    {
        public static SiteControl Generate(InMemoryDbContext db, string siteControlId, object siteControlValue)
        {
            return new SiteControlBuilder
            {
                SiteControlId = siteControlId,
                Value = siteControlValue
            }.Build().In(db);
        }

        public static SiteControlSearchOptions CreateSearchOptions(bool isByDescription = false, bool isByName = false,
                                                                   bool isByValue = false, int? versionId = null, string text = null)
        {
            return new SiteControlSearchOptions
            {
                IsByDescription = isByDescription,
                IsByName = isByName,
                IsByValue = isByValue,
                VersionId = versionId,
                Text = text
            };
        }
    }
}