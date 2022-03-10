using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Inprotech.Web.Characteristics;
using Inprotech.Web.Configuration.Rules.ValidCharacteristic;
using InprotechKaizen.Model.Components.Configuration.Rules.Workflow;

namespace Inprotech.Web.Configuration.Rules.Checklists
{
    public class ChecklistCharacteristicsService : ICharacteristicsService
    {
        readonly IValidatedPropertyTypeCharacteristic _validatedPropertyTypeCharacteristic;
        readonly IValidatedJurisdictionCharacteristic _validatedJurisdictionCharacteristic;
        readonly IValidatedOfficeCharacteristic _validatedOfficeCharacteristic;
        readonly IValidatedCaseTypeCharacteristic _validatedCaseTypeCharacteristic;
        readonly IValidatedCaseCategoryCharacteristic _validatedCaseCategoryCharacteristic;
        readonly IValidatedSubTypeCharacteristic _validatedSubTypeCharacteristic;
        readonly IValidatedBasisCharacteristic _validatedBasisCharacteristic;
        readonly IValidatedProfileCharacteristic _validatedProfileCharacteristic;
        public ChecklistCharacteristicsService(
            IValidatedPropertyTypeCharacteristic validatedPropertyTypeCharacteristic,
            IValidatedJurisdictionCharacteristic validatedJurisdictionCharacteristic,
            IValidatedOfficeCharacteristic validatedOfficeCharacteristic,
            IValidatedCaseTypeCharacteristic validatedCaseTypeCharacteristic,
            IValidatedCaseCategoryCharacteristic validatedCaseCategoryCharacteristic,
            IValidatedSubTypeCharacteristic validatedSubTypeCharacteristic,
            IValidatedBasisCharacteristic validatedBasisCharacteristic, 
            IValidatedProfileCharacteristic validatedProfileCharacteristic)
        {
            _validatedPropertyTypeCharacteristic = validatedPropertyTypeCharacteristic;
            _validatedJurisdictionCharacteristic = validatedJurisdictionCharacteristic;
            _validatedOfficeCharacteristic = validatedOfficeCharacteristic;
            _validatedCaseTypeCharacteristic = validatedCaseTypeCharacteristic;
            _validatedCaseCategoryCharacteristic = validatedCaseCategoryCharacteristic;
            _validatedSubTypeCharacteristic = validatedSubTypeCharacteristic;
            _validatedBasisCharacteristic = validatedBasisCharacteristic;
            _validatedProfileCharacteristic = validatedProfileCharacteristic;
        }

        public ValidatedCharacteristics GetValidCharacteristics(WorkflowCharacteristics characteristics)
        {
            return new ValidatedCharacteristics
            {
                Office = _validatedOfficeCharacteristic.GetOffice(characteristics.Office),
                CaseType = _validatedCaseTypeCharacteristic.GetCaseType(characteristics.CaseType),
                Jurisdiction = _validatedJurisdictionCharacteristic.GetJurisdiction(characteristics.Jurisdiction),
                PropertyType = _validatedPropertyTypeCharacteristic.GetPropertyType(characteristics.PropertyType, characteristics.Jurisdiction),
                CaseCategory = _validatedCaseCategoryCharacteristic.GetCaseCategory(characteristics.CaseCategory,
                    characteristics.CaseType, characteristics.PropertyType,
                    characteristics.Jurisdiction),

                SubType = _validatedSubTypeCharacteristic.GetSubType(characteristics.SubType, characteristics.CaseType,
                    characteristics.CaseCategory, characteristics.PropertyType, characteristics.Jurisdiction),

                Basis = _validatedBasisCharacteristic.GetBasis(characteristics.Basis, characteristics.CaseType,
                    characteristics.CaseCategory, characteristics.PropertyType,
                    characteristics.Jurisdiction),
                Profile = _validatedProfileCharacteristic.GetProfile(characteristics.Profile)
            };
        }

    }
}
