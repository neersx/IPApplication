using System;
using System.Collections.Generic;
using Inprotech.Web.Configuration.Jurisdictions.Maintenance;
using Inprotech.Web.Picklists;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Configuration.Jurisdictions
{
    public class JurisdictionModel
    {
        public string Id { get; set; }
        public string Type { get; set; }
        public string AlternateCode { get; set; }
        public string Name { get; set; }
        public string Abbreviation { get; set; }
        public string PostalName { get; set; }
        public string InformalName { get; set; }
        public string CountryAdjective { get; set; }
        public string IsdCode { get; set; }
        public bool? ReportPriorArt { get; set; }
        public string Notes { get; set; }
        public DateTime? DateCommenced { get; set; }
        public DateTime? DateCeased { get; set; }
        public short? WorkDayFlag { get; set; }
        public string StateLabel { get; set; }
        public bool StateAbbreviated { get; set; }
        public bool PostCodeFirst { get; set; }
        public string PostCodeLiteral { get; set; }
        public TableCodePicklistController.TableCodePicklistItem NameStyle { get; set; }
        public TableCodePicklistController.TableCodePicklistItem AddressStyle { get; set; }
        public bool PostCodeAutoFlag { get; set; }
        public TableCodePicklistController.TableCodePicklistItem PopulateCityFromPostCode { get; set; }
        public TaxRate DefaultTaxRate { get; set; }
        public Currency DefaultCurrency { get; set; }
        public bool IsTaxNumberMandatory { get; set; }
        public bool IsGroup { get; set; }
        public bool IsInternal { get; set; }
        public bool CanEdit { get; set; }
        public bool AllMembersFlag { get; set; }

        public Delta<GroupMembershipModel> GroupMembershipDelta { get; set; }

        public Delta<TextsModel> TextsDelta { get; set; }

        public Delta<AttributesMaintenanceModel> AttributesDelta { get; set; }

        public IList<AttributesMaintenanceModel> Attributes { get; set; }

        public Delta<StatusFlagsMaintenanceModel> StatusFlagsDelta { get; set; }

        public Delta<ClassesMaintenanceModel> ClassesDelta { get; set; }

        public Delta<StateMaintenanceModel> StateDelta { get; set; }

        public Delta<ValidNumbersMaintenanceModel> ValidNumbersDelta { get; set; }

        public Delta<CountryHolidayMaintenanceModel> CountryHolidaysDelta { get; set; }
    }

    public static class CountryExtensions
    {
        public static dynamic WithType(JurisdictionModel country)
        {
            country.IsGroup = KnownJurisdictionTypes.GetType(country.Type) == KnownJurisdictionTypes.GetType("1");
            country.IsInternal = KnownJurisdictionTypes.GetType(country.Type) == KnownJurisdictionTypes.GetType("2");
            return country;
        }
    }

    public class TaxRate
    {
        public string Id { get; set; }
       
        public string Description { get; set; }
    }
    
}