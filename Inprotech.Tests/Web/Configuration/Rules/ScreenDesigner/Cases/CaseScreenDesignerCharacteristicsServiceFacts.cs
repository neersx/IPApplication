using Inprotech.Web.Configuration.Rules.ScreenDesigner.Cases;
using Inprotech.Web.Configuration.Rules.ValidCharacteristic;
using InprotechKaizen.Model.Components.Configuration.Rules.Workflow;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.Rules.ScreenDesigner.Cases
{
  
    public class CaseScreenDesignerCharacteristicsServiceFacts
    {
        public class GetCharacteristicsMethod : FactBase
        {
            [Fact]
            public void ReturnsValidCharacteristicsForCharacteristics()
            {
                var characteristics = new WorkflowCharacteristics()
                {
                    Action = Fixture.String(),
                    Basis = Fixture.String(),
                    CaseCategory = Fixture.String(),
                    CaseType = Fixture.String(),
                    Jurisdiction = Fixture.String(),
                    Office = Fixture.Integer(),
                    PropertyType = Fixture.String(),
                };
                var f = new CaseScreenDesignerCharacteristicsFixture();

                f.Subject.GetValidCharacteristics(characteristics);

                f.PropertyType.Received(1).GetPropertyType(characteristics.PropertyType, characteristics.Jurisdiction);
                f.Jurisdiction.Received(1).GetJurisdiction(characteristics.Jurisdiction);
                f.Office.Received(1).GetOffice(characteristics.Office);
                f.CaseType.Received(1).GetCaseType(characteristics.CaseType);
                f.SubType.Received(1).GetSubType(characteristics.SubType, characteristics.CaseType, characteristics.CaseCategory, characteristics.PropertyType, characteristics.Jurisdiction);
                f.Category.Received(1).GetCaseCategory(characteristics.CaseCategory, characteristics.CaseType, characteristics.PropertyType, characteristics.Jurisdiction);
                f.Program.Received(1).GetDefaultProgram();
                f.Basis.Received(1).GetBasis(characteristics.Basis, characteristics.CaseType, characteristics.CaseCategory, characteristics.PropertyType, characteristics.Jurisdiction);
            }
        }
    }

    public class CaseScreenDesignerCharacteristicsFixture : IFixture<CaseScreenDesignerCharacteristicsService>
    {
        public CaseScreenDesignerCharacteristicsFixture()
        {
            PropertyType = Substitute.For<IValidatedPropertyTypeCharacteristic>();
            Jurisdiction = Substitute.For<IValidatedJurisdictionCharacteristic>();
            Office = Substitute.For<IValidatedOfficeCharacteristic>();
            CaseType = Substitute.For<IValidatedCaseTypeCharacteristic>();
            SubType = Substitute.For<IValidatedSubTypeCharacteristic>();
            Category = Substitute.For<IValidatedCaseCategoryCharacteristic>();
            Basis = Substitute.For<IValidatedBasisCharacteristic>();
            Program= Substitute.For<IValidatedProgramCharacteristic>();
            Profile= Substitute.For<IValidatedProfileCharacteristic>();
            Subject = new CaseScreenDesignerCharacteristicsService(PropertyType, Jurisdiction, Office, CaseType, Category, SubType, Basis, Program, Profile);
        }
        public IValidatedPropertyTypeCharacteristic PropertyType { get; set; }
        public IValidatedJurisdictionCharacteristic Jurisdiction { get; set; }
        public IValidatedOfficeCharacteristic Office { get; set; }
        public IValidatedCaseTypeCharacteristic CaseType { get; set; }
        public IValidatedSubTypeCharacteristic SubType { get; set; }
        public IValidatedCaseCategoryCharacteristic Category { get; set; }
        public IValidatedBasisCharacteristic Basis { get; set; }
        public IValidatedProgramCharacteristic Program { get; set; }
        public IValidatedProfileCharacteristic Profile { get; set; }
        public CaseScreenDesignerCharacteristicsService Subject { get; }
    }
}
