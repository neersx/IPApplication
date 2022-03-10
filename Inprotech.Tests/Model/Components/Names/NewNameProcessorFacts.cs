using System.Collections.Generic;
using System.Linq;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Names;
using Inprotech.Tests.Web.Builders.Model.Security;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Components.System.Policy.AuditTrails;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Model.Components.Names
{
    public class NewNameProcessorFacts
    {
        public class NewNameProcessorFixture : IFixture<NewNameProcessor>
        {
            public NewNameProcessorFixture(InMemoryDbContext db)
            {
                DbContext = db;
                DefaultNameTypeClassification = Substitute.For<IDefaultNameTypeClassification>();
                SecurityContext = Substitute.For<ISecurityContext>();
                SecurityContext.User.Returns(InternalWebApiUser());

                ValidNameTypes = new List<ValidNameTypeClassification>
                {
                    new ValidNameTypeClassification {IsSelected = false, NameTypeKey = KnownNameTypes.Contact},
                    new ValidNameTypeClassification {IsSelected = true, NameTypeKey = KnownNameTypes.UnrestrictedNameTypes},
                    new ValidNameTypeClassification {IsSelected = false, NameTypeKey = KnownNameTypes.Debtor},
                    new ValidNameTypeClassification {IsSelected = false, NameTypeKey = KnownNameTypes.Instructor},
                    new ValidNameTypeClassification {IsSelected = false, NameTypeKey = KnownNameTypes.StaffMember}
                };

                new NameTypeBuilder {NameTypeCode = KnownNameTypes.Contact}.Build().In(db);
                new NameTypeBuilder {NameTypeCode = KnownNameTypes.UnrestrictedNameTypes}.Build().In(db);
                new NameTypeBuilder {NameTypeCode = KnownNameTypes.Debtor}.Build().In(db);
                new NameTypeBuilder {NameTypeCode = KnownNameTypes.Instructor}.Build().In(db);
                new NameTypeBuilder {NameTypeCode = KnownNameTypes.StaffMember}.Build().In(db);

                DefaultNameTypeClassification.FetchNameTypeClassification(Arg.Any<int>(), Arg.Any<int?>())
                                             .Returns(ValidNameTypes);

                Subject = new NewNameProcessor(SecurityContext, DbContext, DefaultNameTypeClassification);
            }

            public ISecurityContext SecurityContext { get; set; }

            public IDefaultNameTypeClassification DefaultNameTypeClassification { get; set; }

            public ITransactionRecordal TransactionRecordal { get; set; }

            public InMemoryDbContext DbContext { get; set; }

            public IEnumerable<ValidNameTypeClassification> ValidNameTypes { get; }

            public NewNameProcessor Subject { get; }

            public User InternalWebApiUser()
            {
                return UserBuilder.AsInternalUser(DbContext, "internal").Build().In(DbContext);
            }
        }

        public class InsertIndividualMethod : FactBase
        {
            const string ContactName = "Test";
            const string Gender = "M";
            const string Salutation = "Mr";

            [Fact]
            public void NameIsInsertedAsIndividual()
            {
                var f = new NewNameProcessorFixture(Db);

                var name = new NameBuilder(Db) {FirstName = ContactName, LastName = ContactName}.Build().In(Db);
                var newName = new NewName {GenderCode = Gender, FormalSalutation = Salutation};
                f.Subject.InsertIndividual(name.Id, newName);

                var individual = Db.Set<Individual>().First(i => i.NameId == name.Id);

                Assert.Equal(newName.GenderCode, individual.Gender);
                Assert.Equal(newName.FormalSalutation, individual.FormalSalutation);
                Assert.Equal(newName.InformalSalutation, individual.CasualSalutation);
            }
        }

        public class InsertNameTypeClassificationMethod : FactBase
        {
            const string ContactName = "Test";

            [Fact]
            public void IsAllowedIsSetForExistingNameTypeClassification()
            {
                var f = new NewNameProcessorFixture(Db);

                var name = new NameBuilder(Db) {FirstName = ContactName, LastName = ContactName}.Build().In(Db);

                var nameType = Db.Set<NameType>().First(nt => nt.NameTypeCode == KnownNameTypes.Contact);
                new NameTypeClassificationBuilder(Db) {Name = name, NameType = nameType, IsAllowed = 0}.Build()
                                                                                                       .In(Db);

                var selectedNameTypes = new List<string> {KnownNameTypes.Contact};
                f.Subject.InsertNameTypeClassification(name, selectedNameTypes);

                var nameTypeClassificationList = Db.Set<NameTypeClassification>().Where(i => i.NameId == name.Id).ToList();
                var contactNameType =
                    nameTypeClassificationList.First(ntc => ntc.NameTypeId.Equals(KnownNameTypes.Contact));

                Assert.True(contactNameType.IsAllowed == 1);
            }

            [Fact]
            public void ValidNameTypeClassificationIsAddedAgainstName()
            {
                var f = new NewNameProcessorFixture(Db);

                var name = new NameBuilder(Db) {FirstName = ContactName, LastName = ContactName}.Build().In(Db);

                var selectedNameTypes = new List<string> {KnownNameTypes.Contact};
                f.Subject.InsertNameTypeClassification(name, selectedNameTypes);

                var nameTypeClassificationList = Db.Set<NameTypeClassification>().Where(i => i.NameId == name.Id).ToList();
                var contactNameType =
                    nameTypeClassificationList.First(ntc => ntc.NameTypeId.Equals(KnownNameTypes.Contact));
                var notSelectedContactNameType =
                    nameTypeClassificationList.First(ntc => ntc.NameTypeId.Equals(KnownNameTypes.Debtor));

                Assert.Equal(nameTypeClassificationList.Count(), f.ValidNameTypes.Count());
                Assert.True(contactNameType.IsAllowed == 1);
                Assert.True(notSelectedContactNameType.IsAllowed == 0);
            }
        }
    }
}