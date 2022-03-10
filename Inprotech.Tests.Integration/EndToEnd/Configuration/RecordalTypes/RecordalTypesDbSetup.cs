using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using InprotechKaizen.Model.Cases.AssignmentRecordal;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.RecordalTypes
{
    public class RecordalTypesDbSetup : DbSetup
    {
        public dynamic SetupRecordalTypes()
        {
            var event1 = new EventBuilder(DbContext).Create();
            var action1 = new ActionBuilder(DbContext).Create();
            var rt1 = InsertWithNewId(new RecordalType { RecordalTypeName = "E2e Recordal Type1", RequestEvent = event1, RequestAction = action1 });
            var rt2 = InsertWithNewId(new RecordalType { RecordalTypeName = "E2e Recordal Type2", RecordEvent = event1, RecordAction = action1 });
            InsertWithNewId(new RecordalType { RecordalTypeName = "Recordal Type3" });
            return new
            {
                rt1,
                rt2
            };
        }
    }
}
