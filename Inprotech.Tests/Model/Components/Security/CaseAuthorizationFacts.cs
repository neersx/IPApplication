using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web;
using Inprotech.Tests.Web.Builders.Model.Cases;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Model.Components.Security
{
    public class CaseAuthorizationFacts
    {
        public class ExternalUserScenario : FactBase
        {
            readonly ISiteControlReader _siteControl = Substitute.For<ISiteControlReader>();

            ICaseAuthorization CreateSubject()
            {
                var user = new User(Fixture.String(), true);
                var securityContext = Substitute.For<ISecurityContext>();
                securityContext.User.Returns(user);

                return new CaseAuthorization(Db, securityContext, _siteControl);
            }

            [Fact]
            public async Task ShouldIndicateCaseExistsButUnauthorised()
            {
                var @case = new CaseBuilder().Build().In(Db);

                var r = await CreateSubject().Authorize(@case.Id, AccessPermissionLevel.Select);

                Assert.True(r.Exists);
                Assert.True(r.IsUnauthorized);
                Assert.Equal(ErrorTypeCode.CaseNotRelatedToExternalUser.ToString(), r.ReasonCode);
            }

            [Fact]
            public async Task ShouldIndicateCaseIsAuthorised()
            {
                var @case = new CaseBuilder().Build().In(Db);
                new FilteredUserCase().In(Db).WithKnownId(x => x.CaseId, @case.Id);

                var r = await CreateSubject().Authorize(@case.Id, AccessPermissionLevel.Select);

                Assert.True(r.Exists);
                Assert.False(r.IsUnauthorized);
            }

            [Fact]
            public async Task ShouldIndicateCaseNotExists()
            {
                var r = await CreateSubject().Authorize(Fixture.Integer(), AccessPermissionLevel.Select);

                Assert.False(r.Exists);
            }
        }

        public class InternalUserViewOrRowLevelSecurityScenario : FactBase
        {
            public InternalUserViewOrRowLevelSecurityScenario()
            {
                _thisUser = new User(Fixture.String(), false).In(Db);
            }

            readonly User _thisUser;
            readonly ISiteControlReader _siteControl = Substitute.For<ISiteControlReader>();

            ICaseAuthorization CreateSubject()
            {
                var securityContext = Substitute.For<ISecurityContext>();
                securityContext.User.Returns(_thisUser);

                return new CaseAuthorization(Db, securityContext, _siteControl);
            }

            [Theory]
            [InlineData(AccessPermissionLevel.Delete)]
            [InlineData(AccessPermissionLevel.Update)]
            [InlineData(AccessPermissionLevel.Insert)]
            public async Task ShouldIndicateCaseNotPermittedIfCaseNotAccessibleDueToRowLevelSecurity(AccessPermissionLevel requiredLevel)
            {
                var @case = new CaseBuilder().Build().In(Db);
                new FilteredEthicalWallCase().In(Db).WithKnownId(x => x.CaseId, @case.Id);
                /* this user only has upto select access for the case */
                new FilteredRowSecurityCase {SecurityFlag = AccessPermissionLevel.Select}.In(Db).WithKnownId(x => x.CaseId, @case.Id);

                var subject = CreateSubject();

                var rowAccess = new RowAccess("full-access", Fixture.String()).In(Db);
                rowAccess.Details.Add(new RowAccessDetail("full-access") {AccessType = "C"}.In(Db));

                _thisUser.RowAccessPermissions.Add(rowAccess);

                var r = await subject.Authorize(@case.Id, requiredLevel);

                Assert.True(r.Exists);
                Assert.True(r.IsUnauthorized);
                Assert.Equal(ErrorTypeCode.NoRowaccessForCase.ToString(), r.ReasonCode);
            }

            [Theory]
            [InlineData(AccessPermissionLevel.Delete)]
            [InlineData(AccessPermissionLevel.Update)]
            [InlineData(AccessPermissionLevel.Insert)]
            public async Task ShouldIndicateCaseNotPermittedIfCaseNotAccessibleDueToRowLevelOfficeSecurity(AccessPermissionLevel requiredLevel)
            {
                var @case = new CaseBuilder().Build().In(Db);
                new FilteredEthicalWallCase().In(Db).WithKnownId(x => x.CaseId, @case.Id);
                /* this user only has upto select access for the case */
                new FilteredRowSecurityCaseMultiOffice {SecurityFlag = AccessPermissionLevel.Select}.In(Db).WithKnownId(x => x.CaseId, @case.Id);

                /* row level access has been configured in the system */
                var rowAccess = new RowAccess("full-access", Fixture.String()).In(Db);
                rowAccess.Details.Add(new RowAccessDetail("full-access") {AccessType = "C"}.In(Db));

                _thisUser.RowAccessPermissions.Add(rowAccess);

                /* indicator that Case is to have multiple officies */
                new TableAttributes
                {
                    ParentTable = KnownTableAttributes.Case,
                    GenericKey = @case.Id.ToString(),
                    SourceTableId = (short) TableTypes.Office
                }.In(Db);

                var subject = CreateSubject();

                var r = await subject.Authorize(@case.Id, requiredLevel);

                Assert.True(r.Exists);
                Assert.True(r.IsUnauthorized);
                Assert.Equal(ErrorTypeCode.NoRowaccessForCase.ToString(), r.ReasonCode);
            }

            [Theory]
            [InlineData(AccessPermissionLevel.Delete)]
            [InlineData(AccessPermissionLevel.Update)]
            [InlineData(AccessPermissionLevel.Insert)]
            [InlineData(AccessPermissionLevel.Select)]
            public async Task ShouldIndicateCasePermittedForMultiOfficeDeterminedByMultiOfficeAttributes(AccessPermissionLevel requiredLevel)
            {
                var @case = new CaseBuilder().Build().In(Db);
                new FilteredEthicalWallCase().In(Db).WithKnownId(x => x.CaseId, @case.Id);
                /* this user only has upto select access for the case */
                new FilteredRowSecurityCaseMultiOffice
                {
                    SecurityFlag = AccessPermissionLevel.Select | AccessPermissionLevel.Update | AccessPermissionLevel.Delete | AccessPermissionLevel.Insert
                }.In(Db).WithKnownId(x => x.CaseId, @case.Id);

                /* indicator that Case is to have multiple officies */
                new TableAttributes
                {
                    ParentTable = KnownTableAttributes.Case,
                    SourceTableId = (short) TableTypes.Office
                }.In(Db);

                var subject = CreateSubject();

                _thisUser.RowAccessPermissions.Add(new RowAccess("full-access", Fixture.String()).In(Db));

                var r = await subject.Authorize(@case.Id, requiredLevel);

                Assert.True(r.Exists);
                Assert.False(r.IsUnauthorized);
            }

            [Theory]
            [InlineData(AccessPermissionLevel.Delete)]
            [InlineData(AccessPermissionLevel.Update)]
            [InlineData(AccessPermissionLevel.Insert)]
            [InlineData(AccessPermissionLevel.Select)]
            public async Task ShouldIndicateCasePermittedForMultiOfficeDeterminedBySiteControl(AccessPermissionLevel requiredLevel)
            {
                var @case = new CaseBuilder().Build().In(Db);
                new FilteredEthicalWallCase().In(Db).WithKnownId(x => x.CaseId, @case.Id);
                /* this user only has upto select access for the case */
                new FilteredRowSecurityCaseMultiOffice
                {
                    SecurityFlag = AccessPermissionLevel.Select | AccessPermissionLevel.Update | AccessPermissionLevel.Delete | AccessPermissionLevel.Insert
                }.In(Db).WithKnownId(x => x.CaseId, @case.Id);

                _siteControl.Read<bool?>(SiteControls.RowSecurityUsesCaseOffice).Returns(false);

                var subject = CreateSubject();

                _thisUser.RowAccessPermissions.Add(new RowAccess("full-access", Fixture.String()).In(Db));

                var r = await subject.Authorize(@case.Id, requiredLevel);

                Assert.True(r.Exists);
                Assert.False(r.IsUnauthorized);
            }

            [Theory]
            [InlineData(AccessPermissionLevel.Delete)]
            [InlineData(AccessPermissionLevel.Update)]
            [InlineData(AccessPermissionLevel.Insert)]
            [InlineData(AccessPermissionLevel.Select)]
            public async Task ShouldIndicateCasePermittedForCaseOfficeDeterminedBySiteControl(AccessPermissionLevel requiredLevel)
            {
                var @case = new CaseBuilder().Build().In(Db);
                new FilteredEthicalWallCase().In(Db).WithKnownId(x => x.CaseId, @case.Id);
                /* this user only has upto select access for the case */
                new FilteredRowSecurityCase
                {
                    SecurityFlag = AccessPermissionLevel.Select | AccessPermissionLevel.Update | AccessPermissionLevel.Delete | AccessPermissionLevel.Insert
                }.In(Db).WithKnownId(x => x.CaseId, @case.Id);

                _siteControl.Read<bool?>(SiteControls.RowSecurityUsesCaseOffice).Returns(true);

                var subject = CreateSubject();

                _thisUser.RowAccessPermissions.Add(new RowAccess("full-access", Fixture.String()).In(Db));

                var r = await subject.Authorize(@case.Id, requiredLevel);

                Assert.True(r.Exists);
                Assert.False(r.IsUnauthorized);
            }

            [Fact]
            public async Task ShouldIndicateCaseNotExists()
            {
                var r = await CreateSubject().Authorize(Fixture.Integer(), AccessPermissionLevel.Select);

                Assert.False(r.Exists);
            }

            [Fact]
            public async Task ShouldIndicateCaseNotPermittedDueToEthicalWall()
            {
                var @case = new CaseBuilder().Build().In(Db);

                var r = await CreateSubject().Authorize(@case.Id, AccessPermissionLevel.Select);

                Assert.True(r.Exists);
                Assert.True(r.IsUnauthorized);
                Assert.Equal(ErrorTypeCode.EthicalWallForCase.ToString(), r.ReasonCode);
            }

            [Fact]
            public async Task ShouldIndicateCaseNotPermittedDueToNoRowLevelSecuritySetupForTheUser()
            {
                var @case = new CaseBuilder().Build().In(Db);
                new FilteredEthicalWallCase().In(Db).WithKnownId(x => x.CaseId, @case.Id);

                var subject = CreateSubject();

                _thisUser.RowAccessPermissions.Clear();

                var otherUser = new User("other", false).In(Db);
                var rowAccess = new RowAccess("full-access", Fixture.String()).In(Db);
                rowAccess.Details.Add(new RowAccessDetail("full-access") {AccessType = "C"}.In(Db));
                otherUser.RowAccessPermissions.Add(rowAccess);

                var r = await subject.Authorize(@case.Id, AccessPermissionLevel.Select);

                Assert.True(r.Exists);
                Assert.True(r.IsUnauthorized);
                Assert.Equal(ErrorTypeCode.NoRowaccessForCase.ToString(), r.ReasonCode);
            }
        }

        public class InternalUserUpdateScenario : FactBase
        {
            User _thisUser;
            readonly ISiteControlReader _siteControl = Substitute.For<ISiteControlReader>();
            const AccessPermissionLevel AllPermissions = AccessPermissionLevel.Select | AccessPermissionLevel.Update | AccessPermissionLevel.Delete | AccessPermissionLevel.Insert;

            ICaseAuthorization CreateSubject()
            {
                _thisUser = new User(Fixture.String(), false).In(Db);
                var securityContext = Substitute.For<ISecurityContext>();
                securityContext.User.Returns(_thisUser);

                return new CaseAuthorization(Db, securityContext, _siteControl);
            }

            [Fact]
            public async Task ShouldIndicateCaseNotPermittedDueToLimitedDefaultStatusSecurity()
            {
                var @case = new CaseBuilder().Build().In(Db);
                new FilteredEthicalWallCase().In(Db).WithKnownId(x => x.CaseId, @case.Id);
                new FilteredRowSecurityCaseMultiOffice
                {
                    SecurityFlag = AllPermissions
                }.In(Db).WithKnownId(x => x.CaseId, @case.Id);

                var subject = CreateSubject();

                /* all users can only have readonly access to cases */
                _siteControl.Read<int?>(SiteControls.DefaultSecurity).Returns(1);

                /* but is demanding update access */
                var r = await subject.Authorize(@case.Id, AccessPermissionLevel.Update);

                Assert.True(r.IsUnauthorized);
                Assert.Equal(ErrorTypeCode.NoStatusSecurityForCase.ToString(), r.ReasonCode);
            }

            [Fact]
            public async Task ShouldIndicateCaseNotPermittedDueToLimitedStatusSecurity()
            {
                var protectedStatus = new Status(Fixture.Short(), Fixture.String()).In(Db);

                var @case = new CaseBuilder
                {
                    Status = protectedStatus
                }.Build().In(Db);

                new FilteredEthicalWallCase().In(Db).WithKnownId(x => x.CaseId, @case.Id);
                new FilteredRowSecurityCaseMultiOffice
                {
                    SecurityFlag = AllPermissions
                }.In(Db).WithKnownId(x => x.CaseId, @case.Id);

                var subject = CreateSubject();

                /* this user can only have readonly access to cases with this status */
                new StatusSecurity(_thisUser.UserName, protectedStatus.Id, (short) AccessPermissionLevel.Select).In(Db);

                /* but is demanding update access */
                var r = await subject.Authorize(@case.Id, AccessPermissionLevel.Update);

                Assert.True(r.IsUnauthorized);
                Assert.Equal(ErrorTypeCode.NoStatusSecurityForCase.ToString(), r.ReasonCode);
            }

            [Fact]
            public async Task ShouldIndicateCasePermittedWithDefaultStatusSecurity()
            {
                var @case = new CaseBuilder().Build().In(Db);
                new FilteredEthicalWallCase().In(Db).WithKnownId(x => x.CaseId, @case.Id);
                new FilteredRowSecurityCaseMultiOffice
                {
                    SecurityFlag = AllPermissions
                }.In(Db).WithKnownId(x => x.CaseId, @case.Id);

                var subject = CreateSubject();

                /* all users can have update access to cases */
                _siteControl.Read<int?>(SiteControls.DefaultSecurity).Returns(5);

                var r = await subject.Authorize(@case.Id, AccessPermissionLevel.Update);

                Assert.False(r.IsUnauthorized);
            }

            [Fact]
            public async Task ShouldIndicateCasePermittedWithStatusSecurity()
            {
                var protectedStatus = new Status(Fixture.Short(), Fixture.String()).In(Db);

                var @case = new CaseBuilder
                {
                    Status = protectedStatus
                }.Build().In(Db);

                new FilteredEthicalWallCase().In(Db).WithKnownId(x => x.CaseId, @case.Id);
                new FilteredRowSecurityCaseMultiOffice
                {
                    SecurityFlag = AllPermissions
                }.In(Db).WithKnownId(x => x.CaseId, @case.Id);

                var subject = CreateSubject();

                /* this user can have update access to cases with this status */
                new StatusSecurity(_thisUser.UserName, protectedStatus.Id, (short) AccessPermissionLevel.Update).In(Db);

                var r = await subject.Authorize(@case.Id, AccessPermissionLevel.Update);

                Assert.False(r.IsUnauthorized);
            }
        }

        public class InternalUserMultipleCasesScenario : FactBase
        {
            public InternalUserMultipleCasesScenario()
            {
                _thisUser = new User(Fixture.String(), false).In(Db);

                var rowAccess = new RowAccess("full-access", Fixture.String()).In(Db);
                rowAccess.Details.Add(new RowAccessDetail("full-access") {AccessType = "C"}.In(Db));

                _thisUser.RowAccessPermissions.Add(rowAccess);

                _securityContext.User.Returns(_thisUser);
            }

            readonly User _thisUser;
            readonly ISiteControlReader _siteControl = Substitute.For<ISiteControlReader>();
            readonly ISecurityContext _securityContext = Substitute.For<ISecurityContext>();

            [Fact]
            public async Task ShouldEvaluateDistinctCases()
            {
                var subject = new CaseAuthorization(Db, _securityContext, _siteControl);

                Case CreateCase()
                {
                    var protectedStatus = new Status(Fixture.Short(), Fixture.String()).In(Db);
                    new StatusSecurity(_thisUser.UserName, protectedStatus.Id, (short) AccessPermissionLevel.Update).In(Db);
                    var @case = new CaseBuilder {Status = protectedStatus}.Build().In(Db);
                    new FilteredEthicalWallCase().In(Db).WithKnownId(x => x.CaseId, @case.Id);
                    new FilteredRowSecurityCase {SecurityFlag = AccessPermissionLevel.FullAccess}.In(Db).WithKnownId(x => x.CaseId, @case.Id);

                    return @case;
                }

                var c1 = CreateCase();
                var c2 = CreateCase();
                var c3 = CreateCase();

                var viewability = (await subject.AccessibleCases(c1.Id, c2.Id, c3.Id, c2.Id, c1.Id, c3.Id)).ToArray();

                Assert.Equal(3, viewability.Length);

                var updatability = (await subject.UpdatableCases(c1.Id, c2.Id, c3.Id, c2.Id, c1.Id, c3.Id)).ToArray();

                Assert.Equal(3, updatability.Length);
            }

            [Fact]
            public async Task ShouldReturnOnlyUpdatableCases()
            {
                var subject = new CaseAuthorization(Db, _securityContext, _siteControl);

                var case1FullAccess = new CaseBuilder().Build().In(Db);
                new FilteredEthicalWallCase().In(Db).WithKnownId(x => x.CaseId, case1FullAccess.Id);
                new FilteredRowSecurityCase {SecurityFlag = AccessPermissionLevel.FullAccess}.In(Db).WithKnownId(x => x.CaseId, case1FullAccess.Id);

                var case2NoEthicalWallAccess = new CaseBuilder().Build().In(Db);

                var case3NoRowLevelAccess = new CaseBuilder().Build().In(Db);
                new FilteredEthicalWallCase().In(Db).WithKnownId(x => x.CaseId, case3NoRowLevelAccess.Id);

                var protectedStatus = new Status(Fixture.Short(), Fixture.String()).In(Db);
                new StatusSecurity(_thisUser.UserName, protectedStatus.Id, (short) AccessPermissionLevel.Select).In(Db); // only has select level.
                var case4NoUpdateBasedOnStatusAccess = new CaseBuilder {Status = protectedStatus}.Build().In(Db);
                new FilteredEthicalWallCase().In(Db).WithKnownId(x => x.CaseId, case4NoUpdateBasedOnStatusAccess.Id);
                new FilteredRowSecurityCase {SecurityFlag = AccessPermissionLevel.Select}.In(Db).WithKnownId(x => x.CaseId, case4NoUpdateBasedOnStatusAccess.Id);

                var caseIds = new[] {case1FullAccess.Id, case2NoEthicalWallAccess.Id, case3NoRowLevelAccess.Id, case4NoUpdateBasedOnStatusAccess.Id};

                var updatability = (await subject.UpdatableCases(caseIds)).ToArray();

                Assert.Single(updatability);
                Assert.Contains(case1FullAccess.Id, updatability);
            }

            [Fact]
            public async Task ShouldReturnOnlyUpdatableCases2()
            {
                var subject = new CaseAuthorization(Db, _securityContext, _siteControl);

                Case CreateAccessibleCase()
                {
                    var protectedStatus = new Status(Fixture.Short(), Fixture.String()).In(Db);
                    new StatusSecurity(_thisUser.UserName, protectedStatus.Id, (short) AccessPermissionLevel.Update).In(Db);
                    var @case = new CaseBuilder {Status = protectedStatus}.Build().In(Db);
                    new FilteredEthicalWallCase().In(Db).WithKnownId(x => x.CaseId, @case.Id);
                    new FilteredRowSecurityCase {SecurityFlag = AccessPermissionLevel.FullAccess}.In(Db).WithKnownId(x => x.CaseId, @case.Id);

                    return @case;
                }

                var c1 = CreateAccessibleCase();
                var c2 = CreateAccessibleCase();
                var c3 = CreateAccessibleCase();

                var updatability = (await subject.UpdatableCases(c1.Id, c2.Id, c3.Id)).ToArray();

                Assert.Equal(3, updatability.Length);
            }

            [Fact]
            public async Task ShouldReturnOnlyViewableCases1()
            {
                var subject = new CaseAuthorization(Db, _securityContext, _siteControl);

                var case1FullAccess = new CaseBuilder().Build().In(Db);
                new FilteredEthicalWallCase().In(Db).WithKnownId(x => x.CaseId, case1FullAccess.Id);
                new FilteredRowSecurityCase {SecurityFlag = AccessPermissionLevel.FullAccess}.In(Db).WithKnownId(x => x.CaseId, case1FullAccess.Id);

                var case2NoEthicalWallAccess = new CaseBuilder().Build().In(Db);

                var case3NoRowLevelAccess = new CaseBuilder().Build().In(Db);
                new FilteredEthicalWallCase().In(Db).WithKnownId(x => x.CaseId, case3NoRowLevelAccess.Id);

                var protectedStatus = new Status(Fixture.Short(), Fixture.String()).In(Db);
                new StatusSecurity(_thisUser.UserName, protectedStatus.Id, (short) AccessPermissionLevel.Select).In(Db);
                var case4NoUpdateBasedOnStatusAccess = new CaseBuilder {Status = protectedStatus}.Build().In(Db);
                new FilteredEthicalWallCase().In(Db).WithKnownId(x => x.CaseId, case4NoUpdateBasedOnStatusAccess.Id);
                new FilteredRowSecurityCase {SecurityFlag = AccessPermissionLevel.Select}.In(Db).WithKnownId(x => x.CaseId, case4NoUpdateBasedOnStatusAccess.Id);

                var caseIds = new[] {case1FullAccess.Id, case2NoEthicalWallAccess.Id, case3NoRowLevelAccess.Id, case4NoUpdateBasedOnStatusAccess.Id};

                var viewability = (await subject.AccessibleCases(caseIds)).ToArray();

                Assert.Equal(2, viewability.Length);
                Assert.Contains(case1FullAccess.Id, viewability);
                Assert.Contains(case4NoUpdateBasedOnStatusAccess.Id, viewability);
            }

            [Fact]
            public async Task ShouldReturnOnlyViewableCases2()
            {
                var subject = new CaseAuthorization(Db, _securityContext, _siteControl);

                Case CreateAccessibleCase()
                {
                    var protectedStatus = new Status(Fixture.Short(), Fixture.String()).In(Db);
                    new StatusSecurity(_thisUser.UserName, protectedStatus.Id, (short) AccessPermissionLevel.Select).In(Db);
                    var @case = new CaseBuilder {Status = protectedStatus}.Build().In(Db);
                    new FilteredEthicalWallCase().In(Db).WithKnownId(x => x.CaseId, @case.Id);
                    new FilteredRowSecurityCase {SecurityFlag = AccessPermissionLevel.FullAccess}.In(Db).WithKnownId(x => x.CaseId, @case.Id);

                    return @case;
                }

                var c1 = CreateAccessibleCase();
                var c2 = CreateAccessibleCase();
                var c3 = CreateAccessibleCase();

                var viewability = (await subject.AccessibleCases(c1.Id, c2.Id, c3.Id)).ToArray();

                Assert.Equal(3, viewability.Length);
            }
        }
    }
}