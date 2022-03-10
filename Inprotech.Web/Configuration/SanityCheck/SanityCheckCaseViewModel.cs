using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using InprotechKaizen.Model.Components.Configuration.Rules.Workflow;
using InprotechKaizen.Model.DataValidation;

namespace Inprotech.Web.Configuration.SanityCheck
{
    public class SanityCheckCaseViewUpdateModel : SanityCheckCaseViewModel
    {
        public int ValidationId { get; set; }
    }

    public class SanityCheckCaseViewModel : BaseSanityCheckViewModel
    {
        public SanityCheckCaseViewModel()
        {
            CaseCharacteristics = new CaseCharacteristicsModel();
            CaseName = new CaseNameModel();
            Event = new EventModel();
        }

        public CaseCharacteristicsModel CaseCharacteristics { get; set; }

        public CaseNameModel CaseName { get; set; }

        public EventModel Event { get; set; }

        public bool IsValid()
        {
            return RuleOverview.IsValid() && StandingInstruction.IsValid();
        }

        public DataValidation ToDataValidation(DataValidation dataValidation = null)
        {
            dataValidation ??= new DataValidation();

            dataValidation.DisplayMessage = RuleOverview.DisplayMessage;
            dataValidation.RuleDescription = RuleOverview.RuleDescription;
            dataValidation.Notes = RuleOverview.Notes;
            dataValidation.DeferredFlag = RuleOverview.Deferred.GetValueOrDefault();
            dataValidation.InUseFlag = RuleOverview.InUse.GetValueOrDefault();
            dataValidation.IsWarning = RuleOverview.InformationOnly.GetValueOrDefault();
            dataValidation.ItemId = RuleOverview.SanityCheckSql;
            dataValidation.CanOverrideRoleId = RuleOverview.MayBypassError;

            dataValidation.OfficeId = CaseCharacteristics.Office;
            dataValidation.CaseType = CaseCharacteristics.CaseType;
            dataValidation.CountryCode = CaseCharacteristics.Jurisdiction;
            dataValidation.PropertyType = CaseCharacteristics.PropertyType;
            dataValidation.CaseCategory = CaseCharacteristics.CaseCategory;
            dataValidation.SubType = CaseCharacteristics.SubType;
            dataValidation.Basis = CaseCharacteristics.Basis;
            dataValidation.LocalclientFlag = CaseCharacteristics.ApplyTo;
            dataValidation.StatusFlag = CaseCharacteristics.GetStatusFlag();

            dataValidation.NotCaseType = CaseCharacteristics.CaseTypeExclude;
            dataValidation.NotCountryCode = CaseCharacteristics.JurisdictionExclude;
            dataValidation.NotPropertyType = CaseCharacteristics.PropertyTypeExclude;
            dataValidation.NotCaseCategory = CaseCharacteristics.CaseCategoryExclude;
            dataValidation.NotSubtype = CaseCharacteristics.SubTypeExclude;
            dataValidation.NotBasis = CaseCharacteristics.BasisExclude;

            dataValidation.NameId = CaseName.Name;
            dataValidation.FamilyNo = CaseName.NameGroup;
            dataValidation.NameType = CaseName.NameType;

            dataValidation.InstructionType = StandingInstruction.InstructionType;
            dataValidation.FlagNumber = StandingInstruction.Characteristics;

            dataValidation.EventNo = Event.EventNo;
            dataValidation.Eventdateflag = Event.GetEventDateFlag();

            dataValidation.ColumnName = Other.TableCode;

            return dataValidation;
        }
    }

    public class CaseCharacteristicsModel
    {
        public int? Office { get; set; }

        [MaxLength(1)]
        public string CaseType { get; set; }

        [MaxLength(3)]
        public string Jurisdiction { get; set; }

        [MaxLength(1)]
        public string PropertyType { get; set; }

        [MaxLength(2)]
        public string CaseCategory { get; set; }

        [MaxLength(2)]
        public string SubType { get; set; }

        [MaxLength(2)]
        public string Basis { get; set; }

        public bool? ApplyTo { get; set; }

        public bool StatusIncludePending { get; set; }

        public bool StatusIncludeRegistered { get; set; }

        public bool StatusIncludeDead { get; set; }

        public bool? CaseTypeExclude { get; set; }

        public bool? JurisdictionExclude { get; set; }

        public bool? PropertyTypeExclude { get; set; }

        public bool? CaseCategoryExclude { get; set; }

        public bool? SubTypeExclude { get; set; }

        public bool? BasisExclude { get; set; }

        public WorkflowCharacteristics ToWorkflowCharacteristics()
        {
            return new()
            {
                Office = Office,
                CaseType = CaseType,
                Jurisdiction = Jurisdiction,
                PropertyType = PropertyType,
                CaseCategory = CaseCategory,
                SubType = SubType,
                Basis = Basis
            };
        }

        public short? GetStatusFlag()
        {
            if (StatusIncludePending && StatusIncludeRegistered)
                return 3;

            if (StatusIncludeDead)
                return 0;

            if (StatusIncludePending)
                return 1;

            if (StatusIncludeRegistered)
                return 2;

            return null;
        }

        public short[] GetStatusFlags()
        {
            var statuses = new List<short>();

            if (StatusIncludeDead)
                statuses.Add(0);

            if (StatusIncludePending)
                statuses.Add(1);

            if (StatusIncludeRegistered)
                statuses.Add(2);

            if (StatusIncludePending || StatusIncludeRegistered)
                statuses.Add(3);

            return statuses.ToArray();
        }
    }

    public class CaseNameModel
    {
        public int? Name { get; set; }
        public short? NameGroup { get; set; }

        [MaxLength(3)]
        public string NameType { get; set; }

        public bool IsValid()
        {
            return !(Name.HasValue && NameGroup.HasValue);
        }
    }

    public class EventModel
    {
        public int? EventNo { get; set; }

        public short? GetEventDateFlag()
        {
            if (EventNo.HasValue)
                return (short)((IncludeOccurred.HasValue && IncludeOccurred.Value ? 1 : 0) + (IncludeDue.HasValue && IncludeDue.Value ? 2 : 0));

            return null;
        }

        public short[] GetEventDateFlags()
        {
            List<short> eventFlags = new List<short>();
            if (!EventNo.HasValue)
                return eventFlags.ToArray();

            if (IncludeOccurred.HasValue && IncludeOccurred.Value)
                eventFlags.Add(1);

            if (IncludeDue.HasValue && IncludeDue.Value)
                eventFlags.Add(2);

            if (IncludeDue.HasValue && IncludeDue.Value || IncludeOccurred.HasValue && IncludeOccurred.Value)
                eventFlags.Add(3);

            return eventFlags.ToArray();
        }

        public bool? IncludeDue { get; set; }

        public bool? IncludeOccurred { get; set; }
    }
}