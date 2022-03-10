using System.Linq;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Web.Cases.Details;
using InprotechKaizen.Model.Components.Cases.Screens;
using Xunit;

namespace Inprotech.Tests.Web.Cases.Details
{
    public class CaseHeaderFieldMapperFacts
    {
        public class MapMethod : FactBase
        {
            [Theory]
            [InlineData("lblCaseReference", nameof(Overview.Irn))]
            [InlineData("lblTitle", nameof(Overview.Title))]
            [InlineData("lblPropertyTypeDescription", nameof(Overview.PropertyType))]
            [InlineData("lblCountryName", nameof(Overview.Country))]
            [InlineData("lblCaseCategoryDescription", nameof(Overview.CaseCategory))]
            [InlineData("lblSubTypeDescription", nameof(Overview.SubType))]
            [InlineData("lblApplicationBasisDescription", nameof(Overview.Basis))]
            [InlineData("lblStatusSummary", nameof(Overview.Status))]
            [InlineData("lblCaseStatusDescription", nameof(Overview.CaseStatus))]
            [InlineData("lblRenewalStatusDescription", nameof(Overview.RenewalStatus))]
            [InlineData("lblCurrentOfficialNumber", nameof(Overview.OfficialNumber))]
            [InlineData("lblCaseFamilyReference", nameof(Overview.Family))]
            [InlineData("lblCaseTypeDescription", nameof(Overview.CaseType))]
            [InlineData("lblCaseOffice", nameof(Overview.CaseOffice))]
            [InlineData("lblFileLocation", nameof(Overview.FileLocation))]
            [InlineData("pkProfitCentre", nameof(Overview.ProfitCentre))]
            [InlineData("cbLocalClientFlag", nameof(Overview.LocalClientFlag))]
            [InlineData("lblEntitySizeDescription", nameof(Overview.EntitySize))]
            [InlineData("lblTypeOfMarkDescription", nameof(Overview.TypeOfMark))]
            [InlineData("lblNoInSeries", nameof(Overview.NumberInSeries))]
            [InlineData("lblClasses", nameof(Overview.Classes))]
            [InlineData("lblWorkingAttorney", nameof(Overview.Staff))]
            [InlineData("lblFirstApplicant", nameof(Overview.FirstApplicant))]
            [InlineData("lblClientName", nameof(Overview.Instructor))]
            [InlineData("lblApplicationFilingDate", nameof(Overview.ApplicationFilingDate))]
            [InlineData("imgCaseImage", nameof(Overview.ImageKey))]
            [InlineData("lblNoMatch", "lblNoMatch")]
            public void MapsOnlyMatchingFields(string fieldName, string mapping)
            {
                var fields = new[] {new ControllableField {FieldName = fieldName, Hidden = Fixture.Boolean(), Label = Fixture.String()}};
                var f = new CaseHeaderFieldMapperFixture();
                var r = f.Subject.Map(fields);
                Assert.Equal(r.First().FieldName, mapping.MakeInitialLowerCase());
            }
        }

        public class CaseHeaderFieldMapperFixture
        {
            public CaseHeaderFieldMapperFixture()
            {
                Subject = new CaseHeaderFieldMapper();
            }

            public CaseHeaderFieldMapper Subject { get; set; }
        }
    }
}