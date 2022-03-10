using InprotechKaizen.Model.Configuration;

namespace Inprotech.Tests.Web.Builders.Model.Configuration
{
    public class TableCodeBuilder : IBuilder<TableCode>
    {
        public int? TableCode { get; set; }

        public string Description { get; set; }

        public short? TableType { get; set; }

        public string UserCode { get; set; }

        public TableCode Build()
        {
            return new TableCode(
                                 TableCode ?? Fixture.Integer(),
                                 TableType ?? Fixture.Short(),
                                 Description ?? Fixture.String())
            {
                UserCode = UserCode
            };
        }
    }

    public static class TableCodeBuilderExt
    {
        public static TableCodeBuilder For(this TableCodeBuilder builder, TableTypes tableType)
        {
            builder.TableType = (short) tableType;
            return builder;
        }
    }
}