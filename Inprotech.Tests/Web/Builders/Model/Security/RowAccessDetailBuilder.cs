using Inprotech.Infrastructure.Security;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Security;

namespace Inprotech.Tests.Web.Builders.Model.Security
{
    public class RowAccessDetailBuilder : IBuilder<RowAccessDetail>
    {
        public string Name { get; set; }
        public string AccessType { get; set; }
        public AccessPermissionLevel AccessPermissionLevel { get; set; }
        public CaseType CaseType { get; set; }
        public Office Office { get; set; }
        public PropertyType PropertyType { get; set; }
        public NameType NameType { get; set; }

        public RowAccessDetail Build()
        {
            return new RowAccessDetail(Name ?? Fixture.UniqueName())
            {
                AccessLevel = (short) AccessPermissionLevel,
                AccessType = AccessType ?? "C",
                CaseType = CaseType,
                Office = Office,
                PropertyType = PropertyType,
                NameType = NameType
            };
        }

        public static RowAccessDetailBuilder ForCase()
        {
            return new RowAccessDetailBuilder {AccessType = "C"};
        }

        public static RowAccessDetailBuilder ForName()
        {
            return new RowAccessDetailBuilder {AccessType = "N"};
        }
    }

    public static class RowAccessDetailBuilderExtensions
    {
        public static RowAccessDetailBuilder WithName(this RowAccessDetailBuilder builder, string name)
        {
            builder.Name = name;
            return builder;
        }

        public static RowAccessDetailBuilder And(this RowAccessDetailBuilder builder, CaseType caseType)
        {
            builder.CaseType = caseType;
            return builder;
        }

        public static RowAccessDetailBuilder And(this RowAccessDetailBuilder builder, Office office)
        {
            builder.Office = office;
            return builder;
        }

        public static RowAccessDetailBuilder And(this RowAccessDetailBuilder builder, PropertyType propertyType)
        {
            builder.PropertyType = propertyType;
            return builder;
        }

        public static RowAccessDetailBuilder And(this RowAccessDetailBuilder builder, NameType nameType)
        {
            builder.NameType = nameType;
            return builder;
        }

        public static RowAccessDetailBuilder And(
            this RowAccessDetailBuilder builder,
            AccessPermissionLevel accessPermissionLevel)
        {
            builder.AccessPermissionLevel = accessPermissionLevel;
            return builder;
        }
    }
}