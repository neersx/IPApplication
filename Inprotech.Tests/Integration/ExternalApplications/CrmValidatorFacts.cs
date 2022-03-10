using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Web.Http;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Security;
using Inprotech.Integration.ExternalApplications.Crm;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Common;
using Inprotech.Tests.Web.Builders.Model.Configuration;
using Inprotech.Tests.Web.Builders.Model.Names;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.ExternalApplications
{
    public class CrmContactFacts
    {
        public class CrmValidatorFixture : IFixture<CrmValidator>
        {
            public CrmValidatorFixture(InMemoryDbContext db)
            {
                DbContext = db;
                TaskSecurityProvider = Substitute.For<ITaskSecurityProvider>();

                Subject = new CrmValidator(DbContext, TaskSecurityProvider);
            }

            public IDbContext DbContext { get; set; }

            public ITaskSecurityProvider TaskSecurityProvider { get; set; }

            public CrmValidator Subject { get; }
        }

        public class ValidateAttributeMethod : FactBase
        {
            void Setup()
            {
                new TableCodeBuilder {TableCode = 1, TableType = 1}.Build().In(Db);
            }

            [Fact]
            public void ReturnsFalseIfAttributeIsNotFound()
            {
                Setup();

                var result = new CrmValidatorFixture(Db).Subject.ValidateAttribute(new SelectedAttribute
                {
                    AttributeTypeId = 1,
                    AttributeId = 2
                });

                Assert.False(result);
            }

            [Fact]
            public void ReturnsTrueIfAttributeIsFound()
            {
                Setup();

                var result = new CrmValidatorFixture(Db).Subject.ValidateAttribute(new SelectedAttribute
                {
                    AttributeTypeId = 1,
                    AttributeId = 1
                });

                Assert.True(result);
            }

            [Fact]
            public void ReturnsTrueIfOfficeAttributeIsFound()
            {
                var office = new OfficeBuilder {Id = Fixture.Integer(), Name = Fixture.String()}.Build().In(Db);

                var result = new CrmValidatorFixture(Db).Subject.ValidateAttribute(new SelectedAttribute
                {
                    AttributeTypeId = (short) TableTypes.Office,
                    AttributeId = office.Id
                });

                Assert.True(result);
            }
        }

        public class ValidateTaskSecurityMethod : FactBase
        {
            [Fact]
            public void ThrowsExceptionIfUserDoesnotHaveAccessToTaskSecurity()
            {
                var f = new CrmValidatorFixture(Db);
                f.TaskSecurityProvider.HasAccessTo(Arg.Any<ApplicationTask>(), Arg.Any<ApplicationTaskAccessLevel>())
                 .Returns(false);

                var exception =
                    Record.Exception(
                                     () =>
                                         f.Subject.ValidateTaskSecurity(ApplicationTask.MaintainNameAttributes,
                                                                        ApplicationTaskAccessLevel.Create));

                Assert.NotNull(exception);
                Assert.IsType<HttpResponseException>(exception);
                Assert.Equal(HttpStatusCode.Forbidden, ((HttpResponseException) exception).Response.StatusCode);
            }
        }

        public class ValidateMaxAndMinLimitMethod : FactBase
        {
            public ValidateMaxAndMinLimitMethod()
            {
                _crmName = new NameBuilder(Db) {LastName = Fixture.String()}.Build().In(Db);
                _tableTypeIndustry = new TableTypeBuilder(Db).For(TableTypes.Industry).BuildWithTableCodes().In(Db);
                var selectionTypeIndustry =
                    new SelectionTypes(_tableTypeIndustry)
                    {
                        ParentTable = KnownParentTable.Individual,
                        MinimumAllowed = 1,
                        MaximumAllowed = 1,
                        ModifiableByService = true
                    }.In(Db);
                _availableSelectionTypes = new List<SelectionTypes>
                {
                    selectionTypeIndustry
                };
            }

            readonly Name _crmName;
            readonly TableType _tableTypeIndustry;
            readonly List<SelectionTypes> _availableSelectionTypes;

            [Fact]
            public void PassesIfAttributesAreUnderLimit()
            {
                TableAttributesBuilder
                    .ForName(_crmName)
                    .WithAttribute(TableTypes.Industry, _tableTypeIndustry.TableCodes.First().Id)
                    .Build().In(Db);

                var exception =
                    Record.Exception(
                                     () =>
                                         new CrmValidatorFixture(Db).Subject.ValidateMinAndMaxAttributeLimit(_crmName,
                                                                                                             _availableSelectionTypes));

                Assert.Null(exception);
            }

            [Fact]
            public void ReturnsErrorIfAttributesCrossesMaxLimit()
            {
                TableAttributesBuilder
                    .ForName(_crmName)
                    .WithAttribute(TableTypes.Industry, _tableTypeIndustry.TableCodes.First().Id)
                    .Build().In(Db);

                TableAttributesBuilder
                    .ForName(_crmName)
                    .WithAttribute(TableTypes.Industry, _tableTypeIndustry.TableCodes.ElementAt(1).Id)
                    .Build().In(Db);

                var exception =
                    Record.Exception(
                                     () =>
                                         new CrmValidatorFixture(Db).Subject.ValidateMinAndMaxAttributeLimit(_crmName,
                                                                                                             _availableSelectionTypes));

                Assert.NotNull(exception);
                Assert.IsType<HttpResponseException>(exception);
                Assert.Equal(HttpStatusCode.NotAcceptable, ((HttpResponseException) exception).Response.StatusCode);
            }

            [Fact]
            public void ReturnsErrorIfAttributesCrossesMinLimit()
            {
                var exception =
                    Record.Exception(
                                     () =>
                                         new CrmValidatorFixture(Db).Subject.ValidateMinAndMaxAttributeLimit(_crmName,
                                                                                                             _availableSelectionTypes));

                Assert.NotNull(exception);
                Assert.IsType<HttpResponseException>(exception);
                Assert.Equal(HttpStatusCode.NotAcceptable, ((HttpResponseException) exception).Response.StatusCode);
            }
        }

        public class IsCrmNameMethod : FactBase
        {
            [Fact]
            public void ReturnsFalseIfTheNameDoesNotHaveAnyCrmNameTypeClassificationAdded()
            {
                var nonCrmName = new NameBuilder(Db) {LastName = Fixture.String()}.Build().In(Db);
                Assert.False(new CrmValidatorFixture(Db).Subject.IsCrmName(nonCrmName));
            }

            [Fact]
            public void ReturnsFalseIfTheNameHasCrmNameTypeClassificationAndIsAllowedFlagIsNotSet()
            {
                var crmName = new NameBuilder(Db) {LastName = Fixture.String()}.Build().In(Db);
                var crmNameType = new NameTypeBuilder {PickListFlags = KnownNameTypeAllowedFlags.CrmNameType}.Build().In(Db);
                var ntc =
                    new NameTypeClassificationBuilder(Db) {Name = crmName, NameType = crmNameType, IsAllowed = 0}.Build()
                                                                                                                 .In(Db);
                crmName.NameTypeClassifications.Add(ntc);

                Assert.False(new CrmValidatorFixture(Db).Subject.IsCrmName(crmName));
            }

            [Fact]
            public void ReturnsTrueIfTheNameHasCrmNameTypeClassificationAndIsAllowedFlagSet()
            {
                var crmName = new NameBuilder(Db) {LastName = Fixture.String()}.Build().In(Db);
                var crmNameType = new NameTypeBuilder {PickListFlags = KnownNameTypeAllowedFlags.CrmNameType}.Build().In(Db);
                var ntc =
                    new NameTypeClassificationBuilder(Db) {Name = crmName, NameType = crmNameType, IsAllowed = 1}.Build()
                                                                                                                 .In(Db);
                crmName.NameTypeClassifications.Add(ntc);

                Assert.True(new CrmValidatorFixture(Db).Subject.IsCrmName(crmName));
            }
        }

        public class ValidateCrmCaseTaskSecurityMethod : FactBase
        {
            public ValidateCrmCaseTaskSecurityMethod()
            {
                new SiteControlBuilder {SiteControlId = SiteControls.PropertyTypeCampaign, StringValue = Campaign}.Build().In(Db);
                new SiteControlBuilder {SiteControlId = SiteControls.PropertyTypeMarketingEvent, StringValue = MarketingActivity}.Build().In(Db);
                new SiteControlBuilder {SiteControlId = SiteControls.PropertyTypeOpportunity, StringValue = Opportunity}.Build().In(Db);

                _fixture = new CrmValidatorFixture(Db);

                _fixture.TaskSecurityProvider.HasAccessTo(ApplicationTask.MaintainMarketingActivities,
                                                          Arg.Any<ApplicationTaskAccessLevel>())
                        .Returns(false);
                _fixture.TaskSecurityProvider.HasAccessTo(ApplicationTask.MaintainOpportunity,
                                                          Arg.Any<ApplicationTaskAccessLevel>())
                        .Returns(true);
            }

            readonly CrmValidatorFixture _fixture;

            const string MarketingActivity = "E";
            const string Opportunity = "A";
            const string Campaign = "F";

            [Fact]
            public void DoesNotThrowAnyExceptionIfPropertyTypeIsOpportunity()
            {
                var opportunityPropertyType = new PropertyTypeBuilder {Id = Opportunity}.Build().In(Db);
                var @case = new CaseBuilder {PropertyType = opportunityPropertyType}.Build().In(Db);

                var exception =
                    Record.Exception(
                                     () => _fixture.Subject.ValidateCrmCaseSecurity(@case));

                Assert.Null(exception);
            }

            [Fact]
            public void ThrowsExceptionIfPropertyTypeIsCampaign()
            {
                var campaignPropertyType = new PropertyTypeBuilder {Id = Campaign}.Build().In(Db);
                var @case = new CaseBuilder {PropertyType = campaignPropertyType}.Build().In(Db);

                var exception =
                    Record.Exception(
                                     () => _fixture.Subject.ValidateCrmCaseSecurity(@case));

                Assert.NotNull(exception);
                Assert.IsType<HttpResponseException>(exception);
                Assert.Equal(HttpStatusCode.Forbidden, ((HttpResponseException) exception).Response.StatusCode);
            }

            [Fact]
            public void ThrowsExceptionIfPropertyTypeIsMarketing()
            {
                var marketingPropertyType = new PropertyTypeBuilder {Id = MarketingActivity}.Build().In(Db);
                var @case = new CaseBuilder {PropertyType = marketingPropertyType}.Build().In(Db);

                var exception =
                    Record.Exception(
                                     () => _fixture.Subject.ValidateCrmCaseSecurity(@case));

                Assert.NotNull(exception);
                Assert.IsType<HttpResponseException>(exception);
                Assert.Equal(HttpStatusCode.Forbidden, ((HttpResponseException) exception).Response.StatusCode);
            }

            [Fact]
            public void ThrowsExceptionIfTheCaseIsNotACrmCaseType()
            {
                var campaignPropertyType = new PropertyTypeBuilder {Id = "T"}.Build().In(Db);
                var @case = new CaseBuilder {PropertyType = campaignPropertyType}.Build().In(Db);

                var exception =
                    Record.Exception(
                                     () => _fixture.Subject.ValidateCrmCaseSecurity(@case));

                Assert.NotNull(exception);
                Assert.IsType<HttpResponseException>(exception);
                Assert.Equal(HttpStatusCode.Forbidden, ((HttpResponseException) exception).Response.StatusCode);
            }
        }
    }
}