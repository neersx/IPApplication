using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Names;

namespace Inprotech.Tests.Web.Builders.Model.Configuration
{
    public class TableAttributesBuilder : IBuilder<TableAttributes>
    {
        public string GenericKey { get; set; }
        public string ParentTable { get; set; }
        public short? TableTypeId { get; set; }
        public int? TableCodeId { get; set; }

        public TableAttributes Build()
        {
            return new TableAttributes(ParentTable ?? Fixture.String(), GenericKey ?? Fixture.String())
            {
                SourceTableId = TableTypeId ?? Fixture.Short(),
                TableCodeId = TableCodeId ?? Fixture.Integer()
            };
        }

        public static TableAttributesBuilder ForCase(Case @case)
        {
            return new TableAttributesBuilder
            {
                GenericKey = @case.Id.ToString(),
                ParentTable = "CASES"
            };
        }

        public static TableAttributesBuilder ForName(Name name)
        {
            return new TableAttributesBuilder
            {
                GenericKey = name.Id.ToString(),
                ParentTable = "NAME"
            };
        }

        public static TableAttributesBuilder ForCountry(Country country)
        {
            return new TableAttributesBuilder
            {
                GenericKey = country.Id,
                ParentTable = "COUNTRY"
            };
        }
    }

    public static class TableAttributesBuilderExtension
    {
        public static TableAttributesBuilder WithAttribute(
            this TableAttributesBuilder builder,
            TableTypes tableType,
            int value)
        {
            builder.TableTypeId = (short) tableType;
            builder.TableCodeId = value;
            return builder;
        }
    }
}