using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Names;

namespace Inprotech.Tests.Web.Builders.Model.Names
{
    internal class NameVariantBuilder : IBuilder<NameVariant>
    {
        readonly InMemoryDbContext _db;

        public NameVariantBuilder(InMemoryDbContext db)
        {
            _db = db;
        }

        public int? Id { get; set; }
        public string NameVariantDesc { get; set; }
        public string FirstNameVariantDesc { get; set; }
        public PropertyType PropertyType { get; set; }
        public Name Name { get; set; }

        internal bool NullPropertyType { get; set; }

        public NameVariant Build()
        {
            return new NameVariant(
                                   Id ?? Fixture.Integer(),
                                   NameVariantDesc ?? Fixture.String("NameVariantDesc"),
                                   NullPropertyType ? null : PropertyType ?? new PropertyTypeBuilder().Build(),
                                   Name ?? new NameBuilder(_db).Build())
            {
                FirstNameVariant = FirstNameVariantDesc
            };
        }
    }

    internal static class NameVariantBuilderEx
    {
        public static NameVariantBuilder ForName(this NameVariantBuilder builder, Name name)
        {
            builder.Name = name;
            return builder;
        }

        public static NameVariantBuilder WithPropertyType(this NameVariantBuilder builder, PropertyType propertyType)
        {
            builder.NullPropertyType = propertyType == null;
            builder.PropertyType = propertyType;
            return builder;
        }
    }
}