using System;
using Inprotech.Integration.ExternalApplications.Crm;
using Inprotech.Integration.ExternalApplications.Crm.Request;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Configuration;
using Inprotech.Tests.Web.Builders.Model.Names;
using InprotechKaizen.Model;
using InprotechKaizen.Model.AuditTrail;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Components.System.Policy.AuditTrails;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.ExternalApplications
{
    public class CrmContactProcessorFacts
    {
        public class CrmContactProcessorFixture : IFixture<CrmContactProcessor>
        {
            public CrmContactProcessorFixture(InMemoryDbContext db)
            {
                DbContext = db;
                NewNameProcessor = Substitute.For<INewNameProcessor>();
                TransactionRecordal = Substitute.For<ITransactionRecordal>();

                SystemClock = Substitute.For<Func<DateTime>>();
                SystemClock().Returns(Fixture.Today());

                NewName = new NewName {FirstName = "A", Name = "B", HomeCountryCode = "AU"};
                NewNameProcessor.GetNameDefaults(Arg.Any<NewName>()).Returns(NewName);

                NewNameProcessor.GenerateNameCode().Returns("1234");

                Name = new NameBuilder(db) {FirstName = "A", LastName = "B", NameCode = "1234"}.Build().In(db);
                NewNameProcessor.InsertName(Arg.Any<NewName>()).Returns(Name);

                var address = new AddressBuilder().Build().In(db);
                NameAddress = new NameAddressBuilder(db) {Name = Name, Address = address}.Build().In(db);
                NewNameProcessor.InsertNameAddress(Arg.Any<int>(), Arg.Any<NewNameAddress>()).Returns(NameAddress);

                Subject = new CrmContactProcessor(DbContext, NewNameProcessor, TransactionRecordal, SystemClock);
            }

            public IDbContext DbContext { get; set; }

            public INewNameProcessor NewNameProcessor { get; set; }

            public ITransactionRecordal TransactionRecordal { get; set; }

            public Func<DateTime> SystemClock { get; }

            public NewName NewName { get; }

            public Name Name { get; }

            public NameAddress NameAddress { get; }

            public CrmContactProcessor Subject { get; }
        }

        public class CreateContactNameMethod : FactBase
        {
            public CreateContactNameMethod()
            {
                _contact = new Contact {Surname = "B", GivenName = "A"};
                _fixture = new CrmContactProcessorFixture(Db);
            }

            readonly Contact _contact;
            readonly CrmContactProcessorFixture _fixture;

            void SetupTelecom(string telecomNo, short telecomType)
            {
                var nameTelecom = new TelecommunicationBuilder
                                  {
                                      TelecomNumber = telecomNo,
                                      TelecomType =
                                          new TableCodeBuilder
                                              {
                                                  TableType = telecomType
                                              }
                                              .Build().In(Db)
                                  }
                                  .Build().In(Db);

                _fixture.Name.Telecoms.Clear();
                _fixture.Name.Telecoms.Add(new NameTelecomBuilder(Db)
                {
                    Name = _fixture.Name,
                    Telecommunication = nameTelecom
                }.Build().In(Db));

                _fixture.NewNameProcessor.InsertNameTelecom(Arg.Any<int>(), Arg.Any<NewNameTeleCommunication>()).Returns(nameTelecom);
            }

            [Fact]
            public void InsertNewContact()
            {
                var f = new CrmContactProcessorFixture(Db);
                var result = f.Subject.CreateContactName(_contact);
                Assert.Equal(result.DateChanged, Fixture.Today());
                Assert.Equal(result.Id, f.Name.Id);
            }

            [Fact]
            public void SetMainEmailForContact()
            {
                var telecomNo = Fixture.String("Tele");
                SetupTelecom(telecomNo, (short) KnownTelecomTypes.Email);

                _contact.Telephone = telecomNo;
                var result = _fixture.Subject.CreateContactName(_contact);

                Assert.Equal(result.MainEmail().TelecomNumber, telecomNo);
            }

            [Fact]
            public void SetMainFaxForContact()
            {
                var telecomNo = Fixture.String("Tele");
                SetupTelecom(telecomNo, (short) KnownTelecomTypes.Fax);

                _contact.Telephone = telecomNo;
                var result = _fixture.Subject.CreateContactName(_contact);

                Assert.Equal(result.MainFax().TelecomNumber, telecomNo);
            }

            [Fact]
            public void SetMainTelephoneForContact()
            {
                var telecomNo = Fixture.String("Tele");
                SetupTelecom(telecomNo, (short) KnownTelecomTypes.Telephone);

                _contact.Telephone = telecomNo;
                var result = _fixture.Subject.CreateContactName(_contact);

                Assert.Equal(result.MainPhone().TelecomNumber, telecomNo);
            }

            [Fact]
            public void SetPostalAddressForMainAddress()
            {
                var f = new CrmContactProcessorFixture(Db)
                {
                    NameAddress =
                    {
                        AddressType = (int) KnownAddressTypes.PostalAddress
                    }
                };

                var result = f.Subject.CreateContactName(_contact);

                Assert.Equal(result.PostalAddressId, f.NameAddress.AddressId);
            }

            [Fact]
            public void SetStreetAddressForMainAddress()
            {
                var f = new CrmContactProcessorFixture(Db)
                {
                    NameAddress =
                    {
                        AddressType = (int) KnownAddressTypes.StreetAddress
                    }
                };
                var result = f.Subject.CreateContactName(_contact);

                Assert.Equal(result.StreetAddressId, f.NameAddress.AddressId);
            }
        }
    }
}