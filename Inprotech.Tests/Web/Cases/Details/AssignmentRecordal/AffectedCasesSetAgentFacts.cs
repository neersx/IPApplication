using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Names;
using Inprotech.Web.Cases.AssignmentRecordal;
using Inprotech.Web.Cases.Details;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases.AssignmentRecordal;
using InprotechKaizen.Model.Components.Cases;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Security;
using NSubstitute;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Xunit;

namespace Inprotech.Tests.Web.Cases.Details.AssignmentRecordal
{
    public class AffectedCasesSetAgentFacts
    {
        public class AffectedCasesSetAgentFixture : IFixture<AffectedCasesSetAgent>
        {
            public AffectedCasesSetAgentFixture(InMemoryDbContext db)
            {
                CaseAuthorization = Substitute.For<ICaseAuthorization>();
                GlobalNameChangeCommand = Substitute.For<IGlobalNameChangeCommand>();
                SecurityContext = Substitute.For<ISecurityContext>();
                SecurityContext.User.Returns(new User());
                Helper = Substitute.For<IAssignmentRecordalHelper>();
                Subject = new AffectedCasesSetAgent(db, CaseAuthorization, GlobalNameChangeCommand, SecurityContext, Helper);
            }

            public AffectedCasesSetAgent Subject { get; set; }
            public ICaseAuthorization CaseAuthorization { get; set; }
            public IGlobalNameChangeCommand GlobalNameChangeCommand { get; set; }
            public ISecurityContext SecurityContext { get; set; }
            public IAssignmentRecordalHelper Helper { get; set; }
        }

        public class SetAgentForAffectedCases : FactBase
        {
            [Fact]
            public async Task ThrowsExceptionWhenArgumentIsNull()
            {
                var f = new AffectedCasesSetAgentFixture(Db);
                await Assert.ThrowsAsync<ArgumentNullException>(async () => await f.Subject.SetAgentForAffectedCases(null));
            }

            [Fact]
            public async Task ThrowsExceptionWhenAgentDoesNotExist()
            {
                var f = new AffectedCasesSetAgentFixture(Db);
                var model = new AffectedCasesAgentModel
                {
                    AgentId = Fixture.Integer()
                };
                await Assert.ThrowsAsync<ArgumentException>(async () => await f.Subject.SetAgentForAffectedCases(model));
            }

            [Fact]
            public async Task SetAgentAsCaseNames()
            {
                var agentName = new NameBuilder(Db).Build().In(Db);
                new NameTypeBuilder { NameTypeCode = KnownNameTypes.Agent }.Build().In(Db);
                var mainCase = new CaseBuilder().Build().In(Db);
                var rc1 = new CaseBuilder().Build().In(Db);
                var country = new CountryBuilder().Build().In(Db);
                const string officialNo = "111111";
                var rt = new RecordalType();
                var ac1 = new RecordalAffectedCase { Case = mainCase, CaseId = mainCase.Id, RelatedCase = rc1, RelatedCaseId = rc1.Id, RecordalStepSeq = 1, RecordalType = rt, RecordalTypeNo = rt.Id, SequenceNo = 1, AgentId = Fixture.Integer() }.In(Db);
                var ac2 = new RecordalAffectedCase { Case = mainCase, CaseId = mainCase.Id, Country = country, CountryId = country.Id, OfficialNumber = officialNo, RecordalStepSeq = 1, RecordalType = rt, RecordalTypeNo = rt.Id, SequenceNo = 1, AgentId = 1 }.In(Db);

                var f = new AffectedCasesSetAgentFixture(Db);
                var model = new AffectedCasesAgentModel
                {
                    AgentId = agentName.Id,
                    MainCaseId = mainCase.Id,
                    AffectedCases = new[]
                    {
                        mainCase.Id + "^" + rc1.Id + "^" + rc1.CountryId + "^" + rc1.CurrentOfficialNumber,
                        mainCase.Id + "^^" + country.Id + "^" + officialNo

                    },
                    IsCaseNameSet = true
                };
                var authorizedCases = new[] { rc1.Id };
                f.CaseAuthorization.UpdatableCases(Arg.Any<int[]>()).Returns(authorizedCases);
                var affectedCases = Db.Set<RecordalAffectedCase>();
                f.Helper.GetAffectedCases(Arg.Any<int>(), Arg.Any<IEnumerable<string>>()).Returns(affectedCases);

                var result = await f.Subject.SetAgentForAffectedCases(model);
                Assert.Equal("success", result.Result);
                Assert.Null(ac1.AgentId);
                Assert.Equal(agentName.Id, ac2.AgentId);
                await f.GlobalNameChangeCommand.Received(1).PerformGlobalNameChange(Arg.Any<int[]>(), f.SecurityContext.User.Id, KnownNameTypes.Agent, agentName.Id, 3, true, true);
            }

            [Fact]
            public async Task SetAgentInAffectedCase()
            {
                var agentName = new NameBuilder(Db).Build().In(Db);
                var mainCase = new CaseBuilder().Build().In(Db);
                var rc1 = new CaseBuilder().Build().In(Db);
                var rt = new RecordalType();
                var ac1 = new RecordalAffectedCase { Case = mainCase, CaseId = mainCase.Id, RelatedCase = rc1, RelatedCaseId = rc1.Id, RecordalStepSeq = 1, RecordalType = rt, RecordalTypeNo = rt.Id, SequenceNo = 1 }.In(Db);

                var f = new AffectedCasesSetAgentFixture(Db);
                var model = new AffectedCasesAgentModel
                {
                    AgentId = agentName.Id,
                    MainCaseId = mainCase.Id,
                    AffectedCases = new[]
                    {
                        mainCase.Id + "^" + rc1.Id + "^"+ rc1.CountryId + "^" + rc1.CurrentOfficialNumber
                    },
                    IsCaseNameSet = false
                };
                var authorizedCases = new[] { rc1.Id };
                f.CaseAuthorization.UpdatableCases(Arg.Any<int[]>()).Returns(authorizedCases);
                var affectedCases = Db.Set<RecordalAffectedCase>();
                f.Helper.GetAffectedCases(Arg.Any<int>(), Arg.Any<IEnumerable<string>>()).Returns(affectedCases);

                var result = await f.Subject.SetAgentForAffectedCases(model);
                Assert.Equal("success", result.Result);
                await f.GlobalNameChangeCommand.Received(0).PerformGlobalNameChange(Arg.Any<int[]>(), Arg.Any<int>(), Arg.Any<string>(), Arg.Any<int>());
                Assert.Equal(agentName.Id, ac1.AgentId);
            }

            [Fact]
            public async Task ShouldNotUpdateCaseIfNotAuthorized()
            {
                var agentName = new NameBuilder(Db).Build().In(Db);
                var mainCase = new CaseBuilder().Build().In(Db);
                var rc1 = new CaseBuilder().Build().In(Db);
                var rt = new RecordalType();
                new RecordalAffectedCase { Case = mainCase, CaseId = mainCase.Id, RelatedCase = rc1, RelatedCaseId = rc1.Id, RecordalStepSeq = 1, RecordalType = rt, RecordalTypeNo = rt.Id, SequenceNo = 1 }.In(Db);

                var f = new AffectedCasesSetAgentFixture(Db);
                var model = new AffectedCasesAgentModel
                {
                    AgentId = agentName.Id,
                    MainCaseId = mainCase.Id,
                    AffectedCases = new[]
                    {
                        mainCase.Id + "^" + rc1.Id + "^^"
                    },
                    IsCaseNameSet = true
                };
                var affectedCases = Db.Set<RecordalAffectedCase>();
                f.Helper.GetAffectedCases(Arg.Any<int>(), Arg.Any<IEnumerable<string>>()).Returns(affectedCases);
                var result = await f.Subject.SetAgentForAffectedCases(model);
                Assert.Equal("success", result.Result);
                await f.GlobalNameChangeCommand.Received(0).PerformGlobalNameChange(Arg.Any<int[]>(), Arg.Any<int>(), Arg.Any<string>(), Arg.Any<int>());
            }
        }

        public class ClearAgentForAffectedCases : FactBase
        {
            [Fact]
            public async Task ThrowsExceptionWhenArgumentIsNull()
            {
                var f = new AffectedCasesSetAgentFixture(Db);
                await Assert.ThrowsAsync<ArgumentNullException>(async () => await f.Subject.ClearAgentForAffectedCases(Fixture.Integer(), null));
            }

            [Fact]
            public async Task ClearAgentsSuccessfully()
            {
                var mainCase = new CaseBuilder().Build().In(Db);
                var rc1 = new CaseBuilder().Build().In(Db);
                var country = new CountryBuilder().Build().In(Db);
                const string officialNo = "111111";
                var rt = new RecordalType();
                var ac1 = new RecordalAffectedCase { Case = mainCase, CaseId = mainCase.Id, RelatedCase = rc1, RelatedCaseId = rc1.Id, RecordalStepSeq = 1, RecordalType = rt, RecordalTypeNo = rt.Id, SequenceNo = 1, AgentId = Fixture.Integer() }.In(Db);
                var ac2 = new RecordalAffectedCase { Case = mainCase, CaseId = mainCase.Id, Country = country, CountryId = country.Id, OfficialNumber = officialNo, RecordalStepSeq = 1, RecordalType = rt, RecordalTypeNo = rt.Id, SequenceNo = 1, AgentId = 1 }.In(Db);

                var f = new AffectedCasesSetAgentFixture(Db);
                var model = new DeleteAffectedCaseModel
                {
                    SelectedRowKeys = new List<string>
                    {
                        mainCase.Id + "^" + rc1.Id + "^" + rc1.CountryId + "^" + rc1.CurrentOfficialNumber,
                        mainCase.Id + "^^" + country.Id + "^" + officialNo
                    }
                };
                var authorizedCases = new[] { rc1.Id };
                f.CaseAuthorization.UpdatableCases(Arg.Any<int[]>()).Returns(authorizedCases);
                var affectedCases = Db.Set<RecordalAffectedCase>();
                f.Helper.GetAffectedCasesToBeChanged(Arg.Any<int>(), Arg.Any<DeleteAffectedCaseModel>()).Returns(affectedCases);

                var result = await f.Subject.ClearAgentForAffectedCases(mainCase.Id, model);
                Assert.Equal("success", result.Result);
                Assert.Null(ac1.AgentId);
                Assert.Null(ac2.AgentId);
                await f.GlobalNameChangeCommand.Received(0).PerformGlobalNameChange(Arg.Any<int[]>(), f.SecurityContext.User.Id, KnownNameTypes.Agent, null, null, false, false, true);
            }

            [Fact]
            public async Task ClearCaseNameAgent()
            {
                var mainCase = new CaseBuilder().Build().In(Db);
                var rc1 = new CaseBuilder().Build().In(Db);
                var rt = new RecordalType();
                new RecordalAffectedCase { Case = mainCase, CaseId = mainCase.Id, RelatedCase = rc1, RelatedCaseId = rc1.Id, RecordalStepSeq = 1, RecordalType = rt, RecordalTypeNo = rt.Id, SequenceNo = 1 }.In(Db);

                var f = new AffectedCasesSetAgentFixture(Db);
                var model = new DeleteAffectedCaseModel
                {
                    SelectedRowKeys = new List<string>
                    {
                        mainCase.Id + "^" + rc1.Id + "^" + rc1.CountryId + "^" + rc1.CurrentOfficialNumber
                    },
                    ClearCaseNameAgent = true
                };
                var authorizedCases = new[] { rc1.Id };
                f.CaseAuthorization.UpdatableCases(Arg.Any<int[]>()).Returns(authorizedCases);
                var affectedCases = Db.Set<RecordalAffectedCase>();
                f.Helper.GetAffectedCasesToBeChanged(Arg.Any<int>(), Arg.Any<DeleteAffectedCaseModel>()).Returns(affectedCases);

                var result = await f.Subject.ClearAgentForAffectedCases(mainCase.Id, model);
                Assert.Equal("success", result.Result);
                await f.GlobalNameChangeCommand.Received(1).PerformGlobalNameChange(Arg.Is<int[]>(_ => _.Length == 1), f.SecurityContext.User.Id, KnownNameTypes.Agent, null, null, false, false, true);
            }

            [Fact]
            public async Task ClearAllCaseNameAgents()
            {
                var mainCase = new CaseBuilder().Build().In(Db);
                var rc1 = new CaseBuilder().Build().In(Db);
                var rc2 = new CaseBuilder().Build().In(Db);
                var rt = new RecordalType();
                new RecordalAffectedCase { Case = mainCase, CaseId = mainCase.Id, RelatedCase = rc1, RelatedCaseId = rc1.Id, RecordalStepSeq = 1, RecordalType = rt, RecordalTypeNo = rt.Id, SequenceNo = 1 }.In(Db);
                new RecordalAffectedCase { Case = mainCase, CaseId = mainCase.Id, RelatedCase = rc2, RelatedCaseId = rc2.Id, RecordalStepSeq = 1, RecordalType = rt, RecordalTypeNo = rt.Id, SequenceNo = 2 }.In(Db);

                var f = new AffectedCasesSetAgentFixture(Db);
                var model = new DeleteAffectedCaseModel
                {
                    IsAllSelected = true,
                    ClearCaseNameAgent = true
                };
                var authorizedCases = new[] { rc1.Id, rc2.Id };
                f.CaseAuthorization.UpdatableCases(Arg.Any<int[]>()).Returns(authorizedCases);
                var affectedCases = Db.Set<RecordalAffectedCase>();
                f.Helper.GetAffectedCasesToBeChanged(Arg.Any<int>(), Arg.Any<DeleteAffectedCaseModel>()).Returns(affectedCases);

                var result = await f.Subject.ClearAgentForAffectedCases(mainCase.Id, model);
                Assert.Equal("success", result.Result);
                await f.GlobalNameChangeCommand.Received(1).PerformGlobalNameChange(Arg.Is<int[]>(_ => _.Length == 2), f.SecurityContext.User.Id, KnownNameTypes.Agent, null, null, false, false, true);

                model = new DeleteAffectedCaseModel
                {
                    IsAllSelected = true,
                    DeSelectedRowKeys = new List<string>
                    {
                        mainCase.Id + "^" + rc1.Id + "^" + rc1.CountryId + "^" + rc1.CurrentOfficialNumber
                    },
                    ClearCaseNameAgent = true
                };
                var cases = Db.Set<RecordalAffectedCase>().Where(_ => _.RelatedCaseId != rc1.Id);
                f.Helper.GetAffectedCasesToBeChanged(Arg.Any<int>(), Arg.Any<DeleteAffectedCaseModel>()).Returns(cases);

                f.CaseAuthorization.UpdatableCases(Arg.Any<int[]>()).Returns(new[] { rc2.Id });
                await f.Subject.ClearAgentForAffectedCases(mainCase.Id, model);
                await f.GlobalNameChangeCommand.Received(1).PerformGlobalNameChange(Arg.Is<int[]>(_ => _.FirstOrDefault() == rc2.Id), f.SecurityContext.User.Id, KnownNameTypes.Agent, null, null, false, false, true);
            }

            [Fact]
            public async Task ShouldNotClearCaseAgentIfNotAuthorized()
            {
                var mainCase = new CaseBuilder().Build().In(Db);
                var rc1 = new CaseBuilder().Build().In(Db);
                var rt = new RecordalType();
                new RecordalAffectedCase { Case = mainCase, CaseId = mainCase.Id, RelatedCase = rc1, RelatedCaseId = rc1.Id, RecordalStepSeq = 1, RecordalType = rt, RecordalTypeNo = rt.Id, SequenceNo = 1 }.In(Db);

                var f = new AffectedCasesSetAgentFixture(Db);
                var model = new DeleteAffectedCaseModel
                {
                    ClearCaseNameAgent = false,
                    SelectedRowKeys = new List<string>
                    {
                        mainCase.Id + "^" + rc1.Id + "^" + rc1.CountryId + "^" + rc1.CurrentOfficialNumber
                    }
                };
                var cases = Db.Set<RecordalAffectedCase>().Where(_ => _.RelatedCaseId == rc1.Id);
                f.Helper.GetAffectedCasesToBeChanged(Arg.Any<int>(), Arg.Any<DeleteAffectedCaseModel>()).Returns(cases);

                var result = await f.Subject.ClearAgentForAffectedCases(mainCase.Id, model);
                Assert.Equal("success", result.Result);
                await f.GlobalNameChangeCommand.Received(0).PerformGlobalNameChange(Arg.Any<int[]>(), f.SecurityContext.User.Id, KnownNameTypes.Agent, null, null, false, false, true);
            }

            [Fact]
            public async Task ShouldNotClearCaseAgentIfClearCaseNameAgentSetToFalse()
            {
                var f = new AffectedCasesSetAgentFixture(Db);
                var mainCase = new CaseBuilder().Build().In(Db);
                var rc1 = new CaseBuilder().Build().In(Db);
                var rc2 = new CaseBuilder().Build().In(Db);
                var rt = new RecordalType();
                new RecordalAffectedCase { Case = mainCase, CaseId = mainCase.Id, RelatedCase = rc1, RelatedCaseId = rc1.Id, RecordalStepSeq = 1, RecordalType = rt, RecordalTypeNo = rt.Id, SequenceNo = 1 }.In(Db);
                var authorizedCases = new[] { rc1.Id, rc2.Id };
                f.CaseAuthorization.UpdatableCases(Arg.Any<int[]>()).Returns(authorizedCases);
                var model = new DeleteAffectedCaseModel
                {
                    ClearCaseNameAgent = false,
                    SelectedRowKeys = new List<string>
                    {
                        mainCase.Id + "^" + rc1.Id + "^" + rc1.CountryId + "^" + rc1.CurrentOfficialNumber
                    }
                };
                var cases = Db.Set<RecordalAffectedCase>().Where(_ => _.RelatedCaseId == rc1.Id);
                f.Helper.GetAffectedCasesToBeChanged(Arg.Any<int>(), Arg.Any<DeleteAffectedCaseModel>()).Returns(cases);

                var result = await f.Subject.ClearAgentForAffectedCases(mainCase.Id, model);
                Assert.Equal("success", result.Result);
                await f.GlobalNameChangeCommand.Received(0).PerformGlobalNameChange(Arg.Any<int[]>(), f.SecurityContext.User.Id, KnownNameTypes.Agent, null, null, false, false, true);
            }
        }
    }
}
