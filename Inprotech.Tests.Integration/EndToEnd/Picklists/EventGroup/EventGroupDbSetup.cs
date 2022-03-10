using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Configuration;

namespace Inprotech.Tests.Integration.EndToEnd.Picklists.EventGroup
{
    public class EventGroupDbSetup : DbSetup
    {
        TableCode _existingEventGroup;

        public ScenarioData DataSetup()
        {
            _existingEventGroup = InsertWithNewId(new TableCode
                                                     {
                                                         Name = Fixture.String(10),
                                                         UserCode = Fixture.String(5),
                                                         TableTypeId = (int)TableTypes.EventGroup
                                                     });
            DbContext.SaveChanges();

            return new ScenarioData
                   {
                       ExistingEventGroup = _existingEventGroup.Name
                   };
        }

        public class ScenarioData
        {
            public string ExistingEventGroup { get; set; }
        }
    }
}