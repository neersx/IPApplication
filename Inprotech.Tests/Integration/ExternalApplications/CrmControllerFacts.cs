using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Threading.Tasks;
using System.Web.Http;
using System.Web.Http.Hosting;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Diagnostics;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Security;
using Inprotech.Integration.ExternalApplications;
using Inprotech.Integration.ExternalApplications.Crm;
using Inprotech.Integration.ExternalApplications.Crm.Request;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Common;
using Inprotech.Tests.Web.Builders.Model.Configuration;
using Inprotech.Tests.Web.Builders.Model.Names;
using Inprotech.Tests.Web.Builders.Model.Security;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Components.Names.Extensions;
using InprotechKaizen.Model.Components.Names.Validation;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Components.System.Policy.AuditTrails;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.ExternalApplications
{
    public class CrmControllerFacts
    {
        public class CrmControllerFixture : IFixture<CrmController>
        {
            public CrmControllerFixture(InMemoryDbContext db)
            {
                DbContext = db;

                SecurityContext = Substitute.For<ISecurityContext>();
                SecurityContext.User.Returns(InternalWebApiUser());

                CaseAuthorization = Substitute.For<ICaseAuthorization>();
                NameAccessSecurity = Substitute.For<INameAccessSecurity>();
                NameAttributeLoader = Substitute.For<INameAttributeLoader>();
                CrmValidator = Substitute.For<ICrmValidator>();
                CreateContactName = Substitute.For<ICrmContactProcessor>();
                NameValidator = Substitute.For<INameValidator>();
                TransactionRecordal = Substitute.For<ITransactionRecordal>();
                ContactActivityProcessor = Substitute.For<IContactActivityProcessor>();

                Subject = new CrmController(DbContext, CaseAuthorization,
                                            NameAccessSecurity, NameAttributeLoader, CrmValidator, CreateContactName, NameValidator,
                                            TransactionRecordal, ContactActivityProcessor, SecurityContext)
                {
                    Request = new HttpRequestMessage(HttpMethod.Get, "crmController")
                };
                Subject.Request.Properties.Add(HttpPropertyKeys.HttpConfigurationKey, new HttpConfiguration());
            }

            public ICaseAuthorization CaseAuthorization { get; set; }

            public INameAccessSecurity NameAccessSecurity { get; set; }

            public INameAttributeLoader NameAttributeLoader { get; set; }

            public ISecurityContext SecurityContext { get; set; }

            public ICrmValidator CrmValidator { get; set; }

            public ICrmContactProcessor CreateContactName { get; set; }

            public INameValidator NameValidator { get; set; }

            public ITransactionRecordal TransactionRecordal { get; set; }

            public IContactActivityProcessor ContactActivityProcessor { get; set; }

            public IDictionary<int, AccessPermissionLevel> AccessPermissions { get; set; }

            public InMemoryDbContext DbContext { get; set; }

            public CrmController Subject { get; }

            User InternalWebApiUser()
            {
                return UserBuilder.AsInternalUser(DbContext, "internal").Build().In(DbContext);
            }

            public void CrmUpdateMarketingContactData()
            {
                var opportunityPropertyType = new PropertyTypeBuilder {Id = "A"}.Build().In(DbContext);
                opportunityPropertyType.SetCrmOnly(true);

                var @case = new CaseBuilder {PropertyType = opportunityPropertyType, Irn = "1234/a"}.Build().In(DbContext);
                var name = new NameBuilder(DbContext) {FirstName = "Test"}.Build().In(DbContext);
                var contactNameType = new NameTypeBuilder {NameTypeCode = KnownNameTypes.Contact}.Build().In(DbContext);
                new CaseNameBuilder(DbContext) {Name = name, NameType = contactNameType}.BuildWithCase(@case, 0).In(DbContext);
                new TableCodeBuilder {TableCode = -1, TableType = (short) ProtectedTableTypes.MarketingActivityResponse}
                    .Build().In(DbContext);

                var nonCrmContact = new NameBuilder(DbContext) {FirstName = "Test2"}.Build().In(DbContext);
                new CaseNameBuilder(DbContext) {Name = nonCrmContact}.BuildWithCase(@case, 0).In(DbContext);
            }
        }

        public class CrmCasesMethod : FactBase
        {
            List<Case> CrmCases { get; set; }

            void SetUpCrmCases()
            {
                var opportunityPropertyType = new PropertyTypeBuilder {Id = "A"}.Build().In(Db);
                opportunityPropertyType.SetCrmOnly(true);

                var firstCrmCase =
                    new Case("1234/c", new CountryBuilder().Build().In(Db), new CaseTypeBuilder().Build().In(Db),
                             opportunityPropertyType).In(Db);
                firstCrmCase.CaseStatus = new StatusBuilder().Build().In(Db);
                firstCrmCase.CaseStatus.LiveFlag = 1m;

                var marketingEventPropertyType = new PropertyTypeBuilder {Id = "E"}.Build().In(Db);
                marketingEventPropertyType.SetCrmOnly(true);

                var secondCrmCase =
                    new Case("1234/b", new CountryBuilder().Build().In(Db), new CaseTypeBuilder().Build().In(Db),
                             marketingEventPropertyType).In(Db);
                secondCrmCase.CaseStatus = new StatusBuilder().Build().In(Db);
                secondCrmCase.CaseStatus.LiveFlag = 1m;

                var campaignPropertyType = new PropertyTypeBuilder {Id = "F"}.Build().In(Db);
                campaignPropertyType.SetCrmOnly(true);

                var thirdCrmCase =
                    new Case("1234/a", new CountryBuilder().Build().In(Db), new CaseTypeBuilder().Build().In(Db),
                             campaignPropertyType).In(Db);
                thirdCrmCase.CaseStatus = new StatusBuilder().Build().In(Db);
                thirdCrmCase.CaseStatus.LiveFlag = 1m;

                CrmCases = new List<Case> {firstCrmCase, secondCrmCase, thirdCrmCase};

                new SiteControlBuilder
                {
                    SiteControlId = SiteControls.PropertyTypeOpportunity,
                    StringValue = "A"
                }.Build().In(Db);

                new SiteControlBuilder
                {
                    SiteControlId = SiteControls.PropertyTypeMarketingEvent,
                    StringValue = "M"
                }.Build().In(Db);

                new SiteControlBuilder
                {
                    SiteControlId = SiteControls.PropertyTypeCampaign
                }.Build().In(Db);
            }

            [Fact]
            public async Task ReturnsCrmCasesBasedOnPropertyType()
            {
                var f = new CrmControllerFixture(Db);

                SetUpCrmCases();

                f.AccessPermissions = new Dictionary<int, AccessPermissionLevel>
                {
                    {CrmCases.First(@case => @case.Irn == "1234/c").Id, AccessPermissionLevel.Select},
                    {CrmCases.First(@case => @case.Irn == "1234/b").Id, AccessPermissionLevel.Select},
                    {CrmCases.First(@case => @case.Irn == "1234/a").Id, AccessPermissionLevel.Select}
                };

                f.CaseAuthorization.GetInternalUserAccessPermissions(Arg.Any<IEnumerable<int>>(), Arg.Any<int?>())
                 .Returns(f.AccessPermissions);

                var r = await f.Subject.ListCases(CrmPropertyType.Opportunity.ToString());

                Assert.Equal(CrmCases.First(crmcase => crmcase.PropertyType.Code.Equals("A")).PropertyType.Code,
                             r.First().PropertyTypeId);
            }

            [Fact]
            public async Task ReturnsCrmCasesForPropertyTypeCrmOnly()
            {
                var f = new CrmControllerFixture(Db);

                SetUpCrmCases();

                var opportunityPropertyType = new PropertyTypeBuilder {Id = "A"}.Build().In(Db);
                opportunityPropertyType.SetCrmOnly(false);

                var crmCase =
                    new Case("1234/x", new CountryBuilder().Build().In(Db), new CaseTypeBuilder().Build().In(Db),
                             opportunityPropertyType).In(Db);
                CrmCases.Add(crmCase);

                f.AccessPermissions = new Dictionary<int, AccessPermissionLevel>
                {
                    {CrmCases.First(@case => @case.Irn == "1234/c").Id, AccessPermissionLevel.Select},
                    {CrmCases.First(@case => @case.Irn == "1234/b").Id, AccessPermissionLevel.Select},
                    {CrmCases.First(@case => @case.Irn == "1234/a").Id, AccessPermissionLevel.Select},
                    {CrmCases.First(@case => @case.Irn == "1234/x").Id, AccessPermissionLevel.Select}
                };

                f.CaseAuthorization.GetInternalUserAccessPermissions(Arg.Any<IEnumerable<int>>(), Arg.Any<int?>())
                 .Returns(f.AccessPermissions);

                var r = await f.Subject.ListCases(CrmPropertyType.Opportunity.ToString());

                Assert.True(!r.Any(c => c.Irn.Equals("1234/x")));
            }

            [Fact]
            public async Task ReturnsCrmCasesInAcendingOrderOnIrn()
            {
                var f = new CrmControllerFixture(Db);

                SetUpCrmCases();

                CrmCases.RemoveAll(crmcase => crmcase.PropertyType.Code.Equals("A"));

                var opportunityPropertyType = new PropertyTypeBuilder {Id = "A"}.Build().In(Db);
                opportunityPropertyType.SetCrmOnly(true);

                CrmCases.Add(
                             new Case("AU/1234/x", new CountryBuilder().Build().In(Db), new CaseTypeBuilder().Build().In(Db),
                                      opportunityPropertyType) {CaseStatus = new StatusBuilder().Build().In(Db)}.In(Db));
                CrmCases.Add(
                             new Case("US/1234/f", new CountryBuilder().Build().In(Db), new CaseTypeBuilder().Build().In(Db),
                                      opportunityPropertyType) {CaseStatus = new StatusBuilder().Build().In(Db)}.In(Db));
                CrmCases.Add(
                             new Case("1234/f", new CountryBuilder().Build().In(Db), new CaseTypeBuilder().Build().In(Db),
                                      opportunityPropertyType) {CaseStatus = new StatusBuilder().Build().In(Db)}.In(Db));

                CrmCases.Where(crmcase => crmcase.PropertyType.Code.Equals("A"))
                        .ToList()
                        .ForEach(item => item.CaseStatus.LiveFlag = 1m);

                f.AccessPermissions = new Dictionary<int, AccessPermissionLevel>
                {
                    {CrmCases.First(@case => @case.Irn == "1234/b").Id, AccessPermissionLevel.Select},
                    {CrmCases.First(@case => @case.Irn == "1234/a").Id, AccessPermissionLevel.Select},
                    {CrmCases.First(@case => @case.Irn == "AU/1234/x").Id, AccessPermissionLevel.Select},
                    {CrmCases.First(@case => @case.Irn == "US/1234/f").Id, AccessPermissionLevel.Select},
                    {CrmCases.First(@case => @case.Irn == "1234/f").Id, AccessPermissionLevel.Select}
                };

                f.CaseAuthorization.GetInternalUserAccessPermissions(Arg.Any<IEnumerable<int>>(), Arg.Any<int?>())
                 .Returns(f.AccessPermissions);

                var r = await f.Subject.ListCases(CrmPropertyType.Opportunity.ToString());

                var crmCases = r as CrmCase[] ?? r.ToArray();
                Assert.Equal("1234/f", crmCases.First().Irn);
                Assert.Equal("US/1234/f", crmCases.Last().Irn);
            }

            [Fact]
            public async Task ReturnsCrmCasesWithSelectAccessPermissions()
            {
                var f = new CrmControllerFixture(Db);

                SetUpCrmCases();

                f.AccessPermissions = new Dictionary<int, AccessPermissionLevel>
                {
                    {CrmCases.First(@case => @case.Irn == "1234/c").Id, AccessPermissionLevel.Select},
                    {CrmCases.First(@case => @case.Irn == "1234/b").Id, AccessPermissionLevel.Select},
                    {CrmCases.First(@case => @case.Irn == "1234/a").Id, AccessPermissionLevel.Select}
                };

                f.CaseAuthorization.GetInternalUserAccessPermissions(Arg.Any<IEnumerable<int>>(), Arg.Any<int?>())
                 .Returns(f.AccessPermissions);

                var opportunityPropertyType = new PropertyTypeBuilder {Id = "A"}.Build().In(Db);
                opportunityPropertyType.SetCrmOnly(true);

                var crmCase =
                    new Case("1234/x", new CountryBuilder().Build().In(Db), new CaseTypeBuilder().Build().In(Db),
                             opportunityPropertyType).In(Db);
                CrmCases.Add(crmCase);

                var r = await f.Subject.ListCases(CrmPropertyType.Opportunity.ToString());

                Assert.True(!r.Any(c => c.Irn.Equals("1234/x")));
            }

            [Fact]
            public async Task ReturnsNoCrmCasesWhenPropertyTypeIsNotRelevant()
            {
                var f = new CrmControllerFixture(Db);

                SetUpCrmCases();

                f.AccessPermissions = new Dictionary<int, AccessPermissionLevel>
                {
                    {CrmCases.First(@case => @case.Irn == "1234/c").Id, AccessPermissionLevel.Select},
                    {CrmCases.First(@case => @case.Irn == "1234/b").Id, AccessPermissionLevel.Select},
                    {CrmCases.First(@case => @case.Irn == "1234/a").Id, AccessPermissionLevel.Select}
                };

                f.CaseAuthorization.GetInternalUserAccessPermissions(Arg.Any<IEnumerable<int>>(), Arg.Any<int?>())
                 .Returns(f.AccessPermissions);

                var r = await f.Subject.ListCases(CrmPropertyType.Marketingevent.ToString());

                Assert.Empty(r);
            }

            [Fact]
            public async Task ReturnsOnlyLiveCasesForRelevantPropertyType()
            {
                var f = new CrmControllerFixture(Db);

                SetUpCrmCases();

                var opportunityPropertyType = new PropertyTypeBuilder {Id = "A"}.Build().In(Db);
                opportunityPropertyType.SetCrmOnly(true);

                var liveCrmCase =
                    new Case("1234/x", new CountryBuilder().Build().In(Db), new CaseTypeBuilder().Build().In(Db),
                             opportunityPropertyType).In(Db);
                liveCrmCase.CaseStatus = new StatusBuilder().Build().In(Db);
                liveCrmCase.CaseStatus.LiveFlag = 1m;

                var deadCrmCase =
                    new Case("1234/f", new CountryBuilder().Build().In(Db), new CaseTypeBuilder().Build().In(Db),
                             opportunityPropertyType).In(Db);
                deadCrmCase.CaseStatus = new StatusBuilder().Build().In(Db);
                deadCrmCase.CaseStatus.LiveFlag = 0m;

                CrmCases.Add(liveCrmCase);
                CrmCases.Add(deadCrmCase);

                f.AccessPermissions = new Dictionary<int, AccessPermissionLevel>
                {
                    {CrmCases.First(@case => @case.Irn == "1234/c").Id, AccessPermissionLevel.Select},
                    {CrmCases.First(@case => @case.Irn == "1234/b").Id, AccessPermissionLevel.Select},
                    {CrmCases.First(@case => @case.Irn == "1234/a").Id, AccessPermissionLevel.Select},
                    {CrmCases.First(@case => @case.Irn == "1234/x").Id, AccessPermissionLevel.Select},
                    {CrmCases.First(@case => @case.Irn == "1234/f").Id, AccessPermissionLevel.Select}
                };

                f.CaseAuthorization.GetInternalUserAccessPermissions(Arg.Any<IEnumerable<int>>(), Arg.Any<int?>())
                 .Returns(f.AccessPermissions);

                var r = await f.Subject.ListCases(CrmPropertyType.Opportunity.ToString());

                Assert.True(!r.Any(c => c.Irn.Equals("1234/f")));
            }

            [Fact]
            public async Task ThrowsExceptionWhenCrmPropertyTypeSiteControlIsNotSet()
            {
                SetUpCrmCases();
                var exception = await Assert.ThrowsAsync<HttpResponseException>(
                                                                                async () => { await new CrmControllerFixture(Db).Subject.ListCases(CrmPropertyType.Campaign.ToString()); });

                Assert.NotNull(exception);
                Assert.Equal(HttpStatusCode.BadRequest, exception.Response.StatusCode);
            }

            [Fact]
            public async Task ThrowsExceptionWhenInvalidCrmPropertyTypeIsPassed()
            {
                SetUpCrmCases();
                var exception = await Assert.ThrowsAsync<HttpResponseException>(
                                                                                async () => { await new CrmControllerFixture(Db).Subject.ListCases("InvalidPropertyType"); });

                Assert.NotNull(exception);
                Assert.Equal(HttpStatusCode.BadRequest, exception.Response.StatusCode);
            }

            [Fact]
            public async Task ThrowsExceptionWhenPropertyTypeIsNotPassedAsParameter()
            {
                var exception = await Assert.ThrowsAsync<HttpResponseException>(
                                                                                async () => { await new CrmControllerFixture(Db).Subject.ListCases(null); });

                Assert.NotNull(exception);
                Assert.Equal(HttpStatusCode.BadRequest, exception.Response.StatusCode);
            }
        }

        public class CrmUpdateResponseMethod : FactBase
        {
            [Fact]
            public async Task ReturnSuccessWhenResponseUpdatedWithNotNull()
            {
                var f = new CrmControllerFixture(Db);
                f.CrmUpdateMarketingContactData();

                var @case = Db.Set<Case>().First(c => c.Irn == "1234/a");
                var contactId = Db.Set<Name>().First(name => name.FirstName == "Test").Id;

                f.CaseAuthorization.Authorize(@case.Id, AccessPermissionLevel.Update).Returns(x =>
                {
                    var caseId = (int) x[0];
                    return new AuthorizationResult(caseId, true, false, null);
                });

                var r = await f.Subject.UpdateResponse(@case.Id, contactId, new MarketingResponse {ResponseId = -1});

                Assert.NotNull(r);
                var caseName =
                    Db.Set<CaseName>()
                      .First(cn => cn.CaseId.Equals(@case.Id) && cn.NameId == contactId);
                Assert.Equal(caseName.CorrespondenceReceived.Id, -1);
                Assert.NotNull(caseName.IsCorrespondenceSent);
                Assert.True(caseName.IsCorrespondenceSent != null && caseName.IsCorrespondenceSent.Value);
                Assert.Equal(HttpStatusCode.OK, r.StatusCode);
            }

            [Fact]
            public async Task ReturnSuccessWhenResponseUpdatedWithNull()
            {
                var f = new CrmControllerFixture(Db);
                f.CrmUpdateMarketingContactData();

                var @case = Db.Set<Case>().First(c => c.Irn == "1234/a");
                var contactId = Db.Set<Name>().First(name => name.FirstName == "Test").Id;

                f.CaseAuthorization.Authorize(@case.Id, AccessPermissionLevel.Update).Returns(x =>
                {
                    var caseId = (int) x[0];
                    return new AuthorizationResult(caseId, true, false, null);
                });

                var r = await f.Subject.UpdateResponse(@case.Id, contactId, new MarketingResponse {ResponseId = null});

                Assert.NotNull(r);
                var caseName =
                    Db.Set<CaseName>()
                      .First(cn => cn.CaseId.Equals(@case.Id) && cn.NameId == contactId);
                Assert.Null(caseName.CorrespondenceReceived);
                Assert.Null(caseName.IsCorrespondenceSent);
                Assert.Equal(HttpStatusCode.OK, r.StatusCode);
            }

            [Fact]
            public async Task ThrowsExceptionWhenCaseNotFound()
            {
                var f = new CrmControllerFixture(Db);
                f.CrmUpdateMarketingContactData();

                var contactId = Db.Set<Name>().First(name => name.FirstName == "Test").Id;
                var exception = await Assert.ThrowsAsync<HttpResponseException>(
                                                                                async () => await f.Subject.UpdateResponse(-1, contactId, new MarketingResponse {ResponseId = -1}));

                Assert.NotNull(exception);
                Assert.Equal(HttpStatusCode.NotFound, exception.Response.StatusCode);
            }

            [Fact]
            public async Task ThrowsExceptionWhenNameNotFound()
            {
                var f = new CrmControllerFixture(Db);
                f.CrmUpdateMarketingContactData();

                var @case = Db.Set<Case>().First(c => c.Irn == "1234/a");

                f.CaseAuthorization.Authorize(@case.Id, AccessPermissionLevel.Update).Returns(x =>
                {
                    var caseId = (int) x[0];
                    return new AuthorizationResult(caseId, true, false, null);
                });

                var exception =
                    await Assert.ThrowsAsync<HttpResponseException>(async () => await
                                                                        f.Subject.UpdateResponse(@case.Id, -1, new MarketingResponse {ResponseId = -1}));

                Assert.NotNull(exception);
                Assert.Equal(HttpStatusCode.NotFound, exception.Response.StatusCode);
            }

            [Fact]
            public async Task ThrowsExceptionWhenResponseCodeNotFound()
            {
                var f = new CrmControllerFixture(Db);
                f.CrmUpdateMarketingContactData();

                var @case = Db.Set<Case>().First(c => c.Irn == "1234/a");
                var contactId = Db.Set<Name>().First(name => name.FirstName == "Test").Id;

                f.CaseAuthorization.Authorize(@case.Id, AccessPermissionLevel.Update).Returns(x =>
                {
                    var caseId = (int) x[0];
                    return new AuthorizationResult(caseId, true, false, null);
                });

                var exception =
                    await Assert.ThrowsAsync<HttpResponseException>(async () =>
                                                                        await f.Subject.UpdateResponse(@case.Id, contactId, new MarketingResponse {ResponseId = 1}));

                Assert.NotNull(exception);
                Assert.Equal(HttpStatusCode.NotFound, exception.Response.StatusCode);
            }

            [Fact]
            public async Task ThrowsUnauthorizedExceptionWhenNoUpdatePermission()
            {
                var f = new CrmControllerFixture(Db);
                f.CrmUpdateMarketingContactData();

                var @case = Db.Set<Case>().First(c => c.Irn == "1234/a");
                var contactId = Db.Set<Name>().First(name => name.FirstName == "Test").Id;

                f.CaseAuthorization.Authorize(@case.Id, AccessPermissionLevel.Update).Returns(x =>
                {
                    var caseId = (int) x[0];
                    return new AuthorizationResult(caseId, true, true, "NoRowaccessForCase");
                });

                var exception =
                    await Assert.ThrowsAsync<DataSecurityException>(async () =>
                                                                        await f.Subject.UpdateResponse(@case.Id, contactId, new MarketingResponse {ResponseId = -1}));

                Assert.NotNull(exception);
                Assert.Equal(ErrorTypeCode.NoRowaccessForCase.ToString().CamelCaseToUnderscore(), exception.Message);
            }
        }

        public class CrmUpdateCorrespondenceMethod : FactBase
        {
            [Fact]
            public async Task ReturnSuccessWhenCorrespondenceSentUpdated()
            {
                var f = new CrmControllerFixture(Db);
                f.CrmUpdateMarketingContactData();

                var @case = Db.Set<Case>().First(c => c.Irn == "1234/a");
                var contactId = Db.Set<Name>().First(name => name.FirstName == "Test").Id;

                f.CaseAuthorization.Authorize(@case.Id, AccessPermissionLevel.Update).Returns(x =>
                {
                    var caseId = (int) x[0];
                    return new AuthorizationResult(caseId, true, false, null);
                });

                var r = await f.Subject.UpdateCorrespondence(@case.Id, contactId,
                                                             new CrmCorrespondence {CorrespondenceSent = true});

                Assert.NotNull(r);
                var caseName =
                    Db.Set<CaseName>()
                      .First(cn => cn.CaseId.Equals(@case.Id) && cn.NameId == contactId);

                Assert.NotNull(caseName.IsCorrespondenceSent);
                Assert.True(caseName.IsCorrespondenceSent != null && caseName.IsCorrespondenceSent.Value);
                Assert.Equal(HttpStatusCode.OK, r.StatusCode);
            }
        }

        public class CrmContactsMethod : FactBase
        {
            dynamic Setup()
            {
                var opportunityPropertyType = new PropertyTypeBuilder {Id = "A"}.Build().In(Db);
                opportunityPropertyType.SetCrmOnly(true);

                var crmCase =
                    new CaseBuilder {PropertyType = opportunityPropertyType, Irn = Fixture.String()}.Build().In(Db);
                var crmCaseNoAccess = new CaseBuilder {Irn = Fixture.String()}.Build().In(Db);
                var contactNameType = new NameTypeBuilder {PickListFlags = 48, NameTypeCode = KnownNameTypes.Contact}.Build().In(Db);
                var sigNameType = new NameType(Fixture.Integer(), KnownNameTypes.Signatory, "Signatory") {PickListFlags = 48}.In(Db);

                var name1 = new NameBuilder(Db) {FirstName = "ABC", LastName = Fixture.String()}.Build().In(Db);
                var ntc1 = new NameTypeClassificationBuilder(Db) {IsAllowed = 1, Name = name1, NameType = contactNameType}.Build().In(Db);
                name1.NameTypeClassifications.Add(ntc1);
                var crmName1 =
                    new CaseNameBuilder(Db) {Name = name1, NameType = contactNameType}.BuildWithCase(crmCase, 0).In(Db);

                var orgName = new AssociatedNameBuilder(Db)
                {
                    Name = new NameBuilder(Db) {LastName = "OrgName"}.Build().In(Db),
                    RelatedName = name1,
                    Relationship = KnownRelations.Employs
                }.Build().In(Db);

                var name2 = new NameBuilder(Db) {FirstName = "XYZ", LastName = Fixture.String()}.Build().In(Db);
                var ntc2 = new NameTypeClassificationBuilder(Db) {IsAllowed = 1, Name = name2, NameType = contactNameType}.Build().In(Db);
                name2.NameTypeClassifications.Add(ntc2);
                new CaseNameBuilder(Db) {Name = name2, NameType = contactNameType}.BuildWithCase(crmCase, 1).In(Db);

                var name3 = new NameBuilder(Db) {FirstName = Fixture.String(), LastName = Fixture.String()}.Build().In(Db);
                var ntc3 = new NameTypeClassificationBuilder(Db) {IsAllowed = 1, Name = name3, NameType = sigNameType}.Build().In(Db);
                name3.NameTypeClassifications.Add(ntc3);
                new CaseNameBuilder(Db) {Name = name3, NameType = sigNameType}.BuildWithCase(crmCase, 2).In(Db);

                var tableTypeIndustry = new TableTypeBuilder(Db).For(TableTypes.Industry).BuildWithTableCodes().In(Db);
                var selectionTypeIndustry =
                    new SelectionTypes(tableTypeIndustry)
                    {
                        ParentTable = KnownParentTable.Individual,
                        MinimumAllowed = 1,
                        MaximumAllowed = 1,
                        ModifiableByService = true
                    }.In(Db);

                var tableTypeForeignAgents =
                    new TableTypeBuilder(Db).For(TableTypes.ForeignAgents).BuildWithTableCodes().In(Db);
                var selectionTypeForeignAgents =
                    new SelectionTypes(tableTypeForeignAgents)
                    {
                        ParentTable = KnownParentTable.Individual,
                        TableTypeId = tableTypeForeignAgents.Id,
                        MinimumAllowed = 0,
                        MaximumAllowed = 2,
                        ModifiableByService = false
                    }.In(Db);

                var selectedAttributes = new List<SelectedAttribute>
                {
                    new SelectedAttribute
                    {
                        AttributeTypeId = tableTypeIndustry.Id,
                        AttributeId = tableTypeIndustry.TableCodes.First().Id
                    },
                    new SelectedAttribute
                    {
                        AttributeTypeId = tableTypeForeignAgents.Id,
                        AttributeId = tableTypeForeignAgents.TableCodes.First().Id
                    }
                };

                return new
                {
                    crmCase,
                    crmCaseNoAccess,
                    name1,
                    name2,
                    orgName,
                    crmName1,
                    selectionTypeIndustry,
                    tableTypeIndustry,
                    selectionTypeForeignAgents,
                    tableTypeForeignAgents,
                    selectedAttributes
                };
            }

            [Fact]
            public async Task ReturnContactsIfCaseHasAccessPermissions()
            {
                var data = Setup();
                var f = new CrmControllerFixture(Db)
                {
                    AccessPermissions = new Dictionary<int, AccessPermissionLevel>
                    {
                        {data.crmCase.Id, AccessPermissionLevel.Select}
                    }
                };
                f.CaseAuthorization.GetInternalUserAccessPermissions(Arg.Any<IEnumerable<int>>(), Arg.Any<int?>())
                 .Returns(f.AccessPermissions);

                var result = await f.Subject.ListContacts(data.crmCase.Id);
                Assert.NotNull(result);
                Assert.Equal(2, result.Count);
            }

            [Fact]
            public async Task ReturnContactsInNameAscendingOrder()
            {
                var data = Setup();
                var f = new CrmControllerFixture(Db)
                {
                    AccessPermissions = new Dictionary<int, AccessPermissionLevel>
                    {
                        {data.crmCase.Id, AccessPermissionLevel.Select}
                    }
                };
                f.CaseAuthorization.GetInternalUserAccessPermissions(Arg.Any<IEnumerable<int>>(), Arg.Any<int?>())
                 .Returns(f.AccessPermissions);

                var result = ((IEnumerable<CrmContact>) await f.Subject.ListContacts(data.crmCase.Id)).ToList();
                Assert.Equal(data.name1.FirstName + " " + data.name1.LastName, result.First().Name);
            }

            [Fact]
            public async Task ReturnsRequiredContactsData()
            {
                var data = Setup();
                var f = new CrmControllerFixture(Db)
                {
                    AccessPermissions = new Dictionary<int, AccessPermissionLevel>
                    {
                        {data.crmCase.Id, AccessPermissionLevel.Select}
                    }
                };
                f.CaseAuthorization.GetInternalUserAccessPermissions(Arg.Any<IEnumerable<int>>(), Arg.Any<int?>())
                 .Returns(f.AccessPermissions);

                var result = ((IEnumerable<CrmContact>) await f.Subject.ListContacts(data.crmCase.Id)).ToList();
                var firstContact = result.First();
                Assert.Equal(data.name1.Id, firstContact.NameId);
                Assert.Equal((data.orgName.Name as Name).Formatted(), firstContact.OrganisationName);
                Assert.Equal(data.orgName.PositionCategory.Name, firstContact.Department);
                Assert.Equal(data.crmName1.CorrespondenceReceived.Id.ToString(), firstContact.ResponseCode);
                Assert.False(firstContact.CorrespondenceSent);
                Assert.Equal((data.name1 as Name).MainEmail().Formatted(), firstContact.EmailAddress);
                Assert.Equal((data.name1 as Name).MainPhone().Formatted(), firstContact.PhoneNumber);
                Assert.Null(firstContact.NameAttributes);
            }

            [Fact]
            public async Task ReturnsRequiredContactsDataWithModifiableAttributes()
            {
                var data = Setup();

                var f = new CrmControllerFixture(Db);

                f.AccessPermissions = new Dictionary<int, AccessPermissionLevel>
                {
                    {data.crmCase.Id, AccessPermissionLevel.Select}
                };

                f.NameAccessSecurity.CanView(Arg.Any<Name>()).ReturnsForAnyArgs(true);

                f.CaseAuthorization.GetInternalUserAccessPermissions(Arg.Any<IEnumerable<int>>(), Arg.Any<int?>())
                 .Returns(f.AccessPermissions);

                f.CrmValidator.IsCrmName(Arg.Any<Name>()).Returns(true);

                f.NameAttributeLoader.ListNameAttributeData(Arg.Any<Name>()).ReturnsForAnyArgs((List<SelectedAttribute>) data.selectedAttributes);

                f.NameAttributeLoader.ListAttributeTypes(Arg.Any<Name>()).Returns(
                                                                                  new List<SelectionTypes> {data.selectionTypeForeignAgents, data.selectionTypeIndustry});

                var result = ((IEnumerable<CrmContact>) await f.Subject.ListContacts(data.crmCase.Id, true)).ToList();
                var firstContact = result.First();
                Assert.Equal(data.name1.Id, firstContact.NameId);
                Assert.Equal((data.orgName.Name as Name).Formatted(), firstContact.OrganisationName);
                Assert.Equal(data.orgName.PositionCategory.Name, firstContact.Department);
                Assert.Equal(data.crmName1.CorrespondenceReceived.Id.ToString(), firstContact.ResponseCode);
                Assert.False(firstContact.CorrespondenceSent);
                Assert.Equal((data.name1 as Name).MainEmail().Formatted(), firstContact.EmailAddress);
                Assert.Equal((data.name1 as Name).MainPhone().Formatted(), firstContact.PhoneNumber);
                Assert.NotNull(firstContact.NameAttributes);
                Assert.DoesNotContain(firstContact.NameAttributes.SelectedNameAttributes, sna => sna.AttributeTypeId == data.tableTypeForeignAgents.Id);
                Assert.DoesNotContain(firstContact.NameAttributes.AvailableNameAttributes, ana => ana.AttributeTypeId == data.tableTypeForeignAgents.Id);
            }

            [Fact]
            public async Task ThrowsExceptionIfProvidedCaseDoesNotExists()
            {
                var data = Setup();
                var f = new CrmControllerFixture(Db)
                {
                    AccessPermissions = new Dictionary<int, AccessPermissionLevel>
                    {
                        {data.crmCase.Id, AccessPermissionLevel.Select}
                    }
                };

                f.CaseAuthorization.GetInternalUserAccessPermissions(Arg.Any<IEnumerable<int>>(), Arg.Any<int?>())
                 .Returns(f.AccessPermissions);

                var exception = await Assert.ThrowsAsync<HttpResponseException>(
                                                                                async () => await f.Subject.ListContacts(Fixture.Integer()));

                Assert.NotNull(exception);
                Assert.Equal(HttpStatusCode.NotFound, exception.Response.StatusCode);
            }

            [Fact]
            public async Task ThrowsExceptionIfProvidedCaseDoesNotHaveAccessPermissions()
            {
                var data = Setup();
                var f = new CrmControllerFixture(Db)
                {
                    AccessPermissions = new Dictionary<int, AccessPermissionLevel>
                    {
                        {data.crmCase.Id, AccessPermissionLevel.Select}
                    }
                };

                f.CaseAuthorization.GetInternalUserAccessPermissions(Arg.Any<IEnumerable<int>>(), Arg.Any<int?>())
                 .Returns(f.AccessPermissions);

                var r = await f.Subject.ListContacts(data.crmCaseNoAccess.Id);

                Assert.Empty(r);
            }
        }

        public class CrmRemoveContact : FactBase
        {
            [Fact]
            public async Task ReturnsOkWhenCrmCaseNameIsSucessFullyRemoved()
            {
                var f = new CrmControllerFixture(Db);
                f.CrmUpdateMarketingContactData();

                var @case = Db.Set<Case>().First(c => c.Irn == "1234/a");
                var contactId = Db.Set<Name>().First(name => name.FirstName == "Test").Id;

                f.CaseAuthorization.Authorize(@case.Id, AccessPermissionLevel.Update).Returns(x =>
                {
                    var caseId = (int) x[0];
                    return new AuthorizationResult(caseId, true, false, null);
                });

                var response = await f.Subject.RemoveContact(@case.Id, contactId);

                Assert.Equal(HttpStatusCode.OK, response.StatusCode);
            }

            [Fact]
            public async Task ThrowExceptionWhenPassedNameIsInvalidContact()
            {
                var f = new CrmControllerFixture(Db);
                f.CrmUpdateMarketingContactData();

                var @case = Db.Set<Case>().First(c => c.Irn == "1234/a");
                var nameId = Db.Set<Name>().First(name => name.FirstName == "Test2").Id;

                f.CaseAuthorization.Authorize(@case.Id, AccessPermissionLevel.Update).Returns(x =>
                {
                    var caseId = (int) x[0];
                    return new AuthorizationResult(caseId, true, false, null);
                });

                var exception = await Assert.ThrowsAsync<HttpResponseException>(async () => await f.Subject.RemoveContact(@case.Id, nameId));

                Assert.IsType<HttpResponseException>(exception);
                Assert.Equal(HttpStatusCode.NotFound, exception.Response.StatusCode);
            }
        }

        public class CrmAddContact : FactBase
        {
            void PreparedTestdata()
            {
                var classification = new[] {KnownNameTypes.Contact};
                var name = new NameBuilder(Db) {FirstName = "test"}.BuildWithClassifications(classification).In(Db);
                var @case = new CaseBuilder {Irn = "1234/a"}.Build().In(Db);
                var contactNameType = new NameTypeBuilder {NameTypeCode = KnownNameTypes.Contact}.Build().In(Db);

                new CaseNameBuilder(Db) {Name = name, NameType = contactNameType}.BuildWithCase(@case, 0).In(Db);
                new NameBuilder(Db) {FirstName = "test2"}.Build().In(Db);
            }

            [Fact]
            public async Task ReturnsOkAndSetIsAllowInNameTypeSpecificationWhenContactSuccessfullyAdded()
            {
                var f = new CrmControllerFixture(Db);
                PreparedTestdata();
                var name = Db.Set<Name>().First(c => c.FirstName == "test2");
                var @case = Db.Set<Case>().First(c => c.Irn == "1234/a");
                var nameType = Db.Set<NameType>().First(c => c.NameTypeCode == KnownNameTypes.Contact);
                new NameTypeClassification(name, nameType) {IsAllowed = 0}.In(Db);

                f.CaseAuthorization.Authorize(@case.Id, AccessPermissionLevel.Update).Returns(x =>
                {
                    var caseId = (int) x[0];
                    return new AuthorizationResult(caseId, true, false, null);
                });

                var response = await f.Subject.AddContact(@case.Id, name.Id);
                var nameTypeSpecification = Db.Set<NameTypeClassification>()
                                              .SingleOrDefault(x => x.NameId == name.Id && x.NameTypeId == KnownNameTypes.Contact);
                Assert.NotNull(nameTypeSpecification);
                Assert.True(nameTypeSpecification.IsAllowed != null && nameTypeSpecification.IsAllowed.Value == 1);
                Assert.Equal(HttpStatusCode.OK, response.StatusCode);
            }

            [Fact]
            public async Task ReturnsOkWhenContactAndNameTypeSpecificationSuccessfullyAdded()
            {
                var f = new CrmControllerFixture(Db);
                PreparedTestdata();
                var @case = Db.Set<Case>().First(c => c.Irn == "1234/a");
                var name = Db.Set<Name>().First(c => c.FirstName == "test2");

                f.CaseAuthorization.Authorize(@case.Id, AccessPermissionLevel.Update).Returns(x =>
                {
                    var caseId = (int) x[0];
                    return new AuthorizationResult(caseId, true, false, null);
                });

                var response = await f.Subject.AddContact(@case.Id, name.Id);

                var nameTypeSpecification = Db.Set<NameTypeClassification>()
                                              .SingleOrDefault(x => x.NameId == name.Id && x.NameTypeId == KnownNameTypes.Contact);
                Assert.NotNull(nameTypeSpecification);
                Assert.Equal(1, nameTypeSpecification.IsAllowed);
                Assert.Equal(HttpStatusCode.OK, response.StatusCode);
            }

            [Fact]
            public async Task ThrowsExceptionWhenCaseDoesNotHaveAccessSecurity()
            {
                var f = new CrmControllerFixture(Db);
                PreparedTestdata();
                var @case = Db.Set<Case>().First(c => c.Irn == "1234/a");
                var name = Db.Set<Name>().First(c => c.FirstName == "test");

                f.CaseAuthorization.Authorize(@case.Id, AccessPermissionLevel.Update).Returns(x =>
                {
                    var caseId = (int) x[0];
                    return new AuthorizationResult(caseId, true, true, "NoRowaccessForCase");
                });

                var exception = await Assert.ThrowsAsync<DataSecurityException>(async () => await f.Subject.AddContact(@case.Id, name.Id));

                Assert.IsType<DataSecurityException>(exception);
                Assert.Equal(ErrorTypeCode.NoRowaccessForCase.ToString().CamelCaseToUnderscore(), exception.Message);
            }

            [Fact]
            public async Task ThrowsExceptionWhenContactAlreadyAssociatedWithCase()
            {
                var f = new CrmControllerFixture(Db);
                PreparedTestdata();
                var @case = Db.Set<Case>().First(c => c.Irn == "1234/a");
                var name = Db.Set<Name>().First(c => c.FirstName == "test");

                f.CaseAuthorization.Authorize(@case.Id, AccessPermissionLevel.Update).Returns(x =>
                {
                    var caseId = (int) x[0];
                    return new AuthorizationResult(caseId, true, false, null);
                });

                var exception = await Assert.ThrowsAsync<HttpResponseException>(async () => await f.Subject.AddContact(@case.Id, name.Id));

                Assert.IsType<HttpResponseException>(exception);
                Assert.Equal(HttpStatusCode.Found, exception.Response.StatusCode);
            }

            [Fact]
            public async Task ThrowsExceptionWhenProvidedCaseDoesnotExists()
            {
                var f = new CrmControllerFixture(Db);
                PreparedTestdata();
                var @case = new CaseBuilder().Build();
                var name = Db.Set<Name>().First(c => c.FirstName == "test");
                var exception = await Assert.ThrowsAsync<HttpResponseException>(async () => await f.Subject.AddContact(@case.Id, name.Id));

                Assert.IsType<HttpResponseException>(exception);
                Assert.Equal(HttpStatusCode.NotFound, exception.Response.StatusCode);
            }

            [Fact]
            public async Task ThrowsExceptionWhenProvidedNameDoesnotExists()
            {
                var f = new CrmControllerFixture(Db);
                PreparedTestdata();
                var @case = Db.Set<Case>().First(c => c.Irn == "1234/a");
                var name = new NameBuilder(Db).Build();
                var exception = await Assert.ThrowsAsync<HttpResponseException>(async () => await f.Subject.AddContact(@case.Id, name.Id));

                Assert.IsType<HttpResponseException>(exception);
                Assert.Equal(HttpStatusCode.NotFound, exception.Response.StatusCode);
            }
        }

        public class CrmAttributesMethod : FactBase
        {
            Name _crmName;
            TableType _tableTypeIndustry;
            TableType _tableTypeForeignAgents;
            TableType _tableTypeOffice;
            SelectionTypes _selectionTypeIndustry;
            SelectionTypes _selectionTypeForeignAgents;
            SelectionTypes _selectionTypeOffice;
            List<SelectedAttribute> _selectedAttributes;

            void SetUp()
            {
                _crmName = new NameBuilder(Db) {LastName = Fixture.String()}.Build().In(Db);

                _tableTypeIndustry = new TableTypeBuilder(Db).For(TableTypes.Industry).BuildWithTableCodes().In(Db);
                _selectionTypeIndustry =
                    new SelectionTypes(_tableTypeIndustry)
                    {
                        ParentTable = KnownParentTable.Individual,
                        MinimumAllowed = 1,
                        MaximumAllowed = 1,
                        ModifiableByService = true
                    }.In(Db);

                _tableTypeForeignAgents = new TableTypeBuilder(Db).For(TableTypes.ForeignAgents).BuildWithTableCodes().In(Db);
                _selectionTypeForeignAgents =
                    new SelectionTypes(_tableTypeForeignAgents)
                    {
                        ParentTable = KnownParentTable.Individual,
                        TableTypeId = _tableTypeForeignAgents.Id,
                        MinimumAllowed = 0,
                        MaximumAllowed = 2,
                        ModifiableByService = false
                    }.In(Db);

                _tableTypeOffice = new TableTypeBuilder(Db) {DatabaseTable = "OFFICE"}.For(TableTypes.Office).Build().In(Db);
                _selectionTypeOffice =
                    new SelectionTypes(_tableTypeOffice)
                    {
                        ParentTable = KnownParentTable.Individual,
                        MinimumAllowed = 0,
                        MaximumAllowed = 3,
                        ModifiableByService = true
                    }.In(Db);

                new OfficeBuilder {Name = "City Office"}.Build().In(Db);
                new OfficeBuilder {Name = "Urban Office"}.Build().In(Db);

                _selectedAttributes = new List<SelectedAttribute>
                {
                    new SelectedAttribute
                    {
                        AttributeTypeId = _tableTypeIndustry.Id,
                        AttributeId = _tableTypeIndustry.TableCodes.First().Id
                    },
                    new SelectedAttribute
                    {
                        AttributeTypeId = _tableTypeForeignAgents.Id,
                        AttributeId = _tableTypeForeignAgents.TableCodes.First().Id
                    }
                };
            }

            [Fact]
            public void ReturnsEmptyNameAttributesWhenUserDoesnotHaveViewPermissionForName()
            {
                SetUp();

                var f = new CrmControllerFixture(Db);

                f.NameAccessSecurity.CanView(_crmName).Returns(false);

                var r = f.Subject.ListAttributes(_crmName.Id);

                Assert.Null(r.AvailableNameAttributes);
                Assert.Null(r.SelectedNameAttributes);
            }

            [Fact]
            public void ReturnsModifiableAvailableAndSelectedAttributesForName()
            {
                SetUp();

                var f = new CrmControllerFixture(Db);

                f.NameAccessSecurity.CanView(_crmName).Returns(true);
                f.CrmValidator.IsCrmName(Arg.Any<Name>()).Returns(true);

                f.NameAttributeLoader.ListNameAttributeData(_crmName)
                 .Returns(_selectedAttributes);

                f.NameAttributeLoader.ListAttributeTypes(_crmName)
                 .Returns(new List<SelectionTypes> {_selectionTypeForeignAgents, _selectionTypeIndustry});

                var r = f.Subject.ListAttributes(_crmName.Id);

                Assert.DoesNotContain(r.SelectedNameAttributes, sna => sna.AttributeTypeId == _tableTypeForeignAgents.Id);
                Assert.DoesNotContain(r.AvailableNameAttributes, ana => ana.AttributeTypeId == _tableTypeForeignAgents.Id);
            }

            [Fact]
            public void ReturnsModifiableAvailableAttributesForOfficeTableType()
            {
                SetUp();

                var f = new CrmControllerFixture(Db);

                f.NameAccessSecurity.CanView(_crmName).Returns(true);
                f.CrmValidator.IsCrmName(Arg.Any<Name>()).Returns(true);

                f.NameAttributeLoader.ListNameAttributeData(_crmName)
                 .Returns(_selectedAttributes);

                f.NameAttributeLoader.ListAttributeTypes(_crmName)
                 .Returns(new List<SelectionTypes> {_selectionTypeForeignAgents, _selectionTypeIndustry, _selectionTypeOffice});

                var r = f.Subject.ListAttributes(_crmName.Id);

                Assert.Contains(r.AvailableNameAttributes, ana => ana.Attributes.Any()
                                                                  && ana.Attributes.Any(attr => attr.AttributeDescription.Equals("City Office")));
            }

            [Fact]
            public void ThrowsExceptionWhenContactPassedDoesnotExistInDatabase()
            {
                SetUp();

                var f = new CrmControllerFixture(Db);

                var exception = Record.Exception(() => { f.Subject.ListAttributes(-1); });

                Assert.IsType<HttpResponseException>(exception);
                Assert.Equal(HttpStatusCode.NotFound, ((HttpResponseException) exception).Response.StatusCode);
            }
        }

        public class CrmUpdateNameAttributesMethod : FactBase
        {
            public CrmUpdateNameAttributesMethod()
            {
                _crmName = new NameBuilder(Db) {LastName = Fixture.String()}.Build().In(Db);
                _nonCrmName = new NameBuilder(Db) {LastName = Fixture.String()}.Build().In(Db);

                var tableTypeIndustry = new TableTypeBuilder(Db).For(TableTypes.Industry).BuildWithTableCodes().In(Db);
                var selectionTypeIndustry = new SelectionTypes(tableTypeIndustry)
                {
                    ParentTable = KnownParentTable.Individual,
                    MinimumAllowed = 1,
                    MaximumAllowed = 1,
                    ModifiableByService = true
                }.In(Db);

                _tableTypeForeignAgents =
                    new TableTypeBuilder(Db).For(TableTypes.ForeignAgents).BuildWithTableCodes().In(Db);
                var selectionTypeForeignAgents = new SelectionTypes(_tableTypeForeignAgents)
                {
                    ParentTable = KnownParentTable.Individual,
                    TableTypeId = _tableTypeForeignAgents.Id,
                    MinimumAllowed = 0,
                    MaximumAllowed = 2,
                    ModifiableByService = true
                }.In(Db);

                _fixture = new CrmControllerFixture(Db);

                _fixture.NameAttributeLoader.ListAttributeTypesModifiableByExternalSystem(_crmName)
                        .Returns(new List<SelectionTypes>
                        {
                            selectionTypeIndustry,
                            selectionTypeForeignAgents
                        });

                _fixture.NameAttributeLoader.ListNameAttributeData(_crmName)
                        .Returns(new List<SelectedAttribute>());
            }

            readonly Name _crmName;
            readonly Name _nonCrmName;
            readonly TableType _tableTypeForeignAgents;
            readonly CrmControllerFixture _fixture;

            void SetupSecurityForAttribute()
            {
                _fixture.NameAccessSecurity.CanUpdate(_crmName).Returns(true);
                _fixture.CrmValidator.IsCrmName(Arg.Any<Name>()).Returns(true);
                _fixture.CrmValidator.ValidateAttribute(Arg.Any<SelectedAttribute>()).Returns(true);
            }

            [Fact]
            public void AddNameAttribuesIfNotPresentInSelectedNameAttributes()
            {
                SetupSecurityForAttribute();

                var r = _fixture.Subject.UpdateNameAttributes(_crmName.Id, new CrmAttributes
                {
                    NameAttributes = new List<SelectedAttribute>
                    {
                        new SelectedAttribute
                        {
                            AttributeTypeId = _tableTypeForeignAgents.Id,
                            AttributeId = _tableTypeForeignAgents.TableCodes.First().Id
                        }
                    }
                });

                Assert.NotNull(r);
                Assert.True(Db.Set<TableAttributes>()
                              .Any(ta => ta.GenericKey == _crmName.Id.ToString(CultureInfo.InvariantCulture)
                                         && ta.SourceTableId == _tableTypeForeignAgents.Id
                                         && ta.TableCodeId == _tableTypeForeignAgents.TableCodes.First().Id));
                Assert.Equal(HttpStatusCode.OK, r.StatusCode);
            }

            [Fact]
            public void DeleteNameAttribuesIfNotPresentInSelectedNameAttributes()
            {
                SetupSecurityForAttribute();

                _fixture.NameAttributeLoader.ListNameAttributeData(_crmName)
                        .Returns(new List<SelectedAttribute>
                        {
                            new SelectedAttribute
                            {
                                AttributeTypeId = _tableTypeForeignAgents.Id,
                                AttributeId = _tableTypeForeignAgents.TableCodes.First().Id
                            }
                        });

                TableAttributesBuilder
                    .ForName(_crmName)
                    .WithAttribute(TableTypes.ForeignAgents, _tableTypeForeignAgents.TableCodes.First().Id)
                    .Build().In(Db);

                var r = _fixture.Subject.UpdateNameAttributes(_crmName.Id, new CrmAttributes
                {
                    NameAttributes = new List<SelectedAttribute>()
                });

                Assert.NotNull(r);
                Assert.False(Db.Set<TableAttributes>()
                               .Any(ta => ta.GenericKey == _crmName.Id.ToString(CultureInfo.InvariantCulture)
                                          && ta.SourceTableId == _tableTypeForeignAgents.Id
                                          && ta.TableCodeId == _tableTypeForeignAgents.TableCodes.First().Id));
                Assert.Equal(HttpStatusCode.OK, r.StatusCode);
            }

            [Fact]
            public void ReturnsSuccessMessageWithDescriptionIfNotAllAttributesAreAdded()
            {
                SetupSecurityForAttribute();

                var r = _fixture.Subject.UpdateNameAttributes(_crmName.Id, new CrmAttributes
                {
                    NameAttributes = new List<SelectedAttribute>
                    {
                        new SelectedAttribute
                        {
                            AttributeTypeId = _tableTypeForeignAgents.Id,
                            AttributeId = _tableTypeForeignAgents.TableCodes.First().Id
                        },
                        new SelectedAttribute
                        {
                            AttributeTypeId = 1,
                            AttributeId = 1
                        }
                    }
                });

                Assert.NotNull(r);
                Assert.Equal(HttpStatusCode.OK, r.StatusCode);
                Assert.Equal("Some attributes could not be updated.", ((ObjectContent) r.Content).Value);
            }

            [Fact]
            public void ThrowsExceptionWhenGivenAttributeIsNotFound()
            {
                var exception =
                    Record.Exception(() =>
                    {
                        _fixture.NameAccessSecurity.CanUpdate(_crmName).Returns(true);
                        _fixture.CrmValidator.ValidateAttribute(Arg.Any<SelectedAttribute>()).Returns(false);
                        _fixture.CrmValidator.IsCrmName(Arg.Any<Name>()).Returns(true);

                        _fixture.Subject.UpdateNameAttributes(_crmName.Id, new CrmAttributes
                        {
                            NameAttributes = new List<SelectedAttribute>
                            {
                                new SelectedAttribute
                                {
                                    AttributeTypeId = _tableTypeForeignAgents.Id,
                                    AttributeId = Fixture.Integer()
                                }
                            }
                        });
                    });

                Assert.NotNull(exception);
                Assert.IsType<HttpResponseException>(exception);
                Assert.Equal(HttpStatusCode.NotFound, ((HttpResponseException) exception).Response.StatusCode);
            }

            [Fact]
            public void ThrowsExceptionWhenGivenNameIsNotACrmName()
            {
                var exception =
                    Record.Exception(() =>
                    {
                        _fixture.Subject.UpdateNameAttributes(_nonCrmName.Id, new CrmAttributes
                        {
                            NameAttributes = new List<SelectedAttribute>()
                        });
                    });

                Assert.NotNull(exception);
                Assert.IsType<DataSecurityException>(exception);
                Assert.Equal(ErrorTypeCode.NoRowaccessForName.ToString().CamelCaseToUnderscore(), exception.Message);
            }

            [Fact]
            public void ThrowsExceptionWhenNameAttributesNotFound()
            {
                var exception =
                    Record.Exception(() => { _fixture.Subject.UpdateNameAttributes(_crmName.Id, new CrmAttributes()); });

                Assert.NotNull(exception);
                Assert.IsType<HttpResponseException>(exception);
                Assert.Equal(HttpStatusCode.NotFound, ((HttpResponseException) exception).Response.StatusCode);
            }

            [Fact]
            public void ThrowsExceptionWhenNameNotFound()
            {
                var exception =
                    Record.Exception(() =>
                    {
                        _fixture.Subject.UpdateNameAttributes(-1, new CrmAttributes
                        {
                            NameAttributes = new List<SelectedAttribute>()
                        });
                    });

                Assert.NotNull(exception);
                Assert.IsType<HttpResponseException>(exception);
                Assert.Equal(HttpStatusCode.NotFound, ((HttpResponseException) exception).Response.StatusCode);
            }

            [Fact]
            public void ThrowsUnauthorizedExceptionWhenNoUpdatePermissionForName()
            {
                var exception =
                    Record.Exception(() =>
                    {
                        _fixture.NameAccessSecurity.CanUpdate(_crmName).Returns(false);
                        _fixture.Subject.UpdateNameAttributes(_crmName.Id, new CrmAttributes
                        {
                            NameAttributes = new List<SelectedAttribute>()
                        });
                    });

                Assert.NotNull(exception);
                Assert.IsType<DataSecurityException>(exception);
                Assert.Equal(ErrorTypeCode.NoRowaccessForName.ToString().CamelCaseToUnderscore(), exception.Message);
            }
        }

        public class CrmCreateContact : FactBase
        {
            const string ContactName = "Test";

            [Fact]
            public async Task AddCaseNameEvenIfDuplicateNameExists()
            {
                var f = new CrmControllerFixture(Db);

                var @case = new CaseBuilder {Irn = "1234/a"}.Build().In(Db);
                var name = new NameBuilder(Db) {FirstName = ContactName, LastName = ContactName}.Build().In(Db);
                var contactNameType = new NameTypeBuilder {NameTypeCode = KnownNameTypes.Contact}.Build().In(Db);
                new CaseNameBuilder(Db) {Name = name, NameType = contactNameType}.BuildWithCase(@case, 0).In(Db);

                f.CaseAuthorization.Authorize(@case.Id, AccessPermissionLevel.Update).Returns(x =>
                {
                    var caseId = (int) x[0];
                    return new AuthorizationResult(caseId, true, false, null);
                });
                f.NameAccessSecurity.CanInsert().Returns(true);

                var duplicateList = new List<DuplicateName> {new DuplicateName {GivenName = ContactName}};
                f.NameValidator.CheckDuplicates(Arg.Any<bool>(), Arg.Any<bool>(), Arg.Any<bool>(), Arg.Any<string>(),
                                                Arg.Any<string>())
                 .Returns(duplicateList);

                f.CreateContactName.CreateContactName(Arg.Any<Contact>()).Returns(name);

                var result = await f.Subject.CreateNewContact(@case.Id, new Contact {Surname = ContactName, GivenName = ContactName},
                                                              true);

                var caseName =
                    Db.Set<CaseName>()
                      .First(cn => cn.CaseId.Equals(@case.Id) && cn.NameId == name.Id && cn.NameTypeId == KnownNameTypes.Contact);

                Assert.NotNull(caseName);
                Assert.Equal(HttpStatusCode.OK, result.StatusCode);
            }

            [Fact]
            public async Task AddCaseNameIfNoDuplicateNameExists()
            {
                var f = new CrmControllerFixture(Db);

                var @case = new CaseBuilder {Irn = "1234/a"}.Build().In(Db);
                var name = new NameBuilder(Db) {FirstName = ContactName, LastName = ContactName}.Build().In(Db);
                var contactNameType = new NameTypeBuilder {NameTypeCode = KnownNameTypes.Contact}.Build().In(Db);
                new CaseNameBuilder(Db) {Name = name, NameType = contactNameType}.BuildWithCase(@case, 0).In(Db);

                f.CaseAuthorization.Authorize(@case.Id, AccessPermissionLevel.Update).Returns(x =>
                {
                    var caseId = (int) x[0];
                    return new AuthorizationResult(caseId, true, false, null);
                });
                f.NameAccessSecurity.CanInsert().Returns(true);

                f.NameValidator.CheckDuplicates(Arg.Any<bool>(), Arg.Any<bool>(), Arg.Any<bool>(), Arg.Any<string>(),
                                                Arg.Any<string>())
                 .Returns(new List<DuplicateName>());

                f.CreateContactName.CreateContactName(Arg.Any<Contact>()).Returns(name);

                var result = await f.Subject.CreateNewContact(@case.Id, new Contact {Surname = ContactName, GivenName = ContactName});

                var caseName =
                    Db.Set<CaseName>()
                      .First(cn => cn.CaseId.Equals(@case.Id) && cn.NameId == name.Id && cn.NameTypeId == KnownNameTypes.Contact);

                Assert.NotNull(caseName);
                Assert.Equal(HttpStatusCode.OK, result.StatusCode);
            }

            [Fact]
            public async Task ReturnListOfDuplicateNamesIfNameAlreadyExists()
            {
                var f = new CrmControllerFixture(Db);

                var @case = new CaseBuilder {Irn = "1234/a"}.Build().In(Db);
                var contact = new Contact {Surname = ContactName, GivenName = ContactName};

                f.CaseAuthorization.Authorize(@case.Id, AccessPermissionLevel.Update).Returns(x =>
                {
                    var caseId = (int) x[0];
                    return new AuthorizationResult(caseId, true, false, null);
                });
                f.NameAccessSecurity.CanInsert().Returns(true);

                var duplicateList = new List<DuplicateName> {new DuplicateName {GivenName = ContactName}};
                f.NameValidator.CheckDuplicates(Arg.Any<bool>(), Arg.Any<bool>(), Arg.Any<bool>(), Arg.Any<string>(),
                                                Arg.Any<string>())
                 .Returns(duplicateList);

                var result = await f.Subject.CreateNewContact(@case.Id, contact);

                Assert.Equal(HttpStatusCode.Conflict, result.StatusCode);
            }

            [Fact]
            public async Task ThrowsExceptionWhenNameIsNotProvided()
            {
                var f = new CrmControllerFixture(Db);

                var @case = new CaseBuilder {Irn = "1234/a"}.Build().In(Db);

                var exception = await Assert.ThrowsAsync<HttpResponseException>(async () => await f.Subject.CreateNewContact(@case.Id, new Contact()));

                Assert.IsType<HttpResponseException>(exception);
                Assert.Equal(HttpStatusCode.BadRequest, exception.Response.StatusCode);
            }

            [Fact]
            public async Task ThrowsExceptionWhenProvidedCaseDoesnotExists()
            {
                var f = new CrmControllerFixture(Db);
                var contact = new Contact
                {
                    Surname = ContactName
                };

                var exception = await Assert.ThrowsAsync<HttpResponseException>(async () => await f.Subject.CreateNewContact(1, contact));

                Assert.IsType<HttpResponseException>(exception);
                Assert.Equal(HttpStatusCode.NotFound, exception.Response.StatusCode);
            }
        }

        public class CrmActivitySupportMethod : FactBase
        {
            const string ContactActivityCategory = "Contact Activity Category";
            const string ContactActivityType = "Contact Activity Type";

            [Fact]
            public void ReturnsProposedValuesForCrmActivitySupport()
            {
                new TableCode(Fixture.Integer(), (int) TableTypes.ContactActivityCategory, ContactActivityCategory).In(Db);
                new TableCode(Fixture.Integer(), (int) TableTypes.ContactActivityType, ContactActivityType).In(Db);
                new TableCode(KnownActivityTypes.PhoneCall, (int) TableTypes.ContactActivityType, ContactActivityType).In(Db);
                new TableCode(KnownActivityTypes.Correspondence, (int) TableTypes.ContactActivityType, ContactActivityType).In(Db);
                new TableCode(KnownActivityTypes.Email, (int) TableTypes.ContactActivityType, ContactActivityType).In(Db);
                new TableCode(KnownActivityTypes.Facsimile, (int) TableTypes.ContactActivityType, ContactActivityType).In(Db);

                var f = new CrmControllerFixture(Db);
                var r = f.Subject.ActivitySupport();

                var required = new[] {KnownActivityTypes.PhoneCall, KnownActivityTypes.Correspondence, KnownActivityTypes.Email, KnownActivityTypes.Facsimile};

                Assert.Equal(
                             ContactActivityCategory,
                             r.ActivityCategories.Single().ActivityCategoryDescription);
                Assert.Equal(
                             ContactActivityType,
                             r.ActivityTypes.First().ActivityTypeDescription);
                Assert.Equal(r.CallStatus.Count, KnownCallStatus.GetValues().Count);
                Assert.Equal(r.ActivityTypes.Where(
                                                   x => x.IsOutgoing).ToList().Count, required.Length);
            }
        }
    }
}