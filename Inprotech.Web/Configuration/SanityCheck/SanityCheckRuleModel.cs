using Inprotech.Web.Picklists;
using InprotechKaizen.Model.DataValidation;
using Newtonsoft.Json;

namespace Inprotech.Web.Configuration.SanityCheck
{
    public class CaseSanityCheckRuleModel
    {
        public CaseDataValidationModel DataValidation { get; set; }

        public CaseRelatedDataModel CaseDetails { get; set; }

        public CaseNameRelatedDataModel CaseNameDetails { get; set; }

        public OtherDataModel OtherDetails { get; set; }
    }

    public class NameSanityCheckRuleIntermediate
    {
        public DataValidation DataValidation { get; set; }
        public SanityCheckService.NameLite NameLite { get; set; }
        public PicklistModel<int> NameGroup { get; set; }
        public PicklistModel<string> Country { get; set; }
        public PicklistModel<string> Category { get; set; } 
        public bool? LocalClient { get; set; }
        public bool IsOrganisation { get; set; }
        public bool IsIndividual { get; set; }
        public bool IsClientOnly { get; set; }
        public bool IsStaff { get; set; }
        public bool IsSupplierOnly { get; set; }
    }

    public class NameSanityCheckRuleModel
    {
        public NameOverviewModel RuleOverView { get; set; }
        public NameCharacteristicsModel NameCharacteristics { get; set; }

        public NamesStandingInstructionsModel StandingInstruction { get; set; }

        public NamesOtherDetailsModel Other { get; set; }
    }

    public class BaseModel
    {
        public int ValidationId { get; set; }
    }

    public class NameOverviewModel : BaseModel
    {
        public PicklistModel<int> SanityCheckSql { get; set; }
        public PicklistModel<int> MayBypassError { get; set; }
        public string DisplayMessage { get; set; }
        public string RuleDescription { get; set; }
        public string Notes { get; set; }
        public bool InformationOnly { get; set; }
        public bool InUse { get; set; }
        public bool Deferred { get; set; }
        public bool IsStaff { get; set; }
    }

    public class NameCharacteristicsModel : BaseModel
    {
        [JsonIgnore]
        public SanityCheckService.NameLite NameLite { get; set; }
        public PicklistModel<int> Name => NameLite == null ? null : new PicklistModel<int> { Key = NameLite.Id, Code = null, Value = NameLite.Formatted() };
        public PicklistModel<int> NameGroup { get; set; }
        public PicklistModel<string> Jurisdiction { get; set; }
        public PicklistModel<string> Category { get; set; } 
        public int? ApplyTo { get; set; }
        public bool TypeIsOrganisation { get; set; }
        public bool TypeIsIndividual { get; set; }
        public bool TypeIsClientOnly { get; set; }
        public bool TypeIsStaff { get; set; }
        public bool TypeIsSupplierOnly { get; set; }
    }

    public class NamesStandingInstructionsModel : BaseModel
    {
        public PicklistModel<string> InstructionType { get; set; } 
        public PicklistModel<int> Characteristic { get; set; }
    }    
    public class NamesOtherDetailsModel : BaseModel
    {
        public PicklistModel<int> TableColumn { get; set; }
    }

    public class CaseRelatedDataModel : BaseModel
    {
        public PicklistModel<int> Office { get; set; }

        public PicklistModel<int> CaseType { get; set; }

        public PicklistModel<string> PropertyType { get; set; }

        public PicklistModel<string> Jurisdiction { get; set; }

        public PicklistModel<string> Category { get; set; }

        public PicklistModel<string> Basis { get; set; }

        public PicklistModel<string> SubType { get; set; }

        public bool StatusIncludePending { get; set; }
        public bool StatusIncludeRegistered { get; set; }
        public bool StatusIncludeDead { get; set; }

        public void SetStatusIncludeFlags(short? statusFlag)
        {
            switch (statusFlag)
            {
                case null: break;
                case 0:
                    StatusIncludeDead = true;
                    break;
                case 1:
                    StatusIncludePending = true;
                    break;
                case 2:
                    StatusIncludeRegistered = true;
                    break;
                case 3:
                    StatusIncludePending = true;
                    StatusIncludeRegistered = true;
                    break;
            }
        }
    }

    public class CaseDataValidationModel
    {
        public int Id { get; set; }
        public string DisplayMessage { get; set; }
        public string RuleDescription { get; set; }
        public string Notes { get; set; }
        public short? StatusFlag { get; set; }
        public short? Eventdateflag { get; set; }
        public bool? IsWarning { get; set; }
        public bool? InUseFlag { get; set; }
        public bool DeferredFlag { get; set; }
        public bool? NotCaseType { get; set; }
        public bool? NotCountryCode { get; set; }
        public bool? NotPropertyType { get; set; }
        public bool? NotCaseCategory { get; set; }
        public bool? NotSubtype { get; set; }
        public bool? NotBasis { get; set; }
        public bool? LocalclientFlag { get; set; }
        public short? UsedasFlag { get; set; }
        public bool? SupplierFlag { get; set; }
    }

    public class CaseNameRelatedDataModel : BaseModel
    {
        public PicklistModel<int> NameType { get; set; }

        public PicklistModel<int> Family { get; set; }

        public PicklistModel<int> Name => NameLite == null ? null : new PicklistModel<int> { Key = NameLite.Id, Code = null, Value = NameLite.Formatted() };

        [JsonIgnore]
        public SanityCheckService.NameLite NameLite { get; set; }
    }

    public class OtherDataModel : BaseModel
    {
        public PicklistModel<string> Instruction { get; set; }

        public PicklistModel<int> Characteristics { get; set; }

        public PicklistModel<int> TableCode { get; set; }

        public PicklistModel<int> RoleByPassError { get; set; }

        public PicklistModel<int> SanityCheckItem { get; set; }

        public PicklistModel<int> Event { get; set; }

        public bool EventIncludeDue { get; set; }

        public bool EventIncludeOccurred { get; set; }

        public void SetEventIncludeFlags(short? eventInclude)
        {
            switch (eventInclude)
            {
                case null: break;
                case 1:
                    EventIncludeOccurred = true;
                    break;
                case 2:
                    EventIncludeDue = true;
                    break;
                case 3:
                    EventIncludeOccurred = true;
                    EventIncludeDue = true;
                    break;
            }
        }
    }
}