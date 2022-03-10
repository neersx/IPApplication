using System;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Configuration;
using Inprotech.Tests.Web.Builders.Model.Names;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Components.Names.Extensions;
using Xunit;

namespace Inprotech.Tests.Model.Components.Names
{
    public class NameExtensionsFacts : FactBase
    {
        [Fact]
        public void ShouldFormatMainEmail()
        {
            var n = new NameBuilder(Db)
            {
                Email = new TelecommunicationBuilder
                {
                    TelecomNumber = "someone@cpaglobal.com"
                }.Build()
            }.Build();

            Assert.Equal("someone@cpaglobal.com", n.MainEmail().Formatted());
        }

        [Fact]
        public void ShouldFormatMainFax()
        {
            var n = new NameBuilder(Db)
            {
                Fax = new TelecommunicationBuilder
                {
                    Isd = "+61",
                    TelecomNumber = "9993 3001",
                    AreaCode = "02"
                }.Build()
            }.Build();

            Assert.Equal("+61 02 9993 3001", n.MainFax().Formatted());
        }

        [Fact]
        public void ShouldFormatMainPhone()
        {
            var n = new NameBuilder(Db)
            {
                Phone = new TelecommunicationBuilder
                {
                    TelecomNumber = "9993 3000",
                    AreaCode = "02",
                    Extension = "666"
                }.Build()
            }.Build();

            Assert.Equal("02 9993 3000 x666", n.MainPhone().Formatted());
        }

        [Fact]
        public void ShouldFormatOtherPhone()
        {
            var name = new NameBuilder(Db).Build();
            var t1 = new TelecommunicationBuilder { TelecomType = new TableCodeBuilder { TableType = (short)KnownTelecomTypes.Telephone, Description = "Telephone" }.Build().In(Db), TelecomNumber = "123" }.Build().In(Db);
            var t2 = new TelecommunicationBuilder { TelecomType = new TableCodeBuilder { TableType = (short)KnownTelecomTypes.Telephone, Description = "Telephone" }.Build().In(Db), TelecomNumber = "456" }.Build().In(Db);
            var nt1 = new NameTelecomBuilder(Db) { Name = name, Telecommunication = t1 }.Build().In(Db);
            var nt2 = new NameTelecomBuilder(Db) { Name = name, Telecommunication = t2 }.Build().In(Db);
            name.Telecoms.Add(nt1);
            name.Telecoms.Add(nt2);
            var phones = name.OtherPhones();
            Assert.Equal(", 123, 456", phones);
        }

        [Fact]
        public void ShouldReturnNullWhenNoTelecomWithName()
        {
            var name = new NameBuilder(Db).Build();
            name.Telecoms.Clear();
            var phones = name.OtherPhones();
            Assert.Equal(null, phones);
        }

        [Fact]
        public void ShouldReturnExceptionsWhenNameIsNull()
        {
            Assert.Throws<ArgumentNullException>(() => ((InprotechKaizen.Model.Names.Name)null).OtherPhones());
        }

        [Fact]
        public void ShouldFormatMainPostalAddress()
        {
            var n = new NameBuilder(Db)
            {
                PostalAddress = new AddressBuilder
                {
                    City = "Sydney",
                    Country = new CountryBuilder
                    {
                        Id = "AU",
                        Name = "Australia"
                    }.Build()
                }.Build()
            }.Build();

            var expected = "Sydney" + Environment.NewLine + "Australia";
            Assert.Equal(expected, n.PostalAddress().Formatted());
        }

        [Fact]
        public void ShouldFormatMainStreetAddress()
        {
            var n = new NameBuilder(Db)
            {
                StreetAddress = new AddressBuilder
                {
                    City = "Sydney",
                    Country = new CountryBuilder
                    {
                        Id = "AU",
                        Name = "Australia"
                    }.Build()
                }.Build()
            }.Build();

            var expected = "Sydney" + Environment.NewLine + "Australia";
            Assert.Equal(expected, n.StreetAddress().Formatted());
        }

        [Fact]
        public void ShouldFormatName()
        {
            var n = new NameBuilder(Db)
            {
                FirstName = "George",
                LastName = "Grey"
            }.Build();

            Assert.Equal("Grey, George", n.Formatted());
        }

        [Fact]
        public void ShouldFormatNameBasedOnFallbackProvided()
        {
            var n = new NameBuilder(Db)
            {
                FirstName = "George",
                LastName = "Grey"
            }.Build();

            Assert.Equal("George Grey", n.Formatted(fallbackNameStyle: NameStyles.FirstNameThenFamilyName));
        }

        [Fact]
        public void ShouldFormatNameWithDefaultStyle()
        {
            var n = new NameBuilder(Db)
            {
                FirstName = "George",
                LastName = "Grey"
            }.Build();
            n.MiddleName = "Humpty";

            Assert.Equal("Grey, George Humpty", n.FormattedWithDefaultStyle());
        }

        [Fact]
        public void ShouldReturnNullIfMainContactNotExists()
        {
            var n = new NameBuilder(Db).Build();
            Assert.Null(n.MainContact.FormattedNameOrNull());
        }

        [Fact]
        public void ShouldReturnNullIfMainEmailNotExists()
        {
            var n = new NameBuilder(Db).Build();
            Assert.Null(n.MainEmail().FormattedOrNull());
        }

        [Fact]
        public void ShouldReturnNullIfMainFaxNotExists()
        {
            var n = new NameBuilder(Db).Build();
            Assert.Null(n.MainFax().FormattedOrNull());
        }

        [Fact]
        public void ShouldReturnNullIfMainPhoneNotExists()
        {
            var n = new NameBuilder(Db).Build();
            Assert.Null(n.MainPhone().FormattedOrNull());
        }

        [Fact]
        public void ShouldReturnNullIfMainPostNotExists()
        {
            var n = new NameBuilder(Db).Build();
            Assert.Null(n.PostalAddress().FormattedOrNull());
        }

        [Fact]
        public void ShouldReturnNullIfMainStreetNotExists()
        {
            var n = new NameBuilder(Db).Build();
            Assert.Null(n.StreetAddress().FormattedOrNull());
        }
    }
}