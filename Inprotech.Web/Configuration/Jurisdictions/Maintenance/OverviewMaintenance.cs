using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Validations;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Configuration.Jurisdictions.Maintenance
{
    public interface IOverviewMaintenance
    {
        void Save(JurisdictionModel formData, Operation operation);
        IEnumerable<ValidationError> Validate(JurisdictionModel formData, Operation operation);
    }

    public class OverviewMaintenance : IOverviewMaintenance
    {
        readonly IDbContext _dbContext;
        public OverviewMaintenance(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public void Save(JurisdictionModel formData, Operation operation)
        {
            if (operation == Operation.Update)
            {
                formData.Update(_dbContext);
            }
            else if (operation == Operation.Add)
            {
                formData.Create(_dbContext);
            }
        }

        public IEnumerable<ValidationError> Validate(JurisdictionModel formData, Operation operation)
        {
            var errors = new List<ValidationError>();

            var all = _dbContext.Set<Country>().ToArray();

            if (operation == Operation.Add && all.Any(v => string.Equals(v.Id, formData.Id, StringComparison.InvariantCultureIgnoreCase)))
            {
                errors.Add(ValidationErrors.NotUnique("jurisdictions.maintenance.errors.duplicate", "code", formData.Id));
            }
            if (formData.Type == "0" && operation == Operation.Update)
            {
                if (string.IsNullOrEmpty(formData.NameStyle?.Value))
                {
                    errors.Add(ValidationErrors.Required("addressSettings", "nameStyle"));
                }
                if (string.IsNullOrEmpty(formData.AddressStyle?.Value))
                {
                    errors.Add(ValidationErrors.Required("addressSettings", "addressStyle"));
                }
            }

            return errors;
        }
    }

    public static class JurisdictionModelExt
    {
        public static void Create(this JurisdictionModel formData, IDbContext dbContext)
        {
            dbContext.Set<Country>().Add(new Country(formData.Id, formData.Name, formData.Type)
            {
                AlternateCode = formData.Id,
                Abbreviation = formData.Name.Length < 10 ? formData.Name : formData.Name.Substring(0, 10),
                InformalName = formData.Name,
                AllMembersFlag = formData.AllMembersFlag ? 1 : 0,
                PostalName = KnownJurisdictionTypes.GetType(formData.Type) == KnownJurisdictionTypes.GetType() ? formData.Name : null
            });
        }

        public static void Update(this JurisdictionModel formData, IDbContext dbContext)
        {
            var jurisdiction = dbContext.Set<Country>().Single(_ => _.Id == formData.Id);
            jurisdiction.Type = formData.Type;
            jurisdiction.AlternateCode = formData.AlternateCode;
            jurisdiction.Name = formData.Name;
            jurisdiction.Abbreviation = formData.Abbreviation;
            jurisdiction.PostalName = formData.PostalName;
            jurisdiction.InformalName = formData.InformalName;
            jurisdiction.CountryAdjective = formData.CountryAdjective;
            jurisdiction.IsdCode = formData.IsdCode;
            jurisdiction.ReportPriorArt = formData.ReportPriorArt;
            jurisdiction.Notes = formData.Notes;
            jurisdiction.DateCommenced = formData.DateCommenced;
            jurisdiction.DateCeased = formData.DateCeased;
            jurisdiction.AllMembersFlag = formData.AllMembersFlag ? 1 : 0;
            jurisdiction.StateLabel = formData.StateLabel;
            jurisdiction.StateAbbreviated = formData.StateAbbreviated ? 1 : 0;
            jurisdiction.PostCodeFirst = formData.PostCodeFirst ? 1 : 0;
            jurisdiction.PostCodeLiteral = formData.PostCodeLiteral;
            jurisdiction.NameStyleId = formData.NameStyle?.Key;
            jurisdiction.AddressStyleId = formData.AddressStyle?.Key;
            jurisdiction.PostCodeAutoFlag = formData.PostCodeAutoFlag ? 1 : 0;
            jurisdiction.PostCodeSearchCodeId = formData.PopulateCityFromPostCode?.Key;
            jurisdiction.DefaultCurrencyId = formData.DefaultCurrency?.Id;
            jurisdiction.DefaultTaxId = formData.DefaultTaxRate?.Id;
            jurisdiction.TaxNoMandatory = formData.IsTaxNumberMandatory ? 1m : 0m;
            jurisdiction.WorkDayFlag = formData.WorkDayFlag;
        }
    }
}
