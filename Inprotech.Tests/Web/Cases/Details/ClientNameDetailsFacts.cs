using Inprotech.Infrastructure;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Security;
using Inprotech.Web.Cases.Details;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Cases.Details
{
    public class ClientNameDetailsFacts
    {
        public class GetExternalNameMethodFact : FactBase
        {
            [Theory]
            [InlineData("A", true, true)]
            [InlineData(null, true, true)]
            [InlineData(null, false, true)]
            [InlineData(null, false, false)]
            public void ReturnsFirmContactWhereAvailable(string contactNameType, bool hasSignatory, bool hasStaff)
            {
                var nameType1 = new NameTypeBuilder {NameTypeCode = contactNameType}.Build().In(Db);
                var nameType2 = new NameTypeBuilder {NameTypeCode = hasSignatory ? KnownNameTypes.Signatory : null}.Build().In(Db);
                var nameType3 = new NameTypeBuilder {NameTypeCode = hasStaff ? KnownNameTypes.StaffMember : null}.Build().In(Db);
                var s = new ClientNameDetailsFixture(Db);
                s.SiteControls.Read<string>(SiteControls.WorkBenchContactNameType).Returns(contactNameType);
                var @case = new CaseBuilder().Build().In(Db);
                var externalCaseName1 = new CaseNameBuilder(Db) {NameType = nameType1}.BuildWithCase(@case, 0).In(Db);
                var externalCaseName2 = new CaseNameBuilder(Db) {NameType = nameType2}.BuildWithCase(@case, 0).In(Db);
                var externalCaseName3 = new CaseNameBuilder(Db) {NameType = nameType3}.BuildWithCase(@case, 0).In(Db);
                
                var results = s.Subject.GetDetails(@case);

                Assert.Null(results.Reference);
                if (!string.IsNullOrEmpty(contactNameType))
                {
                    Assert.Equal(externalCaseName1.NameId, results.FirmContact?.Id);
                    Assert.Equal(contactNameType, results.FirmContactNameType);
                }
                else
                {
                    if (hasSignatory)
                    {
                        Assert.Equal(results.FirmContact.Id, externalCaseName2.NameId);
                        Assert.Equal(KnownNameTypes.Signatory, results.FirmContactNameType);
                    }
                    else
                    {
                        if (hasStaff)
                        {
                            Assert.Equal(results.FirmContact.Id, externalCaseName3.NameId);
                            Assert.Equal(KnownNameTypes.StaffMember, results.FirmContactNameType);
                        }
                        else
                        {
                            Assert.Null(results.FirmContact);
                        }
                    }
                }
            }

            [Fact]
            public void ReturnsCorrespondenceNameAsExternalContact()
            {
                var reference = Fixture.String();
                var s = new ClientNameDetailsFixture(Db);
                var @case = new CaseBuilder().Build().In(Db);
                var externalCaseName1 = new CaseNameBuilder(Db).BuildWithCase(@case, 0).In(Db);
                var externalCaseName2 = new CaseNameBuilder(Db).BuildWithCase(@case, 0).In(Db);
                var accessAccount = AccessAccountBuilder.AsExternalAccount(Fixture.Integer(), Fixture.String()).Build().In(Db);
                new FilteredUserCase
                {
                    CaseId = @case.Id,
                    ClientCorrespondName = externalCaseName1.NameId,
                    ClientMainContact = externalCaseName2.NameId,
                    ClientReferenceNo = reference
                }.In(Db);
                new CaseAccess(@case, accessAccount.Id, externalCaseName1.NameTypeId, externalCaseName1.NameId, externalCaseName1.Sequence).In(Db);
                var results = s.Subject.GetDetails(@case);

                Assert.Equal(externalCaseName1.Name, results.ExternalContact);
                Assert.Equal(reference, results.Reference);
            }

            [Fact]
            public void ReturnsMainContactAsExternalContact()
            {
                var reference = Fixture.String();
                var s = new ClientNameDetailsFixture(Db);
                var @case = new CaseBuilder().Build().In(Db);
                var externalCaseName1 = new CaseNameBuilder(Db).BuildWithCase(@case, 0).In(Db);
                var externalCaseName2 = new CaseNameBuilder(Db).BuildWithCase(@case, 0).In(Db);
                var accessAccount = AccessAccountBuilder.AsExternalAccount(Fixture.Integer(), Fixture.String()).Build().In(Db);
                new FilteredUserCase
                {
                    CaseId = @case.Id,
                    ClientCorrespondName = null,
                    ClientMainContact = externalCaseName2.NameId,
                    ClientReferenceNo = reference
                }.In(Db);
                new CaseAccess(@case, accessAccount.Id, externalCaseName1.NameTypeId, externalCaseName1.NameId, externalCaseName1.Sequence).In(Db);
                var results = s.Subject.GetDetails(@case);

                Assert.Equal(externalCaseName2.Name, results.ExternalContact);
                Assert.Equal(reference, results.Reference);
            }

            [Fact]
            public void ReturnsNothingWhenNoMatches()
            {
                var s = new ClientNameDetailsFixture(Db);
                var @case = new CaseBuilder().Build().In(Db);
                var externalCaseName1 = new CaseNameBuilder(Db).BuildWithCase(@case, 0).In(Db);
                externalCaseName1.Reference = Fixture.String();
                new CaseNameBuilder(Db).BuildWithCase(@case, 0).In(Db);
                var accessAccount = AccessAccountBuilder.AsExternalAccount(Fixture.Integer(), Fixture.String()).Build().In(Db);
                new CaseAccess(@case, accessAccount.Id, externalCaseName1.NameTypeId, externalCaseName1.NameId, externalCaseName1.Sequence).In(Db);
                var results = s.Subject.GetDetails(@case);

                Assert.Null(results.ExternalContact);
                Assert.Null(results.FirmContact);
                Assert.Null(results.Reference);
            }
        }

        public class ClientNameDetailsFixture : IFixture<ClientNameDetails>
        {
            public ClientNameDetailsFixture(InMemoryDbContext db)
            {
                SecurityContext = Substitute.For<ISecurityContext>();
                SiteControls = Substitute.For<ISiteControlReader>();

                Subject = new ClientNameDetails(db, SecurityContext, SiteControls);
                SecurityContext.User.Returns(new User(Fixture.String(), false));
            }

            public ISecurityContext SecurityContext { get; set; }
            public ISiteControlReader SiteControls { get; set; }
            public ClientNameDetails Subject { get; }
        }
    }
}