using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Extensions;
using InprotechKaizen.Model.Components.Cases.Screens;

namespace Inprotech.Web.Cases.Details
{

    public class CaseHeaderFieldMapper : ICaseViewFieldMapper
    {
        static readonly Dictionary<string, string> Mappings = new Dictionary<string, string>
                                                              {
                                                                  {"lblCaseReference", nameof(Overview.Irn)},
                                                                  {"lblTitle", nameof(Overview.Title)},
                                                                  {"lblPropertyTypeDescription", nameof(Overview.PropertyType)},
                                                                  {"lblCountryName", nameof(Overview.Country)},
                                                                  {"lblCaseCategoryDescription", nameof(Overview.CaseCategory)},
                                                                  {"lblSubTypeDescription", nameof(Overview.SubType)},
                                                                  {"lblApplicationBasisDescription", nameof(Overview.Basis)},
                                                                  {"lblStatusSummary", nameof(Overview.Status)},
                                                                  {"lblCaseStatusDescription", nameof(Overview.CaseStatus)},
                                                                  {"lblRenewalStatusDescription", nameof(Overview.RenewalStatus)},
                                                                  {"lblCurrentOfficialNumber", nameof(Overview.OfficialNumber)},
                                                                  {"lblCaseFamilyReference", nameof(Overview.Family)},
                                                                  {"lblCaseTypeDescription", nameof(Overview.CaseType)},
                                                                  {"lblCaseOffice", nameof(Overview.CaseOffice)},
                                                                  {"lblFileLocation", nameof(Overview.FileLocation)},
                                                                  {"pkProfitCentre", nameof(Overview.ProfitCentre)},
                                                                  {"cbLocalClientFlag", nameof(Overview.LocalClientFlag)},
                                                                  {"lblEntitySizeDescription", nameof(Overview.EntitySize)},
                                                                  {"lblTypeOfMarkDescription", nameof(Overview.TypeOfMark)},
                                                                  {"lblNoInSeries", nameof(Overview.NumberInSeries)},
                                                                  {"lblClasses", nameof(Overview.Classes)},
                                                                  {"lblWorkingAttorney", nameof(Overview.Staff)},
                                                                  {"lblFirstApplicant", nameof(Overview.FirstApplicant)},
                                                                  {"lblClientName", nameof(Overview.Instructor)},
                                                                  {"lblApplicationFilingDate", nameof(Overview.ApplicationFilingDate)},
                                                                  {"imgCaseImage", nameof(Overview.ImageKey)}
                                                              };

        public IEnumerable<ControllableField> Map(IEnumerable<ControllableField> fields)
        {
            if (fields == null) return null;
            var controllableFields = fields as ControllableField[] ?? fields.ToArray();
            foreach (var f in controllableFields)
            {
                if (Mappings.ContainsKey(f.FieldName))
                {
                    f.FieldName = Mappings[f.FieldName].MakeInitialLowerCase();
                }
            }
            return controllableFields;
        }
    }
}