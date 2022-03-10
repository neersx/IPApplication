using System;
using System.Linq;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;
#pragma warning disable 612

#pragma warning disable 618

namespace Inprotech.Tests.Integration.DbHelpers.Builders
{
    public class NameBuilder : Builder
    {
        public NameBuilder(IDbContext dbContext) : base(dbContext)
        {
        }

        public Name Create(string prefix = null)
        {
            if (prefix == null)
                prefix = DefaultPrefix;

            return InsertWithNewId(new Name
            {
                LastName = prefix + "name",
            });
        }

        public Name Create(string firstname, string lastName, string email = null)
        {
            var @name = InsertWithNewId(new Name
            {
                LastName = lastName,
                FirstName = firstname
            });

            if (!string.IsNullOrWhiteSpace(email))
            {
                AddMainEmailId(@name, email);
            }

            return @name;
        }

        public Name CreateClientOrg(string prefix = null)
        {
            return CreateOrg(KnownNameTypeAllowedFlags.Client, prefix);
        }

        public Name CreateClientIndividual(string prefix = null)
        {
            return CreateIndividual(NameUsedAs.Client, prefix);
        }

        public Name CreateSupplierOrg(string prefix = null)
        {
            return CreateSupplier(NameUsedAs.Organisation, prefix);
        }

        public Name CreateSupplierIndividual(string prefix = null)
        {
            return CreateSupplier(NameUsedAs.Individual, prefix);
        }

        public Name CreateLeadIndividual(string prefix = null)
        {
            return CreateIndividual(NameUsedAs.Individual, prefix);
        }

        public Name CreateOrg(short clientType, string prefix = null)
        {
            if (prefix == null)
                prefix = DefaultPrefix;

            var @name = InsertWithNewId(new Name
            {
                NameCode = RandomString.Next(10),
                LastName = prefix + "Org",
                UsedAs = (short)(clientType | NameUsedAs.Organisation),
                SearchKey1 = (prefix + "Org").ToUpper(),
                Remarks = RandomString.Next(30)
            });

            AddAddresses(@name);

            AddUnstrictedUse(@name);

            return @name;
        }

        Name CreateIndividual(short clientType, string prefix = null, bool isActive = true)
        {
            if (prefix == null)
                prefix = DefaultPrefix;

            var @name = InsertWithNewId(new Name
            {
                FirstName = prefix + RandomString.Next(4),
                LastName = prefix + RandomString.Next(5),
                MiddleName = "e2e",
                NameCode = RandomString.Next(10),
                UsedAs = (short)(clientType | NameUsedAs.Individual),
                SearchKey1 = (prefix + "Smith").ToUpper(),
                DateCeased = isActive ? null : (DateTime?)DateTime.Today,
                Remarks = RandomString.Next(30),
                DateEntered = DateTime.Today,
                Soundex = Fixture.String(3)
            });

            Insert(new Individual(@name.Id));

            AddAddresses(@name);

            AddUnstrictedUse(@name);

            return @name;
        }

        Name CreateSupplier(short nameUsedAs, string prefix = null)
        {
            if (prefix == null)
                prefix = DefaultPrefix;

            var @name = InsertWithNewId(new Name
            {
                FirstName = prefix + "john",
                LastName = prefix + "smith",
                MiddleName = "e2e",
                NameCode = RandomString.Next(10),
                UsedAs = nameUsedAs,
                SearchKey1 = (prefix + "Smith").ToUpper(),
                SupplierFlag = 1,
                Remarks = RandomString.Next(30)
            });

            AddAddresses(@name);

            AddUnstrictedUse(@name);

            return @name;
        }
        public Name CreateStaff(string prefix = null, string nameCode = null, string email = null)
        {
            if (prefix == null)
                prefix = DefaultPrefix;

            var name = InsertWithNewId(new Name
            {
                FirstName = prefix + "john",
                LastName = prefix + "smith",
                MiddleName = "e2e",
                NameCode = nameCode ?? Fixture.String(20),
                UsedAs = KnownNameTypeAllowedFlags.StaffNames | KnownNameTypeAllowedFlags.Individual,
                SearchKey1 = (prefix + "Smith").ToUpper(),
                Remarks = RandomString.Next(30)
            });

            Insert(new Employee {Id = name.Id, AbbreviatedName = name.FirstName.First() + " " + name.LastName.First()});

            AddAddresses(name);

            AddUnstrictedUse(name);

            if (!string.IsNullOrWhiteSpace(email))
                AddMainEmailId(name, email);

            return name;
        }

        void AddAddresses(Name @name)
        {
            var address = InsertWithNewId(new Address
            {
                State = RandomString.Next(5),
                City = RandomString.Next(5),
                Country = InsertWithNewId(new Country { AllMembersFlag = 0, Type = "0", Name = RandomString.Next(15) })
            });

            @name.Addresses.Add(new NameAddress
            {
                NameId = @name.Id,
                AddressId = address.Id,
                AddressType = (int)KnownAddressTypes.PostalAddress
            });

            @name.Addresses.Add(new NameAddress
            {
                NameId = @name.Id,
                AddressId = address.Id,
                AddressType = (int)KnownAddressTypes.StreetAddress
            });

            @name.PostalAddressId = address.Id;

            @name.StreetAddressId = address.Id;

            DbContext.SaveChanges();
        }

        void AddUnstrictedUse(Name @name)
        {
            var unrestrictedNameType = DbContext.Set<NameType>().Single(_ => _.NameTypeCode == KnownNameTypes.UnrestrictedNameTypes);

            var setUnrestricted = new NameTypeClassification(@name, unrestrictedNameType)
            {
                IsAllowed = 1
            };

            @name.NameTypeClassifications.Add(setUnrestricted);

            DbContext.SaveChanges();
        }

        public void AddMainEmailId(Name @name, string emailId)
        {
            var tableCode = DbContext.Set<TableCode>().Single(_ => _.TableTypeId == (int)TableTypes.TelecommunicationsType && _.Id == (int)KnownTelecomTypes.Email);

            var telecommunication = InsertWithNewId(new Telecommunication { TelecomType = tableCode, TelecomNumber = emailId });

            DbContext.Set<NameTelecom>().Add(new NameTelecom(@name, telecommunication));

            @name.MainEmailId = telecommunication.Id;
            DbContext.SaveChanges();
        }
    }
}