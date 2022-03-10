using Inprotech.Tests.Fakes;
using InprotechKaizen.Model.Configuration;

namespace Inprotech.Tests.Web.Builders.Model.Configuration
{
    public class SelectionTypesBuilder
    {
        readonly InMemoryDbContext _db;

        public SelectionTypesBuilder(InMemoryDbContext db)
        {
            _db = db;
        }

        public TableType TableType { get; set; }
        public string ParentTable { get; set; }

        public SelectionTypes Build()
        {
            return new SelectionTypes(TableType ?? new TableTypeBuilder(_db).BuildWithTableCodes())
            {
                ParentTable = ParentTable
            };
        }
    }
}