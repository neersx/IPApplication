using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Names;

namespace Inprotech.Tests.Web.Builders.Model.Names
{
    public class NameAliasBuilder : IBuilder<NameAlias>
    {
        readonly InMemoryDbContext _db;

        public NameAliasBuilder(InMemoryDbContext db)
        {
            _db = db;
        }

        public string Alias { get; set; }
        public NameAliasType AliasType { get; set; }
        public Country Country { get; set; }
        public bool SetCountryNull { get; set; }
        public Name Name { get; set; }
        public PropertyType PropertyType { get; set; }
        public bool SetPropertyTypeNull { get; set; }

        public NameAlias Build()
        {
            return new NameAlias
            {
                Alias = Alias ?? Fixture.String(),
                AliasType = AliasType ?? new NameAliasType {Code = Fixture.String()},
                Name = Name ?? new NameBuilder(_db).Build(),

                Country = !SetCountryNull ? Country ?? new CountryBuilder().Build() : null,
                PropertyType = !SetPropertyTypeNull ? PropertyType ?? new PropertyTypeBuilder().Build() : null
            };
        }
    }

    public static class NameAliasBuilderExt
    {
        public static NameAliasBuilder WithNoCountry(this NameAliasBuilder builder)
        {
            builder.SetCountryNull = true;
            return builder;
        }

        public static NameAliasBuilder WithNoPropertyType(this NameAliasBuilder builder)
        {
            builder.SetPropertyTypeNull = true;
            return builder;
        }
    }
}