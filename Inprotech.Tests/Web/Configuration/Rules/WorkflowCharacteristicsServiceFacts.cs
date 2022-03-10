using Inprotech.Web.Configuration.Rules.ValidCharacteristic;
using Inprotech.Web.Configuration.Rules.Workflow;
using InprotechKaizen.Model.Components.Configuration.Rules.Workflow;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.Rules
{
    public class WorkflowCharacteristicsServiceFacts
    {
        public class GetCharacteristicsMethod : FactBase
        {
            [Fact]
            public void ReturnsValidCharacteristicsForCharacteristics()
            {
                var characteristics = new WorkflowCharacteristics
                {
                    Action = Fixture.String(),
                    Basis = Fixture.String(),
                    CaseCategory = Fixture.String(),
                    CaseType = Fixture.String(),
                    Jurisdiction = Fixture.String(),
                    Office = Fixture.Integer(),
                    PropertyType = Fixture.String(),
                };
                var f = new WorkflowCharacteristicsFixture();

                f.Subject.GetValidCharacteristics(characteristics);

                f.PropertyType.Received(1).GetPropertyType(characteristics.PropertyType, characteristics.Jurisdiction);
                f.Jurisdiction.Received(1).GetJurisdiction(characteristics.Jurisdiction);
                f.Office.Received(1).GetOffice(characteristics.Office);
                f.CaseType.Received(1).GetCaseType(characteristics.CaseType);
                f.SubType.Received(1).GetSubType(characteristics.SubType, characteristics.CaseType, characteristics.CaseCategory, characteristics.PropertyType, characteristics.Jurisdiction);
                f.Category.Received(1).GetCaseCategory(characteristics.CaseCategory, characteristics.CaseType, characteristics.PropertyType, characteristics.Jurisdiction);
                f.Action.Received(1).GetAction(characteristics.Action, characteristics.Jurisdiction, characteristics.PropertyType, characteristics.CaseType);
                f.Basis.Received(1).GetBasis(characteristics.Basis, characteristics.CaseType, characteristics.CaseCategory, characteristics.PropertyType, characteristics.Jurisdiction);
            }
        }
    }

    public class WorkflowCharacteristicsFixture : IFixture<WorkflowCharacteristicsService>
    {
        public WorkflowCharacteristicsFixture()
        {
            PropertyType = Substitute.For<IValidatedPropertyTypeCharacteristic>();
            Jurisdiction = Substitute.For<IValidatedJurisdictionCharacteristic>();
            Office = Substitute.For<IValidatedOfficeCharacteristic>();
            CaseType = Substitute.For<IValidatedCaseTypeCharacteristic>();
            SubType = Substitute.For<IValidatedSubTypeCharacteristic>();
            Category = Substitute.For<IValidatedCaseCategoryCharacteristic>();
            Action = Substitute.For<IValidatedActionCharacteristic>();
            Basis = Substitute.For<IValidatedBasisCharacteristic>();
            Subject = new WorkflowCharacteristicsService(PropertyType, Jurisdiction, Office, CaseType, Category, SubType, Action, Basis);
        }
        public IValidatedPropertyTypeCharacteristic PropertyType { get; set; }
        public IValidatedJurisdictionCharacteristic Jurisdiction { get; set; }
        public IValidatedOfficeCharacteristic Office { get; set; }
        public IValidatedCaseTypeCharacteristic CaseType { get; set; }
        public IValidatedSubTypeCharacteristic SubType { get; set; }
        public IValidatedCaseCategoryCharacteristic Category { get; set; }
        public IValidatedActionCharacteristic Action { get; set; }
        public IValidatedBasisCharacteristic Basis { get; set; }
        public WorkflowCharacteristicsService Subject { get; }
    }
}