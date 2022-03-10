using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Configuration;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.FileLocationOffice
{
    public class FileLocationOfficeDbSetup : DbSetup
    {
        public dynamic SetupOffices()
        {
            var f1 = InsertWithNewId(new TableCode {TableTypeId = (short) TableTypes.FileLocation, Name = "1E2e1"});
            var f2 = InsertWithNewId(new TableCode {TableTypeId = (short) TableTypes.FileLocation, Name = "1E2e2"});
            var o1 = new OfficeBuilder(DbContext).Create("E2e office 1");
            var o2 = new OfficeBuilder(DbContext).Create("E2e office 2");
            var fo = new InprotechKaizen.Model.Cases.FileLocationOffice(f1, o1);

            DbContext.Set<InprotechKaizen.Model.Cases.FileLocationOffice>().Add(fo);
            DbContext.SaveChanges();

            return new
            {
                f1,
                f2,
                o1,
                o2,
                fo
            };
        }
    }
}
