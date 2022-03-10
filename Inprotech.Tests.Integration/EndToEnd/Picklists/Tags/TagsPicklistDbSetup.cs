using Inprotech.Tests.Integration.DbHelpers;
using InprotechKaizen.Model.Configuration.SiteControl;

namespace Inprotech.Tests.Integration.EndToEnd.Picklists.Tags
{
    class TagsPicklistDbSetup : DbSetup
    {
        public const string ControlId = "e2e";
        public dynamic DataSetUp()
        {
            SiteControl obj = new SiteControl();
            obj.ControlId = ControlId;
            obj.DataType = "C";
            DbContext.Set<SiteControl>().Add(obj);
            DbContext.SaveChanges();

            return new
            {
                ControlId
            };
        }
    }
}
