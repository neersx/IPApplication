using System;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Names;

namespace Inprotech.Tests.Web.Builders.Model.Names
{
    public class NameBuilder : IBuilder<Name>
    {
        readonly InMemoryDbContext _db;

        public NameBuilder(InMemoryDbContext db)
        {
            _db = db;
        }

        public string LastName { get; set; }

        public string FirstName { get; set; }

        public string Initials { get; set; }

        public string NameCode { get; set; }

        public Address PostalAddress { get; set; }

        public Address StreetAddress { get; set; }

        public Telecommunication Email { get; set; }

        public Telecommunication Fax { get; set; }

        public Telecommunication Phone { get; set; }

        public short? UsedAs { get; set; }

        public ClientDetail ClientDetail { get; set; }
        
        public Organisation Organisation { get; set; }

        public Name MainContact { get; set; }

        public Country Nationality { get; set; }

        public string SearchKey1 { get; set; }

        public string Remarks { get; set; }

        public string Soundex { get; set; }

        public DateTime DateChanged { get; set; }

        public DateTime DateEntered { get; set; }

        public NameFamily Family { get; set; }
        
        public string TaxNumber { get; set; }

        public bool NameTelecomAsEntities { get; set; }

        public Name Build()
        {
            var postalAddress = PostalAddress ?? new AddressBuilder().Build();
            var streetAddress = StreetAddress ?? new AddressBuilder().Build();
            var phone = Phone ?? new TelecommunicationBuilder().Build();
            var fax = Fax ?? new TelecommunicationBuilder().Build();
            var email = Email ?? new TelecommunicationBuilder().Build();
            var usedAs = UsedAs ?? NameUsedAs.Individual;
            var name = new Name(Fixture.Integer())
            {
                NameCode = NameCode ?? Fixture.String(),
                LastName = LastName ?? Fixture.String(),
                FirstName = FirstName ?? Fixture.String(),
                Initials = Initials ?? Fixture.String(),
                PostalAddressId = postalAddress.Id,
                StreetAddressId = streetAddress.Id,
                MainEmailId = NameTelecomAsEntities ? email.In(_db).Id : email.Id,
                MainFaxId = NameTelecomAsEntities ? fax.In(_db).Id : fax.Id,
                MainPhoneId = NameTelecomAsEntities ? phone.In(_db).Id : phone.Id,
                UsedAs = usedAs,
                ClientDetail = ClientDetail ?? new ClientDetailBuilder().Build(),
                Organisation = Organisation ?? new OrganisationBuilder().Build(),
                MainContactId = MainContact?.Id,
                MainContact = MainContact,
                Remarks = Remarks,
                SearchKey1 = SearchKey1,
                Soundex = Soundex,
                DateChanged = DateChanged,
                DateEntered = DateEntered,
                NameFamily = Family,
                Nationality = Nationality,
                TaxNumber = TaxNumber
            };

            name.Addresses.Add(
                               new NameAddressBuilder(_db)
                               {
                                   Address = postalAddress
                               }
                                   .As(PostalAddress == postalAddress ? AddressType.Postal : AddressType.Street)
                                   .ForName(name)
                                   .Build());

            name.Addresses.Add(
                               new NameAddressBuilder(_db)
                               {
                                   Address = streetAddress
                               }
                                   .As(StreetAddress == streetAddress ? AddressType.Street : AddressType.Postal)
                                   .ForName(name)
                                   .Build());

            name.Telecoms.Add(new NameTelecomBuilder(_db) { Name = name, Telecommunication = phone, AsEntities = NameTelecomAsEntities }.Build());
            name.Telecoms.Add(new NameTelecomBuilder(_db) { Name = name, Telecommunication = fax, AsEntities = NameTelecomAsEntities }.Build());
            name.Telecoms.Add(new NameTelecomBuilder(_db) { Name = name, Telecommunication = email, AsEntities = NameTelecomAsEntities }.Build());
            
            return name;
        }

        public Name BuildWithClassifications(string[] classifications)
        {
            var builtName = Build();
            foreach (var classification in classifications)
            {
                var nameType = new NameTypeBuilder { NameTypeCode = classification }.Build().In(_db);
                var nameTypeClassification = new NameTypeClassificationBuilder(_db) { Name = builtName, IsAllowed = 1, NameType = nameType }.Build()
                                                                                                                                          .In(_db);

                builtName.NameTypeClassifications.Add(nameTypeClassification);
            }

            return builtName;
        }
    }

    public static class NameBuilderExt
    {
        public static NameBuilder As(this NameBuilder builder, short usedAs)
        {
            if (builder == null) throw new ArgumentNullException(nameof(builder));

            builder.UsedAs = usedAs;
            return builder;
        }

        public static NameBuilder WithFamily(this NameBuilder builder)
        {
            if (builder == null) throw new ArgumentNullException(nameof(builder));

            builder.Family = new NameFamily(Fixture.Short(), Fixture.RandomString(50));
            return builder;
        }
    }
}