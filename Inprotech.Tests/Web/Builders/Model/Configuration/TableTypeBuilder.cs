using Inprotech.Tests.Fakes;
using InprotechKaizen.Model.Configuration;

namespace Inprotech.Tests.Web.Builders.Model.Configuration
{
    public class TableTypeBuilder
    {
        readonly InMemoryDbContext _db;

        public TableTypeBuilder(InMemoryDbContext db)
        {
            _db = db;
        }

        public short? Id { get; set; }
        public string Name { get; set; }
        public string DatabaseTable { get; set; }

        public TableType Build()
        {
            return new TableType(Id ?? Fixture.Short())
            {
                Name = Name ?? Fixture.String(),
                DatabaseTable = DatabaseTable ?? Fixture.String()
            };
        }

        public TableType BuildWithTableCodes()
        {
            var builtTableType = Build();

            var tableCode1 = new TableCodeBuilder {TableType = builtTableType.Id}.Build().In(_db);
            var tableCode2 = new TableCodeBuilder {TableType = builtTableType.Id}.Build().In(_db);
            builtTableType.TableCodes.Add(tableCode1);
            builtTableType.TableCodes.Add(tableCode2);
            return builtTableType;
        }
    }

    public static class TableTypeBuilderExt
    {
        public static TableTypeBuilder For(this TableTypeBuilder builder, TableTypes tableType)
        {
            builder.Id = (short) tableType;
            return builder;
        }
    }
}