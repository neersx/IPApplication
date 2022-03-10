using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Tests.Integration.DbHelpers.Builders
{
    class OfficeBuilder : Builder
    {
        public OfficeBuilder(IDbContext dbContext) : base(dbContext)
        {

        }
        
        public Office Create(string name)
        {
            var tableCode = InsertWithNewId(new TableCode {TableTypeId = (int)TableTypes.Office});
            return InsertWithNewId(new Office(tableCode.Id, name));
        }
    }
}
